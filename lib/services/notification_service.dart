import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app.dart';
import '../config/firebase_config.dart';
import '../config/theme.dart';
import '../screens/hero/notification_job_screen.dart';
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
      _navigateFromPayload(initialMessage.data);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _navigateFromPayload(message.data);
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
    String? token;
    if (Platform.isIOS) {
      // On iOS, wait for the APNS token before requesting FCM token
      for (int i = 0; i < 5; i++) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    try {
      token = await _messaging.getToken();
    } catch (e) {
      debugPrint('FCM getToken error: $e');
    }
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

    final nav = OTWApp.navigatorKey.currentState;
    final ctx = nav?.context;

    if (ctx != null && message.data['type'] == 'new_job') {
      _showInAppBanner(ctx, notification.title, notification.body, message.data);
    } else {
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
  }

  void _showInAppBanner(
    BuildContext context,
    String? title,
    String? body,
    Map<String, dynamic> data,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 8,
        left: 12,
        right: 12,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              entry.remove();
              _navigateFromPayload(data);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.brandGreen, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.work_outline, color: AppTheme.brandGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title ?? 'New Job',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (body != null)
                          Text(
                            body,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'View',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 8), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (_) {}
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final type = data['type'];
    final jobId = data['jobId'] as String?;
    if (jobId == null) return;

    final nav = OTWApp.navigatorKey.currentState;
    if (nav == null) return;

    switch (type) {
      case 'new_job':
        _navigateToJobDetails(nav, jobId);
        break;
      case 'job_accepted':
        break;
      case 'no_heroes':
        break;
    }
  }

  void _navigateToJobDetails(NavigatorState nav, String jobId) {
    nav.push(
      MaterialPageRoute(
        builder: (_) => NotificationJobScreen(jobId: jobId),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {}
