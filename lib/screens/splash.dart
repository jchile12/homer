import 'package:flutter/material.dart';
import 'package:homer/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double opacity = 1.0;

  @override
  void initState() {
    super.initState();
    
    // Inicia la animación de fade out
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          opacity = 0.0;
        });
      }

      // Navega al AuthWrapper después de la animación
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: opacity,
          child: Image.asset(
            "assets/images/homerLogoNegro.png",
            width: 200, // Ajusta el tamaño según necesites
            height: 200,
          ),
        ),
      ),
    );
  }
}