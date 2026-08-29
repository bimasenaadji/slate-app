import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/time_anchor.dart';

/// Service for managing graceful local notifications (Mindful Anchors)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initializes the local notification plugin and timezone database
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      try {
        final String currentTimeZone = DateTime.now().timeZoneName;
        if (tz.timeZoneDatabase.locations.containsKey(currentTimeZone)) {
          tz.setLocalLocation(tz.getLocation(currentTimeZone));
        }
      } catch (_) {}

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _notificationsPlugin.initialize(settings: settings);
      _isInitialized = true;

      // Request notification permissions for Android 13+
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Schedules a discrete Mindful Anchor notification for a specific task
  Future<void> scheduleAnchorNotification({
    required String taskId,
    required String title,
    required String anchor, // 'morning' | 'afternoon' | 'evening'
    bool isForTomorrow = false,
  }) async {
    if (!_isInitialized) await init();

    final timeAnchor = TimeAnchor.fromKey(anchor);
    if (timeAnchor == null) return;

    try {
      final int notifId = taskId.hashCode.abs();
      final now = DateTime.now();
      DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        timeAnchor.targetHour,
        0,
      );

      if (isForTomorrow || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final tz.TZDateTime tzScheduledDate =
          tz.TZDateTime.from(scheduledDate, tz.local);

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'slate_mindful_anchors',
        'Jangkar Waktu',
        channelDescription: 'Sapaan pengingat ritme waktu Slate',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.zonedSchedule(
        id: notifId,
        title: 'Sapaan ${timeAnchor.label}',
        body: title,
        scheduledDate: tzScheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Error scheduling anchor notification: $e');
    }
  }

  /// Cancels a scheduled task notification
  Future<void> cancelNotification(String taskId) async {
    if (!_isInitialized) return;
    try {
      final int notifId = taskId.hashCode.abs();
      await _notificationsPlugin.cancel(id: notifId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }
}
