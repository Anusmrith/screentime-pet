package com.screenpet.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

/**
 * Automatically resumes ScreenPet habit tracking across device reboots.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == "android.intent.action.QUICKBOOT_POWERON") {
            context?.let { ctx ->
                try {
                    val serviceIntent = Intent(ctx, PetOverlayService::class.java)
                    ContextCompat.startForegroundService(ctx, serviceIntent)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
}
