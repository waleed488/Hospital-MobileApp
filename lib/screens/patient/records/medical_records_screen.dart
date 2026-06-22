import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/medical_record_model.dart';
import '../../../widgets/medical_record_card.dart';

class MedicalRecordsScreen extends StatelessWidget {
  final String? patientId;
  const MedicalRecordsScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetPatientId = patientId ?? currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Records"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('medical_records')
            .where('patientId', isEqualTo: targetPatientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Medical Records Found"),
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
      ),
    );
  }
}