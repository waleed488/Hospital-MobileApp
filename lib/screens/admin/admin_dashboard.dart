import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../models/review_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/theme/theme_controller.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Management Portal",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: const Color(0xFF1E293B), // slate color for admin app bar
          foregroundColor: Colors.white,
          actions: [
            ListenableBuilder(
              listenable: themeController,
              builder: (context, child) {
                return IconButton(
                  icon: Icon(
                    themeController.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    themeController.toggleTheme(!themeController.isDarkMode);
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await _showConfirmDialog(
                  "Log Out",
                  "Are you sure you want to log out of the admin panel?",
                );
                if (confirm) {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/landing',
                      (_) => false,
                    );
                  }
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.redAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Stats"),
              Tab(icon: Icon(Icons.medical_services), text: "Doctors"),
              Tab(icon: Icon(Icons.people), text: "Patients"),
              Tab(icon: Icon(Icons.calendar_today), text: "Bookings"),
              Tab(icon: Icon(Icons.rate_review), text: "Reviews"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsTab(),
            _buildDoctorsTab(),
            _buildPatientsTab(),
            _buildAppointmentsTab(),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CONFIRMATION DIALOG HELPER
  // ==========================================================
  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ==========================================================
  // TAB 1: OVERVIEW & STATS
  // ==========================================================
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Stats Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 15),

          // Counts Row 1
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _firestoreService.getUserCount('doctor'),
                  builder: (context, snap) => _statCard(
                    "Total Doctors",
                    (snap.data ?? 0).toString(),
                    Icons.medical_services,
                    Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: StreamBuilder<int>(
                  stream: _firestoreService.getUserCount('patient'),
                  builder: (context, snap) => _statCard(
                    "Total Patients",
                    (snap.data ?? 0).toString(),
                    Icons.people,
                    Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Counts Row 2
          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _firestoreService.getTodaysAppointmentsCount(),
                  builder: (context, snap) => _statCard(
                    "Today's Bookings",
                    (snap.data ?? 0).toString(),
                    Icons.today,
                    Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _firestoreService.getDepartments(),
                  builder: (context, snap) => _statCard(
                    "Departments",
                    (snap.data ?? []).length.toString(),
                    Icons.apartment,
                    Colors.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Quick Management Action Row
          const Text(
            "Quick Controls",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _actionCard(
                  title: "Add Doctor",
                  subtitle: "Register credentials",
                  icon: Icons.person_add,
                  color: Colors.blue,
                  onTap: _showAddDoctorDialog,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _actionCard(
                  title: "Departments",
                  subtitle: "Manage hospital sectors",
                  icon: Icons.apartment,
                  color: Colors.indigo,
                  onTap: _showManageDepartmentsDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TAB 2: DOCTORS DIRECTORY (CRUD & APPROVALS)
  // ==========================================================
  Widget _buildDoctorsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "No doctors registered in the system.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        final doctors = snapshot.data!.docs.map((doc) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            final doc = doctors[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main doctor details row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          backgroundImage: doc.profileImage != null && doc.profileImage!.isNotEmpty
                              ? (doc.profileImage!.startsWith('data:image/')
                                  ? MemoryImage(base64Decode(doc.profileImage!.split('base64,').last))
                                  : NetworkImage(doc.profileImage!)) as ImageProvider
                              : null,
                          child: doc.profileImage == null || doc.profileImage!.isEmpty
                              ? const Icon(Icons.person, size: 32, color: Colors.blue)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${doc.specialization ?? 'General Practitioner'} • ${doc.department ?? 'General Medicine'}",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                doc.email,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Badges showing flags
                    Row(
                      children: [
                        Expanded(child: _statusIndicatorBadge("Approved", doc.isApproved, Colors.green)),
                        const SizedBox(width: 6),
                        Expanded(child: _statusIndicatorBadge("Verified", doc.isVerified, Colors.teal)),
                        const SizedBox(width: 6),
                        Expanded(child: _statusIndicatorBadge("Featured", doc.isFeatured, Colors.amber)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Administrative toggle controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: doc.isApproved ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(doc.isApproved ? Icons.cancel_outlined : Icons.check_circle_outline, size: 16),
                          label: Text(doc.isApproved ? "Disapprove" : "Approve"),
                          onPressed: () async {
                            final action = doc.isApproved ? "disapprove" : "approve";
                            final confirm = await _showConfirmDialog(
                              "Change Doctor Status",
                              "Are you sure you want to $action Dr. ${doc.name}?",
                            );
                            if (confirm) {
                              await _firestoreService.approveDoctor(doc.uid, !doc.isApproved);
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        if (doc.verificationStatus == 'pending' || doc.medicalLicenseUrl != null || doc.degreeUrl != null)
                          IconButton(
                            icon: const Icon(Icons.assignment_turned_in, color: Colors.teal),
                            tooltip: "Verify Credentials",
                            onPressed: () => _showVerifyDocumentsDialog(doc),
                          ),
                        IconButton(
                          icon: Icon(
                            doc.isVerified ? Icons.verified : Icons.verified_user_outlined,
                            color: doc.isVerified ? Colors.teal : Colors.grey,
                          ),
                          tooltip: "Toggle Verified",
                          onPressed: () async {
                            await _firestoreService.verifyDoctor(doc.uid, !doc.isVerified);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            doc.isFeatured ? Icons.star : Icons.star_border,
                            color: doc.isFeatured ? Colors.amber : Colors.grey,
                          ),
                          tooltip: "Toggle Featured",
                          onPressed: () async {
                            await _firestoreService.featureDoctor(doc.uid, !doc.isFeatured);
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: "Edit Profile",
                          onPressed: () => _showEditDoctorDialog(doc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Delete Doctor",
                          onPressed: () async {
                            final confirm = await _showConfirmDialog(
                              "Delete Doctor",
                              "This will permanently delete Dr. ${doc.name} and their record. Proceed?",
                            );
                            if (confirm) {
                              await _firestoreService.deleteUser(doc.uid);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Doctor deleted successfully")),
                                );
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
    );
  }

  Widget _statusIndicatorBadge(String label, bool active, Color activeColor) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: active ? activeColor.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? activeColor.withOpacity(0.4) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: active ? activeColor : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? activeColor : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB 3: PATIENT DIRECTORY (CRUD)
  // ==========================================================
  Widget _buildPatientsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No patients registered in the system.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final patients = snapshot.data!.docs.map((doc) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  backgroundImage: patient.profileImage != null && patient.profileImage!.isNotEmpty
                      ? (patient.profileImage!.startsWith('data:image/')
                          ? MemoryImage(base64Decode(patient.profileImage!.split('base64,').last))
                          : NetworkImage(patient.profileImage!)) as ImageProvider
                      : null,
                  child: patient.profileImage == null || patient.profileImage!.isEmpty
                      ? const Icon(Icons.person, color: Colors.green)
                      : null,
                ),
                title: Text(
                  patient.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Phone: ${patient.phone ?? 'N/A'} • Blood: ${patient.bloodGroup ?? 'N/A'}\nEmail: ${patient.email}",
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: "Edit Profile",
                      onPressed: () => _showEditPatientDialog(patient),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Delete Patient",
                      onPressed: () async {
                        final confirm = await _showConfirmDialog(
                          "Delete Patient",
                          "Are you sure you want to permanently delete patient ${patient.name}?",
                        );
                        if (confirm) {
                          await _firestoreService.deleteUser(patient.uid);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Patient deleted successfully")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // TAB 4: APPOINTMENTS MODERATION
  // ==========================================================
  Widget _buildAppointmentsTab() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _firestoreService.getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const Center(
            child: Text(
              "No appointments registered yet.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final app = bookings[index];

            Color statusColor = Colors.orange;
            switch (app.status.toLowerCase()) {
              case 'approved':
                statusColor = Colors.green;
                break;
              case 'completed':
                statusColor = Colors.blue;
                break;
              case 'cancelled':
              case 'rejected':
                statusColor = Colors.red;
                break;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient name & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            app.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            app.status.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Doctor details
                    Text(
                      "Doctor: ${app.doctorName} (${app.department})",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),

                    // Date / Time
                    Text(
                      "Schedule: ${app.date} @ ${app.time}",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const Divider(height: 20),

                    // Status Change Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DropdownButton<String>(
                          value: ['pending', 'approved', 'completed', 'cancelled', 'rejected']
                                  .contains(app.status.toLowerCase())
                              ? app.status.toLowerCase()
                              : 'pending',
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text("Pending")),
                            DropdownMenuItem(value: 'approved', child: Text("Approved")),
                            DropdownMenuItem(value: 'completed', child: Text("Completed")),
                            DropdownMenuItem(value: 'cancelled', child: Text("Cancelled")),
                            DropdownMenuItem(value: 'rejected', child: Text("Rejected")),
                          ],
                          onChanged: (newStatus) async {
                            if (newStatus != null) {
                              try {
                                await _firestoreService.updateAppointmentStatus(app.id, newStatus);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Appointment status updated to $newStatus")),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Delete Appointment",
                          onPressed: () async {
                            final confirm = await _showConfirmDialog(
                              "Delete Appointment",
                              "Delete this appointment record permanently?",
                            );
                            if (confirm) {
                              await _firestoreService.deleteAppointment(app.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Appointment deleted successfully")),
                                );
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
    );
  }

  // ==========================================================
  // TAB 5: REVIEWS & RATINGS MODERATION
  // ==========================================================
  Widget _buildReviewsTab() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _firestoreService.getAllReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) {
          return const Center(
            child: Text(
              "No patient reviews written yet.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final rev = reviews[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rev.patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (rev.isApproved ? Colors.green : Colors.orange).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rev.isApproved ? "APPROVED" : "PENDING",
                            style: TextStyle(
                              color: rev.isApproved ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Star ratings row
                        Row(
                          children: List.generate(
                            5,
                            (idx) => Icon(
                              idx < rev.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(rev.doctorId).get(),
                      builder: (context, snap) {
                        String docLabel = "Dr. Unknown";
                        if (snap.hasData && snap.data!.exists) {
                          docLabel = (snap.data!.data() as Map)['name'] ?? "Dr. Doctor";
                        }
                        return Text(
                          "For: $docLabel",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rev.reviewText,
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.3),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rev.createdAt.toString().split(' ')[0],
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        Row(
                          children: [
                            if (!rev.isApproved) ...[
                              TextButton.icon(
                                style: TextButton.styleFrom(foregroundColor: Colors.green),
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  await _firestoreService.approveReview(rev.id, rev.doctorId);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Review approved successfully!")),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text("Delete", style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                final confirm = await _showConfirmDialog(
                                  "Moderate Review",
                                  "Are you sure you want to delete this review? The doctor's rating will be recalculated.",
                                );
                                if (confirm) {
                                  await _firestoreService.deleteReview(rev.id, rev.doctorId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Review deleted and rating updated")),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
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
    );
  }

  // ==========================================================
  // CONTROL DIALOGS: MANAGE DEPARTMENTS
  // ==========================================================
  void _showManageDepartmentsDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Manage Departments"),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Department Name",
                    prefixIcon: const Icon(Icons.apartment),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Department name is required";
                    }
                    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return "Letters and spaces only";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Current Departments",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<String>>(
                    stream: _firestoreService.getDepartments(),
                    builder: (context, snapshot) {
                      final depts = snapshot.data ?? [];
                      if (depts.isEmpty) {
                        return const Center(child: Text("No departments configured."));
                      }

                      return ListView.builder(
                        itemCount: depts.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.apartment, color: AppColors.primary),
                            title: Text(depts[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await _showConfirmDialog(
                                  "Delete Department",
                                  "Are you sure you want to delete '${depts[index]}'?",
                                );
                                if (confirm) {
                                  await _firestoreService.deleteDepartment(depts[index]);
                                }
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final dept = nameController.text.trim();
                await _firestoreService.addDepartment(dept);
                nameController.clear();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CONTROL DIALOGS: ADD DOCTOR
  // ==========================================================
  void _showAddDoctorDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final specializationController = TextEditingController();

    String? selectedDept;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Register Doctor"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Doctor Name"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Name required";
                          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return "Letters only";
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Email required";
                          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value)) return "Invalid email format";
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Password"),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Password required";
                          if (value.length < 6) return "Min 6 characters required";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<List<String>>(
                        stream: _firestoreService.getDepartments(),
                        builder: (context, snapshot) {
                          final depts = snapshot.data ?? [];

                          if (depts.isEmpty) {
                            return const Text(
                              "No departments available.\nPlease add one first.",
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          if (selectedDept == null || !depts.contains(selectedDept)) {
                            selectedDept = depts.first;
                          }

                          return DropdownButtonFormField<String>(
                            value: selectedDept,
                            decoration: const InputDecoration(
                              labelText: "Department",
                            ),
                            items: depts.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedDept = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: specializationController,
                        decoration: const InputDecoration(labelText: "Specialization"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Specialization required";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  child: const Text("Register"),
                  onPressed: () async {
                    if (formKey.currentState!.validate() && selectedDept != null) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await _firestoreService.addDoctor(
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                          department: selectedDept!,
                          specialization: specializationController.text.trim(),
                        );

                        if (context.mounted) {
                          Navigator.pop(context); // close progress indicator
                          Navigator.pop(dialogContext); // close register dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Doctor registered successfully"),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // close progress
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed: $e"), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // CONTROL DIALOGS: EDIT DOCTOR
  // ==========================================================
  void _showEditDoctorDialog([UserModel? doc]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: doc?.name);
    final qualificationController = TextEditingController(text: doc?.qualification);
    final specializationController = TextEditingController(text: doc?.specialization);
    final experienceController = TextEditingController(text: doc?.experience);
    final feeController = TextEditingController(text: doc?.consultationFee);
    final bioController = TextEditingController(text: doc?.bio);
    final addressController = TextEditingController(text: doc?.address);

    String? selectedDept = doc?.department;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(doc == null ? "Add Doctor Profile" : "Edit Doctor Profile"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Doctor Name"),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Name required";
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) return "Letters only";
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<String>>(
                    stream: _firestoreService.getDepartments(),
                    builder: (context, snapshot) {
                      final depts = snapshot.data ?? [];
                      if (selectedDept == null || !depts.contains(selectedDept)) {
                        selectedDept = depts.isNotEmpty ? depts.first : null;
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedDept,
                        decoration: const InputDecoration(labelText: "Department"),
                        items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setDialogState(() => selectedDept = v),
                      );
                    },
                  ),
                  TextFormField(
                    controller: qualificationController,
                    decoration: const InputDecoration(labelText: "Qualification (e.g. MBBS, MD)"),
                  ),
                  TextFormField(
                    controller: specializationController,
                    decoration: const InputDecoration(labelText: "Specialization"),
                  ),
                  TextFormField(
                    controller: experienceController,
                    decoration: const InputDecoration(labelText: "Experience (e.g. 5 Years)"),
                  ),
                  TextFormField(
                    controller: feeController,
                    decoration: const InputDecoration(labelText: "Consultation Fee (\$)"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                        return "Please enter a valid price";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Clinic Address"),
                  ),
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Biography"),
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
                if (formKey.currentState!.validate() && doc != null) {
                  final updated = UserModel(
                    uid: doc.uid,
                    name: nameController.text.trim(),
                    email: doc.email,
                    role: 'doctor',
                    department: selectedDept,
                    specialization: specializationController.text.trim(),
                    qualification: qualificationController.text.trim(),
                    experience: experienceController.text.trim(),
                    consultationFee: feeController.text.trim(),
                    address: addressController.text.trim(),
                    bio: bioController.text.trim(),
                    profileImage: doc.profileImage,
                    isApproved: doc.isApproved,
                    isVerified: doc.isVerified,
                    isFeatured: doc.isFeatured,
                    availableSlots: doc.availableSlots,
                    favoriteDoctors: doc.favoriteDoctors,
                    availabilityStatus: doc.availabilityStatus,
                  );

                  try {
                    await _firestoreService.updateUser(updated);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Doctor profile updated successfully")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
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

  // ==========================================================
  // CONTROL DIALOGS: EDIT PATIENT
  // ==========================================================
  void _showEditPatientDialog(UserModel patient) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: patient.name);
    final ageController = TextEditingController(text: patient.age);
    final bloodController = TextEditingController(text: patient.bloodGroup);
    final phoneController = TextEditingController(text: patient.phone);
    final addressController = TextEditingController(text: patient.address);
    final emergencyController = TextEditingController(text: patient.emergencyContact);
    final allergiesController = TextEditingController(text: patient.allergies);
    final chronicController = TextEditingController(text: patient.chronicDiseases);

    String? selectedGender = ['male', 'female', 'other'].contains(patient.gender?.toLowerCase())
        ? patient.gender!.toLowerCase()
        : 'male';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Patient Profile"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Patient Name"),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Name required";
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) return "Letters only";
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: "Age"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        final ageVal = int.tryParse(v);
                        if (ageVal == null || ageVal < 0 || ageVal > 120) {
                          return "Enter age between 0 and 120";
                        }
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(labelText: "Gender"),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text("Male")),
                      DropdownMenuItem(value: 'female', child: Text("Female")),
                      DropdownMenuItem(value: 'other', child: Text("Other")),
                    ],
                    onChanged: (v) => setDialogState(() => selectedGender = v),
                  ),
                  TextFormField(
                    controller: bloodController,
                    decoration: const InputDecoration(labelText: "Blood Group (e.g. O+)"),
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone Number"),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty && v.trim().length < 8) {
                        return "Invalid phone number length";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: emergencyController,
                    decoration: const InputDecoration(labelText: "Emergency Contact"),
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    validator: (v) {
                      if (v != null && v.trim().isNotEmpty && !RegExp(r'^\d+$').hasMatch(v.trim())) {
                        return "Emergency contact must contain only numeric digits";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: "Address"),
                  ),
                  TextFormField(
                    controller: allergiesController,
                    decoration: const InputDecoration(labelText: "Allergies"),
                  ),
                  TextFormField(
                    controller: chronicController,
                    decoration: const InputDecoration(labelText: "Chronic Diseases"),
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
                if (formKey.currentState!.validate()) {
                  final updated = UserModel(
                    uid: patient.uid,
                    name: nameController.text.trim(),
                    email: patient.email,
                    role: 'patient',
                    age: ageController.text.trim(),
                    gender: selectedGender,
                    bloodGroup: bloodController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                    emergencyContact: emergencyController.text.trim(),
                    allergies: allergiesController.text.trim(),
                    chronicDiseases: chronicController.text.trim(),
                    profileImage: patient.profileImage,
                    isApproved: patient.isApproved,
                    isVerified: patient.isVerified,
                    isFeatured: patient.isFeatured,
                    availableSlots: patient.availableSlots,
                    favoriteDoctors: patient.favoriteDoctors,
                    height: patient.height,
                    weight: patient.weight,
                    dateOfBirth: patient.dateOfBirth,
                  );

                  try {
                    await _firestoreService.updateUser(updated);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Patient profile updated successfully")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
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

  void _showVerifyDocumentsDialog(UserModel doctor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Verify Credentials - ${doctor.name}"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Review uploaded credential documents:",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildDocumentViewer("Medical Practice License", doctor.medicalLicenseUrl),
                const SizedBox(height: 16),
                _buildDocumentViewer("Degree / Specialization Board Certificate", doctor.degreeUrl),
                const SizedBox(height: 16),
                _buildDocumentViewer("Other Medical Certificates", doctor.certificateUrl),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _firestoreService.updateDoctorVerification(doctor.uid, 'rejected');
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Credentials rejected. Doctor unverified.")),
                );
              }
            },
            child: const Text("Reject Docs"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _firestoreService.updateDoctorVerification(doctor.uid, 'verified');
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Credentials approved! Verified badge granted.")),
                );
              }
            },
            child: const Text("Approve & Verify"),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
        ),
        const SizedBox(height: 6),
        url == null || url.isEmpty
            ? Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: const Center(
                  child: Text(
                    "No document uploaded yet",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: url.startsWith('data:image/')
                    ? Image.memory(
                        base64Decode(url.split('base64,').last),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("Error loading document image file", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      )
                    : Image.network(
                        url,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("Error loading document image file", style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ),
              ),
      ],
    );
  }
}
