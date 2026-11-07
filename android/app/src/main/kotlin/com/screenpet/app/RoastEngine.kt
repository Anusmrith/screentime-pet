package com.screenpet.app

import java.util.Calendar

/**
 * Intelligent Sarcastic Roast & Dialogue Engine.
 *
 * Generates context-aware, witty, and humorous speech bubbles for ScreenPet
 * based on unlock frequency, time away from phone, continuous screen time,
 * and user poking interactions.
 */
object RoastEngine {

    private val POKE_ROASTS = listOf(
        "Hey, watch the whiskers! 😼",
        "Stop poking, start working! 💼",
        "Purrrrr~ 🐾",
        "I'm a camera pet, not bubble wrap!",
        "Boop! 🐱",
        "Checking screentime won't lower it 📉",
        "Looking at me won't do your chores 🧹",
        "You really like touching glass, huh?",
        "Don't mind me, just judging you 👁️",
        "Feed me a fish snack first! 🐟"
    )

    private val QUICK_RELOCK_ROASTS = listOf(
        "Locked 40s ago... miss me? 😏",
        "Nothing changed in 30 seconds.",
        "Phantom buzz syndrome? 📳",
        "Back already? Fridge empty? 🥪",
        "You put me down for 10 seconds 😂",
        "Did you forget what you unlocked for?"
    )

    private val HIGH_UNLOCK_ROASTS = listOf(
        "Need a fidget spinner? 🌀",
        "Your thumb is running a marathon 🏃",
        "Checking it like the fridge again 🥶",
        "Notification addiction detected 🚨",
        "Your lock screen misses you already."
    )

    private val LATE_NIGHT_ROASTS = listOf(
        "Go to sleep, tomorrow is real 🌙",
        "Blue light at night? Bold choice 🦉",
        "Nothing good happens after 12 AM 😴",
        "Go count sheep, not reels 🐑",
        "Your pillow is lonely right now 💤"
    )

    private val FOCUS_WIN_ROASTS = listOf(
        "Over 45m focused! Proud of you ⭐",
        "I took a great nap while you worked! 🐾",
        "Productivity detected! Keep it up 🚀",
        "You survived without your phone! 🎉"
    )

    private val DOOMSCROLL_ROASTS = listOf(
        "Blink your eyes! 25m straight 👀",
        "Doomscroll alert! Touch grass 🌱",
        "My paws hurt watching you scroll 🐾",
        "Did you forget how to blink?"
    )

    /**
     * Generates a context-aware roast when user unlocks the phone.
     */
    fun getUnlockRoast(unlockCount: Int, timeSinceLastScreenOffMs: Long): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

        // 1. Late night check (11 PM - 5 AM)
        if (hour >= 23 || hour < 5) {
            return LATE_NIGHT_ROASTS.random()
        }

        // 2. Focused study/work break (> 40 minutes away)
        if (timeSinceLastScreenOffMs > 40 * 60 * 1000L) {
            return FOCUS_WIN_ROASTS.random()
        }

        // 3. Quick re-open (< 50 seconds after locking)
        if (timeSinceLastScreenOffMs in 1..50000L) {
            return QUICK_RELOCK_ROASTS.random()
        }

        // 4. High unlock frequency milestone
        if (unlockCount >= 25 && unlockCount % 4 == 0) {
            return "Unlock #$unlockCount! " + HIGH_UNLOCK_ROASTS.random()
        }

        // 5. Pleasant / witty check-in
        return listOf(
            "Welcome back! Make it count ⚡",
            "ScreenPet on duty! 🐾",
            "What's the mission this time? 🎯",
            "Ready when you are! 🐱",
            "Back in action! 🐾"
        ).random()
    }

    /**
     * Generates a playful roast when the user taps or pokes the pet.
     */
    fun getPokeRoast(unlockCount: Int, screenTimeMs: Long): String {
        return POKE_ROASTS.random()
    }

    /**
     * Generates a warning roast when user has been staring continuously.
     */
    fun getDoomscrollRoast(): String {
        return DOOMSCROLL_ROASTS.random()
    }
}

