import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../verify_email_screen.dart';
import '../../core/glass_card.dart';

class SecureRegisterScreen extends StatefulWidget {
  const SecureRegisterScreen({super.key});

  @override
  State<SecureRegisterScreen> createState() => _SecureRegisterScreenState();
}

class _SecureRegisterScreenState extends State<SecureRegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      body: Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                ),
                const SizedBox(height: 30),
                loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          setState(() => loading = true);

                          final error = await auth.register(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                            role: "customer",
                          );

                          setState(() => loading = false);

                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VerifyEmailScreen(),
                              ),
                            );
                          }
                        },
                        child: const Text("Register"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
