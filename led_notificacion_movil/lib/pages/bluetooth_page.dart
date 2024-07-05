import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:led_notificacion_movil/pages/apagado.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'dart:convert';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  List<BluetoothDevice> devicesList = [];
  BluetoothConnection? connection;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  void requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();
    getPairedDevices();
  }

  void getPairedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on Exception {
      print('Error getting paired devices.');
    }
    setState(() {
      devicesList = devices;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    if (connection != null && connection!.isConnected) {
      await connection!.close();
    }

    try {
      connection = await BluetoothConnection.toAddress(device.address);
      print('Connected to the device');
      setState(() {
        isConnected = true;
        connectedDevice = device;
      });

      connection!.input!.listen((Uint8List data) {
        print('Data incoming: ${ascii.decode(data)}');
        connection!.output.add(data); // Sending data
        if (ascii.decode(data).contains('!')) {
          connection!.finish(); // Closing connection
          print('Disconnecting by local host');
        }
      }).onDone(() {
        print('Disconnected by remote request');
      });

      // Enviar comando "OFF" para apagar el LED
      _sendCommand("OFF\n");

      // Navega a PantallaApagado después de una conexión exitosa, pasando el nombre del dispositivo y la conexión Bluetooth
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaApagado(
            deviceName: device.name ?? 'Unknown',
            connection: connection!,
          ),
        ),
      );
    } catch (e) {
      print('Cannot connect, exception occurred: $e');
    }
  }

  void _sendCommand(String command) {
    try {
      connection!.output.add(Uint8List.fromList(command.codeUnits));
      connection!.output.allSent;
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dispositivos Bluetooth',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black, // Fondo negro
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: devicesList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      devicesList[index].name ?? 'Unknown',
                      style: const TextStyle(color: Colors.white), // Texto blanco
                    ),
                    subtitle: Text(
                      devicesList[index].address.toString(),
                      style: const TextStyle(color: Colors.grey), // Texto gris
                    ),
                    onTap: () {
                      connectToDevice(devicesList[index]);
                    },
                  );
                },
              ),
            ),
            isConnected
                ? Column(
                    children: [
                      Text(
                        'Connected to ${connectedDevice!.name} (${connectedDevice!.address})',
                        style: const TextStyle(color: Colors.white), // Texto blanco
                      ),
                    ],
                  )
                : const Text(
                    'Not connected',
                    style: TextStyle(color: Colors.white), // Texto blanco
                  ),
          ],
        ),
      ),
    );
  }
}
