import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login/customer_login_screen.dart';
import 'animated_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Center(
        child: Image.asset("assets/logo.png", height: 120)
            .animate()
            .scale(duration: 800.ms),
      ),
    );
  }
}
