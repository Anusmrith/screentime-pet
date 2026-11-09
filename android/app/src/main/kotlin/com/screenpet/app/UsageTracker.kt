package com.screenpet.app

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * Event-driven Screen Habit Tracker.
 *
 * Tracks daily phone unlocks and total active screen-on time with zero battery drain.
 * Strictly avoids polling loops by relying exclusively on dynamic broadcast receivers
 * for ACTION_SCREEN_ON, ACTION_SCREEN_OFF, ACTION_USER_PRESENT, and ACTION_DATE_CHANGED.
 *
 * Automatically performs midnight reset at 12:00 AM (00:00) like a clock,
 * resetting active seconds and unlocks fresh for each new calendar day.
 */
class UsageTracker(private val context: Context) {

    interface Listener {
        fun onUnlock(totalScreenTimeMs: Long, unlockCount: Int, timeSinceLastScreenOffMs: Long)
        fun onScreenStateChanged(isScreenOn: Boolean, totalScreenTimeMs: Long)
        fun onDailyReset()
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val mainHandler = Handler(Looper.getMainLooper())
    private var listener: Listener? = null
    private var isReceiverRegistered = false
    private var hasUnlockedThisScreenSession = false
    private var isKeyguardPolling = false

    private val keyguardPollingRunnable = object : Runnable {
        override fun run() {
            if (!isScreenCurrentlyOn() || hasUnlockedThisScreenSession) {
                isKeyguardPolling = false
                return
            }
            val unlocked = recordUnlockIfPresent("keyguard_poll")
            if (unlocked || hasUnlockedThisScreenSession) {
                isKeyguardPolling = false
            } else if (isScreenCurrentlyOn()) {
                mainHandler.postDelayed(this, 350L)
            } else {
                isKeyguardPolling = false
            }
        }
    }

    private fun startKeyguardPolling() {
        if (!isKeyguardPolling && !hasUnlockedThisScreenSession && isScreenCurrentlyOn()) {
            isKeyguardPolling = true
            mainHandler.removeCallbacks(keyguardPollingRunnable)
            mainHandler.postDelayed(keyguardPollingRunnable, 200L)
        }
    }

