// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/user_model.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Stream<User?> get userStream => _auth.authStateChanges();

//   String? get currentUid => _auth.currentUser?.uid;

//   Future<UserCredential> login(String email, String password) async {
//     try {
//       return await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//     } catch (e) {
//       throw Exception("Login failed: $e");
//     }
//   }

//   Future<UserCredential> register({
//     required String name,
//     required String email,
//     required String password,
//     required String role,
//     String? department,
//     String? specialization,
//   }) async {
//     try {
//       final cred = await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );

//       final user = cred.user!;

//       final userModel = UserModel(
//         uid: user.uid,
//         name: name,
//         email: email.trim(),
//         role: role,
//         department: department ?? '',
//         specialization: specialization ?? '',
//       );

//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .set(userModel.toMap());

//       return cred;
//     } catch (e) {
//       throw Exception("Register failed: $e");
//     }
//   }

//   Future<UserModel?> getUserData([String? uid]) async {
//     final id = uid ?? currentUid;
//     if (id == null) return null;

//     final doc = await _firestore.collection('users').doc(id).get();

//     if (!doc.exists) return null;

//     return UserModel.fromMap(doc.data()!, id);
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//   }
// }

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
      throw Exception(e.message);
    }
  }

  // ================= REGISTER =================

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? department,
    String? specialization,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await cred.user!.updateDisplayName(name);

      final userModel = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        role: role,
        department: department,
        specialization: specialization,
      );

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(userModel.toMap());

      return cred;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
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
    final uid = currentUid;

    if (uid == null) return "patient";

    final doc = await _firestore.collection('users').doc(uid).get();

    return doc.data()?['role'] ?? 'patient';
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    if (currentUid == null) return;

    await _firestore.collection('users').doc(currentUid).update({
      'name': name,
      'phone': phone,
    });
  }

  // ================= PASSWORD =================

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ================= LOGOUT =================

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
