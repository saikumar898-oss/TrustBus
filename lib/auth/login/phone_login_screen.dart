import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String? verificationId;
  bool otpSent = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Phone Login")),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!otpSent)
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone (+91XXXXXXXXXX)",
                  ),
                ),
              if (otpSent)
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!otpSent) {
                    await auth.sendOTP(
                      phoneNumber: phoneController.text.trim(),
                      codeSent: (verId) {
                        setState(() {
                          verificationId = verId;
                          otpSent = true;
                        });
                      },
                      onError: (error) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      },
                    );
                  } else {
                    final error = await auth.verifyOTP(
                      verificationId: verificationId!,
                      smsCode: otpController.text.trim(),
                    );

                    if (error != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  }
                },
                child: Text(otpSent ? "Verify OTP" : "Send OTP"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
