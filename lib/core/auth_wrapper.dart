import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login/customer_login_screen.dart';
import '../auth/verify_email_screen.dart';
import '../dashboard/customer_dashboard.dart';
import '../dashboard/authority_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        /// 🔄 LOADING STATE
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        /// ❌ NOT LOGGED IN
        if (!snapshot.hasData) {
          return const CustomerLoginScreen();
        }

        final user = snapshot.data!;

        /// 📧 EMAIL NOT VERIFIED
        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        /// 🔐 FETCH ROLE FROM FIRESTORE
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get(),
          builder: (context, roleSnapshot) {
            /// 🔄 LOADING ROLE
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            /// ❌ ERROR HANDLING
            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text("Something went wrong")),
              );
            }

            /// ⚠️ USER DOC NOT FOUND
            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(child: Text("User data not found")),
              );
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>;

            final role = data["role"] ?? "customer";

            /// 🔑 ROLE-BASED ROUTING
            if (role == "authority") {
              return const AuthorityDashboard();
            } else {
              return const CustomerDashboard();
            }
          },
        );
      },
    );
  }
}
