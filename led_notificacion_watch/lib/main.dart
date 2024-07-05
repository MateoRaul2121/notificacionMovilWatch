import 'package:flutter/material.dart';
import 'package:led_notificacion_watch/pages/apagado.dart';
import 'package:led_notificacion_watch/pages/bluetooth_page.dart';
import 'package:led_notificacion_watch/pages/inicio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsOnPlatform(),
            TargetPlatform.iOS: NoTransitionsOnPlatform(),
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: 'home',
      routes: {
        'home': (context) => const HomePage(),
        'bluetooth': (context) => BluetoothScreen(),
      },
    );
  }
}

class NoTransitionsOnPlatform extends PageTransitionsBuilder {
  const NoTransitionsOnPlatform();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
