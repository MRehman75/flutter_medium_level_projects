import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0526), Color(0xFFFF007F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            'Welcome to Admin Dashboard',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.lightBlueAccent, offset: Offset(2, 2), blurRadius: 4),
              ],
            ),
            textAlign: TextAlign.center,
          ).animate()
              .fadeIn(duration: 1000.ms)
              .scale(duration: 1000.ms),
        ),
      ),
    );
  }
}