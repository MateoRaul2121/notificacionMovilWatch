import 'package:flutter/material.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<Color> _randomColors; // Lista de colores aleatorios

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _randomColors = _generarColorRamdom(); // Generar colores aleatorios una vez
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _generarColorRamdom() {
    final random = Random();
    return [
      Color.fromARGB(
          255, random.nextInt(256), random.nextInt(256), random.nextInt(256)),
      Color.fromARGB(
          255, random.nextInt(256), random.nextInt(256), random.nextInt(256)),
      Color.fromARGB(
          255, random.nextInt(256), random.nextInt(256), random.nextInt(256)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: LinearGradient(
                  colors:
                      _randomColors, // Usar los colores aleatorios generados
                  stops: [1.0, 1.5, 2.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_animation.value * 2 * pi),
                ),
              ),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 40.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, 'bluetooth');
                },
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors:
                          _randomColors, // Usar los colores aleatorios generados
                      stops: [0.0, 0.5, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(_animation.value * 2 * pi),
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'INICIAR',
                    style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 18.0),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
