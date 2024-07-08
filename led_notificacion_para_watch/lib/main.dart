import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wear/wear.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Muestra la notificación cuando la app está en segundo plano
  flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title,
    message.notification?.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Solicitar permisos para notificaciones
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  var androidNotificationChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidNotificationChannel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Obtener y mostrar el token en la consola
  FirebaseMessaging.instance.getToken().then((String? token) {
    assert(token != null);
    print("FCM Token: $token");
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? payload;

  const HomePage({Key? key, this.payload}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _imagePath = 'assets/img/led_off.png';

  @override
  void initState() {
    super.initState();
    _initFirebaseMessaging();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotification(message.notification?.body);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotification(message.notification?.body);
    });
    if (widget.payload != null) {
      _handleNotification(widget.payload);
    }

    // Solicitar permisos de notificaciones
    _requestPermissions();
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }

  void _handleNotification(String? body) {
    print(body);
    if (body == 'LED Encendido') {
      setState(() {
        _imagePath = 'assets/img/led_on.png';
      });
    } else if (body == 'LED Apagado') {
      setState(() {
        _imagePath = 'assets/img/led_off.png';
      });
    }

    if (body != null) {
      _showNotification(body);
    }
  }

  void _showNotification(String body) {
    flutterLocalNotificationsPlugin.show(
      body.hashCode,
      'Notificación LED',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          priority: Priority.high,
          showWhen: false,
        ),
      ),
    );
  }

  void _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: SizedBox(width: 150, height: 150, child: Image.asset(_imagePath)),
              ),
            );
          },
        );
      },
    );
  }
}
