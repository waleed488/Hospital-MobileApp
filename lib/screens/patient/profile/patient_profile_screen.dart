import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final ImagePicker _picker = ImagePicker();

  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String dob = '';
  String bloodGroup = '';
  String gender = 'Male';
  String emergencyContact = '';
  String allergies = '';
  String chronicDiseases = '';
  String bio = ''; // Used for General Medical Information
  String? profileImage;
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 400,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final Uint8List imageBytes = await image.readAsBytes();
      final String fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final downloadUrl = await _firestoreService.uploadProfileImage(
        uid,
        imageBytes,
        fileName,
      );

      setState(() {
        profileImage = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
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

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);
    final dobController = TextEditingController(text: dob);
    final emergencyController = TextEditingController(text: emergencyContact);
    final allergiesController = TextEditingController(text: allergies);
    final chronicController = TextEditingController(text: chronicDiseases);
    final bioController = TextEditingController(text: bio);

    String localGender =
        ['male', 'female', 'other'].contains(gender.toLowerCase())
        ? gender.toLowerCase()
        : 'male';
    String localBloodGroup = bloodGroup.isNotEmpty ? bloodGroup : 'O+';

    final List<String> bloodGroups = [
      'A+',
      'A-',
      'B+',
      'B-',
      'AB+',
      'AB-',
      'O+',
      'O-',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Update Personal Info",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Name is required";
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                          return "Letters and spaces only";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Phone number is required";
                        }
                        if (value.trim().length < 8) {
                          return "Enter a valid phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Address is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dobController,
                      decoration: const InputDecoration(
                        labelText: "Date of Birth",
                        prefixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 25),
                          ),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            dobController.text = picked.toString().split(
                              ' ',
                            )[0];
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Date of birth is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: localGender,
                      decoration: const InputDecoration(labelText: "Gender"),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text("Male")),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text("Female"),
                        ),
                        DropdownMenuItem(value: 'other', child: Text("Other")),
                      ],
                      onChanged: (v) => setDialogState(() => localGender = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: localBloodGroup,
                      decoration: const InputDecoration(
                        labelText: "Blood Group",
                      ),
                      items: bloodGroups.map((bg) {
                        return DropdownMenuItem(value: bg, child: Text(bg));
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => localBloodGroup = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emergencyController,
                      decoration: const InputDecoration(
                        labelText: "Emergency Contact",
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Emergency contact is required";
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                          return "Emergency contact must contain only numeric digits";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: allergiesController,
                      decoration: const InputDecoration(
                        labelText: "Allergies (if any)",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: chronicController,
                      decoration: const InputDecoration(
                        labelText: "Chronic Diseases",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Medical Notes / Information",
                        hintText: "Enter surgical history, medications, etc.",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'address': addressController.text.trim(),
                          'dateOfBirth': dobController.text.trim(),
                          'gender': localGender,
                          'bloodGroup': localBloodGroup,
                          'emergencyContact': emergencyController.text.trim(),
                          'allergies': allergiesController.text.trim(),
                          'chronicDiseases': chronicController.text.trim(),
                          'bio': bioController.text.trim(),
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
                      SnackBar(
                        content: Text("Update failed: $e"),
                        backgroundColor: AppColors.error,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, size: 28),
            tooltip: "Edit profile details",
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            name = data['name'] ?? 'Patient';
            email = data['email'] ?? '';
            phone = data['phone'] ?? '';
            address = data['address'] ?? '';
            dob = data['dateOfBirth'] ?? '';
            bloodGroup = data['bloodGroup'] ?? 'O+';
            gender = data['gender'] ?? 'Male';
            emergencyContact = data['emergencyContact'] ?? '';
            allergies = data['allergies'] ?? 'None';
            chronicDiseases = data['chronicDiseases'] ?? 'None';
            bio = data['bio'] ?? '';
            profileImage = data['profileImage'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // Profile Photo & Name Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 54,
                            backgroundColor: AppColors.primary.withOpacity(
                              0.12,
                            ),
                            backgroundImage:
                                profileImage != null && profileImage!.isNotEmpty
                                ? (profileImage!.startsWith('data:image/')
                                    ? MemoryImage(base64Decode(profileImage!.split('base64,').last))
                                    : NetworkImage(profileImage!)) as ImageProvider
                                : null,
                            child: profileImage == null || profileImage!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 54,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingImage
                                  ? null
                                  : _showImageSourceActionSheet,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: Icon(
                                  profileImage == null || profileImage!.isEmpty
                                      ? Icons.add_a_photo
                                      : Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Medical / Clinical Details Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Clinical & Medical Profile",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        Icons.bloodtype,
                        "Blood Type",
                        bloodGroup,
                        Colors.red,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.medical_services,
                        "Allergies",
                        allergies,
                        Colors.orange,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.health_and_safety,
                        "Chronic Diseases",
                        chronicDiseases,
                        Colors.deepPurple,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.assignment,
                        "Medical Record Info",
                        bio.isNotEmpty ? bio : "Not entered yet",
                        Colors.teal,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Contact Details Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "Contact & Demographics",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoTile(
                        Icons.phone,
                        "Phone Number",
                        phone.isNotEmpty ? phone : "Not set",
                        AppColors.primary,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.contact_emergency,
                        "Emergency Phone",
                        emergencyContact.isNotEmpty
                            ? emergencyContact
                            : "Not set",
                        Colors.pink,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.wc,
                        "Gender",
                        gender[0].toUpperCase() +
                            gender.substring(1).toLowerCase(),
                        Colors.blue,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.cake,
                        "Date of Birth",
                        dob.isNotEmpty ? dob : "Not set",
                        Colors.indigo,
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        Icons.home,
                        "Home Address",
                        address.isNotEmpty ? address : "Not set",
                        Colors.blueGrey,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Theme Mode Option
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListenableBuilder(
                    listenable: themeController,
                    builder: (context, child) {
                      return SwitchListTile(
                        secondary: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.secondary.withOpacity(0.1),
                          child: const Icon(
                            Icons.dark_mode,
                            color: AppColors.secondary,
                            size: 18,
                          ),
                        ),
                        title: const Text(
                          "Dark Mode",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: themeController.isDarkMode,
                        onChanged: (bool val) {
                          themeController.toggleTheme(val);
                        },
                      );
                    },
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
                    label: const Text(
                      "Log Out from Account",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            "Confirm Logout",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            "Are you sure you want to log out of your patient profile?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Logout"),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/landing',
                            (_) => false,
                          );
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

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
