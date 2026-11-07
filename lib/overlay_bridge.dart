import 'package:flutter/services.dart';

/// Clean MethodChannel bridge communicating with Native Android WindowManager
/// and UsageTracker background overlay service.
class OverlayBridge {
  static const MethodChannel _channel = MethodChannel('com.screenpet.app/overlay');

  /// Checks if the SYSTEM_ALERT_WINDOW (Display over other apps) permission is granted.
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error checkOverlayPermission: ${e.message}');
      return false;
    }
  }

  /// Launches Android System Settings directly to the "Display over other apps" page.
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error requestOverlayPermission: ${e.message}');
      return false;
    }
  }

  /// Spawns the persistent ForegroundService drawing the floating punch-hole pet.
  static Future<bool> startOverlay() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('startOverlay');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error startOverlay: ${e.message}');
      return false;
    }
  }

  /// Dismisses and stops the floating punch-hole pet overlay.
  static Future<bool> stopOverlay() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('stopOverlay');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error stopOverlay: ${e.message}');
      return false;
    }
  }

  /// Checks whether the PetOverlayService is currently active and floating.
  static Future<bool> isOverlayRunning() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('isOverlayRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error isOverlayRunning: ${e.message}');
      return false;
    }
  }

  /// Live real-time calibration: sends updated coordinates to move the pet live on-screen.
  static Future<bool> updateCalibration({
    required double xPercent,
    required int yDp,
    required int sizeDp,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('updateCalibration', {
        'xPercent': xPercent,
        'yDp': yDp,
        'sizeDp': sizeDp,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error updateCalibration: ${e.message}');
      return false;
    }
  }

  /// Retrieves currently saved calibration values from SharedPreferences.
  static Future<Map<String, dynamic>> getCalibration() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getCalibration');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error getCalibration: ${e.message}');
    }
    return {
      'xPercent': 55.0,
      'yDp': 4,
      'sizeDp': 32,
    };
  }

  /// Queries the UsageTracker for today's active screen-on time and device unlock count.
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getStats');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error getStats: ${e.message}');
    }
    return {
      'unlockCount': 0,
      'screenTimeMs': 0,
      'screenTimeFormatted': '0m 00s',
      'lastRoast': 'ScreenPet on duty! 🐾',
    };
  }

  /// Inspects DisplayCutout API on hardware to auto-detect notch/punch-hole bounding rect.
  static Future<Map<String, dynamic>> detectCutout() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('detectCutout');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error detectCutout: ${e.message}');
    }
    return {
      'detected': false,
      'xPercent': 55.0,
      'yDp': 4,
    };
  }

  /// Triggers a poke animation and witty roast dialogue on the floating pet.
  static Future<bool> pokePet() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('pokePet');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error pokePet: ${e.message}');
      return false;
    }
  }

  /// Manually resets today's stats back to 0 (for testing midnight clock refresh).
  static Future<bool> resetDailyStats() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('resetDailyStats');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error resetDailyStats: ${e.message}');
      return false;
    }
  }

  /// Retrieves the most recent roast or speech dialogue from the pet.
  static Future<String> getLastRoast() async {
    try {
      final String? result = await _channel.invokeMethod<String>('getLastRoast');
      return result ?? 'ScreenPet on duty! 🐾';
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('OverlayBridge error getLastRoast: ${e.message}');
      return 'ScreenPet on duty! 🐾';
    }
  }
}

