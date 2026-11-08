package com.screenpet.app

import java.util.Calendar

/**
 * Intelligent Sarcastic Roast & Dialogue Engine.
 *
 * Generates context-aware, witty, and humorous speech bubbles in English & Manglish
 * based on unlock frequency, time away from phone, continuous screen time,
 * morning/late-night hours, and user poking interactions.
 */
object RoastEngine {

    private val POKE_ROASTS = listOf(
        // Manglish
        "Kuthi kalikkalle bro! 😼",
        "Enne thodathe poi padikk 📚",
        "Nokki irunno, ippo nadakkum 😒",
        "Oru meen thaa aadyam 🐟",
        "Pani edukk bro, padikk 💼",
        "Enthada angane nokkunne? 🤨",
        "Thodathe bro, ticklish aanu 😹",
        "Aha, enneyum thottu kalikkunno? 🐾",
        "Meow! Njan camera guard aanu 🐱",
        // English
        "Hey, watch the whiskers! 😼",
        "Stop poking, start working! 💼",
        "Purrrrr~ 🐾",
        "I'm a camera pet, not bubble wrap!",
        "Boop! 🐱",
        "Checking screentime won't lower it 📉",
        "Do I look like a touchscreen? 🤨",
        "Pet tax: 1 fish please 🐟",
        "Still here? Be productive! ⚡",
        "Got your eyes on me or your work? 😼",
        "Wheee! High five! 🐾"
    )

    private val AMBIENT_WHISPERS = listOf(
        "Purrrr... 🐾",
        "Meow! 😸",
        "Pacing around the notch 🚶",
        "Blink your eyes! 👀",
        "Still scrolling? 📱",
        "Cozy status bar spot 🌿",
        "Just stretching my paws 🐾",
        "Catch me if you can! 😼",
        "Stay hydrated! 💧",
        "Watching over your phone 🐱",
        "Nice focus! Keep it up ⭐",
        "Curious what you're building! 🧶"
    )

    /**
     * Generates a gentle ambient whisper when the pet wanders autonomously.
     */
    fun getAmbientWhisper(): String {
        return AMBIENT_WHISPERS.random()
    }

    private val QUICK_RELOCK_ROASTS = listOf(
        // Manglish
        "Ippo alle veche? Appozhekkum? 😂",
        "Onnum vannittilla bro, po 🚶",
        "Aara message ayache? 👻",
        "Fridgil onnum ille mone? 🥪",
        "Veendum vannalle? Mathi! 🤦",
        "Onnum maarittilla bro 📱",
        // English
        "Locked 40s ago... miss me? 😏",
        "Nothing changed in 20 seconds.",
        "Phantom buzz syndrome? 📳",
        "Back already? Fridge empty? 🥪",
        "Record speed re-opening! 🏎️",
        "Forgot why you unlocked? 🧠",
        "Put me down for 5 minutes ✋"
    )

    private val LATE_NIGHT_ROASTS = listOf(
        // Manglish
        "Kidann urangada mone 😴",
        "Nale ravile enikkande? 🌙",
        "Kallakkannu varum, urang 🐼",
        "Phone vechittu poi kidakk 🛌",
        "Ithano reel kaanan samayam? 💤",
        // English
        "Go to sleep, tomorrow is real 🌙",
        "Blue light at night? Bold choice 🦉",
        "Sleep > Reels. Trust me 💤",
        "Dark circles incoming 🐼",
        "Tomorrow you will regret this 🥱",
        "Close your eyes, human 🛌"
    )

    private val MORNING_ROASTS = listOf(
        // Manglish
        "Kannezhunnettappo phone? 🌅",
        "Pallu thechoda aadyam? 🪥",
        "Chaya kudy aadyam mone ☕",
        "Ezhunnett nallapole nadakk 🚶",
        // English
        "First thought was your phone? 📱",
        "Stretch before scrolling 🌅",
        "Did you brush your teeth yet? 🪥",
        "Good morning! Make it quick ⚡"
    )

    private val FOCUS_WIN_ROASTS = listOf(
        // Manglish
        "Sammathichu, nalla focus ⭐",
        "Njan nalla urakkam aayirunnu 🐾",
        "Ithrem neram phone illathe? 🚀",
        "Scene mone, adipoli focus 🏆",
        // English
        "Over 40m focused! Proud of you ⭐",
        "I took a great nap while you worked! 🐾",
        "Productivity detected! Keep it up 🚀",
        "You survived without your phone! 🎉"
    )

    private val DOOMSCROLL_ROASTS = listOf(
        // Manglish
        "Kanninu kurach rest kodu 👀",
        "Kannu adichu pokum bro 😵",
        "Kannu vedanikkunnille? 🤕",
        "Scroll cheyth mathiyayille? 📱",
        "Purath irang swasam edu 🌱",
        "Phone choodayi pottum 🔥",
        "Oru reel koode? Ennitu po 🙄",
        // English
        "Blink your eyes! 25m straight 👀",
        "Doomscroll alert! Touch grass 🌱",
        "40m straight! Touch grass 🌳",
        "Your phone is heating up 🔥",
        "Just 'one more reel', right? 🙄"
    )

    private val GENERAL_GREETINGS = listOf(
        // Manglish
        "Vannallo! Entha karyam? 🎯",
        "ScreenPet on duty da! 🐾",
        "Adipoli, thudangikkoloo ⚡",
        "Hello bro! Make it fast 🐱",
        // English
        "Welcome back! Make it count ⚡",
        "ScreenPet on duty! 🐾",
        "What's the mission this time? 🎯",
        "Ready when you are! 🐱",
        "Back in action! 🐾"
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

        // 2. Morning check (6 AM - 9 AM)
        if (hour in 6..9) {
            return MORNING_ROASTS.random()
        }

        // 3. Focused study/work break (> 40 minutes away)
        if (timeSinceLastScreenOffMs > 40 * 60 * 1000L) {
            return FOCUS_WIN_ROASTS.random()
        }

        // 4. Quick re-open (< 50 seconds after locking)
        if (timeSinceLastScreenOffMs in 1..50000L) {
            return QUICK_RELOCK_ROASTS.random()
        }

        // 5. High unlock frequency milestone
        if (unlockCount >= 25 && unlockCount % 4 == 0) {
            return getHighUnlockRoast(unlockCount)
        }

        // 6. General unlock greeting
        return GENERAL_GREETINGS.random()
    }

    /**
     * Generates compact high-unlock roasts with actual count.
     */
    private fun getHighUnlockRoast(count: Int): String {
        return listOf(
            "Unlock #$count! Viral theayum 🏃",
            "Unlock #$count! Chill out 🛑",
            "Unlock #$count! Nirthada uvve 🤦",
            "Unlock #$count! Vellam kudy 💧",
            "Unlock #$count! Fidget spinner? 🌀"
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
