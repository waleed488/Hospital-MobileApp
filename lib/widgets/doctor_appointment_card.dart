import 'package:flutter/material.dart';

import '../models/appointment_model.dart';

class DoctorAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onStartConsultation;
  final VoidCallback? onComplete;

  const DoctorAppointmentCard({
    super.key,
    required this.appointment,
    this.onApprove,
    this.onReject,
    this.onStartConsultation,
    this.onComplete,
  });

  Color statusColor() {
    switch (appointment.status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'in_consultation':
        return Colors.purple;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = appointment.status.toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appointment.patientName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "Status: ${appointment.status}",
              style: TextStyle(color: statusColor()),
            ),

            Text("Date: ${appointment.date}"),
            Text("Time: ${appointment.time}"),

            const SizedBox(height: 10),

            if (status == 'pending')
              Row(
                children: [
                  ElevatedButton(
                    onPressed: onApprove,
                    child: const Text("Approve"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onReject,
                    child: const Text("Reject"),
                  ),
                ],
              ),

            if (status == 'approved')
              ElevatedButton(
                onPressed: onStartConsultation,
                child: const Text("Start Consultation"),
              ),

            if (status == 'in_consultation')
              ElevatedButton(
                onPressed: onComplete,
                child: const Text("Complete"),
              ),
          ],
        ),
      ),
    );
  }
}
