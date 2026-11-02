// lib/auth/login/customer_login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';
import '../../core/glass_card.dart';
import '../register/secure_register_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool showPassword = false;
  bool loading = false;
  bool rememberMe = false;

  // ✅ FIX 1: Cache SharedPreferences instance — avoids repeated init overhead
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs(); // single init for prefs + load remembered email

    // 🔥 Auto login if already signed in
    final user = context.read<AuthService>().user;
    if (user != null) {
      Future.microtask(() {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/home");
      });
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // INIT PREFS + LOAD REMEMBERED EMAIL
  // Combined into one call to avoid double getInstance() overhead
  // ─────────────────────────────────────────
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedEmail = _prefs!.getString("remember_email");

    if (savedEmail != null && mounted) {
      setState(() {
        emailCtrl.text = savedEmail;
        rememberMe = true;
      });
    }
  }

  // ─────────────────────────────────────────
  // SAVE REMEMBERED EMAIL
  // ✅ FIX 2: Reuses cached _prefs — no getInstance() call here
  // ─────────────────────────────────────────
  Future<void> _saveRememberEmail() async {
    if (rememberMe) {
      await _prefs?.setString("remember_email", emailCtrl.text.trim());
    } else {
      await _prefs?.remove("remember_email");
    }
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
          // BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/logo/bus.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // OVERLAY
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          // LOGIN UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  child: Column(
                    children: [
                      const Text(
                        "Welcome Back",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _field(
                        icon: Icons.email,
                        hint: "Email",
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      _field(
                        icon: Icons.lock,
                        hint: "Password",
                        controller: passwordCtrl,
                        obscure: !showPassword,
                        suffix: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() => showPassword = !showPassword);
                          },
                        ),
                      ),

                      // REMEMBER ME
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            activeColor: Colors.redAccent,
                            onChanged: (v) {
                              setState(() => rememberMe = v ?? false);
                            },
                          ),
                          const Text(
                            "Remember Me",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),

                      // FORGOT PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading ? null : _resetPassword,
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: const StadiumBorder(),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // GOOGLE LOGIN
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
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: loading ? null : _googleLogin,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // REGISTER
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecureRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Create new account",
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
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
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

  // ─────────────────────────────────────────
  // LOGIN
  // ✅ FIX 3: setState(loading=true) BEFORE prefs save
  // ✅ FIX 4: Future.wait runs prefs save + Firebase auth in parallel
  // ─────────────────────────────────────────
  Future<void> _login() async {
    if (!emailCtrl.text.contains("@")) {
      _show("Enter a valid email");
      return;
    }

    if (passwordCtrl.text.length < 6) {
      _show("Password must be at least 6 characters");
      return;
    }

    // ✅ Show spinner FIRST — UI responds immediately
    setState(() => loading = true);

    // ✅ Run prefs save + Firebase auth simultaneously
    String? authError;

    await Future.wait([
      _saveRememberEmail(),
      context
          .read<AuthService>()
          .login(
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text.trim(),
          )
          .then((error) => authError = error),
    ]);

    if (!mounted) return;
    setState(() => loading = false);

    if (authError != null) {
      _show(authError!);
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  // ─────────────────────────────────────────
  // GOOGLE LOGIN
  // ─────────────────────────────────────────
  Future<void> _googleLogin() async {
    setState(() => loading = true);

    final error = await context.read<AuthService>().googleLogin();

    if (!mounted) return;
    setState(() => loading = false);

    if (error != null) {
      _show(error);
    } else {
      Navigator.pushReplacementNamed(context, "/home");
    }
  }

  // ─────────────────────────────────────────
  // FORGOT PASSWORD
  // ─────────────────────────────────────────
  Future<void> _resetPassword() async {
    if (emailCtrl.text.isEmpty) {
      _show("Enter your email first");
      return;
    }

    setState(() => loading = true);

    final error =
        await context.read<AuthService>().forgotPassword(emailCtrl.text.trim());

    if (!mounted) return;
    setState(() => loading = false);

    if (error != null) {
      _show(error);
    } else {
      _show("Password reset email sent! Check your inbox.");
    }
  }

  // ─────────────────────────────────────────
  // SHOW MESSAGE DIALOG
  // ─────────────────────────────────────────
  void _show(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
