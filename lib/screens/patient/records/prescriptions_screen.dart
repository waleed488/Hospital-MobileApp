import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/prescription_model.dart';
import '../../../widgets/prescription_card.dart';

class PrescriptionsScreen extends StatelessWidget {
  final String? patientId;
  const PrescriptionsScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetPatientId = patientId ?? currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescriptions"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prescriptions')
            .where('patientId', isEqualTo: targetPatientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No Prescriptions Found"),
            );
          }

          final prescriptions = snapshot.data!.docs.map((doc) {
            return PrescriptionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              return PrescriptionCard(
                prescription: prescriptions[index],
              );
            },
          );
        },
      ),
    );
  }
}