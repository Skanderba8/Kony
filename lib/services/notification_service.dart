// lib/services/notification_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static const String _lastOpenTimeKey = 'last_open_time_admin';
  static const String _lastViewedSubmittedKey = 'last_viewed_submitted';

  // Get the last time admin opened the app
  static Future<DateTime?> getLastOpenTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastOpenTimeKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
    } catch (e) {
      debugPrint('Error getting last open time: $e');
    }
    return null;
  }

  // Save the current time as last open time
  static Future<void> saveLastOpenTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastOpenTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving last open time: $e');
    }
  }

  // Get the last time admin viewed submitted reports
  static Future<DateTime?> getLastViewedSubmittedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastViewedSubmittedKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
    } catch (e) {
      debugPrint('Error getting last viewed submitted time: $e');
    }
    return null;
  }

  // Save the current time as last viewed submitted reports time
  static Future<void> saveLastViewedSubmittedTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastViewedSubmittedKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Error saving last viewed submitted time: $e');
    }
  }

  // Clear all notification data
  static Future<void> clearNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastOpenTimeKey);
      await prefs.remove(_lastViewedSubmittedKey);
    } catch (e) {
      debugPrint('Error clearing notification data: $e');
    }
  }
}
