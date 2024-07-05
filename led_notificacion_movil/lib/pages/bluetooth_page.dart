import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'apagado.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<BluetoothDevice> devicesList = [];
  BluetoothConnection? connection;
  bool isConnected = false;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    setupFirebaseMessaging();
  }

  void requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.notification,
    ].request();
    getPairedDevices();
  }

  void setupFirebaseMessaging() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message contained a notification: ${message.notification}');
        _showNotification(message.notification!.title, message.notification!.body);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      Navigator.pushNamed(context, '/message', arguments: message);
    });

    String? token = await messaging.getToken();
    print('Device Token: $token');
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

      _sendCommand("OFF\n");

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
      if (command == "ON\n") {
        sendNotification("LED Encendido", "El LED ha sido encendido");
      } else if (command == "OFF\n") {
        sendNotification("LED Apagado", "El LED ha sido apagado");
      }
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  void sendNotification(String title, String body) async {
    _showNotification(title, body);
  }

  void _showNotification(String? title, String? body) async {
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
      appBar: AppBar(
        title: const Text(
          'Dispositivos Bluetooth',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    connectToDevice(devicesList[index]);
                  },
                  child: ListTile(
                    title: Text(
                      devicesList[index].name ?? 'Unknown',
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      devicesList[index].address.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          isConnected
              ? Column(
                  children: [
                    Text(
                      'Connected to ${connectedDevice!.name} (${connectedDevice!.address})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                )
              : const Text(
                  'Not connected',
                  style: TextStyle(color: Colors.white),
                ),
        ],
      ),
    );
  }
}
