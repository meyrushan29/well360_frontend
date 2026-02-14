import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;
  bool _initialized = false;

  FlutterLocalNotificationsPlugin get _plugin {
    _notifications ??= FlutterLocalNotificationsPlugin();
    return _notifications!;
  }

  Future<void> init() async {
    if (kIsWeb) return; // Local notifications not supported on web
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
      },
    );
    _initialized = true;
  }

  Future<void> scheduleDailyHourlyReminders() async {
    if (kIsWeb) return; // Local notifications not supported on web
    if (!_initialized) await init();
    // Clear existing to avoid duplicates
    await _plugin.cancelAll();

    // 1. Goal Renewal at Midnight (00:00)
    await _scheduleDailyAtTime(
      0, 0,
      id: 0, // ID 0 for midnight renewal
      title: 'Goal Renewed 🌊',
      body: "It's a brand new day! Your hydration goal has been reset. Stay hydrated!",
    );

    // 2. Schedule 6 AM to 10 PM (22:00)
    for (int hour = 6; hour <= 22; hour++) {
      await _scheduleDailyAtTime(
        hour, 0, 
        id: hour,
        title: 'Hydration Reminder',
        body: 'Time to drink recent slot!',
      );
    }
  }

  Future<void> _scheduleDailyAtTime(int hour, int minute, {required int id, required String title, required String body}) async {
    if (kIsWeb) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration_channel',
          'Hydration Reminders',
          channelDescription: 'Daily hourly reminders to drink water',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Recurring daily
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
