import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../core/constants/app_colors.dart';
import '../services/firestore_service.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const AppointmentCard({super.key, required this.appointment});

  Color getColor() {
    switch (appointment.status.toLowerCase()) {
      case "approved":
        return AppColors.success;
      case "pending":
        return AppColors.warning;
      case "in_consultation":
        return Colors.purple;
      case "completed":
        return AppColors.primary;
      case "rejected":
        return AppColors.error;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getColor();
    final statusLower = appointment.status.toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment.doctorName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appointment.status.isEmpty
                      ? "Pending"
                      : appointment.status[0].toUpperCase() + appointment.status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.apartment, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Department: ${appointment.department}",
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Date: ${appointment.date}",
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Time: ${appointment.time}",
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Visual Timeline Status Stepper
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          _buildTimeline(appointment.status),

          if (appointment.diagnosis != null && appointment.diagnosis!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Text(
              "Diagnosis: ${appointment.diagnosis}",
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],

          if (statusLower == 'pending' || statusLower == 'approved') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text("Cancel Appointment"),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Cancel Appointment"),
                      content: const Text("Are you sure you want to cancel this appointment?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("No"),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Yes, Cancel"),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await FirestoreService().cancelAppointmentIfAllowed(appointment);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Appointment cancelled successfully")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to cancel: $e")),
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(String currentStatus) {
    final status = currentStatus.toLowerCase();
    
    List<String> steps = ['pending', 'approved', 'completed'];
    if (status == 'in_consultation') {
      steps = ['pending', 'approved', 'in consultation', 'completed'];
    } else if (status == 'cancelled' || status == 'rejected') {
      steps = ['pending', status];
    }

    int currentIndex = steps.indexOf(status);
    if (status == 'in_consultation') {
      currentIndex = 2;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: List.generate(steps.length, (idx) {
          final stepName = steps[idx];
          final stepLabel = stepName[0].toUpperCase() + stepName.substring(1);
          final isCompleted = idx <= currentIndex;
          final isCurrent = idx == currentIndex;
          final isLast = idx == steps.length - 1;

          Color stepColor = Colors.grey.shade300;
          if (isCompleted) {
            stepColor = getColor();
          }

          return Expanded(
            flex: isLast ? 0 : 1,
            child: Row(
              children: [
                // Step Dot + Label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: stepColor,
                      child: isCurrent
                          ? const CircleAvatar(radius: 4, backgroundColor: Colors.white)
                          : (isCompleted
                              ? const Icon(Icons.check, size: 10, color: Colors.white)
                              : null),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.textPrimary : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                // Connector Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? getColor() : Colors.grey.shade300,
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}