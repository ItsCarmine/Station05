import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class NotificationService {
  NotificationService._internal();
  // Initialize notification service instances.
  static final NotificationService _notificationInstance = NotificationService._internal();
  factory NotificationService() => _notificationInstance;

  final FlutterLocalNotificationsPlugin _notificationPlugin = FlutterLocalNotificationsPlugin();

  // Singleton pattern to ensure only one instance of NotificationService is created.
  Future<void> init() async {
    // Check the notification permission status.
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
      developer.log('Notification permission denied', name: 'NotificationService', level: 0);
    }

    developer.log('Permission success', name: 'NotificationService', level: 0);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final settings = InitializationSettings(android: androidSettings);

    await _notificationPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onClick,
    );
  }

  /// Set the notification click callback.
  /// Modify the if statement to add your own logic.
  void _onClick(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // TODO: add your logic here
      print('Notification payload: $payload');
    }
  }

  /// Send a real-time notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_channel_id',
      'Instant Notification',
      channelDescription: 'Instant Notification from Station 5',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationPlugin.show(id, title, body, details, payload: payload);
  }

  /// Cancel a notification by its ID.
  Future<void> cancel(int id) => _notificationPlugin.cancel(id);

  /// Cancel all notifications.
  Future<void> cancelAll() => _notificationPlugin.cancelAll();
}
