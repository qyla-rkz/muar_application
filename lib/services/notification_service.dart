import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ TOP-LEVEL FUNCTION required for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. Setup Local Notifications (for foreground popups)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);

    // 3. Create Android Channel (High Importance)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // 🔽 check toggle preference
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('notificationsEnabled') ?? true;
      if (!enabled) return;

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If app is in foreground, show local notification manually
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              priority: Priority.high,
              importance: Importance.max,
            ),
          ),
        );
      }
    });

    // 5. Background Handler Setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 6. Subscribe to broadcast topic
    await _firebaseMessaging.subscribeToTopic('all_users');

    _isInitialized = true;
  }

  // 💾 SAVE TOKEN
  Future<void> saveTokenToDatabase() async {
    String? token = await _firebaseMessaging.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
      debugPrint("FCM Token Saved: $token");
    }
  }

  // 📤 SEND NOTIFICATION (Offloaded to Cloud Functions)
  static Future<void> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    String? type,
    String? senderId,
    String? senderName,
    String? relatedId,
  }) async {
    try {
      // Standardize to write to 'notifications' collection.
      // The Cloud Function 'sendPushNotification' will trigger on this.
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': receiverId,
        'senderId': senderId ?? FirebaseAuth.instance.currentUser?.uid,
        'senderName': senderName ?? 'Sistem',
        'title': title,
        'body': body, // Standard field
        'type': type ?? 'alert',
        'relatedId': relatedId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      debugPrint("Notification queued in Firestore for: $receiverId");
    } catch (e) {
      debugPrint("Error queuing notification: $e");
    }
  }
}

