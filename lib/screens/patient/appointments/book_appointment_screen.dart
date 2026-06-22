import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../services/firestore_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? selectedDepartment;
  String? selectedDoctorId;
  String? selectedDoctorName;
  String? selectedTime;
  DateTime? selectedDate;

  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String patientName = '';

  final List<String> timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadPatientName();
  }

  Future<void> _loadPatientName() async {
    if (uid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        patientName = doc.data()?['name'] ?? 'Patient';
      }
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> bookAppointment() async {
    if (selectedDepartment == null ||
        selectedDoctorId == null ||
        selectedTime == null ||
        selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final dateStr = selectedDate!.toString().split(" ")[0];

    try {
      final newApp = AppointmentModel(
        id: '',
        patientId: uid,
        patientName: patientName.isNotEmpty ? patientName : 'Patient',
        doctorId: selectedDoctorId!,
        doctorName: selectedDoctorName ?? 'Doctor',
        department: selectedDepartment!,
        date: dateStr,
        time: selectedTime!,
        status: 'pending',
      );

      await FirestoreService().bookAppointment(newApp);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment Booked Successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Booking failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Book Appointment")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule a Visit",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Department
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('departments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final depts = snapshot.data!.docs.map((doc) => doc.id).toList();

                if (depts.isEmpty) {
                  depts.addAll([
                    'Cardiology',
                    'Neurology',
                    'Orthopedics',
                    'Dermatology',
                    'Pediatrics',
                  ]);
                }

                return _buildDropdown(
                  label: "Department",
                  value: selectedDepartment,
                  items: depts,
                  onChanged: (v) {
                    setState(() {
                      selectedDepartment = v;
                      selectedDoctorId = null;
                      selectedDoctorName = null;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // Doctor
            selectedDepartment == null
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'doctor')
                        .where('department', isEqualTo: selectedDepartment)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDoctorId,
                            hint: const Text("Select Doctor"),
                            isExpanded: true,
                            items: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Doctor';

                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                final matched = docs.firstWhere(
                                  (d) => d.id == v,
                                );
                                final data =
                                    matched.data() as Map<String, dynamic>;

                                setState(() {
                                  selectedDoctorId = v;
                                  selectedDoctorName = data['name'] ?? 'Doctor';
                                });
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? "Select Date"
                          : selectedDate.toString().split(" ")[0],
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time
            _buildDropdown(
              label: "Time Slot",
              value: selectedTime,
              items: timeSlots,
              onChanged: (v) => setState(() => selectedTime = v),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: bookAppointment,
                child: const Text("Confirm Appointment"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
