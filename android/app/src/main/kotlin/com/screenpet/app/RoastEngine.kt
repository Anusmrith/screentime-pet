package com.screenpet.app

import java.util.Calendar

/**
 * Intelligent Sarcastic Roast & Dialogue Engine.
 *
 * Supports dual language modes:
 * - "english": Exclusively English dialogues for international & non-Malayalam users.
 * - "manglish": Authentic humorous blend of Manglish and English dialogues for Malayalis.
 */
object RoastEngine {

    var languageMode: String = "manglish" // "english" or "manglish"

    fun setLanguage(mode: String) {
        languageMode = if (mode.equals("english", ignoreCase = true)) "english" else "manglish"
    }

    private fun pick(englishList: List<String>, manglishList: List<String>, isMalayalam: Boolean = (languageMode == "manglish")): String {
        return if (!isMalayalam) {
            englishList.random()
        } else {
            (englishList + manglishList).random()
        }
    }

    // 1. POKE ROASTS
    private val ENGLISH_POKE_ROASTS = listOf(
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
        "Wheee! High five! 🐾",
        "Paws off, human! Focus on tasks 💼",
        "Blink! Your eyes need a rest 👀",
        "Less poking, more doing! 🎯"
    )

    private val MANGLISH_POKE_ROASTS = listOf(
        "Kuthi kalikkalle bro! 😼",
        "Enne thodathe poi padikk 📚",
        "Nokki irunno, ippo nadakkum 😒",
        "Oru meen thaa aadyam 🐟",
        "Pani edukk bro, padikk 💼",
        "Enthada angane nokkunne? 🤨",
        "Thodathe bro, ticklish aanu 😹",
        "Aha, enneyum thottu kalikkunno? 🐾",
        "Meow! Njan camera guard aanu 🐱",
        "Vellam kudikk bro, kure neram aayi 💧"
    )

