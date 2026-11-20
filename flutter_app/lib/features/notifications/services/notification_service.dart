import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/config/app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationAction(details);
      },
    );
  }

  void _handleNotificationAction(NotificationResponse details) {
    final actionId = details.actionId;
    final payload = details.payload;

    if (actionId == 'DONE') {
      // Mark as done action
    } else if (actionId == 'SNOOZE_15') {
      // Snooze 15 minutes
      if (payload != null) {
        snoozeNotification(int.parse(payload), const Duration(minutes: 15));
      }
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required List<int> reminderOffsets,
    int quietHoursStart = AppConfig.quietHoursStart,
    int quietHoursEnd = AppConfig.quietHoursEnd,
  }) async {
    for (int i = 0; i < reminderOffsets.length; i++) {
      final offsetSeconds = reminderOffsets[i];
      final targetTime = scheduledDate.subtract(Duration(seconds: offsetSeconds));

      // Quiet hours check
      if (targetTime.hour >= quietHoursStart || targetTime.hour < quietHoursEnd) {
        // Postpone until quiet hours end
        continue;
      }

      if (targetTime.isAfter(DateTime.now())) {
        await _notificationsPlugin.zonedSchedule(
          id + i,
          title,
          body,
          tz.TZDateTime.from(targetTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders_channel',
              'Event Reminders',
              channelDescription: 'Notifications for upcoming events and solicitations',
              importance: Importance.high,
              priority: Priority.high,
              actions: [
                AndroidNotificationAction('DONE', 'Mark Done'),
                AndroidNotificationAction('SNOOZE_15', 'Snooze 15m'),
              ],
            ),
            iOS: DarwinNotificationDetails(),
          ),
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> snoozeNotification(int id, Duration duration) async {
    final newTime = DateTime.now().add(duration);
    await _notificationsPlugin.zonedSchedule(
      id,
      'Snoozed Reminder',
      'Reminder snoozed for ${duration.inMinutes} minutes',
      tz.TZDateTime.from(newTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders_channel', 'Event Reminders'),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
