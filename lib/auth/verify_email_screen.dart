import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/customer_dashboard.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Verify Email",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("Please check your inbox and verify your email."),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser!.reload();

                final user = FirebaseAuth.instance.currentUser;

                if (user != null && user.emailVerified) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerDashboard(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email not verified yet")),
                  );
                }
              },
              child: const Text("I Have Verified"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.currentUser!
                    .sendEmailVerification();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Verification email sent")),
                );
              },
              child: const Text("Resend Email"),
            )
          ],
        ),
      ),
    );
  }
}