    // 2. AMBIENT WHISPERS
    private val ENGLISH_AMBIENT_WHISPERS = listOf(
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

    private val MANGLISH_AMBIENT_WHISPERS = listOf(
        "Nalla thണുpp status bar 🍃",
        "Oru meen kittumo aavo? 🐟",
        "Scroll cheyth madiyayille? 📱",
        "Adipoli focus! Thudaroo ⭐",
        "Chumma pacing around 🐾",
        "Vellam kudikkada mone 💧"
    )

    fun getAmbientWhisper(isMalayalam: Boolean = (languageMode == "manglish")): String {
        return pick(ENGLISH_AMBIENT_WHISPERS, MANGLISH_AMBIENT_WHISPERS, isMalayalam)
    }

    // 3. QUICK RELOCK ROASTS
    private val ENGLISH_QUICK_RELOCK_ROASTS = listOf(
        "Locked 40s ago... miss me? 😏",
        "Nothing changed in 20 seconds.",
        "Phantom buzz syndrome? 📳",
        "Back already? Fridge empty? 🥪",
        "Record speed re-opening! 🏎️",
        "Forgot why you unlocked? 🧠",
        "Put me down for 5 minutes ✋",
        "Did you even check what you needed? 🧐"
    )

    private val MANGLISH_QUICK_RELOCK_ROASTS = listOf(
        "Ippo alle veche? Appozhekkum? 😂",
        "Onnum vannittilla bro, po 🚶",
        "Aara message ayache? 👻",
        "Fridgil onnum ille mone? 🥪",
        "Veendum vannalle? Mathi! 🤦",
        "Onnum maarittilla bro 📱"
    )

    // 4. LATE NIGHT ROASTS
    private val ENGLISH_LATE_NIGHT_ROASTS = listOf(
        "Go to sleep, tomorrow is real 🌙",
        "Blue light at night? Bold choice 🦉",
        "Sleep > Reels. Trust me 💤",
        "Dark circles incoming 🐼",
        "Tomorrow you will regret this 🥱",
        "Close your eyes, human 🛌",
        "Midnight scrolling again? Sleep! 😴"
    )

    private val MANGLISH_LATE_NIGHT_ROASTS = listOf(
        "Kidann urangada mone 😴",
        "Nale ravile enikkande? 🌙",
        "Kallakkannu varum, urang 🐼",
        "Phone vechittu poi kidakk 🛌",
        "Ithano reel kaanan samayam? 💤"
    )

    // 5. MORNING ROASTS
    private val ENGLISH_MORNING_ROASTS = listOf(
        "First thought was your phone? 📱",
        "Stretch before scrolling 🌅",
        "Did you brush your teeth yet? 🪥",
        "Good morning! Make it quick ⚡",
        "Drink some water first 💧"
    )

    private val MANGLISH_MORNING_ROASTS = listOf(
        "Kannezhunnettappo phone? 🌅",
        "Pallu thechoda aadyam? 🪥",
        "Chaya kudy aadyam mone ☕",
        "Ezhunnett nallapole nadakk 🚶"
    )

    // 6. FOCUS WIN ROASTS
    private val ENGLISH_FOCUS_WIN_ROASTS = listOf(
        "Over 40m focused! Proud of you ⭐",
        "I took a great nap while you worked! 🐾",
        "Productivity detected! Keep it up 🚀",
        "You survived without your phone! 🎉",
        "Look at that focus streak! 🏆"
    )

    private val MANGLISH_FOCUS_WIN_ROASTS = listOf(
        "Sammathichu, nalla focus ⭐",
        "Njan nalla urakkam aayirunnu 🐾",
        "Ithrem neram phone illathe? 🚀",
        "Scene mone, adipoli focus 🏆"
    )

    // 7. DOOMSCROLL ROASTS
    private val ENGLISH_DOOMSCROLL_ROASTS = listOf(
        "Blink your eyes! 25m straight 👀",
        "Doomscroll alert! Touch grass 🌱",
        "40m straight! Stretch your neck 🦒",
        "Your phone is heating up 🔥",
        "Just 'one more reel', right? 🙄",
        "Time flies when scrolling... pause! 🛑"
    )

    private val MANGLISH_DOOMSCROLL_ROASTS = listOf(
        "Kanninu kurach rest kodu 👀",
        "Kannu adichu pokum bro 😵",
        "Kannu vedanikkunnille? 🤕",
        "Scroll cheyth mathiyayille? 📱",
        "Purath irang swasam edu 🌱",
        "Phone choodayi pottum 🔥",
        "Oru reel koode? Ennitu po 🙄"
    )

    // 8. GENERAL GREETINGS
    private val ENGLISH_GENERAL_GREETINGS = listOf(
        "Welcome back! Make it count ⚡",
        "Bubbloo on duty! 🐾",
        "What's the mission this time? 🎯",
        "Ready when you are! 🐱",
        "Back in action! 🐾",
        "Stay mindful today 🌿"
    )

    private val MANGLISH_GENERAL_GREETINGS = listOf(
        "Vannallo! Entha karyam? 🎯",
        "Bubbloo on duty da! 🐾",
        "Adipoli, thudangikkoloo ⚡",
        "Hello bro! Make it fast 🐱",
        "Ippo enthaano parupadi? 🔍"
    )

    /**
     * Generates a context-aware roast when user unlocks the phone.
     */
    fun getUnlockRoast(unlockCount: Int, timeSinceLastScreenOffMs: Long, isMalayalam: Boolean = (languageMode == "manglish")): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

        // 1. Late night check (11 PM - 5 AM)
        if (hour >= 23 || hour < 5) {
            return pick(ENGLISH_LATE_NIGHT_ROASTS, MANGLISH_LATE_NIGHT_ROASTS, isMalayalam)
        }

        // 2. Morning check (6 AM - 9 AM)
        if (hour in 6..9) {
            return pick(ENGLISH_MORNING_ROASTS, MANGLISH_MORNING_ROASTS, isMalayalam)
        }

        // 3. Focused study/work break (> 40 minutes away)
        if (timeSinceLastScreenOffMs > 40 * 60 * 1000L) {
            return pick(ENGLISH_FOCUS_WIN_ROASTS, MANGLISH_FOCUS_WIN_ROASTS, isMalayalam)
        }

        // 4. Quick re-open (< 50 seconds after locking)
        if (timeSinceLastScreenOffMs in 1..50000L) {
            return pick(ENGLISH_QUICK_RELOCK_ROASTS, MANGLISH_QUICK_RELOCK_ROASTS, isMalayalam)
        }

        // 5. High unlock frequency milestone
        if (unlockCount >= 25 && unlockCount % 4 == 0) {
            return getHighUnlockRoast(unlockCount, isMalayalam)
        }

        // 6. General unlock greeting
        return pick(ENGLISH_GENERAL_GREETINGS, MANGLISH_GENERAL_GREETINGS, isMalayalam)
    }

    /**
     * Generates compact high-unlock roasts with actual count.
     */
    private fun getHighUnlockRoast(count: Int, isMalayalam: Boolean = (languageMode == "manglish")): String {
        val english = listOf(
            "Unlock #$count! Chill out 🛑",
            "Unlock #$count! Drink some water 💧",
            "Unlock #$count! Fidget spinner? 🌀",
            "Unlock #$count! Take a 10m walk 🚶",
            "Unlock #$count! Resting my paws 🐾"
        )
        val manglish = listOf(
            "Unlock #$count! Viral theayum 🏃",
            "Unlock #$count! Nirthada uvve 🤦",
            "Unlock #$count! Vellam kudy 💧",
            "Unlock #$count! Oru chaya kudy ☕"
        )
        return pick(english, manglish, isMalayalam)
    }

    /**
     * Generates a playful roast when the user taps or pokes the pet.
     */
    fun getPokeRoast(unlockCount: Int, screenTimeMs: Long, isMalayalam: Boolean = (languageMode == "manglish")): String {
        return pick(ENGLISH_POKE_ROASTS, MANGLISH_POKE_ROASTS, isMalayalam)
    }

    /**
     * Generates a warning roast when user has been staring continuously.
     */
    fun getDoomscrollRoast(isMalayalam: Boolean = (languageMode == "manglish")): String {
        return pick(ENGLISH_DOOMSCROLL_ROASTS, MANGLISH_DOOMSCROLL_ROASTS, isMalayalam)
    }
}
