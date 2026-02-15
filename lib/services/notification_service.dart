import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/firebase_config.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseConfig.messaging;
  final _firestoreService = FirestoreService();
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    await _createNotificationChannel();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotification,
        payload: jsonEncode(initialMessage.data),
      ));
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(NotificationResponse(
        notificationResponseType:
            NotificationResponseType.selectedNotification,
        payload: jsonEncode(message.data),
      ));
    });
  }

  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'otw_jobs',
      'Job Notifications',
      description: 'Notifications for new jobs and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<String?> getAndSaveToken({String? userId, String? heroId}) async {
    final token = await _messaging.getToken();
    if (token == null) return null;
    if (userId != null) {
      await _firestoreService.updateUser(userId, {
        'settings.pushToken': token,
      });
    }
    if (heroId != null) {
      await _firestoreService.updateHeroPushToken(heroId, token);
    }
    _messaging.onTokenRefresh.listen((newToken) {
      if (userId != null) {
        _firestoreService.updateUser(userId!, {'settings.pushToken': newToken});
      }
      if (heroId != null) {
        _firestoreService.updateHeroPushToken(heroId!, newToken);
      }
    });
    return token;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'otw_jobs',
          'Job Notifications',
          channelDescription: 'Notifications for new jobs and updates',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final type = data['type'];
      final jobId = data['jobId'];
      // Navigate based on type/jobId - handled by app router
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {}
