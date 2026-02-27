import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn();

  User? get user => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ================= REGISTER =================
  Future<String?> register({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user!.sendEmailVerification();

      await _firestore.collection("users").doc(cred.user!.uid).set({
        "email": email,
        "role": role,
        "createdAt": Timestamp.now(),
      });

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= LOGIN =================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= GOOGLE LOGIN =================
  Future<String?> googleSignIn() async {
    try {
      final account = await _google.signIn();
      if (account == null) return "Cancelled";

      final auth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);

      await _firestore.collection("users").doc(result.user!.uid).set({
        "email": result.user!.email,
        "role": "customer",
        "createdAt": Timestamp.now(),
      }, SetOptions(merge: true));

      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= PHONE OTP =================
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (e) => onError(e.message ?? "OTP Failed"),
      codeSent: (verificationId, _) => codeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<String?> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ================= ROLE =================
  Future<String?> getUserRole() async {
    final doc = await _firestore.collection("users").doc(user!.uid).get();
    return doc.data()?["role"];
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  // ================= EMAIL VERIFICATION =================
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    notifyListeners();
  }

  User? get currentUser => _auth.currentUser;
}
