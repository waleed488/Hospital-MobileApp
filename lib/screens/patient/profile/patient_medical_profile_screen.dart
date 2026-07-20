import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PatientMedicalProfileScreen extends StatefulWidget {
  const PatientMedicalProfileScreen({super.key});

  @override
  State<PatientMedicalProfileScreen> createState() =>
      _PatientMedicalProfileScreenState();
}

class _PatientMedicalProfileScreenState
    extends State<PatientMedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? selectedBloodGroup;
  String? selectedGender;
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController chronicDiseasesController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> genders = ['Male', 'Female', 'Other'];

  bool isSaving = false;

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    allergiesController.dispose();
    chronicDiseasesController.dispose();
    emergencyContactController.dispose();
    dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _saveMedicalProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'bloodGroup': selectedBloodGroup,
        'gender': selectedGender,
        'height': heightController.text.trim(),
        'weight': weightController.text.trim(),
        'allergies': allergiesController.text.trim(),
        'chronicDiseases': chronicDiseasesController.text.trim(),
        'emergencyContact': emergencyContactController.text.trim(),
        'dateOfBirth': dobController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Medical Profile Saved Successfully"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save profile: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Medical Profile"),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            
            // Populate fields if they haven't been touched yet
            if (heightController.text.isEmpty && data['height'] != null) {
              heightController.text = data['height'];
            }
            if (weightController.text.isEmpty && data['weight'] != null) {
              weightController.text = data['weight'];
            }
            if (allergiesController.text.isEmpty && data['allergies'] != null) {
              allergiesController.text = data['allergies'];
            }
            if (chronicDiseasesController.text.isEmpty && data['chronicDiseases'] != null) {
              chronicDiseasesController.text = data['chronicDiseases'];
            }
            if (emergencyContactController.text.isEmpty && data['emergencyContact'] != null) {
              emergencyContactController.text = data['emergencyContact'];
            }
            if (dobController.text.isEmpty && data['dateOfBirth'] != null) {
              dobController.text = data['dateOfBirth'];
            }
            if (selectedBloodGroup == null && data['bloodGroup'] != null) {
              selectedBloodGroup = data['bloodGroup'];
            }
            if (selectedGender == null && data['gender'] != null) {
              selectedGender = data['gender'];
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Medical Parameters",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please keep your health details up to date for emergency reference.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Blood Group & Gender dropdowns
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedBloodGroup,
                          decoration: _inputDecoration("Blood Group", Icons.bloodtype),
                          items: bloodGroups
                              .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedBloodGroup = val),
                          validator: (val) => val == null ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          decoration: _inputDecoration("Gender", Icons.face),
                          items: genders
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedGender = val),
                          validator: (val) => val == null ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Height & Weight
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: heightController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration("Height (cm)", Icons.height),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Required";
                            if (double.tryParse(val) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: weightController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration("Weight (kg)", Icons.scale),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return "Required";
                            if (double.tryParse(val) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth
                  TextFormField(
                    controller: dobController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: _inputDecoration("Date of Birth", Icons.calendar_today),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Emergency Contact
                  TextFormField(
                    controller: emergencyContactController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration("Emergency Contact Name/Phone", Icons.contact_phone),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  TextFormField(
                    controller: allergiesController,
                    maxLines: 2,
                    decoration: _inputDecoration("Known Allergies (comma separated)", Icons.warning_amber),
                  ),
                  const SizedBox(height: 16),

                  // Chronic Diseases
                  TextFormField(
                    controller: chronicDiseasesController,
                    maxLines: 2,
                    decoration: _inputDecoration("Chronic Diseases / Conditions", Icons.healing),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isSaving ? null : _saveMedicalProfile,
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Profile",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
