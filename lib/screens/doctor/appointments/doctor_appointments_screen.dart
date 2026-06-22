import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/appointment_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/doctor_appointment_card.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> updateStatus(String docId, String status) async {
    try {
      await FirestoreService().updateAppointmentStatus(docId, status);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Marked as $status")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assigned Appointments")),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: FirestoreService().getDoctorAppointments(doctorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appointments = snapshot.data!;

          if (appointments.isEmpty) {
            return const Center(child: Text("No Assigned Appointments Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final app = appointments[index];

              return DoctorAppointmentCard(
                appointment: app,
                onApprove: () => updateStatus(app.id, 'approved'),
                onReject: () => updateStatus(app.id, 'rejected'),
                onComplete: () => updateStatus(app.id, 'completed'),
              );
            },
          );
        },
      ),
    );
  }
}
