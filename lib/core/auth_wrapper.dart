import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../auth/login/customer_login_screen.dart';
import '../auth/verify_email_screen.dart';
import '../dashboard/customer_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = auth.user;

        if (user == null) {
          return const CustomerLoginScreen();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        return const CustomerDashboard();
      },
    );
  }
}
