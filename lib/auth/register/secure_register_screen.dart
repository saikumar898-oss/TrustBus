import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../core/glass_card.dart';

class SecureRegisterScreen extends StatefulWidget {
  const SecureRegisterScreen({super.key});

  @override
  State<SecureRegisterScreen> createState() => _SecureRegisterScreenState();
}

class _SecureRegisterScreenState extends State<SecureRegisterScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool loading = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/logo/bus.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF0F172A),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// DARK OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
            ),
          ),

          /// REGISTER CARD
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
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _field(Icons.person, "Full Name", nameCtrl),

                      _field(
                        Icons.email,
                        "Email",
                        emailCtrl,
                        keyboard: TextInputType.emailAddress,
                      ),

                      _field(
                        Icons.phone,
                        "Phone",
                        phoneCtrl,
                        keyboard: TextInputType.phone,
                      ),

                      /// PASSWORD
                      _field(
                        Icons.lock,
                        "Password",
                        passCtrl,
                        obscure: !showPassword,
                        suffix: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                      ),

                      /// CONFIRM PASSWORD
                      _field(
                        Icons.lock_outline,
                        "Confirm Password",
                        confirmCtrl,
                        obscure: !showConfirmPassword,
                        suffix: IconButton(
                          icon: Icon(
                            showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              showConfirmPassword = !showConfirmPassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// REGISTER BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: const StadiumBorder(),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// GOOGLE SIGNUP
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Image.asset(
                            "assets/logo/google.png",
                            height: 20,
                            width: 20,
                          ),
                          label: const Text(
                            "Continue with Google",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: loading ? null : _googleSignup,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// LOGIN
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Already have an account? Login",
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

  /// FIELD
  Widget _field(
    IconData icon,
    String hint,
    TextEditingController controller, {
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(0.12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// REGISTER
  Future<void> _register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        passCtrl.text.isEmpty ||
        confirmCtrl.text.isEmpty) {
      _showMessage("Please fill all fields");
      return;
    }

    if (!emailCtrl.text.contains("@")) {
      _showMessage("Enter a valid email");
      return;
    }

    if (passCtrl.text.length < 6) {
      _showMessage("Password must be at least 6 characters");
      return;
    }

    if (passCtrl.text != confirmCtrl.text) {
      _showMessage("Passwords do not match");
      return;
    }

    setState(() => loading = true);

    final error = await context.read<AuthService>().register(
          fullName: nameCtrl.text.trim(),
          email: emailCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          password: passCtrl.text.trim(),
        );

    if (mounted) setState(() => loading = false);

    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage(
        "Account created successfully.\nVerification email sent.",
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  /// GOOGLE SIGNUP
  Future<void> _googleSignup() async {
    setState(() => loading = true);

    final error = await context.read<AuthService>().googleLogin();

    if (mounted) setState(() => loading = false);

    if (error != null) {
      _showMessage(error);
    }
  }

  /// MESSAGE
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
          )
        ],
      ),
    );
  }
}
