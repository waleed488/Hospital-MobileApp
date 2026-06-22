import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/medical_record_model.dart';
import '../../../models/user_model.dart';
import '../../patient/records/medical_records_screen.dart';
import '../../patient/records/prescriptions_screen.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
}

class _PatientRecordsScreenState extends State<PatientRecordsScreen> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Patient Records & History")),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search patient by name...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchController.clear();
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {
                  searchQuery = v.trim().toLowerCase();
                });
              },
            ),
          ),

          // Patients List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'patient')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Patients Registered"));
                }

                final patients = snapshot.data!.docs
                    .map((doc) {
                      return UserModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                    })
                    .where((patient) {
                      return patient.name.toLowerCase().contains(searchQuery);
                    })
                    .toList();

                if (patients.isEmpty) {
                  return const Center(
                    child: Text("No Matching Patients Found"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          patient.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(patient.email),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientHistoryDetailScreen(patient: patient),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Detailed History, Prescription and Note Writing Screen for a selected patient
class PatientHistoryDetailScreen extends StatefulWidget {
  final UserModel patient;
  const PatientHistoryDetailScreen({super.key, required this.patient});

  @override
  State<PatientHistoryDetailScreen> createState() =>
      _PatientHistoryDetailScreenState();
}

class _PatientHistoryDetailScreenState
    extends State<PatientHistoryDetailScreen> {
  final doctorId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String doctorName = 'Dr. Doctor';

  @override
  void initState() {
    super.initState();
    _loadDoctorName();
  }

  Future<void> _loadDoctorName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(doctorId)
        .get();
    if (doc.exists) {
      setState(() {
        doctorName = doc.data()?['name'] ?? 'Dr. Doctor';
      });
    }
  }

  // Dialog to Add a Medical Record Note
  void _showAddRecordDialog() {
    final diagnosisController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Notes for ${widget.patient.name}"),
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
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Clinical Notes"),
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
              final notes = notesController.text.trim();

              if (diag.isEmpty || notes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all fields")),
                );
                return;
              }

              try {
                final record = MedicalRecordModel(
                  id: '',
                  patientId: widget.patient.uid,
                  patientName: widget.patient.name,
                  doctorId: doctorId,
                  doctorName: doctorName,
                  diagnosis: diag,
                  notes: notes,
                  date: DateTime.now().toString().split(' ')[0],
                );

                await FirebaseFirestore.instance
                    .collection('medical_records')
                    .add(record.toMap());
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Record added successfully")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Dialog to Add a Prescription
  void _showAddPrescriptionDialog() {
    final medicineController = TextEditingController();
    final dosageController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Prescription for ${widget.patient.name}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medicineController,
                decoration: const InputDecoration(labelText: "Medicine Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: "Dosage (e.g. 1-0-1)",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: "Duration (e.g. 7 Days)",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Notes / Instructions",
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
          ElevatedButton(onPressed: () async {}, child: const Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.patient.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.folder_shared), text: "Medical Records"),
              Tab(icon: Icon(Icons.medication), text: "Prescriptions"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Medical records tab
            Stack(
              children: [
                MedicalRecordsScreen(patientId: widget.patient.uid),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: _showAddRecordDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Record"),
                  ),
                ),
              ],
            ),

            // Prescriptions tab
            Stack(
              children: [
                PrescriptionsScreen(patientId: widget.patient.uid),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: _showAddPrescriptionDialog,
                    icon: const Icon(Icons.add_moderator),
                    label: const Text("Write Rx"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
