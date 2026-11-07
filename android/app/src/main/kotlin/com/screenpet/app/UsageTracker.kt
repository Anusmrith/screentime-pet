package com.screenpet.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.PowerManager
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Event-driven Screen Habit Tracker.
 *
 * Tracks daily phone unlocks and total active screen-on time with zero battery drain.
 * Strictly avoids polling loops by relying exclusively on dynamic broadcast receivers
 * for ACTION_SCREEN_ON, ACTION_SCREEN_OFF, and ACTION_USER_PRESENT.
 *
 * Automatically performs midnight reset whenever queried across day boundaries.
 */
class UsageTracker(private val context: Context) {

    interface Listener {
        fun onUnlock(totalScreenTimeMs: Long, unlockCount: Int, timeSinceLastScreenOffMs: Long)
        fun onScreenStateChanged(isScreenOn: Boolean, totalScreenTimeMs: Long)
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private var listener: Listener? = null
    private var isReceiverRegistered = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_ON -> handleScreenOn()
                Intent.ACTION_SCREEN_OFF -> handleScreenOff()
                Intent.ACTION_USER_PRESENT -> handleUserUnlock()
            }
        }
    }

    fun setListener(listener: Listener?) {
        this.listener = listener
    }

    /**
     * Registers dynamic broadcast receiver for screen events.
     * Zero-polling approach ensures zero background battery drain.
     */
    fun startTracking() {
        if (!isReceiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            context.registerReceiver(receiver, filter)
            isReceiverRegistered = true

            // Initialize state in case screen is already on when service spawns
            checkAndResetDailyStats()
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            val isInteractive = powerManager?.isInteractive ?: true
            if (isInteractive) {
                val currentScreenOn = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
                if (currentScreenOn == 0L) {
                    prefs.edit().putLong(KEY_SCREEN_ON_TIMESTAMP, System.currentTimeMillis()).apply()
                }
            }
        }
    }

    /**
     * Unregisters the dynamic broadcast receiver.
     */
    fun stopTracking() {
        if (isReceiverRegistered) {
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
        checkAndResetDailyStats()
        prefs.edit().putLong(KEY_SCREEN_ON_TIMESTAMP, System.currentTimeMillis()).apply()
        listener?.onScreenStateChanged(isScreenOn = true, getTodayScreenTimeMs())
    }

    private fun handleScreenOff() {
        checkAndResetDailyStats()
        val now = System.currentTimeMillis()
        val screenOnTime = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
        if (screenOnTime > 0L) {
            val elapsed = (now - screenOnTime).coerceAtLeast(0L)
            val accumulated = prefs.getLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
            prefs.edit()
                .putLong(KEY_ACCUMULATED_SCREEN_TIME_MS, accumulated + elapsed)
                .putLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
                .putLong(KEY_LAST_SCREEN_OFF_TIMESTAMP, now)
                .apply()
        } else {
            prefs.edit().putLong(KEY_LAST_SCREEN_OFF_TIMESTAMP, now).apply()
        }
        listener?.onScreenStateChanged(isScreenOn = false, getTodayScreenTimeMs())
    }

    private fun handleUserUnlock() {
        checkAndResetDailyStats()
        val lastOff = prefs.getLong(KEY_LAST_SCREEN_OFF_TIMESTAMP, 0L)
        val timeSinceOff = if (lastOff > 0L) (System.currentTimeMillis() - lastOff).coerceAtLeast(0L) else -1L
        val currentUnlocks = prefs.getInt(KEY_UNLOCK_COUNT, 0) + 1
        prefs.edit().putInt(KEY_UNLOCK_COUNT, currentUnlocks).apply()

        val screenTime = getTodayScreenTimeMs()
        listener?.onUnlock(screenTime, currentUnlocks, timeSinceOff)
    }

    /**
     * Resets habit counters at midnight automatically by comparing stored date string (yyyyMMdd).
     */
    fun checkAndResetDailyStats() {
        val todayStr = getTodayDateString()
        val storedDate = prefs.getString(KEY_DATE, null)

        if (storedDate != todayStr) {
            prefs.edit()
                .putString(KEY_DATE, todayStr)
                .putLong(KEY_ACCUMULATED_SCREEN_TIME_MS, 0L)
                .putInt(KEY_UNLOCK_COUNT, 0)
                .putLong(KEY_SCREEN_ON_TIMESTAMP, if (isScreenCurrentlyOn()) System.currentTimeMillis() else 0L)
                .apply()
        }
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
     * Returns current ongoing continuous session time in ms.
     */
    fun getCurrentContinuousScreenTimeMs(): Long {
        val screenOn = prefs.getLong(KEY_SCREEN_ON_TIMESTAMP, 0L)
        return if (screenOn > 0L) (System.currentTimeMillis() - screenOn).coerceAtLeast(0L) else 0L
    }

    companion object {
        const val PREFS_NAME = "screen_pet_habits"
        private const val KEY_DATE = "pref_habit_date"
        private const val KEY_ACCUMULATED_SCREEN_TIME_MS = "pref_accumulated_screen_time_ms"
        private const val KEY_UNLOCK_COUNT = "pref_unlock_count"
        private const val KEY_SCREEN_ON_TIMESTAMP = "pref_screen_on_timestamp"
        private const val KEY_LAST_SCREEN_OFF_TIMESTAMP = "pref_last_screen_off_timestamp"

        fun getTodayDateString(): String {
            val formatter = SimpleDateFormat("yyyyMMdd", Locale.US)
            return formatter.format(Date())
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

