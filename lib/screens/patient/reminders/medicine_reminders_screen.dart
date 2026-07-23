import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/medicine_reminder_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';

class MedicineRemindersScreen extends StatefulWidget {
  const MedicineRemindersScreen({super.key});

  @override
  State<MedicineRemindersScreen> createState() => _MedicineRemindersScreenState();
}

class _MedicineRemindersScreenState extends State<MedicineRemindersScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddReminderDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    String frequency = 'Daily';
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("New Medicine Reminder"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Medicine Name",
                      prefixIcon: Icon(Icons.medication),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Please enter medicine name"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: dosageController,
                    decoration: const InputDecoration(
                      labelText: "Dosage (e.g. 1 Tablet, 5ml)",
                      prefixIcon: Icon(Icons.scale),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Please enter dosage"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() => selectedTime = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime == null
                                ? "Select Time"
                                : selectedTime!.format(context),
                            style: TextStyle(
                              color: selectedTime == null
                                  ? Colors.grey.shade600
                                  : Colors.black,
                            ),
                          ),
                          const Icon(Icons.access_time, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(
                      labelText: "Frequency",
                      prefixIcon: Icon(Icons.loop),
                    ),
                    items: const [
                      DropdownMenuItem(value: "Daily", child: Text("Daily")),
                      DropdownMenuItem(value: "Twice Daily", child: Text("Twice Daily")),
                      DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => frequency = v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a time")),
                  );
                  return;
                }

                final timeStr = selectedTime!.format(context);

                final reminder = MedicineReminderModel(
                  id: '',
                  patientId: uid,
                  name: nameController.text.trim(),
                  dosage: dosageController.text.trim(),
                  time: timeStr,
                  frequency: frequency,
                  isTaken: false,
                  lastTakenDate: '',
                  createdAt: DateTime.now(),
                );

                try {
                  await _firestoreService.addMedicineReminder(reminder);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Reminder Added Successfully"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add reminder: $e")),
                    );
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicine Reminders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            onPressed: _showAddReminderDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<MedicineReminderModel>>(
        stream: _firestoreService.getPatientMedicineReminders(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return EmptyState(
              title: "No Reminders Set",
              message: "Stay on top of your health by scheduling your daily medicine intakes.",
              icon: Icons.medication,
              actionLabel: "Add Reminder",
              onActionPressed: _showAddReminderDialog,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final rem = list[index];
              // Reset checkbox state locally/dynamically if it is a new day
              final isTakenToday = rem.isTaken && rem.lastTakenDate == todayStr;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.04),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isTakenToday
                              ? AppColors.success.withOpacity(0.12)
                              : AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medication,
                          color: isTakenToday ? AppColors.success : AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rem.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isTakenToday
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isTakenToday
                                    ? Colors.grey.shade500
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${rem.dosage} • ${rem.frequency}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  rem.time,
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Checkbox(
                            value: isTakenToday,
                            activeColor: AppColors.success,
                            onChanged: (val) async {
                              if (val != null) {
                                try {
                                  await _firestoreService.markMedicineReminderAsTaken(
                                    rem.id,
                                    todayStr,
                                    val,
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Failed: $e")),
                                  );
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("Delete Reminder"),
                                  content: Text("Are you sure you want to delete '${rem.name}'?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await _firestoreService.deleteMedicineReminder(rem.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Reminder Deleted")),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Failed to delete: $e")),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
