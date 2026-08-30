import 'dart:developer' as dev;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../models/vanity_item_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          dev.log('Notification tapped: ${response.payload}', name: 'NotificationService');
        },
      );

      _initialized = true;
      dev.log('Local Notification Service initialized successfully', name: 'NotificationService');
    } catch (e) {
      dev.log('Error initializing notification service: $e', name: 'NotificationService');
    }
  }

  /// Request permissions for iOS / Android 13+
  Future<void> requestPermissions() async {
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      dev.log('Error requesting notification permissions: $e', name: 'NotificationService');
    }
  }

  /// Schedule notifications for an opened vanity item:
  /// 1. 30 days before expiry (Amber alert)
  /// 2. On expiry date (Expired alert)
  Future<void> scheduleExpiryNotifications(VanityItemModel item) async {
    if (item.expiryDate == null) return;

    final expiry = item.expiryDate!;
    final amberDate = expiry.subtract(const Duration(days: 30));
    final now = DateTime.now();

    final amberId = (item.vanityItemId.hashCode.abs() % 100000) * 2;
    final expiryId = amberId + 1;

    // 1. Amber notification (30 days out)
    if (amberDate.isAfter(now)) {
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          amberId,
          '⚠️ ${item.productName} Expiring Soon!',
          'Your ${item.brand} ${item.productName} will expire in 30 days (${item.formattedExpiryDate}). Use it before it goes bad!',
          tz.TZDateTime.from(amberDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'vanity_expiry_channel',
              'Vanity Expiry Reminders',
              channelDescription: 'Alerts for expiring cosmetics and skincare',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.vanityItemId,
        );
        dev.log('Scheduled 30-day amber notification for ${item.productName} at $amberDate', name: 'NotificationService');
      } catch (e) {
        dev.log('Failed to schedule amber notification: $e', name: 'NotificationService');
      }
    }

    // 2. Expiry day notification
    if (expiry.isAfter(now)) {
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          expiryId,
          '🛑 ${item.productName} Has Expired!',
          'Your ${item.brand} ${item.productName} has passed its PAO period. Replace or discard to avoid irritation.',
          tz.TZDateTime.from(expiry, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'vanity_expiry_channel',
              'Vanity Expiry Reminders',
              channelDescription: 'Alerts for expiring cosmetics and skincare',
              importance: Importance.max,
              priority: Priority.max,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: item.vanityItemId,
        );
        dev.log('Scheduled expiry notification for ${item.productName} at $expiry', name: 'NotificationService');
      } catch (e) {
        dev.log('Failed to schedule expiry notification: $e', name: 'NotificationService');
      }
    }
  }

  /// Cancels scheduled notifications when an item is deleted or marked finished
  Future<void> cancelNotificationsForItem(String vanityItemId) async {
    final amberId = (vanityItemId.hashCode.abs() % 100000) * 2;
    final expiryId = amberId + 1;
    try {
      await _flutterLocalNotificationsPlugin.cancel(amberId);
      await _flutterLocalNotificationsPlugin.cancel(expiryId);
      dev.log('Cancelled notifications for item: $vanityItemId', name: 'NotificationService');
    } catch (e) {
      dev.log('Error cancelling notifications: $e', name: 'NotificationService');
    }
  }
}
