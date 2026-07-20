import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/constants/app_colors.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ImagePicker _picker = ImagePicker();

  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String qualification = '';
  String department = '';
  String specialization = '';
  String experience = '';
  String consultationFee = '50';
  String availabilityStatus = 'Available Today';
  String bio = '';
  String? profileImage;
  bool isApproved = false;
  bool isVerified = false;
  bool isFeatured = false;
  String verificationStatus = 'unverified';
  List<String> availableSlots = [];

  String? medicalLicenseUrl;
  String? degreeUrl;
  String? certificateUrl;

  bool _isLoading = false;
  bool _isUploadingDoc = false;

  Future<void> _pickAndUploadProfilePic() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 400,
      );

      if (image == null) return;

      setState(() => _isLoading = true);
      final downloadUrl = await _firestoreService.uploadProfileImage(
        uid,
        File(image.path),
      );

      setState(() {
        profileImage = downloadUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to upload: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadDocument(String docType) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file == null) return;

      setState(() => _isUploadingDoc = true);

      final downloadUrl = await _firestoreService.uploadDoctorDocument(
        uid: uid,
        docType: docType,
        file: File(file.path),
      );

      setState(() {
        if (docType == 'license') medicalLicenseUrl = downloadUrl;
        else if (docType == 'degree') degreeUrl = downloadUrl;
        else if (docType == 'certificate') certificateUrl = downloadUrl;
        verificationStatus = 'pending';
        _isUploadingDoc = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${docType[0].toUpperCase() + docType.substring(1)} uploaded. Waiting for verification."),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingDoc = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);
    final feeController = TextEditingController(text: consultationFee);
    final bioController = TextEditingController(text: bio);
    String dialogAvailability = availabilityStatus;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Edit Practice Details"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone Number"),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Phone required";
                      if (value.trim().length < 8) return "Invalid phone length";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Clinic Address"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Address required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: feeController,
                    decoration: const InputDecoration(labelText: "Consultation Fee (\$)"),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Fee required";
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
                        return "Enter a valid positive fee";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Biography"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Biography bio required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dialogAvailability,
                    decoration: const InputDecoration(labelText: "Availability Status"),
                    items: const [
                      DropdownMenuItem(value: "Available Today", child: Text("Available Today")),
                      DropdownMenuItem(value: "Busy", child: Text("Busy")),
                      DropdownMenuItem(value: "On Leave", child: Text("On Leave")),
                    ],
                    onChanged: (v) => setDialogState(() => dialogAvailability = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                      'consultationFee': feeController.text.trim(),
                      'bio': bioController.text.trim(),
                      'availabilityStatus': dialogAvailability,
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile details updated successfully"),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Update failed: $e"), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSlotDialog() {
    final slotController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Availability Slot"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: slotController,
            decoration: const InputDecoration(
              hintText: "e.g. 04:00 PM, 05:30 PM",
              labelText: "Time Slot",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return "Time slot required";
              if (!RegExp(r'^(0[1-9]|1[0-2]):[0-5][0-9]\s(AM|PM)$').hasMatch(value.toUpperCase().trim())) {
                return "Use format: HH:MM AM/PM";
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newSlot = slotController.text.toUpperCase().trim();
                if (availableSlots.contains(newSlot)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Slot already exists")),
                  );
                  return;
                }

                final updatedSlots = List<String>.from(availableSlots)..add(newSlot);
                // Sort slots chronologically simple string match sort
                updatedSlots.sort();

                try {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'availableSlots': updatedSlots,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed: $e")),
                  );
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSlot(String slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Slot"),
        content: Text("Are you sure you want to remove the slot '$slot'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedSlots = List<String>.from(availableSlots)..remove(slot);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'availableSlots': updatedSlots,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Doctor Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, size: 28),
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? 'Doctor';
            email = data['email'] ?? '';
            department = data['department'] ?? 'General Medicine';
            specialization = data['specialization'] ?? 'General Practitioner';
            qualification = data['qualification'] ?? 'MBBS, Clinical MD';
            experience = data['experience'] ?? '5 Years';
            consultationFee = data['consultationFee'] ?? '50';
            availabilityStatus = data['availabilityStatus'] ?? 'Available Today';
            bio = data['bio'] ?? '';
            profileImage = data['profileImage'];

            isApproved = data['isApproved'] ?? false;
            isVerified = data['isVerified'] ?? false;
            isFeatured = data['isFeatured'] ?? false;
            verificationStatus = data['verificationStatus'] ?? 'unverified';

            availableSlots = data['availableSlots'] != null
                ? List<String>.from(data['availableSlots'])
                : [];

            medicalLicenseUrl = data['medicalLicenseUrl'];
            degreeUrl = data['degreeUrl'];
            certificateUrl = data['certificateUrl'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Main Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            backgroundImage: profileImage != null && profileImage!.isNotEmpty
                                ? NetworkImage(profileImage!)
                                : null,
                            child: profileImage == null || profileImage!.isEmpty
                                ? const Icon(Icons.person, size: 54, color: AppColors.primary)
                                : null,
                          ),
                          if (_isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadProfilePic,
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.photo_camera, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.verified, size: 20),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$specialization • $department",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Availability Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (availabilityStatus == 'Available Today'
                                  ? Colors.green
                                  : (availabilityStatus == 'Busy' ? Colors.orange : Colors.red))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          availabilityStatus,
                          style: TextStyle(
                            color: availabilityStatus == 'Available Today'
                                ? Colors.green.shade800
                                : (availabilityStatus == 'Busy' ? Colors.orange.shade800 : Colors.red.shade800),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Credentials Verification Card
                const Text(
                  "Verification Credentials",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Verification Status:",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isVerified
                                      ? Colors.green
                                      : (verificationStatus == 'pending' ? Colors.blue : Colors.red))
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isVerified
                                  ? "VERIFIED BADGE"
                                  : (verificationStatus == 'pending' ? "PENDING REVIEW" : "UNVERIFIED"),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isVerified
                                    ? Colors.green.shade800
                                    : (verificationStatus == 'pending' ? Colors.blue.shade800 : Colors.red.shade800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDocUploadRow("Medical Practice License", medicalLicenseUrl, 'license'),
                      const SizedBox(height: 12),
                      _buildDocUploadRow("Degree / Specialization Board", degreeUrl, 'degree'),
                      const SizedBox(height: 12),
                      _buildDocUploadRow("Other Medical Certificates", certificateUrl, 'certificate'),
                      if (_isUploadingDoc) ...[
                        const SizedBox(height: 12),
                        const Center(child: LinearProgressIndicator()),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Available Time Slots Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "My Consultation Time Slots",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 26),
                      onPressed: _showAddSlotDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                    ],
                  ),
                  child: availableSlots.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              "No active slots. Click + to add custom consultation hours.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: availableSlots.map((slot) {
                            return Chip(
                              label: Text(slot),
                              onDeleted: () => _removeSlot(slot),
                              deleteIconColor: Colors.red.shade600,
                              backgroundColor: AppColors.background,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 20),

                // Clinical & Practice Info List
                const Text(
                  "Clinical & Bio Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(Icons.school, "Qualifications", qualification),
                      const Divider(height: 1),
                      _buildInfoTile(Icons.business, "Registered Department", department),
                      const Divider(height: 1),
                      _buildInfoTile(Icons.work, "Years of Experience", experience),
                      const Divider(height: 1),
                      _buildInfoTile(Icons.attach_money, "Consultation Fee", "\$$consultationFee"),
                      const Divider(height: 1),
                      _buildInfoTile(Icons.home, "Clinic Address", address.isNotEmpty ? address : "Not configured"),
                      const Divider(height: 1),
                      _buildInfoTile(Icons.info, "Biography", bio.isNotEmpty ? bio : "Write a biography..."),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Log out Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout from Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirm Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text("Are you sure you want to log out of your doctor portal?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/landing', (_) => false);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocUploadRow(String label, String? url, String docType) {
    final bool hasDoc = url != null && url.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 3),
              Text(
                hasDoc ? "Credentials Uploaded" : "No document selected",
                style: TextStyle(color: hasDoc ? Colors.green : Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
        if (hasDoc) ...[
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
        ],
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: hasDoc ? AppColors.background : AppColors.primary,
            foregroundColor: hasDoc ? AppColors.textPrimary : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: Icon(hasDoc ? Icons.replay : Icons.upload_file, size: 14),
          label: Text(hasDoc ? "Re-upload" : "Upload", style: const TextStyle(fontSize: 12)),
          onPressed: () => _pickAndUploadDocument(docType),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}