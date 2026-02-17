import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../dashboard/customer_dashboard.dart';
import '../auth/login/customer_login_screen.dart';
import 'animated_background.dart';

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
      final auth = context.read<AuthService>();
      if (auth.user != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CustomerDashboard()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CustomerLoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Icon(
            Icons.directions_bus,
            size: 100,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
