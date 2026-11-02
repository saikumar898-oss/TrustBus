import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login/customer_login_screen.dart';
import '../dashboard/customer_dashboard.dart';
import '../dashboard/authority_dashboard.dart'; // adjust path as needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────────
  late final AnimationController _logoCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _textCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _taglineCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _progressCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  // ── Animations ───────────────────────────────────────────────
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _logoCtrl,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _logoCtrl,
    curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
  );
  late final Animation<Offset> _textSlide = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
  late final Animation<double> _textOpacity = CurvedAnimation(
    parent: _textCtrl,
    curve: Curves.easeIn,
  );
  late final Animation<double> _taglineOpacity = CurvedAnimation(
    parent: _taglineCtrl,
    curve: Curves.easeIn,
  );

  // ── Loading label ────────────────────────────────────────────
  String _loadingLabel = "Initialising...";

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  Future<void> _runSequence() async {
    // Staggered animation sequence
    await Future.delayed(const Duration(milliseconds: 100));
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _progressCtrl.forward();

    // Update loading labels during progress
    _updateLabel(500, "Checking connection...");
    _updateLabel(1200, "Loading your profile...");
    _updateLabel(1800, "Almost ready...");

    // Wait for animations + minimum splash time
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;
    _navigate();
  }

  void _updateLabel(int delayMs, String label) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) setState(() => _loadingLabel = label);
    });
  }

  // ── Auth-aware routing ───────────────────────────────────────
  Future<void> _navigate() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in → login screen
      _go(const CustomerLoginScreen());
      return;
    }

    try {
      // Check user role in Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role'] ?? 'customer';

      if (role == 'authority' || role == 'admin') {
        _go(const AuthorityDashboard());
      } else {
        _go(const CustomerDashboard());
      }
    } catch (_) {
      // Firestore error → fall back to login
      _go(const CustomerLoginScreen());
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoSize = width > 1200
        ? 220.0
        : width > 800
            ? 180.0
            : width > 600
                ? 150.0
                : 120.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
              Color(0xFF1C3B45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative background circles ──────────────
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -50,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),

            // ── Main content ───────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ────────────────────────────────
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Image.asset(
                        "assets/logo/trustbuslogo.png",
                        width: logoSize,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── App name ─────────────────────────────
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: const Text(
                        "TrustBus",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Tagline ──────────────────────────────
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: const Text(
                      "Safe  •  Smart  •  Reliable",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white60,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ── Progress bar ─────────────────────────
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: SizedBox(
                      width: logoSize + 40,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _progressCtrl,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progressCtrl.value,
                                minHeight: 3,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _loadingLabel,
                              key: ValueKey(_loadingLabel),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Version tag bottom ─────────────────────────
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineOpacity,
                child: const Text(
                  "v1.0.0",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
