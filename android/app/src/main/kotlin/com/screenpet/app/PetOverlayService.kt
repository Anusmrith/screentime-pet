package com.screenpet.app

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.graphics.ImageDecoder
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.AnimatedImageDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.view.animation.LinearInterpolator
import android.view.animation.OvershootInterpolator
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.util.Random
import kotlin.math.abs

/**
 * Floating Punch-Hole Overlay Service.
 *
 * Runs as an optimized ForegroundService that draws a floating minimalist companion view
 * using WindowManager and TYPE_APPLICATION_OVERLAY. Configured with LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS,
 * FLAG_LAYOUT_NO_LIMITS, and FLAG_NOT_FOCUSABLE so that it renders right up against the display
 * cutout inside the status bar area without letterboxing.
 */
class PetOverlayService : Service(), UsageTracker.Listener {

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var windowParams: WindowManager.LayoutParams? = null

    private lateinit var ivPet: ImageView
    private lateinit var layoutStatsBadge: LinearLayout
    private lateinit var tvStatsBadgeText: TextView
    private lateinit var rootContainer: LinearLayout

    private lateinit var usageTracker: UsageTracker
    private lateinit var prefs: SharedPreferences

    private val mainHandler = Handler(Looper.getMainLooper())
    private var isTickerRunning = false
    private var activeRoastUntilMs = 0L
    private var isCustomAnimating = false
    private var isWalking = false
    private var isNapping = false
    private var lastInteractiveEventTimeMs = System.currentTimeMillis()
    private val random = Random()
    private var idleAnimator: ValueAnimator? = null
    private var isDoomscrollWarningShown = false
    private var currentPetDrawable: Drawable? = null
    private var revertToIdleRunnable: Runnable? = null

    private val ambientActionRunnable = Runnable {
        triggerAmbientBehavior()
    }

    private val secondTickerRunnable = object : Runnable {
        override fun run() {
            usageTracker.checkAndResetDailyStats()
            updateStatsBadge()
            mainHandler.postDelayed(this, 1000L)
        }
    }

    private val settingsReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_UPDATE_SETTINGS -> {
                    applyCalibrationSettings()
                    val lang = prefs.getString(KEY_LANGUAGE_MODE, "manglish") ?: "manglish"
                    RoastEngine.setLanguage(lang)
                }
                ACTION_UPDATE_LANGUAGE -> {
                    val lang = prefs.getString(KEY_LANGUAGE_MODE, "manglish") ?: "manglish"
                    RoastEngine.setLanguage(lang)
                }
                ACTION_STOP_SERVICE -> stopSelf()
                ACTION_SHOW_PET -> showOverlay()
                ACTION_DISMISS_PET -> hideOverlay()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        setTheme(R.style.Theme_Bubbloo)
        isRunning = true
        prefs = getSharedPreferences(PREFS_SETTINGS, Context.MODE_PRIVATE)
        prefs.edit().putBoolean(KEY_SERVICE_ENABLED, true).apply()

        val initialLang = prefs.getString(KEY_LANGUAGE_MODE, "manglish") ?: "manglish"
        RoastEngine.setLanguage(initialLang)

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        usageTracker = UsageTracker(this)
        usageTracker.setListener(this)
        usageTracker.startTracking()

        val filter = IntentFilter().apply {
            addAction(ACTION_UPDATE_SETTINGS)
            addAction(ACTION_UPDATE_LANGUAGE)
            addAction(ACTION_STOP_SERVICE)
            addAction(ACTION_SHOW_PET)
            addAction(ACTION_DISMISS_PET)
        }
        ContextCompat.registerReceiver(
            this,
            settingsReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )

        createNotificationChannel()
        startServiceInForeground()

