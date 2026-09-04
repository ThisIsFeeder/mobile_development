import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:login_signup/firebase_options.dart';
import 'package:login_signup/screens/home_screen.dart';
import 'package:login_signup/screens/welcome_screen.dart';
import 'package:login_signup/services/auth_service.dart';
import 'package:login_signup/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint(
      'Firebase initialization notice: $e\n'
      'Run "flutterfire configure" to link your active Firebase project credentials.',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth Demo',
      theme: lightMode,
      home: const AuthGate(),
    );
  }
}

/// Listens to auth state changes and automatically routes to either
/// [HomeScreen] when logged in or [WelcomeScreen] when logged out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const WelcomeScreen();
        },
      );
    } catch (_) {
      // Fallback if Firebase was not yet initialized
      return const WelcomeScreen();
    }
  }
}
