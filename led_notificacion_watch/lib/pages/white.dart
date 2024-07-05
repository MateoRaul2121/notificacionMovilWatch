import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:wear/wear.dart';
import 'dart:async'; // Importación de Timer
import 'dart:typed_data';

import 'apagado.dart';

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
  double intensity = 0.5; // Valor inicial para la intensidad
  double temperature = 50; // Valor inicial para la temperatura (escala 0-100)
  Color currentColor = Colors.white;

  Timer? debounceTemperature;
  Timer? debounceIntensity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WatchShape(
        builder: (context, shape, child) {
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/galaxy.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height:15,),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/img/FOCO.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 5.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                        activeTrackColor: Color.lerp(
                            Colors.white, Colors.yellow, temperature / 100),
                        inactiveTrackColor: Colors.grey.withOpacity(0.5),
                        thumbColor: const Color.fromARGB(255, 198, 190, 116),
                        overlayColor: const Color.fromARGB(255, 19, 19, 18).withOpacity(0.2),
                      ),
                      child: Slider(
                        value: temperature,
                        onChanged: (newValue) {
                          setState(() {
                            temperature = newValue;
                            currentColor = Color.lerp(Colors.white,
                                Colors.yellow, temperature / 100)!;
                          });
                          if (debounceTemperature?.isActive ?? false)
                            debounceTemperature?.cancel();
                          debounceTemperature =
                              Timer(const Duration(milliseconds: 500), () {
                            _sendTemperature(newValue.toInt());
                          });
                        },
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: 'Temperatura',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                        activeTrackColor: Color.lerp(Colors.grey, Colors.white, intensity),
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
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: GestureDetector(
                    onTap: _Apagado,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.power_settings_new,
                          size: 31.0, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

  void _Apagado() async {
    // Enviar señal al módulo Bluetooth para apagar el LED RGB
    try {
      widget.connection.output.add(Uint8List.fromList("OFF\n".codeUnits));
      await widget.connection.output.allSent;

       //Navegar de regreso a la pantalla "PantallaApagado"
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
}
