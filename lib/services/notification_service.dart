import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// เริ่มต้น Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // ตั้งค่า timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    // ตั้งค่า Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // ตั้งค่า iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('✅ NotificationService: Initialized');
  }

  /// ขอ Permission สำหรับ iOS
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    return result ?? true;
  }

  /// เมื่อกด Notification
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // TODO: Navigate to specific page
  }

  /// ตั้งเวลาแจ้งเตือนรายวัน
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    await _notifications.cancelAll();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // ถ้าเวลาที่ตั้งผ่านไปแล้ววันนี้ ให้เลื่อนไปพรุ่งนี้
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      '🌟 ถึงเวลาบันทึกอารมณ์แล้ว',
      'มาเล่าให้ฉันฟังหน่อยสิว่าวันนี้เป็นอย่างไรบ้าง',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'แจ้งเตือนให้บันทึกอารมณ์รายวัน',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print('✅ Notification scheduled: ${scheduledDate.hour}:${scheduledDate.minute}');
  }

  /// ยกเลิก Notification
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🚫 All notifications cancelled');
  }

  /// โหลดการตั้งค่าและตั้ง Notification
  Future<void> loadAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('notification_enabled') ?? false;

    if (isEnabled) {
      final hour = prefs.getInt('notification_hour') ?? 20;
      final minute = prefs.getInt('notification_minute') ?? 0;
      
      await scheduleDailyNotification(hour: hour, minute: minute);
      print('🔔 Notification loaded: $hour:$minute');
    } else {
      await cancelAllNotifications();
    }
  }
}