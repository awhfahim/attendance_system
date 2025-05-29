import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions
    await _requestPermissions();

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        debugPrint('Notification permission denied');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<void> showCheckInReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_reminders',
      'Attendance Reminders',
      channelDescription: 'Reminders for checking in and out',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Time to Check In',
      'Don\'t forget to mark your attendance for today!',
      notificationDetails,
      payload: 'check_in_reminder',
    );
  }

  static Future<void> showCheckOutReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_reminders',
      'Attendance Reminders',
      channelDescription: 'Reminders for checking in and out',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Time to Check Out',
      'Remember to mark your check-out time before leaving!',
      notificationDetails,
      payload: 'check_out_reminder',
    );
  }

  static Future<void> scheduleCheckInReminder({
    required int hour,
    required int minute,
  }) async {
    // Scheduling functionality would require additional setup with timezone package
    // For now, we'll just show an immediate notification as a placeholder
    debugPrint('Check-in reminder would be scheduled for $hour:$minute');
    await showCheckInReminder();
  }

  static Future<void> scheduleCheckOutReminder({
    required int hour,
    required int minute,
  }) async {
    // Scheduling functionality would require additional setup with timezone package
    // For now, we'll just show an immediate notification as a placeholder
    debugPrint('Check-out reminder would be scheduled for $hour:$minute');
    await showCheckOutReminder();
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> showAttendanceConfirmation(String message) async {
    const androidDetails = AndroidNotificationDetails(
      'attendance_confirmations',
      'Attendance Confirmations',
      channelDescription: 'Confirmations for attendance actions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'Attendance Updated',
      message,
      notificationDetails,
    );
  }
}
