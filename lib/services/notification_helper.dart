import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combine settings (only Android required for status bar notifications)
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      // Rejalashtirilgan bildirishnomalar uchun timezone
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

      // Request permissions for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );
      _isInitialized = true;
      debugPrint('NotificationHelper initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing NotificationHelper: $e');
    }
  }

  Future<void> showNotification(int id, String title, String body,
      {String? payload}) async {
    if (!_isInitialized) {
      await init();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'super_app_channel_id',
      'Super App Eslatmalar',
      channelDescription: 'Rejalar va eslatmalar uchun bildirishnoma kanali',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Har hafta belgilangan kun (ISO weekday: 1=Dushanba ... 7=Yakshanba) va
  /// vaqtda takrorlanadigan bildirishnoma rejalashtirish.
  Future<void> scheduleWeekly(
    int id,
    String title,
    String body, {
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fitness_reminders',
      'Fitnes Eslatmalar',
      channelDescription: 'Mashg\'ulot kunlari uchun eslatma kanali',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOf(weekday, hour, minute),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling weekly notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOf(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// [fromId] dan [toId] gacha (ikkalasi ham kiradi) ID diapazonini bekor qilish.
  Future<void> cancelRange(int fromId, int toId) async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= fromId && request.id <= toId) {
          await _notificationsPlugin.cancel(request.id);
        }
      }
    } catch (e) {
      debugPrint('Error cancelling notification range: $e');
    }
  }
}