    private fun stopKeyguardPolling() {
        isKeyguardPolling = false
        mainHandler.removeCallbacks(keyguardPollingRunnable)
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON -> handleScreenOn()
                Intent.ACTION_SCREEN_OFF -> handleScreenOff()
                Intent.ACTION_USER_PRESENT -> handleUserUnlock()
                Intent.ACTION_DATE_CHANGED,
                Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED -> handleDateOrTimeChanged()
            }
        }
    }

    fun setListener(listener: Listener?) {
        this.listener = listener
    }

    /**
     * Registers dynamic broadcast receiver for screen and midnight clock events.
     * Zero-polling approach ensures zero background battery drain.
     */
    fun startTracking() {
        if (!isReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
                addAction(Intent.ACTION_DATE_CHANGED)
                addAction(Intent.ACTION_TIME_CHANGED)
                addAction(Intent.ACTION_TIMEZONE_CHANGED)
            }
            ContextCompat.registerReceiver(
                context,
                receiver,
                filter,
                ContextCompat.RECEIVER_NOT_EXPORTED
            )
            isReceiverRegistered = true

            // Initialize state in case screen is already on when service spawns
            checkAndResetDailyStats()
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val isInteractive = powerManager?.isInteractive ?: true
            if (isInteractive) {
                hasUnlockedThisScreenSession = true
                val now = System.currentTimeMillis()
                val currentScreenOn = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
                if (currentScreenOn == 0L) {
                    prefs.edit()
                        .putLong(KEY_SCREEN_ON_TIMESTAMP, now)
                        .putLong(KEY_CONTINUOUS_SESSION_START, now)
                        .apply()
                }
            } else {
                hasUnlockedThisScreenSession = false
            }
        }
    }

    /**
     * Unregisters the dynamic broadcast receiver.
     */
    fun stopTracking() {
        if (isReceiverRegistered) {
            stopKeyguardPolling()
            // Commit any currently ongoing screen-on session before stopping
            handleScreenOff()
            try {
                context.unregisterReceiver(receiver)
            } catch (ignored: IllegalArgumentException) {
            }
            isReceiverRegistered = false
        }
    }

    private fun handleScreenOn() {
        stopKeyguardPolling()
        hasUnlockedThisScreenSession = false
        checkAndResetDailyStats()
        val now = System.currentTimeMillis()
        prefs.edit()
            .putLong(KEY_SCREEN_ON_TIMESTAMP, now)
            .putLong(KEY_CONTINUOUS_SESSION_START, now)
            .apply()

        // 1. First notify listeners that screen is ON so live ticker and views are primed
        listener?.onScreenStateChanged(isScreenOn = true, getTodayScreenTimeMs())

        // 2. Check if already unlocked (e.g. fingerprint sensor woke & unlocked device, or no lockscreen)
        val unlockedImmediately = recordUnlockIfPresent("screen_on")

        // 3. If still locked (e.g. user clicked power button), poll keyguard until unlocked or screen off
        if (!unlockedImmediately && !hasUnlockedThisScreenSession) {
            startKeyguardPolling()
        }
    }

    private fun handleScreenOff() {
        stopKeyguardPolling()
        hasUnlockedThisScreenSession = false
        checkAndResetDailyStats()
        val now = System.currentTimeMillis()
        val screenOnTime = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
        val accumulated = prefs.getLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
        val elapsed = if (screenOnTime > 0L) (now - screenOnTime).coerceAtLeast(0L) else 0L

        prefs.edit()
            .putLong(KEY_ACCUMULATED_SCREEN_TIME_MS, accumulated + elapsed)
            .putLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
            .putLong(KEY_CONTINUOUS_SESSION_START, 0L)
            .putLong(KEY_LAST_SCREEN_OFF_TIMESTAMP, now)
            .apply()

        listener?.onScreenStateChanged(isScreenOn = false, getTodayScreenTimeMs())
    }

    private fun handleUserUnlock() {
        stopKeyguardPolling()
        recordUnlockIfPresent("user_present")
    }

    /**
     * Evaluates and records an unlock event deterministically.
     * Guarantees exact 1 unlock per user session without duplicate triggers.
     */
    @Synchronized
    fun recordUnlockIfPresent(source: String = "unknown"): Boolean {
        // If already triggered for this screen wake-up, do not duplicate
        if (hasUnlockedThisScreenSession) {
            return false
        }

        // For non-USER_PRESENT sources (screen_on, keyguard poll, second_ticker), verify keyguard is truly dismissed
        if (source != "user_present") {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val isInteractive = powerManager?.isInteractive ?: true
            if (!isInteractive) {
                return false
            }

            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            val isLocked = try {
                keyguardManager?.isKeyguardLocked ?: false
            } catch (e: Exception) {
                false
            }
            if (isLocked) {
                // Keyguard is still showing; user has not completed authentication yet
                return false
            }
        }

        val now = System.currentTimeMillis()
        val lastUnlockTime = prefs.getLong(KEY_LAST_UNLOCK_TIMESTAMP, 0L)
        val lastOff = prefs.getLong(KEY_LAST_SCREEN_OFF_TIMESTAMP, 0L)

        // Only debounce rapid duplicate triggers (< 500ms) if screen did NOT turn off in between
        if (now - lastUnlockTime < 500L && lastOff <= lastUnlockTime) {
            return false
        }

        hasUnlockedThisScreenSession = true
        stopKeyguardPolling()
        checkAndResetDailyStats()

        val timeSinceOff = if (lastOff > 0L) (now - lastOff).coerceAtLeast(0L) else -1L
        val currentUnlocks = prefs.getInt(KEY_UNLOCK_COUNT, 0) + 1

        prefs.edit()
            .putLong(KEY_LAST_UNLOCK_TIMESTAMP, now)
            .putInt(KEY_UNLOCK_COUNT, currentUnlocks)
            .apply()

        val screenTime = getTodayScreenTimeMs()
        listener?.onUnlock(screenTime, currentUnlocks, timeSinceOff)
        return true
    }

    private fun handleDateOrTimeChanged() {
        checkAndResetDailyStats()
        listener?.onDailyReset()
    }

    /**
     * Resets habit counters at 12:00 AM (midnight) automatically by comparing stored date string (yyyyMMdd).
     * If the screen is on across midnight, the new day's screen time accurately starts at 00:00:00.
     */
    fun checkAndResetDailyStats() {
        val now = System.currentTimeMillis()
        val todayStr = getTodayDateString(now)
        val storedDate = prefs.getString(KEY_DATE, null)

        if (storedDate == null) {
            // First run initialization
            val isScreenOn = isScreenCurrentlyOn()
            prefs.edit()
                .putString(KEY_DATE, todayStr)
                .putLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
                .putInt(KEY_UNLOCK_COUNT, 0)
                .putLong(KEY_SCREEN_ON_TIMESTAMP, if (isScreenOn) now else 0L)
                .putLong(KEY_CONTINUOUS_SESSION_START, if (isScreenOn) now else 0L)
                .apply()
            return
        }

        if (storedDate != todayStr) {
            val isScreenOn = isScreenCurrentlyOn()
            val previousScreenOn = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
            val startOfToday = getStartOfDayMillis(now)

            // If device was on across midnight (within the last 12 hours),
            // the portion of the session belonging to today starts exactly at midnight (12:00 AM)
            val wasOngoingSession = isScreenOn && previousScreenOn > 0L && (now - previousScreenOn) < (12 * 60 * 60 * 1000L)
            val newScreenOnTimestamp = if (wasOngoingSession) {
                startOfToday
            } else if (isScreenOn) {
                now
            } else {
                0L
            }

            prefs.edit()
                .putString(KEY_DATE, todayStr)
                .putLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
                .putInt(KEY_UNLOCK_COUNT, 0)
                .putLong(KEY_SCREEN_ON_TIMESTAMP, newScreenOnTimestamp)
                .apply()

            listener?.onDailyReset()
        }
    }

    /**
     * Manually resets today's stats immediately (useful for testing or debug reset).
     */
    fun resetTodayStatsNow() {
        val now = System.currentTimeMillis()
        val todayStr = getTodayDateString(now)
        val isScreenOn = isScreenCurrentlyOn()
        hasUnlockedThisScreenSession = isScreenOn
        prefs.edit()
            .putString(KEY_DATE, todayStr)
            .putLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
            .putInt(KEY_UNLOCK_COUNT, 0)
            .putLong(KEY_LAST_UNLOCK_TIMESTAMP, 0L)
            .putLong(KEY_SCREEN_ON_TIMESTAMP, if (isScreenOn) now else 0L)
            .putLong(KEY_CONTINUOUS_SESSION_START, if (isScreenOn) now else 0L)
            .apply()
        listener?.onDailyReset()
    }

    /**
     * Returns total active screen-on time in milliseconds for today.
     * Incorporates currently active session if screen is on right now.
     */
    fun getTodayScreenTimeMs(): Long {
        checkAndResetDailyStats()
        val accumulated = prefs.getLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
        val screenOnTime = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)

        return if (screenOnTime > 0L) {
            val currentSession = (System.currentTimeMillis() - screenOnTime).coerceAtLeast(0L)
            accumulated + currentSession
        } else {
            accumulated
        }
    }

    /**
     * Returns today's total unlock count.
     */
    fun getTodayUnlockCount(): Int {
        checkAndResetDailyStats()
        return prefs.getInt(KEY_UNLOCK_COUNT, 0)
    }

    /**
     * Checks if the device screen is currently interactive.
     */
    fun isScreenCurrentlyOn(): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return powerManager?.isInteractive ?: true
    }

    /**
     * Returns current ongoing continuous session time in ms (for doomscroll fatigue tracking).
     */
    fun getCurrentContinuousScreenTimeMs(): Long {
        val sessionStart = prefs.getLong(KEY_CONTINUOUS_SESSION_START, 0L)
        return if (sessionStart > 0L) (System.currentTimeMillis() - sessionStart).coerceAtLeast(0L) else 0L
    }

    companion object {
        const val PREFS_NAME = "screen_pet_habits"
        private const val KEY_DATE = "pref_habit_date"
        private const val KEY_ACCUMULATED_SCREEN_TIME_MS = "pref_accumulated_screen_time_ms"
        private const val KEY_UNLOCK_COUNT = "pref_unlock_count"
        private const val KEY_SCREEN_ON_TIMESTAMP = "pref_screen_on_timestamp"
        private const val KEY_CONTINUOUS_SESSION_START = "pref_continuous_session_start"
        private const val KEY_LAST_SCREEN_OFF_TIMESTAMP = "pref_last_screen_off_timestamp"
        private const val KEY_LAST_UNLOCK_TIMESTAMP = "pref_last_unlock_timestamp"
        private const val UNLOCK_DEBOUNCE_MS = 1500L

        fun getTodayDateString(timestamp: Long = System.currentTimeMillis()): String {
            val formatter = SimpleDateFormat("yyyyMMdd", Locale.US)
            return formatter.format(Date(timestamp))
        }

        /**
         * Computes the epoch timestamp of 12:00:00.000 AM (midnight) for the given timestamp.
         */
        fun getStartOfDayMillis(timestamp: Long = System.currentTimeMillis()): Long {
            val cal = Calendar.getInstance()
            cal.timeInMillis = timestamp
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            return cal.timeInMillis
        }

        /**
         * Formats duration in milliseconds into a sleek format with seconds,
         * e.g. "1h 24m 05s", "12m 34s", or "0m 15s".
         */
        fun formatDuration(millis: Long): String {
            val totalSeconds = (millis / 1000).coerceAtLeast(0)
            val hours = totalSeconds / 3600
            val minutes = (totalSeconds % 3600) / 60
            val seconds = totalSeconds % 60

            return when {
                hours > 0 -> "${hours}h ${minutes}m ${String.format(Locale.US, "%02ds", seconds)}"
                else -> "${minutes}m ${String.format(Locale.US, "%02ds", seconds)}"
            }
        }

        /**
         * Formats badge stats string with seconds and unlock count,
         * e.g. "12m 34s • 18 🔓" or "1h 24m 05s • 18 🔓"
         */
        fun formatBadgeStats(screenTimeMs: Long, unlockCount: Int): String {
            val durationStr = formatDuration(screenTimeMs)
            return "$durationStr • $unlockCount 🔓"
        }
    }
}


