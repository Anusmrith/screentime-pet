package com.screenpet.app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter MainActivity with MethodChannel bridge to Native Android WindowManager Overlay.
 */
class MainActivity : FlutterActivity() {

    private lateinit var usageTracker: UsageTracker

    companion object {
        private const val CHANNEL = "com.screenpet.app/overlay"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        usageTracker = UsageTracker(context)

        // Always ensure background habit tracking is running 24/7
        try {
            val serviceIntent = Intent(context, PetOverlayService::class.java)
            ContextCompat.startForegroundService(context, serviceIntent)
        } catch (ignored: Exception) {
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(context))
                }

                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    ).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    result.success(true)
                }

                "startOverlay" -> {
                    if (Settings.canDrawOverlays(context)) {
                        val intent = Intent(context, PetOverlayService::class.java).apply {
                            action = PetOverlayService.ACTION_SHOW_PET
                        }
                        ContextCompat.startForegroundService(context, intent)
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                    }
                }

                "stopOverlay" -> {
                    val intent = Intent(context, PetOverlayService::class.java).apply {
                        action = PetOverlayService.ACTION_DISMISS_PET
                    }
                    startService(intent)
                    result.success(true)
                }

                "isOverlayRunning" -> {
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    val isVisible = PetOverlayService.isOverlayVisible || (PetOverlayService.isRunning && prefs.getBoolean(PetOverlayService.KEY_OVERLAY_VISIBLE, false))
                    result.success(isVisible)
                }

                "updateCalibration" -> {
                    val rawX = (call.argument<Number>("xPercent"))?.toFloat()
                        ?: PetOverlayService.DEFAULT_X_PERCENT
                    val rawY = (call.argument<Number>("yDp"))?.toInt()
                        ?: PetOverlayService.DEFAULT_Y_OFFSET_DP
                    val rawSize = (call.argument<Number>("sizeDp"))?.toInt()
                        ?: PetOverlayService.DEFAULT_PET_SIZE_DP

                    // Defensive input validation: clamp to strict valid boundaries
                    val xPercent = rawX.coerceIn(0f, 100f)
                    val yDp = rawY.coerceIn(0, 100)
                    val sizeDp = rawSize.coerceIn(16, 72)

                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putFloat(PetOverlayService.KEY_X_PERCENT, xPercent)
                        .putInt(PetOverlayService.KEY_Y_OFFSET_DP, yDp)
                        .putInt(PetOverlayService.KEY_PET_SIZE_DP, sizeDp)
                        .apply()

                    if (PetOverlayService.isRunning) {
                        try {
                            val serviceIntent = Intent(context, PetOverlayService::class.java).apply {
                                action = PetOverlayService.ACTION_UPDATE_SETTINGS
                            }
                            startService(serviceIntent)
                        } catch (ignored: Exception) {
                        }
                        val broadcastIntent = Intent(PetOverlayService.ACTION_UPDATE_SETTINGS).apply {
                            setPackage(packageName)
                        }
                        sendBroadcast(broadcastIntent)
                    }
                    result.success(true)
                }

                "getCalibration" -> {
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    val xPercent = prefs.getFloat(PetOverlayService.KEY_X_PERCENT, PetOverlayService.DEFAULT_X_PERCENT)
                    val yDp = prefs.getInt(PetOverlayService.KEY_Y_OFFSET_DP, PetOverlayService.DEFAULT_Y_OFFSET_DP)
                    val sizeDp = prefs.getInt(PetOverlayService.KEY_PET_SIZE_DP, PetOverlayService.DEFAULT_PET_SIZE_DP)

                    result.success(
                        mapOf(
                            "xPercent" to xPercent.toDouble(),
                            "yDp" to yDp,
                            "sizeDp" to sizeDp
                        )
                    )
                }

                "getStats" -> {
                    val screenTimeMs = usageTracker.getTodayScreenTimeMs()
                    val unlocks = usageTracker.getTodayUnlockCount()
                    val formatted = UsageTracker.formatDuration(screenTimeMs)
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    val lastRoast = prefs.getString(PetOverlayService.KEY_LAST_ROAST, "Bubbloo on duty! 🐾") ?: "Bubbloo on duty! 🐾"

                    result.success(
                        mapOf(
                            "unlockCount" to unlocks,
                            "screenTimeMs" to screenTimeMs,
                            "screenTimeFormatted" to formatted,
                            "lastRoast" to lastRoast
                        )
                    )
                }

                "pokePet" -> {
                    val screenTimeMs = usageTracker.getTodayScreenTimeMs()
                    val unlocks = usageTracker.getTodayUnlockCount()
                    val newRoast = RoastEngine.getPokeRoast(unlocks, screenTimeMs)
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    prefs.edit().putString(PetOverlayService.KEY_LAST_ROAST, newRoast).apply()

                    if (PetOverlayService.isRunning) {
                        try {
                            val serviceIntent = Intent(context, PetOverlayService::class.java).apply {
                                action = PetOverlayService.ACTION_POKE_PET
                            }
                            startService(serviceIntent)
                        } catch (ignored: Exception) {
                        }
                    }
                    result.success(newRoast)
                }

                "resetDailyStats" -> {
                    usageTracker.resetTodayStatsNow()
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    prefs.edit().putString(PetOverlayService.KEY_LAST_ROAST, "Habit counters refreshed! 🐾").apply()
                    if (PetOverlayService.isRunning) {
                        try {
                            val serviceIntent = Intent(context, PetOverlayService::class.java).apply {
                                action = PetOverlayService.ACTION_RESET_STATS
                            }
                            startService(serviceIntent)
                        } catch (ignored: Exception) {
                        }
                    }
                    result.success(true)
                }

                "getLastRoast" -> {
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    val lastRoast = prefs.getString(PetOverlayService.KEY_LAST_ROAST, "Bubbloo on duty! 🐾") ?: "Bubbloo on duty! 🐾"
                    result.success(lastRoast)
                }

                "detectCutout" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        val cutout = window.decorView.rootWindowInsets?.displayCutout
                        val rects = cutout?.boundingRects
                        val nonZeroRects = rects?.filter { it.width() > 0 && it.height() > 0 }
                        if (!nonZeroRects.isNullOrEmpty()) {
                            val primary = nonZeroRects.first()
                            val screenWidth = resources.displayMetrics.widthPixels
                            val density = resources.displayMetrics.density
                            val targetX = ((primary.right + (6 * density)) / screenWidth * 100f)
                                .coerceIn(10f, 90f)
                            val targetY = ((primary.centerY().toFloat() - (16 * density)) / density)
                                .toInt()
                                .coerceIn(0, 30)

                            result.success(
                                mapOf(
                                    "detected" to true,
                                    "xPercent" to targetX.toDouble(),
                                    "yDp" to targetY
                                )
                            )
                            return@setMethodCallHandler
                        }
                    }
                    result.success(
                        mapOf(
                            "detected" to false,
                            "xPercent" to 55.0,
                            "yDp" to 4
                        )
                    )
                }

                "setLanguageMode" -> {
                    val rawMode = call.argument<String>("mode") ?: "manglish"
                    val mode = if (rawMode.equals("english", ignoreCase = true)) "english" else "manglish"
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    prefs.edit().putString(PetOverlayService.KEY_LANGUAGE_MODE, mode).apply()
                    RoastEngine.setLanguage(mode)

                    if (PetOverlayService.isRunning) {
                        try {
                            val broadcastIntent = Intent(PetOverlayService.ACTION_UPDATE_LANGUAGE).apply {
                                setPackage(packageName)
                            }
                            sendBroadcast(broadcastIntent)
                        } catch (ignored: Exception) {
                        }
                    }
                    result.success(true)
                }

                "getLanguageMode" -> {
                    val prefs = context.getSharedPreferences(PetOverlayService.PREFS_SETTINGS, Context.MODE_PRIVATE)
                    val mode = prefs.getString(PetOverlayService.KEY_LANGUAGE_MODE, "manglish") ?: "manglish"
                    result.success(mode)
                }

                else -> result.notImplemented()
            }
        }
    }
}

