# Privacy Policy for ScreenPet

*Last updated: November 9, 2026*

ScreenPet ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy explains our practices regarding user data and device permissions.

---

### 1. 100% Offline Architecture (Zero Data Collection)
ScreenPet is engineered from the ground up as a **100% offline, local-first application**:
- **No Internet Transmission**: The release version of ScreenPet does not request or possess the `android.permission.INTERNET` permission. The app is physically incapable of transmitting data off your device.
- **No Personal Data Collected**: We do not collect, store, sell, or transmit any personal information, names, email addresses, phone numbers, IP addresses, or device identifiers.
- **No App Tracking or Analytics**: We do not include third-party tracking SDKs, advertising trackers, or telemetry libraries.

---

### 2. How Screen Time & Habit Data Works
- **Local Calculation Only**: ScreenPet calculates active screen-on time and unlock counts locally using standard Android operating system broadcast events (`ACTION_SCREEN_ON`, `ACTION_SCREEN_OFF`, and `ACTION_USER_PRESENT`).
- **No Access to App Content**: ScreenPet does **not** read your messages, browsing history, camera feed, microphone, or what you do inside other apps.
- **Local Storage**: All habit counters (daily screen time and unlock tallies) are saved solely inside your phone's private app storage (`SharedPreferences`). This data never leaves your device and resets fresh each day at midnight (00:00).

---

### 3. Device Permissions & Why They Are Needed
ScreenPet requests only the minimum Android permissions required to deliver the punch-hole companion experience:

| Permission | Purpose |
| :--- | :--- |
| **`SYSTEM_ALERT_WINDOW` ("Display over other apps")** | Required exclusively to draw the animated pet sprite and compact habit pill beside your front camera cutout / status bar while using other apps. |
| **`FOREGROUND_SERVICE` (`specialUse`)** | Required by Android to run the continuous status bar companion service reliably without being unexpectedly terminated by OS battery optimization. |
| **`POST_NOTIFICATIONS`** | Required on Android 13+ to display the system-mandated persistent notification while the companion overlay is active. |
| **`RECEIVE_BOOT_COMPLETED`** | Allows the companion to automatically resume habit tracking after your phone reboots (only if you have enabled the pet). |

---

### 4. Children's Privacy
ScreenPet does not knowingly collect any information from children under 13 years of age. Because no data is collected from any user, ScreenPet complies with the requirements of the Children’s Online Privacy Protection Act (COPPA) and GDPR.

---

### 5. Changes to This Policy
We may update our Privacy Policy periodically. Any changes will be reflected in this document with an updated revision date.

---

### 6. Contact
If you have questions about this Privacy Policy, you can open an issue or contact the developer via the GitHub repository:  
https://github.com/Anusmrith/screentime-pet
