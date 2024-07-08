import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'white.dart'; // Importar la pantalla WhitePage
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';




final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PantallaApagado extends StatefulWidget {
  final String deviceName;
  final BluetoothConnection connection;

  const PantallaApagado({
    required this.deviceName,
    required this.connection,
    Key? key,
  }) : super(key: key);

  @override
  State<PantallaApagado> createState() => _PantallaApagadoState();
}

Future<String> getAccessToken() async {
  // Your client ID and client secret obtained from Google Cloud Console
  final serviceAccountJson = {
    //CredencialesPropias
};

 List<String> scopes = [
  "https://www.googleapis.com/auth/userinfo.email",
  "https://www.googleapis.com/auth/firebase.database",
 "https://www.googleapis.com/auth/firebase.messaging"
];
 
 http.Client client = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
  );

  // Obtain the access token
  auth.AccessCredentials credentials = await auth.obtainAccessCredentialsViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
    scopes,
    client
  );

  // Close the HTTP client
  client.close();

  // Return the access token
  return credentials.accessToken.data;

}

Future<void> sendFCMMessage() async {
  final String serverKey = await getAccessToken() ; // Your FCM server key
  final String fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/lednotificaciones/messages:send';
  final  currentFCMToken = await FirebaseMessaging.instance.getToken();
  final String tokenRelo = 'cb0yyPokT82HkagKjWyElR:APA91bG7DCFfgcR7DTtv97NxwfI7HduoFbAHoB1KLL8FUPJml5k4pQ4VtzTsGanyhEE7-Xz-7RQc738ppm7gNhFFXdL7-p3evhUDwuxbBMh0_sUHVS1W3eUjRC-pj6MO0bVBcDQyDIvd';
  print("fcmkey : $currentFCMToken");
  final Map<String, dynamic> message = {
    'message': {
      'token': tokenRelo, // Token of the device you want to send the message to
      'notification': {
        'body': 'LED Encendido',
        'title': 'Cambio de LED'
      },
      'data': {
        'current_user_fcm_token': currentFCMToken, // Include the current user's FCM token in data payload
      },
    }
  };

  final http.Response response = await http.post(
    Uri.parse(fcmEndpoint),
    headers: <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $serverKey',
    },
    body: jsonEncode(message),
  );

  if (response.statusCode == 200) {
    print('FCM message sent successfully');
  } else {
    print('Failed to send FCM message: ${response.statusCode}');
  }
}

Future<void> _sendNotification(String message) async {
  final databaseReference = FirebaseDatabase.instance.ref();
  try {
    await databaseReference.child('notifications').push().set({'message': message});
    print('Notification sent successfully: $message');
  } catch (error) {
    print('Failed to send notification: $error');
  }
}


class _PantallaApagadoState extends State<PantallaApagado> {
  void _encender() async {
    try {
      widget.connection.output.add(Uint8List.fromList("ON\n".codeUnits));
      
      sendFCMMessage();
      await widget.connection.output.allSent;
      await _sendNotification('LED Encendido');
      sendNotification("LED Encendido", "El LED ha sido encendido");

          // Enviar notificación FCM
    
      // Navegar a la pantalla WhitePage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WhitePage(
            deviceName: widget.deviceName,
            connection: widget.connection,
          ),
        ),
      );
    } catch (e) {
      print('Error sending data: $e');
    }
  }

  void sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', 'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics,
        payload: 'item x');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/galaxy.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Image.asset(
                    'assets/img/FOCO_Apagado.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _encender,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.power_settings_new,
                    size: 36.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
