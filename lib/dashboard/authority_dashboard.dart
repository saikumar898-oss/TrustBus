import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthorityDashboard extends StatelessWidget {
  const AuthorityDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Authority Dashboard"),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.logout();
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome Authority",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
