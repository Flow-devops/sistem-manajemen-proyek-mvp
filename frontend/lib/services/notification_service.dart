import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Minta Izin
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. Setup Local Notifications
      var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/launcher_icon');
      var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await _localNotifications.initialize(initializationSettings);

      // 3. Dengarkan pesan saat Foreground
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      
      // 4. Dengarkan jika token berubah di sistem Firebase
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });

      debugPrint('Notification Service Initialized');
    } catch (e) {
      debugPrint('Error initializing Notification Service: $e');
    }
  }

  // Fungsi untuk mengambil token dan menyimpannya
  static Future<void> updateToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('Token FCM Ditemukan: $token');
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('Gagal mengambil token FCM: $e');
    }
  }

  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      
      if (user != null) {
        await client.from('profiles').update({
          'fcm_token': token,
        }).eq('id', user.id);
        debugPrint('FCM Token berhasil disimpan ke profil user: ${user.id}');
      } else {
        debugPrint('User belum login, token tidak disimpan ke database.');
      }
    } catch (e) {
      debugPrint('Gagal simpan token: $e');
    }
  }

  static void _showForegroundNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'flow_moments',
            'Flow Moments',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
        ),
      );
    }
  }
}
