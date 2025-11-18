// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:homer/screens/splash.dart';
import 'package:homer/screens/inicio_sesion.dart';
import 'package:homer/screens/inicio.dart';
import 'package:homer/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCBy5yCf4MGx11pIidpcmVkSy70I5NAZ8s",
        authDomain: "homer-95f55.firebaseapp.com",
        projectId: "homer-95f55",
        storageBucket: "homer-95f55.firebasestorage.app",
        messagingSenderId: "350370218778",
        appId: "1:350370218778:web:206c7c15ef3666dff362a3"
      ),
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

// ========== AUTH WRAPPER ==========
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mientras se carga el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay un usuario autenticado, ir a HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Si no hay usuario, mostrar LoginScreen
        return const LoginScreen();
      },
    );
  }
}

// ========== HOME SCREEN ==========
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
      
      // El AuthWrapper detectará automáticamente el cambio y mostrará LoginScreen
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          // Mostrar info del usuario
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  user.displayName ?? user.email ?? 'Usuario',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: const ProductsScreen(),
    );
  }
}