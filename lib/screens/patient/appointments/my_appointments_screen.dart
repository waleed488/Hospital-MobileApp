// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../../models/appointment_model.dart';
// import '../../../widgets/appointment_card.dart';

// class MyAppointmentsScreen extends StatelessWidget {
//   const MyAppointmentsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final patientId = FirebaseAuth.instance.currentUser?.uid ?? '';

//     return Scaffold(
//       appBar: AppBar(title: const Text("My Appointments")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection('appointments')
//             .where('patientId', isEqualTo: patientId)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No Appointments Found"));
//           }

//           final appointments = snapshot.data!.docs.map((doc) {
//             return AppointmentModel.fromMap(
//               doc.data() as Map<String, dynamic>,
//               doc.id,
//             );
//           }).toList();

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: appointments.length,
//             itemBuilder: (_, i) => AppointmentCard(appointment: appointments[i]),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'book_appointment_screen.dart';
import '../../../models/appointment_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/appointment_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_loader.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patientId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("My Appointments")),
      body: StreamBuilder<List<AppointmentModel>>(
        stream: FirestoreService().getPatientAppointments(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4);
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return EmptyState(
              title: "No Appointments Scheduled",
              message: "It looks like you don't have any appointments lined up. Easily schedule one today!",
              icon: Icons.event_busy,
              actionLabel: "Book Appointment",
              onActionPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookAppointmentScreen()),
                );
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => AppointmentCard(appointment: list[i]),
          );
        },
      ),
    );
  }
}
