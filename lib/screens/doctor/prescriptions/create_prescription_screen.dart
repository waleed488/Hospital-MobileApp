import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../models/prescription_model.dart';
import '../../../services/firestore_service.dart';

class CreatePrescriptionScreen extends StatefulWidget {
  const CreatePrescriptionScreen({super.key});

  @override
  State<CreatePrescriptionScreen> createState() =>
      _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final medicineController = TextEditingController();
  final dosageController = TextEditingController();
  final durationController = TextEditingController();
  final notesController = TextEditingController();

  final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String doctorName = '';

  AppointmentModel? selectedAppointment;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    final service = FirestoreService();
    final doctors = await service.getDoctors().first;

    try {
      final doctor = doctors.firstWhere((d) => d.uid == doctorId);
      setState(() {
        doctorName = doctor.name;
      });
    } catch (_) {}
  }

  Future<void> savePrescription() async {
    if (selectedAppointment == null ||
        medicineController.text.trim().isEmpty ||
        dosageController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final prescription = PrescriptionModel(
      id: '',
      // appointmentId: selectedAppointment!.id,
      patientId: selectedAppointment!.patientId,
      patientName: selectedAppointment!.patientName,
      doctorId: doctorId,
      doctorName: doctorName,
      medicine: medicineController.text.trim(),
      dosage: dosageController.text.trim(),
      duration: durationController.text.trim(),
      notes: notesController.text.trim(),
      date: DateTime.now().toString().split(' ')[0],
    );

    try {
      await FirestoreService().addPrescription(prescription);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Prescription created")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Create Prescription")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 ONLY COMPLETED APPOINTMENTS
            StreamBuilder<List<AppointmentModel>>(
              stream: FirestoreService().getDoctorAppointments(doctorId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final completed = snapshot.data!
                    .where((a) => a.status == 'completed')
                    .toList();

                return DropdownButton<AppointmentModel>(
                  value: selectedAppointment,
                  hint: const Text("Select Completed Appointment"),
                  isExpanded: true,
                  items: completed.map((a) {
                    return DropdownMenuItem(
                      value: a,
                      child: Text("${a.patientName} - ${a.date}"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAppointment = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: medicineController,
              decoration: const InputDecoration(
                labelText: "Medicine",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: "Dosage",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                labelText: "Duration",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: savePrescription,
                child: const Text("Create Prescription"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
