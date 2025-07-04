import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/auth_page.dart';
import 'auth/login_page.dart';
import 'auth/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthPage(),
        '/login':
            (context) => LoginPage(
              onRegisterClicked:
                  () => Navigator.of(context).pushReplacementNamed('/register'),
            ),
        '/register':
            (context) => RegisterPage(
              onLoginClicked:
                  () => Navigator.of(context).pushReplacementNamed('/login'),
            ),
      },
    );
  }
}
