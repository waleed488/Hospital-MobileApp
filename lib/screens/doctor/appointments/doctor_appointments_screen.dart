// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// import '../../../models/appointment_model.dart';
// import '../../../services/firestore_service.dart';
// import '../../../widgets/doctor_appointment_card.dart';

// class DoctorAppointmentsScreen extends StatefulWidget {
//   const DoctorAppointmentsScreen({super.key});

//   @override
//   State<DoctorAppointmentsScreen> createState() =>
//       _DoctorAppointmentsScreenState();
// }

// class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
//   final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';

//   Future<void> updateStatus(String docId, String status) async {
//     try {
//       await FirestoreService().updateAppointmentStatus(docId, status);

//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Marked as $status")));
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Failed: $e")));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Assigned Appointments")),
//       body: StreamBuilder<List<AppointmentModel>>(
//         stream: FirestoreService().getDoctorAppointments(doctorId),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final appointments = snapshot.data!;

//           if (appointments.isEmpty) {
//             return const Center(child: Text("No Assigned Appointments Found"));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: appointments.length,
//             itemBuilder: (context, index) {
//               final app = appointments[index];

//               return DoctorAppointmentCard(
//                 appointment: app,
//                 onApprove: () => updateStatus(app.id, 'approved'),
//                 onReject: () => updateStatus(app.id, 'rejected'),
//                 onComplete: () => updateStatus(app.id, 'completed'),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

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

  final service = FirestoreService();

  Future<void> update(String id, String status) async {
    await service.updateAppointmentStatus(id, status);
  }

  Future<void> startConsultation(String id) async {
    await service.startConsultation(id);
  }

  void _showCompleteConsultationDialog(AppointmentModel app) {
    final diagnosisController = TextEditingController();
    final symptomsController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Complete Consultation - ${app.patientName}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diagnosisController,
                decoration: const InputDecoration(labelText: "Diagnosis"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: symptomsController,
                decoration: const InputDecoration(labelText: "Symptoms"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Clinical Notes / Suggestions",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final diag = diagnosisController.text.trim();
              final symptoms = symptomsController.text.trim();
              final notes = notesController.text.trim();

              if (diag.isEmpty || symptoms.isEmpty || notes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              try {
                await service.completeConsultation(
                  appointmentId: app.id,
                  diagnosis: diag,
                  symptoms: symptoms,
                  notes: notes,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Consultation completed and medical record generated",
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Complete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appointments")),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: service.getDoctorAppointments(doctorId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;

          if (list.isEmpty) {
            return const Center(child: Text("No Appointments"));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final app = list[i];

              return DoctorAppointmentCard(
                appointment: app,
                onApprove: () => update(app.id, 'approved'),
                onReject: () => update(app.id, 'rejected'),
                onStartConsultation: () => startConsultation(app.id),
                onComplete: () => _showCompleteConsultationDialog(app),
              );
            },
          );
        },
      ),
    );
  }
}
