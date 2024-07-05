import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'white.dart'; // Asegúrate de importar la pantalla WhitePage
import 'dart:typed_data';

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

class _PantallaApagadoState extends State<PantallaApagado> {
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
                onTap: _Encendido,
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

  void _Encendido() async {
    // Enviar señal al módulo Bluetooth para encender el LED RGB en blanco normal
    try {
      widget.connection.output.add(Uint8List.fromList("ON\n".codeUnits));
      await widget.connection.output.allSent;

      // Navegar a la pantalla "WhitePage"
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
}
