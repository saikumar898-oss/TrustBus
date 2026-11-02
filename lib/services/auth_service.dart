// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ✅ Use clientId for web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? "YOUR_CLIENT_ID.apps.googleusercontent.com" : null,
    scopes: ["email"],
  );

  // ─────────────────────────────────────────
  // 👤 CURRENT USER GETTERS
  // ─────────────────────────────────────────
  User? get user => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─────────────────────────────────────────
  // 🔥 USERNAME GENERATOR
  // ─────────────────────────────────────────
  String generateUsername(String name) {
    final clean = name.toLowerCase().replaceAll(" ", "");
    final random =
        (100 + DateTime.now().millisecondsSinceEpoch % 900).toString();
    return "$clean$random";
  }

  // ─────────────────────────────────────────
  // 🔐 REGISTER WITH EMAIL & PASSWORD
  // ─────────────────────────────────────────
  Future<String?> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      await _db.collection("users").doc(uid).set({
        "userId": uid,
        "username": generateUsername(fullName),
        "name": fullName.trim(),
        "email": email.trim(),
        "phone": phone.trim(),
        "role": "customer",
        "profilePic": "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await cred.user!.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🔐 LOGIN WITH EMAIL & PASSWORD
  // ─────────────────────────────────────────
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return "Please verify your email before logging in.\nCheck your inbox for the verification link.";
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🔐 GOOGLE SIGN IN  ✅ FIXED FOR WEB
  // ─────────────────────────────────────────
  Future<String?> googleLogin() async {
    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // Web: use signInSilently first (avoids the LegacyJavaScriptObject cast error)
        googleUser = await _googleSignIn.signInSilently();
        googleUser ??= await _googleSignIn.signIn();
      } else {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) return "Sign in cancelled";

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final firebaseUser = userCred.user!;

      final doc = await _db.collection("users").doc(firebaseUser.uid).get();

      if (!doc.exists) {
        await _db.collection("users").doc(firebaseUser.uid).set({
          "userId": firebaseUser.uid,
          "username": generateUsername(firebaseUser.displayName ?? "user"),
          "name": firebaseUser.displayName ?? "",
          "email": firebaseUser.email ?? "",
          "phone": firebaseUser.phoneNumber ?? "",
          "role": "customer",
          "profilePic": firebaseUser.photoURL ?? "",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 📱 PHONE LOGIN — SEND OTP
  // ─────────────────────────────────────────
  Future<String?> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_handleAuthError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 📱 PHONE LOGIN — VERIFY OTP
  // ─────────────────────────────────────────
  Future<String?> verifyOtp({
    required String verificationId,
    required String otp,
    required String phone,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final firebaseUser = userCred.user!;

      final doc = await _db.collection("users").doc(firebaseUser.uid).get();
      if (!doc.exists) {
        await _db.collection("users").doc(firebaseUser.uid).set({
          "userId": firebaseUser.uid,
          "username": generateUsername("user"),
          "name": "",
          "email": "",
          "phone": phone,
          "role": "customer",
          "profilePic": "",
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🔑 FORGOT PASSWORD
  // ─────────────────────────────────────────
  Future<String?> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🔄 RESEND VERIFICATION EMAIL
  // ─────────────────────────────────────────
  Future<String?> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🚪 LOGOUT
  // ─────────────────────────────────────────
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // 👤 GET USER PROFILE
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final uid = currentUserId;
      if (uid == null) return null;
      final doc = await _db.collection("users").doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Real-time profile stream
  Stream<DocumentSnapshot> getUserProfileStream() {
    return _db.collection("users").doc(currentUserId).snapshots();
  }

  // ─────────────────────────────────────────
  // ✏️ UPDATE USER PROFILE
  // ─────────────────────────────────────────
  Future<String?> updateProfile({
    required String name,
    required String phone,
    String? profilePic,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return "Not logged in";

      final Map<String, dynamic> data = {
        "name": name.trim(),
        "phone": phone.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (profilePic != null) data["profilePic"] = profilePic;

      await _db.collection("users").doc(uid).update(data);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🚌 GET ALL BUSES (for search screen)
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getBuses({
    String? from,
    String? to,
    String? date,
  }) {
    Query query = _db.collection("buses").where("isActive", isEqualTo: true);

    if (from != null && from.isNotEmpty) {
      query = query.where("from", isEqualTo: from);
    }
    if (to != null && to.isNotEmpty) {
      query = query.where("to", isEqualTo: to);
    }
    if (date != null && date.isNotEmpty) {
      query = query.where("date", isEqualTo: date);
    }

    return query.snapshots();
  }

  // Get single bus details
  Future<Map<String, dynamic>?> getBusDetails(String busId) async {
    try {
      final doc = await _db.collection("buses").doc(busId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Real-time single bus stream
  Stream<DocumentSnapshot> getBusStream(String busId) {
    return _db.collection("buses").doc(busId).snapshots();
  }

  // ─────────────────────────────────────────
  // 💺 GET BOOKED SEATS FOR A BUS
  // ─────────────────────────────────────────
  Stream<List<String>> getBookedSeats(String busId) {
    return _db
        .collection("bookings")
        .where("busId", isEqualTo: busId)
        .where("status", whereIn: ["pending", "confirmed"])
        .snapshots()
        .map((snapshot) {
          final List<String> bookedSeats = [];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final seats = List<String>.from(data["seats"] ?? []);
            bookedSeats.addAll(seats);
          }
          return bookedSeats;
        });
  }

  // ─────────────────────────────────────────
  // 🎟️ CREATE BOOKING
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> createBooking({
    required String busId,
    required String busName,
    required String from,
    required String to,
    required String journeyDate,
    required List<String> seats,
    required double amount,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return {"success": false, "error": "Not logged in"};

      final bookingRef = await _db.collection("bookings").add({
        "userId": uid,
        "busId": busId,
        "busName": busName,
        "from": from,
        "to": to,
        "journeyDate": journeyDate,
        "seats": seats,
        "amount": amount,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      return {"success": true, "bookingId": bookingRef.id};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ─────────────────────────────────────────
  // 💳 MAKE PAYMENT
  // ─────────────────────────────────────────
  Future<String?> makePayment({
    required String bookingId,
    required double amount,
    String paymentMethod = "upi",
    String? transactionId,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return "Not logged in";

      await _db.collection("payments").add({
        "userId": uid,
        "bookingId": bookingId,
        "amount": amount,
        "paymentMethod": paymentMethod,
        "transactionId":
            transactionId ?? "TXN${DateTime.now().millisecondsSinceEpoch}",
        "status": "success",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _db.collection("bookings").doc(bookingId).update({
        "status": "confirmed",
        "paidAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 📋 GET USER BOOKINGS
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getUserBookings() {
    final uid = currentUserId;
    return _db
        .collection("bookings")
        .where("userId", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // Get single booking details
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      final doc = await _db.collection("bookings").doc(bookingId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // ─────────────────────────────────────────
  // ❌ CANCEL BOOKING
  // ─────────────────────────────────────────
  Future<String?> cancelBooking(String bookingId) async {
    try {
      await _db.collection("bookings").doc(bookingId).update({
        "status": "cancelled",
        "cancelledAt": FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // ⭐ ADD REVIEW
  // ─────────────────────────────────────────
  Future<String?> addReview({
    required String busId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null) return "Not logged in";

      final existing = await _db
          .collection("reviews")
          .where("bookingId", isEqualTo: bookingId)
          .where("userId", isEqualTo: uid)
          .get();

      if (existing.docs.isNotEmpty) {
        return "You have already reviewed this trip";
      }

      await _db.collection("reviews").add({
        "userId": uid,
        "busId": busId,
        "bookingId": bookingId,
        "rating": rating,
        "comment": comment.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // ⭐ GET REVIEWS FOR A BUS
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getBusReviews(String busId) {
    return _db
        .collection("reviews")
        .where("busId", isEqualTo: busId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — GET ALL BUSES
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getAllBusesAdmin() {
    return _db
        .collection("buses")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — ADD BUS
  // ─────────────────────────────────────────
  Future<String?> addBus({
    required String busName,
    required String busNumber,
    required String from,
    required String to,
    required String date,
    required String departureTime,
    required String arrivalTime,
    required int totalSeats,
    required double price,
    required String busType,
  }) async {
    try {
      await _db.collection("buses").add({
        "busName": busName.trim(),
        "busNumber": busNumber.trim(),
        "from": from.trim(),
        "to": to.trim(),
        "date": date,
        "departureTime": departureTime,
        "arrivalTime": arrivalTime,
        "totalSeats": totalSeats,
        "availableSeats": totalSeats,
        "price": price,
        "busType": busType,
        "condition": "good",
        "safetyStatus": "safe",
        "isActive": true,
        "driverName": "",
        "driverPhone": "",
        "createdAt": FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — UPDATE BUS CONDITION
  // ─────────────────────────────────────────
  Future<String?> updateBusCondition({
    required String busId,
    required String condition,
    required String safetyStatus,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "condition": condition,
        "safetyStatus": safetyStatus,
        "updatedAt": FieldValue.serverTimestamp(),
      };
      if (notes != null) data["notes"] = notes;

      await _db.collection("buses").doc(busId).update(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — UPDATE BUS INFO
  // ─────────────────────────────────────────
  Future<String?> updateBus({
    required String busId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data["updatedAt"] = FieldValue.serverTimestamp();
      await _db.collection("buses").doc(busId).update(data);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — DELETE BUS
  // ─────────────────────────────────────────
  Future<String?> deleteBus(String busId) async {
    try {
      await _db.collection("buses").doc(busId).update({
        "isActive": false,
        "deletedAt": FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — GET ALL BOOKINGS
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getAllBookingsAdmin() {
    return _db
        .collection("bookings")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — GET ALL USERS
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getAllUsersAdmin() {
    return _db
        .collection("users")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — GET ALL REVIEWS
  // ─────────────────────────────────────────
  Stream<QuerySnapshot> getAllReviewsAdmin() {
    return _db
        .collection("reviews")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // 🛡️ ADMIN — SAFETY CHECK LOG
  // ─────────────────────────────────────────
  Future<String?> addSafetyCheck({
    required String busId,
    required String checkedBy,
    required Map<String, dynamic> checkItems,
    required String overallStatus,
    String? remarks,
  }) async {
    try {
      await _db.collection("safety_checks").add({
        "busId": busId,
        "checkedBy": checkedBy,
        "checkItems": checkItems,
        "overallStatus": overallStatus,
        "remarks": remarks ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      await _db.collection("buses").doc(busId).update({
        "safetyStatus": overallStatus,
        "lastChecked": FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Stream safety checks for a bus
  Stream<QuerySnapshot> getBusSafetyChecks(String busId) {
    return _db
        .collection("safety_checks")
        .where("busId", isEqualTo: busId)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────
  // 🚨 ERROR HANDLER
  // ─────────────────────────────────────────
  String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-verification-code':
        return 'Invalid OTP. Please enter the correct code.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'session-expired':
        return 'OTP session expired. Please request a new one.';
      case 'account-exists-with-different-credential':
        return 'Account already exists with a different sign-in method.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
