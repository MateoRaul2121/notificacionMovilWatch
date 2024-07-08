import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'apagado.dart'; // Importar la pantalla PantallaApagado
import 'dart:typed_data';
import 'dart:async'; // Importación de Timer
import 'package:firebase_database/firebase_database.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class WhitePage extends StatefulWidget {
  final String deviceName;
  final BluetoothConnection connection;

  const WhitePage({
    required this.deviceName,
    required this.connection,
    Key? key,
  }) : super(key: key);

  @override
  State<WhitePage> createState() => _WhitePageState();
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
        'body': 'LED Apagado',
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

class _WhitePageState extends State<WhitePage> {
  List<bool> isSelected = [true, false];
  double intensity = 0.5; // Initial value for intensity
  double temperature = 50; // Initial value for temperature (0-100 scale)
  Color currentColor = Colors.white;

  Timer? debounceTemperature;
  Timer? debounceIntensity;

  void _apagar() async {
    try {
      widget.connection.output.add(Uint8List.fromList("OFF\n".codeUnits));
      await widget.connection.output.allSent;
      sendNotification("LED Apagado", "El LED ha sido apagado");
      sendFCMMessage();

      await _sendNotification('LED Apagado');

      // Navegar de regreso a PantallaApagado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaApagado(
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

  void _sendTemperature(int temperature) {
    try {
      String command = "T$temperature\n";
      widget.connection.output.add(Uint8List.fromList(command.codeUnits));
      widget.connection.output.allSent;
    } catch (e) {
      print('Error sending temperature: $e');
    }
  }

  void _sendIntensity(double intensity) {
    try {
      String command = "I${(intensity * 100).toInt()}\n";
      widget.connection.output.add(Uint8List.fromList(command.codeUnits));
      widget.connection.output.allSent;
    } catch (e) {
      print('Error sending intensity: $e');
    }
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
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 80.0),
              child: Text(
                "White",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40.0),
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Image.asset(
                      'assets/img/FOCO.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 30.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 16.0),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 24.0),
                          activeTrackColor:
                              Color.lerp(Colors.grey, Colors.white, intensity),
                          inactiveTrackColor: Colors.grey.withOpacity(0.5),
                          thumbColor: const Color.fromARGB(255, 134, 134, 134),
                          overlayColor: Colors.white.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: intensity,
                          onChanged: (newValue) {
                            setState(() {
                              intensity = newValue;
                            });
                            if (debounceIntensity?.isActive ?? false)
                              debounceIntensity?.cancel();
                            debounceIntensity =
                                Timer(const Duration(milliseconds: 500), () {
                              _sendIntensity(newValue);
                            });
                          },
                          min: 0,
                          max: 1,
                          divisions: 100,
                          label: 'Intensidad',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: _apagar,
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
