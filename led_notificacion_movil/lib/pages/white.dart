import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'apagado.dart'; // Importar la pantalla PantallaApagado
import 'dart:typed_data';
import 'dart:async'; // Importación de Timer

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
