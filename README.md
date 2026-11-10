# Bubbloo 🐱📱

> **Punch-Hole Camera Screen-Time Companion with Attitude**  
> Built with **Flutter (Material 3 Dark UI)** and **Native Android Kotlin (WindowManager Overlay Service)** communicating via `MethodChannel` (`com.screenpet.app/overlay`).

---

## 🌟 Overview

**Bubbloo** sits directly adjacent to your front camera notch/punch-hole cutout across all apps. It keeps you mindful of your digital habits in real-time with zero battery drain while bringing life and personality to your screen:

```
+-------------------------------------------------------+
|  [Status Bar]        (📷 Cutout) 🐱  "Back already? 🥪"|
|                                                       |
|                     (Any Active App)                  |
|                                                       |
+-------------------------------------------------------+
```

* **Live Screentime & Pickups:** Displays active screen time with live ticking seconds and device unlock count (`2h 31m 53s • 18 🔓`).
* **Sarcastic "Duolingo-Style" Roasts:** Bubbloo roasts you when you unlock too frequently, doomscroll continuously, or check your phone late at night.
* **Dual Language Mode:** Toggle between **English** and authentic **Manglish + English** dialogues!
* **Physics-Based Avatar Animations:** 
  - **Idle Breathing Loop:** Pet hovers up and down gently (2.5dp) by the camera notch.
  - **Squash & Stretch Bounce:** Playful squash on tap with spring overshoot.
  - **360° Somersault:** Full barrel roll animation.
  - **Startled Wobble:** Shakes left and right like a surprised cat.
  - **Peek-A-Boo Dip:** Dips behind the notch and pops back out.
  - **Wake-Up Spring:** Pops up and stretches when you unlock the phone.
  - **Fatigue Tilt:** Tilts tiredly when you doomscroll continuously for > 25 mins.
* **Zero Battery Drain:** All tickers and animations immediately halt when the screen turns off.

---

## 🏗️ Architecture

### 1. Flutter Frontend (`lib/`)
* **Dashboard Screen:** Today's screen-on time, unlock counts, Start/Stop toggle button, latest pet dialogue roast card, English/Manglish switcher, and interactive **"Poke Pet"** tester.
* **Punch-Hole Calibration Screen:** Real-time sliders for **Horizontal Position (X %)**, **Vertical Offset (Y dp)**, and **Pet Size (dp)** that move the native pet live as you drag, plus hardware **Snap to Cutout**.
* **Pet Wardrobe:** Companion skins grid (Bubbloo active, with upcoming skins).
* **MethodChannel Bridge (`overlay_bridge.dart`):** Type-safe Dart bridge communicating with native Android services.

### 2. Native Android Core (`android/`)
* **PetOverlayService.kt:** Persistent foreground service drawing a floating `WindowManager` view using `TYPE_APPLICATION_OVERLAY`, `FLAG_NOT_FOCUSABLE`, `FLAG_NOT_TOUCH_MODAL`, and `LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS`.
* **UsageTracker.kt:** Event-driven habit tracker listening to `ACTION_SCREEN_ON`, `ACTION_SCREEN_OFF`, and `ACTION_USER_PRESENT` with automatic midnight resets and zero battery polling.
* **RoastEngine.kt:** Contextual dialogue engine generating witty roasts for quick re-opens, high unlock frequency, doomscrolling, focus streaks, and poking.
* **MainActivity.kt:** Extends `FlutterActivity` handling the `com.screenpet.app/overlay` method calls.

---

## 📁 Clean Project Structure

```
Bubbloo/
├── android/                             # Native Android Host
│   └── app/
│       ├── build.gradle.kts             # MinSdk 28, CompileSdk 35, TargetSdk 35
│       └── src/main/
│           ├── AndroidManifest.xml      # Overlay, FGS Special Use permissions
│           ├── kotlin/com/screenpet/app/
│           │   ├── MainActivity.kt      # FlutterActivity + MethodChannel bridge
│           │   ├── PetOverlayService.kt # WindowManager floating punch-hole overlay
│           │   ├── UsageTracker.kt      # Zero-drain screen & unlock tracker
│           │   └── RoastEngine.kt       # Sarcastic dialogue & roast engine
│           └── res/
│               ├── drawable/            # ic_pet.png, bg_pill.xml
│               └── layout/              # layout_pet_overlay.xml
├── assets/images/                       # Companion skin assets (pet_tiger.png)
├── lib/                                 # Flutter Material 3 UI
│   ├── main.dart                        # App entry point & NavigationBar
│   ├── overlay_bridge.dart              # MethodChannel bridge
│   ├── models/                          # PetSkin models
│   └── screens/
│       ├── dashboard_screen.dart        # Screen habits, roasts & controls
│       ├── calibration_screen.dart      # Real-time sliders & notch snapping
│       └── wardrobe_screen.dart         # Pet skins shop & customization
├── test/                                # Widget test suite
├── debug-run.ps1                        # 1-command build, pair & hot-deploy script
└── pubspec.yaml                         # Flutter dependencies & assets
```

---

## 🚀 Running the App

```powershell
# 1. Standard Flutter run (with hot reload)
flutter run

# 2. Or using the automated deploy script
.\debug-run.ps1
```

---

## 📄 License & Restrictions

Copyright © 2026 Bubbloo Authors & Contributors. All rights reserved.

This software is proprietary. Copying, redistributing, modifying, sublicensing, or selling this software, its source code, or binary APKs without prior express written permission is strictly prohibited. See the [LICENSE](LICENSE) file for full legal terms.
