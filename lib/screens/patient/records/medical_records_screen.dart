import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/medical_record_model.dart';
import '../../../widgets/medical_record_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../core/constants/app_colors.dart';

class MedicalRecordsScreen extends StatelessWidget {
  final String? patientId;
  const MedicalRecordsScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetPatientId = patientId ?? currentUid;

    Widget buildRecordsList() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medical_records')
            .where('patientId', isEqualTo: targetPatientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 3);
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyState(
              title: "No Medical Records",
              message: "No historical medical records or consultation outcomes are logged in the system yet.",
              icon: Icons.folder_off_outlined,
            );
          }

          final records = snapshot.data!.docs.map((doc) {
            return MedicalRecordModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return MedicalRecordCard(
                record: records[index],
              );
            },
          );
        },
      );
    }

    if (targetPatientId == currentUid) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Medical Records"),
        ),
        body: buildRecordsList(),
      );
    }

    // Secure checking for accessing another user's records
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUid).get(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (roleSnapshot.hasData && roleSnapshot.data!.exists) {
          final data = roleSnapshot.data!.data() as Map<String, dynamic>;
          final role = data['role'] ?? 'patient';

          if (role == 'doctor' || role == 'admin') {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Patient Medical Records"),
              ),
              body: buildRecordsList(),
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Access Denied"),
            backgroundColor: AppColors.error.withOpacity(0.1),
            foregroundColor: AppColors.error,
          ),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                "Access Denied: You are not authorized to view this patient's medical records.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        );
      },
    );
  }
}