import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'dart:io';

class NotificationService {
  static dynamic _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _database = FirebaseDatabase.instance;

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Klik notifikasi
        },
      );
    } catch (e) {
      print('Notification Init Error: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title,
          body: message.notification!.body,
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
        print("📩 Data Notifikasi Diterima: ${data['title']}");
        
        int timestamp = data['timestamp'] ?? 0;
        int now = DateTime.now().millisecondsSinceEpoch;
        
        // Toleransi 30 detik untuk memastikan notifikasi muncul saat HP baru aktif
        if ((now - timestamp).abs() < 30000) {
          showNotification(
            title: data['title'] ?? 'Lancar Ekspedisi',
            body: data['body'] ?? '',
            payload: data['type'],
          );
        }
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
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'lancar_ekspedisi_channel',
        'Notifikasi Ekspedisi',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}
