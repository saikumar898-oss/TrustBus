import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/animated_background.dart';
import '../../core/glass_card.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool loading = false;
  bool resendCooldown = false;
  int cooldownSeconds = 30;

  Timer? verificationTimer;
  Timer? cooldownTimer;

  @override
  void initState() {
    super.initState();

    // Auto-check verification every 5 seconds
    verificationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    verificationTimer?.cancel();
    cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_read,
                    size: 72,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'A verification link has been sent to your email.\n'
                    'Please verify your email to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 24),

                  /// CONTINUE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: loading ? null : _continueAfterVerify,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.redAccent,
                            )
                          : const Text(
                              "I've Verified My Email",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// RESEND EMAIL
                  TextButton(
                    onPressed: resendCooldown ? null : _resendEmail,
                    child: Text(
                      resendCooldown
                          ? 'Resend in $cooldownSeconds s'
                          : 'Resend verification email',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- AUTO CHECK ----------------

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.reload();

      if (user.emailVerified) {
        verificationTimer?.cancel();
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  // ---------------- CONTINUE ----------------

  Future<void> _continueAfterVerify() async {
    setState(() => loading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          verificationTimer?.cancel();
          await FirebaseAuth.instance.signOut();
        } else {
          _showMessage(
            'Email not verified yet.\nPlease check your inbox or spam folder.',
          );
        }
      }
    } catch (e) {
      _showMessage('Error checking verification.\n$e');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // ---------------- RESEND EMAIL ----------------

  Future<void> _resendEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        setState(() {
          resendCooldown = true;
          cooldownSeconds = 30;
        });

        cooldownTimer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            if (cooldownSeconds == 0) {
              timer.cancel();

              if (mounted) {
                setState(() {
                  resendCooldown = false;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  cooldownSeconds--;
                });
              }
            }
          },
        );

        _showMessage("Verification email sent again.");
      }
    } catch (e) {
      _showMessage("Failed to send email.\n$e");
    }
  }

  // ---------------- MESSAGE ----------------

  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Email Verification'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
