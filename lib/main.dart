import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';

import 'auth/login/customer_login_screen.dart';
import 'auth/verify_email_screen.dart';

import 'dashboard/admin_panel_screen.dart';
import 'dashboard/customer_dashboard.dart';
import 'dashboard/authority_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyFirstApp());
}

class MyFirstApp extends StatelessWidget {
  const MyFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "TrustBus",
        themeMode: ThemeMode.system,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F0F1B),
          inputDecorationTheme: const InputDecorationTheme(
            border: UnderlineInputBorder(),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

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
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const CustomerLoginScreen();
        }

        final user = auth.user;

        if (!user!.emailVerified) {
          return const VerifyEmailScreen();
        }

        return const RoleRouter();
      },
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<String?>(
      future: auth.getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        switch (snapshot.data) {
          case "admin":
            return const AdminPanelScreen();

          case "authority":
            return const AuthorityDashboard();

          default:
            return const CustomerDashboard();
        }
      },
    );
  }
}
