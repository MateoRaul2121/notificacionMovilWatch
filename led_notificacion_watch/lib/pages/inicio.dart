import 'package:flutter/material.dart';
import 'package:wear/wear.dart'; // Nueva importación

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WatchShape(
        builder: (context, shape, child) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, 'bluetooth');
              },
              child: Text('INICIAR'),
            ),
          );
        },
      ),
    );
  }
}
