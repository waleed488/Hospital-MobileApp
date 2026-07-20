import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  // ================= LOGIN =================

  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Login failed");
    }
  }

  // ================= REGISTER =================

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? department,
    String? specialization,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user!.updateDisplayName(name);

      final user = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email.trim(),
        role: role,
        department: department,
        specialization: specialization,
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      // Firebase automatically logs in a newly created user.
      // Sign doctors out so they must wait for admin approval and log in.
      // Keep patients logged in so they immediately access the dashboard.
      if (role == 'doctor') {
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Registration failed");
    }
  }

  // ================= USER DATA =================

  Future<UserModel?> getUserData([String? uid]) async {
    final targetUid = uid ?? currentUid;

    if (targetUid == null) return null;

    final doc = await _firestore.collection('users').doc(targetUid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<String> getUserRole() async {
    if (currentUid == null) return "patient";

    final doc = await _firestore.collection('users').doc(currentUid).get();

    return doc.data()?['role'] ?? "patient";
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    if (currentUid == null) return;

    await _firestore.collection('users').doc(currentUid).update({
      'name': name,
      'phone': phone,
    });

    await currentUser?.updateDisplayName(name);
  }

  // ================= PASSWORD RESET =================

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ================= LOGOUT =================

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
