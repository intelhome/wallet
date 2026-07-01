import 'dart:convert';

import 'package:dapp_movil/core/notifications/push_router.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance; 
  static Map<String, dynamic>? pendingRoute;

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
     onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          try {
            Map<String, dynamic> payloadData = jsonDecode(response.payload!);
            print("🚀 [FOREGROUND CLICK] Ejecutando acción");
            PushRouter.handleNotificationClick(payloadData); 
          } catch (e) {
            print("Error parseando payload: $e");
          }
        }
      },
    );
    // Solicitar permisos al usuario (Android 13+ / iOS)
    //_localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

   NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _firebaseMessaging.getToken();
      print("🔥 FIREBASE TOKEN DEL DISPOSITIVO: $token");
    }

    // 2. RECIBIR EN PRIMER PLANO (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Convertimos el mapa de datos (data) a un String JSON para pasarlo al payload local
      String payloadStr = jsonEncode(message.data);
      
      showLocalNotification(
        message.notification?.title ?? "Nueva Notificación", 
        message.notification?.body ?? "",
        payloadStr
      );
    });
// 3. CLIC EN SEGUNDO PLANO (Background - App minimizada)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 [BACKGROUND CLICK] Ejecutando acción desde segundo plano");
      PushRouter.handleNotificationClick(message.data);
    });

    // 4. CLIC CUANDO LA APP ESTABA CERRADA DEL TODO (Terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("🚀 [TERMINATED CLICK] App abierta desde notificación");
      // Damos un poco de tiempo extra para asegurar que Flutter dibujó el MaterialApp
      Future.delayed(const Duration(seconds: 2), () {
        PushRouter.handleNotificationClick(initialMessage.data);
      });
    }
  }

  // Modificamos para recibir el payload
  static Future<void> showLocalNotification(String title, String body, [String? payload]) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ttc_channel_push', 'TTC Push',
      importance: Importance.max, 
      priority: Priority.high, 
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    
    await _localNotifications.show(
      id: DateTime.now().millisecond, 
      title: title, 
      body: body, 
      notificationDetails: details,
      payload: payload,
    );
  }
}