        val canDraw = android.provider.Settings.canDrawOverlays(this)
        val shouldShow = prefs.getBoolean(KEY_OVERLAY_VISIBLE, true) && canDraw
        if (shouldShow) {
            showOverlay()
        } else {
            hideOverlay()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.service_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.service_channel_desc)
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingOpenApp = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleIntent = Intent(this, PetOverlayService::class.java).apply {
            action = if (isOverlayVisible) ACTION_DISMISS_PET else ACTION_SHOW_PET
        }
        val pendingToggle = PendingIntent.getService(
            this,
            1,
            toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = if (isOverlayVisible) "Bubbloo Active" else "Bubbloo Habit Tracker"
        val text = if (isOverlayVisible) "Companion floating on camera cutout" else "Tracking screen time & unlocks in background"
        val actionText = if (isOverlayVisible) "Dismiss Bubbloo" else "Show Bubbloo"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_pet)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingOpenApp)
            .addAction(0, actionText, pendingToggle)
            .build()
    }

    private fun startServiceInForeground() {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIFICATION_ID, buildNotification())
    }

    fun showOverlay() {
        if (!android.provider.Settings.canDrawOverlays(this)) {
            return
        }
        isOverlayVisible = true
        prefs.edit().putBoolean(KEY_OVERLAY_VISIBLE, true).apply()

        mainHandler.post {
            if (overlayView == null) {
                initOverlayView()
            } else {
                val view = overlayView ?: return@post
                val params = windowParams ?: return@post
                if (view.parent == null) {
                    try {
                        calculatePosition(params)
                        windowManager.addView(view, params)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
                view.visibility = View.VISIBLE
                setPetAnimation(R.raw.cat_idle, loop = true)
                updateStatsBadge(force = true)
                if (usageTracker.isScreenCurrentlyOn()) {
                    startSecondTicker()
                    startIdleBreathing()
                    scheduleNextAmbientAction()
                }
            }
            updateNotification()
        }
    }

    fun hideOverlay() {
        isOverlayVisible = false
        prefs.edit().putBoolean(KEY_OVERLAY_VISIBLE, false).apply()

        mainHandler.post {
            stopSecondTicker()
            stopIdleBreathing()
            cancelAmbientAction()
            if (isWalking) {
                ivPet.animate().cancel()
                ivPet.translationX = 0f
                isWalking = false
            }
            (currentPetDrawable as? AnimatedImageDrawable)?.stop()
            revertToIdleRunnable?.let { mainHandler.removeCallbacks(it) }
            revertToIdleRunnable = null
            overlayView?.let { view ->
                if (view.parent != null) {
                    try {
                        windowManager.removeView(view)
                    } catch (ignored: Exception) {
                    }
                }
                view.visibility = View.GONE
            }
            updateNotification()
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun initOverlayView() {
        val themedContext = android.view.ContextThemeWrapper(this, R.style.Theme_Bubbloo)
        val inflater = LayoutInflater.from(themedContext)
        overlayView = inflater.inflate(R.layout.layout_pet_overlay, null)

        val view = overlayView ?: return
        rootContainer = view.findViewById(R.id.rootOverlayContainer)
        ivPet = view.findViewById(R.id.ivPetOverlay)
        layoutStatsBadge = view.findViewById(R.id.layoutStatsBadge)
        tvStatsBadgeText = view.findViewById(R.id.tvStatsBadgeText)

        rootContainer.clipChildren = false
        rootContainer.clipToPadding = false
        (view as? ViewGroup)?.clipChildren = false
        (view as? ViewGroup)?.clipToPadding = false

        // Always visible badge; tapping badge triggers poke or dismisses active roast
        layoutStatsBadge.setOnClickListener {
            if (activeRoastUntilMs > System.currentTimeMillis()) {
                dismissRoast()
            } else {
                onPetPoked()
            }
        }

        // Interactive touch dragging & tap listener on pet
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false
        val touchSlop = ViewConfiguration.get(this).scaledTouchSlop

        ivPet.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    cancelAmbientAction()
                    if (isWalking) {
                        ivPet.animate().cancel()
                        ivPet.translationX = 0f
                        isWalking = false
                    }
                    if (isNapping) {
                        isNapping = false
                    }
                    lastInteractiveEventTimeMs = System.currentTimeMillis()
                    initialX = windowParams?.x ?: 0
                    initialY = windowParams?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY
                    if (!isDragging && (abs(dx) > touchSlop || abs(dy) > touchSlop)) {
                        isDragging = true
                        setPetAnimation(R.raw.cat_pounce, loop = true)
                    }
                    if (isDragging) {
                        windowParams?.let { params ->
                            val screenW = getDisplayWidth()
                            val viewW = overlayView?.width ?: 0

                            params.x = (initialX + dx.toInt()).coerceIn(0, (screenW - viewW).coerceAtLeast(0))
                            params.y = (initialY + dy.toInt()).coerceAtLeast(0)
                            try {
                                windowManager.updateViewLayout(overlayView, params)
                            } catch (ignored: Exception) {
                            }
                        }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (isDragging) {
                        windowParams?.let { params ->
                            val screenW = getDisplayWidth()
                            val density = resources.displayMetrics.density
                            val petSizeDp = prefs.getInt(KEY_PET_SIZE_DP, DEFAULT_PET_SIZE_DP)
                            val petSizePx = (petSizeDp * density).toInt()

                            val newXPercent = ((params.x + petSizePx / 2f) / screenW * 100f).coerceIn(0f, 100f)
                            val newYDp = (params.y / density).toInt().coerceIn(0, 80)

                            prefs.edit()
                                .putFloat(KEY_X_PERCENT, newXPercent)
                                .putInt(KEY_Y_OFFSET_DP, newYDp)
                                .apply()

                            applyCalibrationSettings()
                        }
                        playSquashBounce()
                        setPetAnimation(R.raw.cat_idle, loop = true)
                        scheduleNextAmbientAction()
                    } else {
                        onPetPoked()
                    }
                    true
                }
                else -> false
            }
        }

        // Layout parameters configured specifically for seamless punch-hole drawing
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
            }
        }

        windowParams = params

        // Initialize badge content & ensure it is always visible
        updateStatsBadge()
        layoutStatsBadge.visibility = View.VISIBLE
        layoutStatsBadge.alpha = 1.0f
        layoutStatsBadge.scaleX = 1.0f
        layoutStatsBadge.scaleY = 1.0f

        calculatePosition(params)

        try {
            windowManager.addView(view, params)
            setPetAnimation(R.raw.cat_idle, loop = true)
            isOverlayVisible = true
            prefs.edit().putBoolean(KEY_OVERLAY_VISIBLE, true).apply()
        } catch (e: Exception) {
            e.printStackTrace()
            isOverlayVisible = false
            return
        }

        // Start live 1-second ticker and gentle idle breathing if screen is interactive
        if (usageTracker.isScreenCurrentlyOn()) {
            startSecondTicker()
            startIdleBreathing()
        }
    }

    /**
     * Calculates the window X and Y based on user calibration sliders.
     */
    private fun calculatePosition(params: WindowManager.LayoutParams) {
        val xPercent = prefs.getFloat(KEY_X_PERCENT, DEFAULT_X_PERCENT)
        val yOffsetDp = prefs.getInt(KEY_Y_OFFSET_DP, DEFAULT_Y_OFFSET_DP)
        val petSizeDp = prefs.getInt(KEY_PET_SIZE_DP, DEFAULT_PET_SIZE_DP)

        val density = resources.displayMetrics.density
        val petSizePx = (petSizeDp * density).toInt()

        // Update pet ImageView layout size
        val petLp = ivPet.layoutParams
        if (petLp.width != petSizePx || petLp.height != petSizePx) {
            petLp.width = petSizePx
            petLp.height = petSizePx
            ivPet.layoutParams = petLp
        }

        val screenWidth = getDisplayWidth()
        val yPx = (yOffsetDp * density).toInt()

        val petTargetLeft = ((screenWidth * (xPercent / 100f)) - (petSizePx / 2f)).toInt()

        // Dynamic badge orientation: if pet is placed near right edge (> 70%),
        // badge extends leftward [Badge] [Pet] so it never clips off-screen edge.
        // Otherwise (including default 55% center punch-hole), pet sits flush beside cutout [Pet] [Badge].
        val expandToLeft = xPercent > 70f
        adjustBadgeOrientation(expandToLeft)

        overlayView?.measure(
            View.MeasureSpec.makeMeasureSpec(screenWidth, View.MeasureSpec.AT_MOST),
            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
        )
        val totalWidth = overlayView?.measuredWidth ?: petSizePx

        val windowX = if (expandToLeft) {
            (petTargetLeft - (totalWidth - petSizePx)).coerceIn(0, (screenWidth - totalWidth).coerceAtLeast(0))
        } else {
            petTargetLeft.coerceIn(0, (screenWidth - totalWidth).coerceAtLeast(0))
        }

        params.x = windowX
        params.y = yPx
    }

    private fun adjustBadgeOrientation(expandToLeft: Boolean) {
        val root = rootContainer
        val pet = ivPet
        val badge = layoutStatsBadge

        root.removeAllViews()
        if (expandToLeft) {
            // [Badge] [Pet]
            val badgeLp = badge.layoutParams as? ViewGroup.MarginLayoutParams
            badgeLp?.marginEnd = (5 * resources.displayMetrics.density).toInt()
            badgeLp?.marginStart = 0
            badge.layoutParams = badgeLp
            root.addView(badge)
            root.addView(pet)
        } else {
            // [Pet] [Badge]
            val badgeLp = badge.layoutParams as? ViewGroup.MarginLayoutParams
            badgeLp?.marginStart = (5 * resources.displayMetrics.density).toInt()
            badgeLp?.marginEnd = 0
            badge.layoutParams = badgeLp
            root.addView(pet)
            root.addView(badge)
        }
    }

    /**
     * Re-applies position and size when sliders change in MainActivity.
     */
    private fun applyCalibrationSettings() {
        val view = overlayView ?: return
        val params = windowParams ?: return

        if (isWalking) {
            ivPet.animate().cancel()
            ivPet.translationX = 0f
            isWalking = false
        }

        calculatePosition(params)
        try {
            windowManager.updateViewLayout(view, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /**
     * Sets and starts an animated GIF on the pet ImageView using Android's native AnimatedImageDrawable.
     * If autoRevertMs > 0, automatically reverts to R.raw.cat_idle after the specified duration.
     */
    private fun setPetAnimation(resId: Int, loop: Boolean = true, autoRevertMs: Long = 0L) {
        if (!::ivPet.isInitialized) return

        revertToIdleRunnable?.let { mainHandler.removeCallbacks(it) }
        revertToIdleRunnable = null

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val source = ImageDecoder.createSource(resources, resId)
                val drawable = ImageDecoder.decodeDrawable(source)
                ivPet.setImageDrawable(drawable)
                currentPetDrawable = drawable
                if (drawable is AnimatedImageDrawable) {
                    drawable.repeatCount = if (loop) AnimatedImageDrawable.REPEAT_INFINITE else 0
                    drawable.start()
                }
            } else {
                ivPet.setImageResource(R.drawable.ic_pet)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            ivPet.setImageResource(R.drawable.ic_pet)
        }

        if (autoRevertMs > 0L) {
            revertToIdleRunnable = Runnable {
                setPetAnimation(R.raw.cat_idle, loop = true)
            }
            mainHandler.postDelayed(revertToIdleRunnable!!, autoRevertMs)
        }
    }

    /**
     * Idle Breathing Loop: Pet gently hovers vertically by 2-3dp so it feels alive.
     */
    private fun startIdleBreathing() {
        stopIdleBreathing()
        val density = resources.displayMetrics.density
        idleAnimator = ValueAnimator.ofFloat(0f, -2.5f * density, 0f).apply {
            duration = 2400
            repeatCount = ValueAnimator.INFINITE
            interpolator = AccelerateDecelerateInterpolator()
            addUpdateListener { anim ->
                if (!isCustomAnimating) {
                    ivPet.translationY = anim.animatedValue as Float
                }
            }
            start()
        }
    }

    private fun stopIdleBreathing() {
        idleAnimator?.cancel()
        idleAnimator = null
        if (!isCustomAnimating) {
            ivPet.translationY = 0f
        }
    }

    /**
     * Animation 1: Squash & Stretch Double-Bounce.
     */
    private fun playSquashBounce() {
        isCustomAnimating = true
        val density = resources.displayMetrics.density
        ivPet.animate()
            .scaleX(1.35f)
            .scaleY(0.7f)
            .setDuration(120)
            .withEndAction {
                ivPet.animate()
                    .scaleX(0.85f)
                    .scaleY(1.3f)
                    .translationY(-10f * density)
                    .setDuration(160)
                    .setInterpolator(DecelerateInterpolator())
                    .withEndAction {
                        ivPet.animate()
                            .scaleX(1.0f)
                            .scaleY(1.0f)
                            .translationY(0f)
                            .setDuration(180)
                            .setInterpolator(OvershootInterpolator(2.0f))
                            .withEndAction { isCustomAnimating = false }
                            .start()
                    }
                    .start()
            }
            .start()
    }

    /**
     * Animation 2: 360 Somersault Barrel Roll.
     */
    private fun playSomersaultRoll() {
        isCustomAnimating = true
        ivPet.animate()
            .rotationBy(360f)
            .scaleX(1.25f)
            .scaleY(1.25f)
            .setDuration(360)
            .setInterpolator(AccelerateDecelerateInterpolator())
            .withEndAction {
                ivPet.animate()
                    .scaleX(1.0f)
                    .scaleY(1.0f)
                    .setDuration(140)
                    .withEndAction {
                        ivPet.rotation = 0f
                        isCustomAnimating = false
                    }
                    .start()
            }
            .start()
    }

    /**
     * Animation 3: Startled Wobble / Shiver.
     */
    private fun playWobbleShiver() {
        isCustomAnimating = true
        ivPet.animate()
            .rotation(-22f)
            .setDuration(80)
            .withEndAction {
                ivPet.animate()
                    .rotation(22f)
                    .setDuration(80)
                    .withEndAction {
                        ivPet.animate()
                            .rotation(-12f)
                            .setDuration(70)
                            .withEndAction {
                                ivPet.animate()
                                    .rotation(0f)
                                    .setDuration(70)
                                    .withEndAction { isCustomAnimating = false }
                                    .start()
                            }
                            .start()
                    }
                    .start()
            }
            .start()
    }

    /**
     * Animation 4: Peek-A-Boo Dip behind the notch.
     */
    private fun playPeekABoo() {
        isCustomAnimating = true
        val dipDistance = -14f * resources.displayMetrics.density
        ivPet.animate()
            .translationY(dipDistance)
            .scaleX(0.75f)
            .scaleY(0.75f)
            .setDuration(180)
            .withEndAction {
                mainHandler.postDelayed({
                    ivPet.animate()
                        .translationY(0f)
                        .scaleX(1.2f)
                        .scaleY(1.2f)
                        .setDuration(220)
                        .setInterpolator(OvershootInterpolator(2.5f))
                        .withEndAction {
                            ivPet.animate()
                                .scaleX(1.0f)
                                .scaleY(1.0f)
                                .setDuration(120)
                                .withEndAction { isCustomAnimating = false }
                                .start()
                        }
                        .start()
                }, 140)
            }
            .start()
    }

    /**
     * Plays a random poke animation when user taps the pet.
     */
    private fun playRandomPokeAnimation() {
        val pokeAnimRes = when ((0..3).random()) {
            0 -> R.raw.cat_play
            1 -> R.raw.cat_happy
            2 -> R.raw.cat_pounce
            else -> R.raw.cat_jump
        }
        setPetAnimation(pokeAnimRes, loop = true, autoRevertMs = 2400L)

        when ((0..3).random()) {
            0 -> playSquashBounce()
            1 -> playSomersaultRoll()
            2 -> playWobbleShiver()
            3 -> playPeekABoo()
        }
    }

    /**
     * Wake up pop animation when the phone is unlocked.
     */
    private fun playWakeUpAnimation() {
        isCustomAnimating = true
        val density = resources.displayMetrics.density
        ivPet.translationY = -18f * density
        ivPet.scaleX = 0.5f
        ivPet.scaleY = 0.5f
        ivPet.animate()
            .translationY(0f)
            .scaleX(1.25f)
            .scaleY(1.25f)
            .setDuration(350)
            .setInterpolator(OvershootInterpolator(2.2f))
            .withEndAction {
                ivPet.animate()
                    .scaleX(1.0f)
                    .scaleY(1.0f)
                    .setDuration(150)
                    .withEndAction { isCustomAnimating = false }
                    .start()
            }
            .start()
    }

    /**
     * Doomscroll tilt to look exhausted.
     */
    private fun playDoomscrollTilt() {
        setPetAnimation(R.raw.cat_curious, loop = true, autoRevertMs = 3500L)
        ivPet.animate()
            .rotation(15f)
            .setDuration(300)
            .start()
    }

    /**
     * Displays a sarcastic roast or dialogue in the status pill for a set duration.
     */
    private fun showRoast(text: String, durationMs: Long = 4500L) {
        prefs.edit().putString(KEY_LAST_ROAST, text).apply()
        activeRoastUntilMs = System.currentTimeMillis() + durationMs
        tvStatsBadgeText.text = text

        // Subtle pop-in bounce on badge
        layoutStatsBadge.scaleX = 0.85f
        layoutStatsBadge.scaleY = 0.85f
        layoutStatsBadge.animate()
            .scaleX(1.0f)
            .scaleY(1.0f)
            .setDuration(200)
            .setInterpolator(OvershootInterpolator(2.0f))
            .start()

        // Update window layout so WindowManager expands to wrap the roast text width
        windowParams?.let { params ->
            try {
                windowManager.updateViewLayout(overlayView, params)
            } catch (ignored: Exception) {
            }
        }
    }

    private fun dismissRoast() {
        if (activeRoastUntilMs > 0L) {
            activeRoastUntilMs = 0L
            updateStatsBadge(force = true)
        }
    }

    /**
     * Triggered on pet tap: runs a randomized animation & triggers a witty poke roast!
     */
    private fun onPetPoked() {
        lastInteractiveEventTimeMs = System.currentTimeMillis()
        if (isWalking) {
            ivPet.animate().cancel()
            ivPet.translationX = 0f
            isWalking = false
        }
        if (isNapping) {
            isNapping = false
            playWakeUpAnimation()
            setPetAnimation(R.raw.cat_happy, loop = true, autoRevertMs = 2400L)
            showRoast("Yaaawn... awake now! 🐾")
            scheduleNextAmbientAction()
            return
        }
        playRandomPokeAnimation()
        val screenTimeMs = usageTracker.getTodayScreenTimeMs()
        val unlocks = usageTracker.getTodayUnlockCount()
        showRoast(RoastEngine.getPokeRoast(unlocks, screenTimeMs))
        scheduleNextAmbientAction()
    }

    private fun scheduleNextAmbientAction(minDelayMs: Long = 11000L, maxDelayMs: Long = 22000L) {
        cancelAmbientAction()
        if (!usageTracker.isScreenCurrentlyOn() || !isOverlayVisible) return

        val delay = minDelayMs + (random.nextFloat() * (maxDelayMs - minDelayMs)).toLong()
        mainHandler.postDelayed(ambientActionRunnable, delay)
    }

    private fun cancelAmbientAction() {
        mainHandler.removeCallbacks(ambientActionRunnable)
    }

    private fun triggerAmbientBehavior() {
        if (!isOverlayVisible || !usageTracker.isScreenCurrentlyOn()) return
        if (isCustomAnimating || isWalking) {
            scheduleNextAmbientAction(6000L, 12000L)
            return
        }
        if (activeRoastUntilMs > System.currentTimeMillis()) {
            scheduleNextAmbientAction(6000L, 12000L)
            return
        }

        val now = System.currentTimeMillis()
        val timeSinceInteraction = now - lastInteractiveEventTimeMs

        // If inactive for > 120s, take a temporary 14-second catnap, then wake back up automatically
        if (timeSinceInteraction > 120000L && !isNapping) {
            isNapping = true
            setPetAnimation(R.raw.cat_sleep, loop = true, autoRevertMs = 14000L)
            mainHandler.postDelayed({
                if (isOverlayVisible && usageTracker.isScreenCurrentlyOn()) {
                    isNapping = false
                    lastInteractiveEventTimeMs = System.currentTimeMillis()
                    setPetAnimation(R.raw.cat_wave, loop = true, autoRevertMs = 2600L)
                    showRoast("Yawn... still on duty! 🐾", durationMs = 4000L)
                    scheduleNextAmbientAction(14000L, 24000L)
                }
            }, 14000L)
            return
        }

        if (isNapping) {
            scheduleNextAmbientAction(10000L, 20000L)
            return
        }

        val choice = random.nextInt(6)
        when (choice) {
            0, 1 -> performAmbientWalk() // Pacing walk across status bar!
            2 -> performAmbientLookAround()
            3 -> performAmbientPlay()
            4 -> performAmbientWave()
            5 -> performAmbientHappy()
        }
    }

    private fun performAmbientWalk() {
        if (isWalking || isCustomAnimating) return
        isWalking = true

        val xPercent = prefs.getFloat(KEY_X_PERCENT, DEFAULT_X_PERCENT)
        val walkLeft = when {
            xPercent > 70f -> true
            xPercent < 30f -> false
            else -> random.nextBoolean()
        }

        val density = resources.displayMetrics.density
        val walkDistDp = 22f + (random.nextFloat() * 14f)
        val targetTranslationX = if (walkLeft) -walkDistDp * density else walkDistDp * density

        val walkAnimRes = if (walkLeft) R.raw.cat_walk else R.raw.cat_walk_right
        setPetAnimation(walkAnimRes, loop = true)

        ivPet.animate()
            .translationX(targetTranslationX)
            .setDuration(1200)
            .setInterpolator(LinearInterpolator())
            .withEndAction {
                if (!isWalking || !isOverlayVisible) return@withEndAction
                setPetAnimation(R.raw.cat_look_around, loop = true)
                mainHandler.postDelayed({
                    if (!isWalking || !isOverlayVisible) return@postDelayed
                    val returnAnimRes = if (walkLeft) R.raw.cat_walk_right else R.raw.cat_walk
                    setPetAnimation(returnAnimRes, loop = true)
                    ivPet.animate()
                        .translationX(0f)
                        .setDuration(1200)
                        .setInterpolator(LinearInterpolator())
                        .withEndAction {
                            isWalking = false
                            setPetAnimation(R.raw.cat_idle, loop = true)
                            scheduleNextAmbientAction()
                        }
                        .start()
                }, 1600)
            }
            .start()
    }

    private fun performAmbientLookAround() {
        setPetAnimation(R.raw.cat_look_around, loop = true, autoRevertMs = 2800L)
        if (activeRoastUntilMs <= System.currentTimeMillis() && random.nextBoolean()) {
            showRoast(RoastEngine.getAmbientWhisper(), durationMs = 4000L)
        }
        ivPet.animate()
            .rotation(7f)
            .setDuration(300)
            .withEndAction {
                ivPet.animate()
                    .rotation(-7f)
                    .setDuration(300)
                    .withEndAction {
                        ivPet.rotation = 0f
                    }
                    .start()
            }
            .start()
        scheduleNextAmbientAction()
    }

    private fun performAmbientPlay() {
        setPetAnimation(R.raw.cat_play, loop = true, autoRevertMs = 2500L)
        if (activeRoastUntilMs <= System.currentTimeMillis() && random.nextBoolean()) {
            showRoast(RoastEngine.getAmbientWhisper(), durationMs = 4000L)
        }
        playSquashBounce()
        scheduleNextAmbientAction()
    }

    private fun performAmbientWave() {
        setPetAnimation(R.raw.cat_wave, loop = true, autoRevertMs = 2500L)
        if (activeRoastUntilMs <= System.currentTimeMillis()) {
            showRoast(RoastEngine.getAmbientWhisper(), durationMs = 4500L)
        }
        scheduleNextAmbientAction()
    }

    private fun performAmbientHappy() {
        setPetAnimation(R.raw.cat_happy, loop = true, autoRevertMs = 2400L)
        if (activeRoastUntilMs <= System.currentTimeMillis() && random.nextBoolean()) {
            showRoast(RoastEngine.getAmbientWhisper(), durationMs = 4000L)
        }
        val density = resources.displayMetrics.density
        ivPet.animate()
            .translationY(-5f * density)
            .setDuration(160)
            .withEndAction {
                ivPet.animate()
                    .translationY(0f)
                    .setDuration(160)
                    .start()
            }
            .start()
        scheduleNextAmbientAction()
    }

    /**
     * Updates the persistent stats badge text with live seconds and unlock count.
     */
    private fun updateStatsBadge(force: Boolean = false) {
        val now = System.currentTimeMillis()
        if (!force && now < activeRoastUntilMs) {
            return
        }

        // Check doomscroll milestone (> 25 mins continuous)
        val continuousMs = usageTracker.getCurrentContinuousScreenTimeMs()
        if (continuousMs > 25 * 60 * 1000L && !isDoomscrollWarningShown) {
            isDoomscrollWarningShown = true
            showRoast(RoastEngine.getDoomscrollRoast())
            playDoomscrollTilt()
            return
        } else if (continuousMs < 25 * 60 * 1000L) {
            isDoomscrollWarningShown = false
        }

        val screenTimeMs = usageTracker.getTodayScreenTimeMs()
        val unlocks = usageTracker.getTodayUnlockCount()
        val statsText = UsageTracker.formatBadgeStats(screenTimeMs, unlocks)
        if (tvStatsBadgeText.text != statsText) {
            tvStatsBadgeText.text = statsText
            windowParams?.let { params ->
                try {
                    windowManager.updateViewLayout(overlayView, params)
                } catch (ignored: Exception) {
                }
            }
        }
    }

    private fun startSecondTicker() {
        if (!isTickerRunning) {
            isTickerRunning = true
            mainHandler.removeCallbacks(secondTickerRunnable)
            mainHandler.post(secondTickerRunnable)
        }
    }

    private fun stopSecondTicker() {
        isTickerRunning = false
        mainHandler.removeCallbacks(secondTickerRunnable)
    }

    /**
     * UsageTracker.Listener callback: Called whenever user unlocks the phone.
     */
    override fun onUnlock(totalScreenTimeMs: Long, unlockCount: Int, timeSinceLastScreenOffMs: Long) {
        mainHandler.post {
            updateNotification()
            if (isOverlayVisible) {
                lastInteractiveEventTimeMs = System.currentTimeMillis()
                isNapping = false
                if (isWalking) {
                    ivPet.animate().cancel()
                    ivPet.translationX = 0f
                    isWalking = false
                }
                val unlockAnimRes = if (unlockCount % 5 == 0) R.raw.cat_celebrate else R.raw.cat_wave
                setPetAnimation(unlockAnimRes, loop = true, autoRevertMs = 3000L)
                playWakeUpAnimation()
                showRoast(RoastEngine.getUnlockRoast(unlockCount, timeSinceLastScreenOffMs), durationMs = 5000L)
                startSecondTicker()
                startIdleBreathing()
                scheduleNextAmbientAction(14000L, 24000L)
            }
        }
    }

    /**
     * UsageTracker.Listener callback: Screen on / off transitions.
     * When screen is ON -> start 1s live ticker, idle breathing & ambient wander.
     * When screen is OFF -> stop ticker, breathing & ambient loop immediately for ZERO battery drain.
     */
    override fun onScreenStateChanged(isScreenOn: Boolean, totalScreenTimeMs: Long) {
        mainHandler.post {
            if (isOverlayVisible) {
                if (isScreenOn) {
                    lastInteractiveEventTimeMs = System.currentTimeMillis()
                    isNapping = false
                    setPetAnimation(R.raw.cat_idle, loop = true)
                    updateStatsBadge()
                    startSecondTicker()
                    startIdleBreathing()
                    scheduleNextAmbientAction(8000L, 16000L)
                } else {
                    stopSecondTicker()
                    stopIdleBreathing()
                    cancelAmbientAction()
                    if (isWalking) {
                        ivPet.animate().cancel()
                        ivPet.translationX = 0f
                        isWalking = false
                    }
                    (currentPetDrawable as? AnimatedImageDrawable)?.stop()
                    revertToIdleRunnable?.let { mainHandler.removeCallbacks(it) }
                    revertToIdleRunnable = null
                }
            }
        }
    }

    /**
     * UsageTracker.Listener callback: Midnight clock or date-changed reset.
     * Automatically clears fatigue warnings and refreshes the badge to 0m 00s • 0 🔓 like a clock.
     */
    override fun onDailyReset() {
        mainHandler.post {
            isDoomscrollWarningShown = false
            if (isOverlayVisible) {
                updateStatsBadge(force = true)
            }
        }
    }

    private fun getDisplayWidth(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = windowManager.currentWindowMetrics
            val bounds: Rect = metrics.bounds
            bounds.width()
        } else {
            val dm = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealMetrics(dm)
            dm.widthPixels
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_SERVICE -> stopSelf()
            ACTION_SHOW_PET -> showOverlay()
            ACTION_DISMISS_PET -> hideOverlay()
            ACTION_UPDATE_SETTINGS -> applyCalibrationSettings()
            ACTION_SHOW_BADGE -> onPetPoked()
            ACTION_POKE_PET -> onPetPoked()
            ACTION_RESET_STATS -> {
                usageTracker.resetTodayStatsNow()
                updateStatsBadge(force = true)
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        isOverlayVisible = false
        prefs.edit().putBoolean(KEY_SERVICE_ENABLED, false).apply()
        stopSecondTicker()
        stopIdleBreathing()
        cancelAmbientAction()
        if (isWalking) {
            ivPet.animate().cancel()
            ivPet.translationX = 0f
            isWalking = false
        }
        mainHandler.removeCallbacksAndMessages(null)

        try {
            unregisterReceiver(settingsReceiver)
        } catch (ignored: Exception) {
        }

        usageTracker.stopTracking()

        overlayView?.let {
            try {
                windowManager.removeView(it)
            } catch (ignored: Exception) {
            }
            overlayView = null
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val CHANNEL_ID = "screenpet_overlay_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_UPDATE_SETTINGS = "com.screenpet.app.ACTION_UPDATE_SETTINGS"
        const val ACTION_UPDATE_LANGUAGE = "com.screenpet.app.ACTION_UPDATE_LANGUAGE"
        const val ACTION_STOP_SERVICE = "com.screenpet.app.ACTION_STOP_SERVICE"
        const val ACTION_SHOW_PET = "com.screenpet.app.ACTION_SHOW_PET"
        const val ACTION_DISMISS_PET = "com.screenpet.app.ACTION_DISMISS_PET"
        const val ACTION_SHOW_BADGE = "com.screenpet.app.ACTION_SHOW_BADGE"
        const val ACTION_POKE_PET = "com.screenpet.app.ACTION_POKE_PET"
        const val ACTION_RESET_STATS = "com.screenpet.app.ACTION_RESET_STATS"

        const val PREFS_SETTINGS = "screen_pet_settings"
        const val KEY_SERVICE_ENABLED = "pref_service_enabled"
        const val KEY_OVERLAY_VISIBLE = "pref_overlay_visible"
        const val KEY_LANGUAGE_MODE = "pref_language_mode"
        const val KEY_X_PERCENT = "pref_x_percent"
        const val KEY_Y_OFFSET_DP = "pref_y_dp"
        const val KEY_PET_SIZE_DP = "pref_pet_size_dp"
        const val KEY_LAST_ROAST = "pref_last_roast"

        const val DEFAULT_X_PERCENT = 55.0f
        const val DEFAULT_Y_OFFSET_DP = 4
        const val DEFAULT_PET_SIZE_DP = 32

        @Volatile
        var isRunning = false
            private set

        @Volatile
        var isOverlayVisible = false
            private set
    }
}
