import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required int hour,
    required int minute,
    required String repeatType,
  }) async {
    await init();

    var scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    final now = tz.TZDateTime.now(tz.local);

    if (scheduledDate.isBefore(now)) {
      if (repeatType == "Daily") {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      } else if (repeatType == "Weekly") {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      } else {
        return;
      }
    }

    DateTimeComponents? dateTimeComponents;

    if (repeatType == "Daily") {
      dateTimeComponents = DateTimeComponents.time;
    } else if (repeatType == "Weekly") {
      dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription:
              'Daily safety and protection reminder notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: dateTimeComponents,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await init();

    await _notifications.cancel(
      id: id,
    );
  }

  static Future<void> cancelAllReminders() async {
    await init();
    await _notifications.cancelAll();
  }
}