import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wear/wear.dart';

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
    if (widget.payload != null) {
      _handleNotification(widget.payload);
    }
  }

  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }

  void _handleNotification(String? body) {
    if (body == 'LED Encendido') {
      setState(() {
        _imagePath = 'assets/img/led_on.png';
      });
    } else if (body == 'LED Apagado') {
      setState(() {
        _imagePath = 'assets/img/led_off.png';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            return Scaffold(
              body: Center(
                child: Image.asset(_imagePath),
              ),
            );
          },
        );
      },
    );
  }
}
