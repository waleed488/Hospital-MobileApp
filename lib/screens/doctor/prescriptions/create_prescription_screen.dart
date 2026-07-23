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

  String? selectedAppointmentId;

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    try {
      final service = FirestoreService();
      final doctors = await service.getDoctors().first;

      final doctor = doctors.firstWhere(
        (d) => d.uid == doctorId,
        orElse: () => throw Exception("Doctor not found"),
      );

      setState(() {
        doctorName = doctor.name;
      });
    } catch (e) {
      debugPrint("Doctor load error: $e");
    }
  }

  Future<void> savePrescription(List<AppointmentModel> appointments) async {
    if (selectedAppointmentId == null ||
        medicineController.text.trim().isEmpty ||
        dosageController.text.trim().isEmpty ||
        durationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    try {
      final appointment = appointments.firstWhere(
        (a) => a.id == selectedAppointmentId,
        orElse: () => throw Exception("Appointment not found"),
      );

      final prescription = PrescriptionModel(
        id: '',
        appointmentId: appointment.id,
        patientId: appointment.patientId,
        patientName: appointment.patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        medicine: medicineController.text.trim(),
        dosage: dosageController.text.trim(),
        duration: durationController.text.trim(),
        notes: notesController.text.trim(),
        date: DateTime.now().toString().split(' ')[0],
      );

      await FirestoreService().addPrescription(prescription);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription created successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  void dispose() {
    medicineController.dispose();
    dosageController.dispose();
    durationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Prescription")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<AppointmentModel>>(
          stream: FirestoreService().getDoctorAppointments(doctorId),
          builder: (context, snapshot) {
            final appointments = snapshot.data ?? [];

            final completedAppointments = appointments
                .where((a) => a.status.toLowerCase() == 'completed')
                .toList();

            return Column(
              children: [
                // ================= DROPDOWN =================
                DropdownButton<String>(
                  value: selectedAppointmentId,
                  hint: const Text("Select Completed Appointment"),
                  isExpanded: true,
                  items: completedAppointments.map((a) {
                    return DropdownMenuItem<String>(
                      value: a.id,
                      child: Text("${a.patientName} - ${a.date}"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAppointmentId = value;
                    });
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
                    onPressed: () {
                      savePrescription(appointments);
                    },
                    child: const Text("Create Prescription"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
