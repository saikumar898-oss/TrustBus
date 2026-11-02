// lib/auth/login/phone_login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../core/glass_card.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  bool otpSent = false;
  bool loading = false;
  String verificationId = "";

  @override
  void dispose() {
    phoneCtrl.dispose();
    otpCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND GRADIENT
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ICON
                      const Icon(
                        Icons.phone_android,
                        size: 56,
                        color: Colors.white,
                      ),

                      const SizedBox(height: 16),

                      // TITLE
                      Text(
                        otpSent ? "Enter OTP" : "Phone Login",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        otpSent
                            ? "Enter the OTP sent to ${phoneCtrl.text}"
                            : "Enter your phone number to receive an OTP",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // PHONE FIELD
                      if (!otpSent)
                        _field(
                          icon: Icons.phone,
                          hint: "+91 XXXXX XXXXX",
                          controller: phoneCtrl,
                          keyboard: TextInputType.phone,
                        ),

                      // OTP FIELD
                      if (otpSent)
                        _field(
                          icon: Icons.lock_outline,
                          hint: "6-digit OTP",
                          controller: otpCtrl,
                          keyboard: TextInputType.number,
                        ),

                      const SizedBox(height: 8),

                      // MAIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : otpSent
                                  ? _verifyOTP
                                  : _sendOTP,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.redAccent,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  otpSent ? "Verify OTP" : "Send OTP",
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // CHANGE NUMBER
                      if (otpSent)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              otpSent = false;
                              otpCtrl.clear();
                            });
                          },
                          child: const Text(
                            "Change number",
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),

                      // BACK TO LOGIN
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Back to Login",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // INPUT FIELD WIDGET
  // ─────────────────────────────────────────
  Widget _field({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.12),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SEND OTP
  // ─────────────────────────────────────────
  Future<void> _sendOTP() async {
    final phone = phoneCtrl.text.trim();

    if (phone.isEmpty) {
      _showMessage("Please enter your phone number.");
      return;
    }

    if (!phone.startsWith("+")) {
      _showMessage("Include country code e.g. +91XXXXXXXXXX");
      return;
    }

    setState(() => loading = true);

    // ✅ sendOtp (lowercase) — matches auth_service.dart
    await context.read<AuthService>().sendOtp(
          phoneNumber: phone,
          onCodeSent: (vid) {
            // ✅ onCodeSent — matches auth_service.dart parameter name
            if (mounted) {
              setState(() {
                verificationId = vid;
                otpSent = true;
                loading = false;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() => loading = false);
              _showMessage(error);
            }
          },
        );
  }

  // ─────────────────────────────────────────
  // VERIFY OTP
  // ─────────────────────────────────────────
  Future<void> _verifyOTP() async {
    final otp = otpCtrl.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      _showMessage("Please enter the 6-digit OTP.");
      return;
    }

    setState(() => loading = true);

    // ✅ verifyOtp (lowercase) — matches auth_service.dart
    // ✅ otp: not smsCode — matches auth_service.dart parameter name
    // ✅ phone: required param added
    final error = await context.read<AuthService>().verifyOtp(
          verificationId: verificationId,
          otp: otp,
          phone: phoneCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => loading = false);

    if (error != null) {
      _showMessage(error);
    } else {
      // ✅ Navigate to home after successful phone login
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  // ─────────────────────────────────────────
  // SHOW MESSAGE DIALOG
  // ─────────────────────────────────────────
  void _showMessage(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Message"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
