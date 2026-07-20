import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'login_screen.dart';
import 'admin_login_screen.dart';
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
        if (!snapshot.hasData || snapshot.data == null) {
          return const PortalSelectionScreen();
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
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            if (!snap.hasData || !snap.data!.exists) {
              // Sign out automatically if the profile is missing
              FirebaseAuth.instance.signOut();
              return const PortalSelectionScreen();
            }

            final data = snap.data!.data() as Map<String, dynamic>;
            final role = data['role'] ?? 'patient';

            if (role == 'admin') {
              return const AdminDashboard();
            } else if (role == 'doctor') {
              // Check approval status
              final isApproved = data['isApproved'] ?? false;
              if (!isApproved) {
                FirebaseAuth.instance.signOut();
                return const PortalSelectionScreen(
                  errorMessage: "Your doctor account is pending admin approval.",
                );
              }
              return const DoctorDashboard();
            }

            return const PatientDashboard();
          },
        );
      },
    );
  }
}

class PortalSelectionScreen extends StatelessWidget {
  final String? errorMessage;
  const PortalSelectionScreen({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      });
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF1565C0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hospital Logo & Title
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.tagline,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      "Select Portal to Log In",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cards for portals
                    _portalCard(
                      context: context,
                      title: "Patient Portal",
                      description: "Book visits, view records, track reminders",
                      icon: Icons.people_alt,
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(role: 'patient'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _portalCard(
                      context: context,
                      title: "Doctor Portal",
                      description: "Manage consults, write prescriptions",
                      icon: Icons.medical_services,
                      color: Colors.blue.shade400,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(role: 'doctor'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _portalCard(
                      context: context,
                      title: "Admin Control",
                      description: "Manage clinic, verify doctors, view statistics",
                      icon: Icons.admin_panel_settings,
                      color: Colors.grey.shade800,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _portalCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}