import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import '../patient/dashboard/patient_dashboard.dart';
import '../doctor/dashboard/doctor_dashboard.dart';
import '../admin/admin_dashboard.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 🔥 Safe auth check
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // 🔥 Safe existence check
            if (!snap.hasData || !snap.data!.exists) {
              return const Scaffold(
                body: Center(child: Text("User profile not found")),
              );
            }

            // 🔥 SAFE MAP CONVERSION
            final raw = snap.data!.data();
            final data = (raw is Map<String, dynamic>) ? raw : {};

            // 🔥 SAFE ROLE EXTRACTION
            final role = (data['role'] ?? 'patient').toString();

            if (role == 'doctor') {
              return const DoctorDashboard();
            }

            if (role == 'admin') {
              return const AdminDashboard();
            }

            return const PatientDashboard();
          },
        );
      },
    );
  }
}