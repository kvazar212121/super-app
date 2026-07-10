import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Budilnik bildirishnomasi bosilganda/ochilganda chaqiriladi (payload = alarm JSON).
  /// main.dart bu callback orqali jiringlash ekranini ochadi.
  void Function(String payload)? onAlarmPayload;

  /// Ilova o'chiq holatdan budilnik bildirishnomasi orqali ochilsa, shu yerda saqlanadi.
  /// main.dart uni o'qib jiringlash ekranini ochadi (init'dan keyin).
  String? pendingAlarmPayload;

  /// Budilnik notification ID'lari shu bazadan boshlanadi (boshqa bildirishnomalar bilan
  /// to'qnashmasligi uchun). Har budilnik uchun: base + alarm.id*10 + kun-indeksi.
  static const int alarmIdBase = 100000;

  /// Umumiy bildirishnoma kanali. ID'da "_v2" bor — Android'da kanal bir marta
  /// yaratilgach sozlamasi (ovoz/muhimlik) o'zgarmaydi, shuning uchun eski ovozsiz
  /// kanalni chetlab o'tish uchun YANGI ID ishlatamiz.
  static const String _generalChannelId = 'super_app_channel_v2';

  /// Kanallarni aniq (ovoz + tebranish bilan) yaratadi. Init'da chaqiriladi.
  Future<void> _createChannels() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    const generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      'Eslatmalar va bildirishnomalar',
      description: 'Buyurtmalar, rejalar va umumiy bildirishnomalar',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await android.createNotificationChannel(generalChannel);

    const fitnessChannel = AndroidNotificationChannel(
      'fitness_reminders',
      'Fitnes Eslatmalar',
      description: 'Mashg\'ulot kunlari uchun eslatma kanali',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await android.createNotificationChannel(fitnessChannel);
  }

  Future<void> init() async {
    if (_isInitialized) return;

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS (Darwin) Settings — talab qilinadi, aks holda iOS'da
    // "iOS settings must be set when targeting iOS platform" xatosi chiqadi.
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combine settings (Android + iOS/macOS)
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    try {
      // Rejalashtirilgan bildirishnomalar uchun timezone
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

      // Request permissions for Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
          final payload = details.payload;
          if (payload != null && payload.startsWith('alarm:')) {
            onAlarmPayload?.call(payload.substring('alarm:'.length));
          }
        },
      );
      // Kanallarni ovoz bilan yaratamiz (Android 8+ uchun majburiy)
      await _createChannels();

      // Ilova budilnik bildirishnomasi orqali ochilgan bo'lsa, payloadни ushlab qolamiz
      final launch = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final p = launch!.notificationResponse?.payload;
        if (p != null && p.startsWith('alarm:')) {
          pendingAlarmPayload = p.substring('alarm:'.length);
        }
      }

      _isInitialized = true;
      debugPrint('NotificationHelper initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing NotificationHelper: $e');
    }
  }

  Future<void> showNotification(
    int id,
    String title,
    String body, {
    String? payload,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _generalChannelId,
          'Eslatmalar va bildirishnomalar',
          channelDescription: 'Buyurtmalar, rejalar va umumiy bildirishnomalar',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          playSound: true,
          enableVibration: true,
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

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
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

  // ─────────────────────── MAJBURLOVCHI BUDILNIK ───────────────────────

  /// Budilnik uchun to'liq-ekranli, aniq vaqtli bildirishnoma tafsilotlari.
  /// Jiringlash ekran (AlarmRingScreen) baland ovozni o'zi boshqaradi; bu bildirishnoma
  /// telefonni uyg'otib, ekranни ochib, ilovani old fonga chiqaradi.
  AndroidNotificationDetails get _alarmAndroidDetails =>
      const AndroidNotificationDetails(
        'forcing_alarm_channel',
        'Majburlovchi budilnik',
        channelDescription: 'Budilnik jiringlashi uchun kanal',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent:
            true, // qulflangan ekranда ham to'liq ekranда ochiladi
        ongoing: true, // surib tashlab bo'lmaydi
        autoCancel: false,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
      );

  int _alarmNotifId(int alarmId, int weekday) =>
      alarmIdBase + alarmId * 10 + weekday;

  /// Budilnikni rejalashtirish. Takror kunlari bo'lsa har kun uchun haftalik takror,
  /// bo'lmasa keyingi mos vaqtga bir martalik.
  Future<void> scheduleAlarm(Alarm alarm) async {
    if (!_isInitialized) await init();
    await cancelAlarm(alarm.id);
    if (!alarm.isEnabled) return;

    final payload = 'alarm:${jsonEncode(alarm.toPayload()..['id'] = alarm.id)}';
    final details = NotificationDetails(android: _alarmAndroidDetails);

    try {
      if (alarm.isOneTime) {
        await _notificationsPlugin.zonedSchedule(
          _alarmNotifId(alarm.id, 0),
          alarm.label,
          'Budilnikni o\'chirish uchun vazifani bajaring',
          _nextInstanceOfTime(alarm.hour, alarm.minute),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } else {
        for (final weekday in alarm.repeatDayList) {
          await _notificationsPlugin.zonedSchedule(
            _alarmNotifId(alarm.id, weekday),
            alarm.label,
            'Budilnikni o\'chirish uchun vazifani bajaring',
            _nextInstanceOf(weekday, alarm.hour, alarm.minute),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      }
      debugPrint('Alarm ${alarm.id} scheduled (${alarm.timeLabel}).');
    } catch (e) {
      debugPrint('Error scheduling alarm ${alarm.id}: $e');
    }
  }

  /// Snooze — belgilangan daqiqadan keyin qayta jiringlash (bir martalik).
  Future<void> snoozeAlarm(Alarm alarm) async {
    if (!_isInitialized) await init();
    final when = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: alarm.snoozeMinutes));
    final payload = 'alarm:${jsonEncode(alarm.toPayload()..['id'] = alarm.id)}';
    try {
      await _notificationsPlugin.zonedSchedule(
        _alarmNotifId(
          alarm.id,
          8,
        ), // 8 = snooze sloti (weekday 1-7 dan tashqarida)
        alarm.label,
        'Snooze — budilnik qaytadi',
        when,
        NotificationDetails(android: _alarmAndroidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error snoozing alarm ${alarm.id}: $e');
    }
  }

  /// Bitta budilnikning barcha (7 kun + snooze + one-time) bildirishnomalarini bekor qilish.
  Future<void> cancelAlarm(int alarmId) async {
    final base = alarmIdBase + alarmId * 10;
    await cancelRange(base, base + 9);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
