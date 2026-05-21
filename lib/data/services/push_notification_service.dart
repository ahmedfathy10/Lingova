import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/api_config.dart';
import '../models/auth_user.dart';
import 'auth_http_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'lingova_notifications',
    'Lingova Notifications',
    description: 'تنبيهات التطبيق',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _prepared = false;
  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  Future<void> prepareApp() async {
    if (_prepared || kIsWeb) {
      return;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      _foregroundSubscription ??= FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
      _openedAppSubscription ??= FirebaseMessaging.onMessageOpenedApp.listen(
        (_) {},
      );

      _prepared = true;
    } catch (_) {
      _prepared = false;
    }
  }

  Future<void> bindUser(AuthUser? user) async {
    if (user == null || user.id.isEmpty || kIsWeb) {
      return;
    }

    _currentUserId = user.id;
    await prepareApp();
    if (!_prepared) {
      return;
    }

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, user.id);
      }

      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((token) async {
            final currentUserId = _currentUserId;
            if (currentUserId == null || currentUserId.isEmpty) {
              return;
            }
            await _registerToken(token, currentUserId);
          });
    } catch (_) {}
  }

  Future<void> _registerToken(String token, String userId) async {
    try {
      await postJson(Uri.parse('${ApiConfig.baseUrl}/api/devices/register'), {
        'userId': userId,
        'token': token,
        'platform': defaultTargetPlatform.name,
      });
    } catch (_) {}
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
