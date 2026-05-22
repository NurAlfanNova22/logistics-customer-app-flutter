import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _database = FirebaseDatabase.instance;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('ic_launcher_foreground');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Klik notifikasi
        },
      );
    } catch (e) {
      print('Notification Init Error: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Lancar Ekspedisi',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  // Listener untuk Realtime Database (Disamakan dengan pola Driver)
  static void listenToRealtimeNotifications(dynamic userId) {
    String uid = userId.toString();
    String path = 'notifications_customer/$uid';
    print("🔔 [DEBUG] Monitoring Firebase Path: $path");
    
    DatabaseReference ref = _database.ref(path);
    
    ref.onChildAdded.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map?;
      print("📩 [DEBUG] Ada data masuk ke path $path: $data");
      
      if (data != null) {
        // Tampilkan notifikasi tanpa filter waktu untuk testing
        showNotification(
          title: data['title'] ?? 'Lancar Ekspedisi',
          body: data['body'] ?? '',
          payload: data['type'],
        );
      }
    }, onError: (error) {
      print("❌ Firebase Listener Error: $error");
    });
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
    
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await ApiService.updateFcmToken(token);
      }
    } catch (e) {
      print('FCM Token Error: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'lancar_ekspedisi_channel',
        'Lancar Ekspedisi Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_launcher_foreground',
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        id: 0,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      print("❌ Error showing notification: $e");
    }
  }
}
