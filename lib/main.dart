import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          // If user is logged in, show HomeScreen
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.data != null) {
              return const HomeScreen();
            }
          }
          // Otherwise show WelcomeScreen (login page)
          return const WelcomeScreen();
        },
      ),
    );
  }
}
