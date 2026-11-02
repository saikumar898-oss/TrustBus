import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';

import 'core/app_theme.dart';
import 'core/auth_wrapper.dart';

import 'auth/login/customer_login_screen.dart';
import 'auth/register/secure_register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TrustBusApp());
}

class TrustBusApp extends StatelessWidget {
  const TrustBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// 🔐 AUTH PROVIDER (GLOBAL ACCESS)
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "TrustBus",

        /// 🎨 THEME
        theme: AppTheme.darkTheme,

        /// 🔥 AUTO ROUTING SYSTEM
        home: const AuthWrapper(),

        /// 📍 ROUTES
        routes: {
          "/login": (_) => const CustomerLoginScreen(),
          "/register": (_) => const SecureRegisterScreen(),
        },

        /// 🧠 BEST PRACTICE (NAVIGATION SAFETY)
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const CustomerLoginScreen(),
          );
        },
      ),
    );
  }
}
