// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import '../../../core/constants/app_colors.dart';
// import '../../../models/appointment_model.dart';
// import '../../../models/user_model.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/firestore_service.dart';

// class AdminDashboard extends StatefulWidget {
//   const AdminDashboard({super.key});

//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final AuthService _authService = AuthService();

//   String _userSearchQuery = '';
//   String _selectedRoleFilter = 'all';
//   String _selectedDeptFilter = 'all';

//   String _appSearchQuery = '';
//   String _selectedStatusFilter = 'all';

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: AppBar(
//           title: const Text("Admin Panel"),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.logout, color: Colors.red),
//               onPressed: () async {
//                 await _authService.signOut();
//                 if (mounted) {
//                   Navigator.pushNamedAndRemoveUntil(
//                     context,
//                     '/landing',
//                     (_) => false,
//                   );
//                 }
//               },
//             ),
//           ],
//           bottom: const TabBar(
//             tabs: [
//               Tab(icon: Icon(Icons.dashboard), text: "Stats"),
//               Tab(icon: Icon(Icons.people), text: "Users"),
//               Tab(icon: Icon(Icons.calendar_today), text: "Bookings"),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             _buildStatsTab(context),
//             _buildUsersTab(),
//             _buildAppointmentsTab(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ================= TAB 1: OVERVIEW & CONTROLS =================
//   Widget _buildStatsTab(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "System Stats",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 15),

//           // Real-time Stats Cards
//           Row(
//             children: [
//               Expanded(
//                 child: StreamBuilder<int>(
//                   stream: _firestoreService.getUserCount('doctor'),
//                   builder: (context, snapshot) => _statCard(
//                     "Doctors",
//                     (snapshot.data ?? 0).toString(),
//                     Icons.medical_services,
//                     Colors.blue,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: StreamBuilder<int>(
//                   stream: _firestoreService.getUserCount('patient'),
//                   builder: (context, snapshot) => _statCard(
//                     "Patients",
//                     (snapshot.data ?? 0).toString(),
//                     Icons.people,
//                     Colors.green,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Expanded(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection('appointments')
//                       .snapshots(),
//                   builder: (context, snapshot) => _statCard(
//                     "Appointments",
//                     (snapshot.hasData ? snapshot.data!.docs.length : 0)
//                         .toString(),
//                     Icons.calendar_today,
//                     Colors.orange,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: StreamBuilder<List<String>>(
//                   stream: _firestoreService.getDepartments(),
//                   builder: (context, snapshot) => _statCard(
//                     "Departments",
//                     (snapshot.data ?? []).length.toString(),
//                     Icons.apartment,
//                     Colors.indigo,
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 30),
//           const Text(
//             "Quick Management Actions",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 15),

//           Row(
//             children: [
//               Expanded(
//                 child: _actionBtn(
//                   title: "Add Doctor",
//                   subtitle: "Register doctor credential",
//                   icon: Icons.person_add,
//                   color: Colors.blue,
//                   onTap: _showAddDoctorDialog,
//                 ),
//               ),
//               const SizedBox(width: 15),
//               Expanded(
//                 child: _actionBtn(
//                   title: "Departments",
//                   subtitle: "Manage hospital services",
//                   icon: Icons.apartment,
//                   color: Colors.indigo,
//                   onTap: _showManageDepartmentsDialog,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= TAB 2: USERS DIRECTORY =================
//   Widget _buildUsersTab() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('users').snapshots(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(child: Text("No users in system"));
//         }

//         final users = snapshot.data!.docs.map((doc) {
//           return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
//         }).toList();

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: users.length,
//           itemBuilder: (context, index) {
//             final user = users[index];
//             final roleColor = user.role == 'admin'
//                 ? Colors.red
//                 : user.role == 'doctor'
//                 ? Colors.blue
//                 : Colors.green;

//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: roleColor.withOpacity(0.12),
//                   child: Icon(
//                     user.role == 'doctor'
//                         ? Icons.medical_services
//                         : user.role == 'admin'
//                         ? Icons.admin_panel_settings
//                         : Icons.person,
//                     color: roleColor,
//                   ),
//                 ),
//                 title: Text(
//                   user.name,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text("${user.email} | ${user.role.toUpperCase()}"),
//                 trailing: user.role == 'doctor' && user.department != null
//                     ? Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           user.department!,
//                           style: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       )
//                     : null,
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // ================= TAB 3: APPOINTMENTS LOG =================
//   Widget _buildAppointmentsTab() {
//     return StreamBuilder<List<AppointmentModel>>(
//       stream: _firestoreService.getAllAppointments(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final list = snapshot.data ?? [];
//         if (list.isEmpty) {
//           return const Center(child: Text("No appointments filed yet."));
//         }

//         return ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: list.length,
//           itemBuilder: (context, index) {
//             final app = list[index];
//             final statusColor = app.status == 'Approved'
//                 ? Colors.green
//                 : app.status == 'Rejected'
//                 ? Colors.red
//                 : app.status == 'Completed'
//                 ? Colors.blue
//                 : Colors.orange;

//             return Card(
//               margin: const EdgeInsets.only(bottom: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           app.patientName,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: statusColor.withOpacity(0.12),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             app.status,
//                             style: TextStyle(
//                               color: statusColor,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),
//                     Text("Doctor: ${app.doctorName} (${app.department})"),
//                     Text("Scheduled: ${app.date} @ ${app.time}"),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // ================= STATISTICS COMPONENT =================
//   Widget _statCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           CircleAvatar(
//             backgroundColor: color.withOpacity(0.12),
//             child: Icon(icon, color: color),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= ACTION BUTTONS COMPONENT =================
//   Widget _actionBtn({
//     required String title,
//     required String subtitle,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color.withOpacity(0.15)),
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
//           ],
//         ),
//         child: Column(
//           children: [
//             CircleAvatar(
//               backgroundColor: color.withOpacity(0.12),
//               child: Icon(icon, color: color),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               subtitle,
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ================= ACTIONS DIALOGS =================

//   // Manage Departments Dialog
//   void _showManageDepartmentsDialog() {
//     final nameController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Manage Departments"),
//         content: SizedBox(
//           width: double.maxFinite,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: const InputDecoration(
//                   labelText: "New Department Name",
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   "Active Departments:",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: StreamBuilder<List<String>>(
//                   stream: _firestoreService.getDepartments(),
//                   builder: (context, snapshot) {
//                     final depts = snapshot.data ?? [];
//                     if (depts.isEmpty) {
//                       return const Center(
//                         child: Text("No departments configured"),
//                       );
//                     }
//                     return ListView.builder(
//                       itemCount: depts.length,
//                       itemBuilder: (c, idx) => ListTile(
//                         leading: const Icon(
//                           Icons.apartment,
//                           color: AppColors.primary,
//                         ),
//                         title: Text(depts[idx]),
//                         trailing: IconButton(
//                           icon: const Icon(
//                             Icons.delete,
//                             color: Colors.red,
//                             size: 18,
//                           ),
//                           onPressed: () async {
//                             final confirm = await showDialog<bool>(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: const Text("Delete Department"),
//                                 content: Text(
//                                   "Are you sure you want to delete '${depts[idx]}'?",
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () =>
//                                         Navigator.pop(context, false),
//                                     child: const Text("Cancel"),
//                                   ),
//                                   TextButton(
//                                     onPressed: () =>
//                                         Navigator.pop(context, true),
//                                     child: const Text(
//                                       "Delete",
//                                       style: TextStyle(color: Colors.red),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                             if (confirm == true) {
//                               try {
//                                 await _firestoreService.deleteDepartment(
//                                   depts[idx],
//                                 );
//                               } catch (e) {
//                                 if (context.mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                       content: Text("Error deleting: $e"),
//                                     ),
//                                   );
//                                 }
//                               }
//                             }
//                           },
//                         ),
//                         dense: true,
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Close"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final val = nameController.text.trim();
//               if (val.isEmpty) return;
//               try {
//                 await _firestoreService.addDepartment(val);
//                 nameController.clear();
//               } catch (e) {
//                 ScaffoldMessenger.of(
//                   context,
//                 ).showSnackBar(SnackBar(content: Text("Error: $e")));
//               }
//             },
//             child: const Text("Add"),
//           ),
//         ],
//       ),
//     );
//   }

//   // Add Doctor Dialog
//   void _showAddDoctorDialog() {
//     final nameController = TextEditingController();
//     final emailController = TextEditingController();
//     final passwordController = TextEditingController();
//     final specializationController = TextEditingController();

//     String selectedDept = 'Cardiology';

//     showDialog(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setDialogState) => AlertDialog(
//           title: const Text("Add New Doctor"),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: "Doctor's Name"),
//                 ),
//                 TextField(
//                   controller: emailController,
//                   decoration: const InputDecoration(
//                     labelText: "Doctor's Email",
//                   ),
//                 ),
//                 TextField(
//                   controller: passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     labelText: "Temporary Password",
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 StreamBuilder<List<String>>(
//                   stream: _firestoreService.getDepartments(),
//                   builder: (context, snapshot) {
//                     final depts =
//                         snapshot.data ??
//                         [
//                           'Cardiology',
//                           'Neurology',
//                           'Orthopedics',
//                           'Dermatology',
//                           'Pediatrics',
//                         ];
//                     return DropdownButtonFormField<String>(
//                       initialValue: selectedDept,
//                       decoration: const InputDecoration(
//                         labelText: "Department",
//                       ),
//                       items: depts
//                           .map(
//                             (d) => DropdownMenuItem(value: d, child: Text(d)),
//                           )
//                           .toList(),
//                       onChanged: (v) {
//                         if (v != null) {
//                           setDialogState(() => selectedDept = v);
//                         }
//                       },
//                     );
//                   },
//                 ),
//                 TextField(
//                   controller: specializationController,
//                   decoration: const InputDecoration(
//                     labelText: "Specialization",
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final name = nameController.text.trim();
//                 final email = emailController.text.trim();
//                 final password = passwordController.text.trim();
//                 final spec = specializationController.text.trim();

//                 if (name.isEmpty ||
//                     email.isEmpty ||
//                     password.isEmpty ||
//                     spec.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Please fill all fields")),
//                   );
//                   return;
//                 }

//                 // Show loading spinner
//                 showDialog(
//                   context: context,
//                   barrierDismissible: false,
//                   builder: (c) =>
//                       const Center(child: CircularProgressIndicator()),
//                 );

//                 try {
//                   await _firestoreService.addDoctor(
//                     name: name,
//                     email: email,
//                     password: password,
//                     department: selectedDept,
//                     specialization: spec,
//                   );
//                   if (mounted) {
//                     Navigator.pop(ctx); // Close loading spinner
//                     Navigator.pop(ctx); // Close dialog
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text("Doctor Registered Successfully"),
//                       ),
//                     );
//                   }
//                 } catch (e) {
//                   if (mounted) {
//                     Navigator.pop(ctx); // Close loading spinner
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("Failed to register: $e")),
//                     );
//                   }
//                 }
//               },
//               child: const Text("Register"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String _userSearchQuery = '';
  String _selectedRoleFilter = 'all';
  String _selectedDeptFilter = 'all';

  String _appSearchQuery = '';
  String _selectedStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("Admin Panel"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red),
              onPressed: () async {
                await _authService.signOut();

                if (!mounted) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/landing',
                  (_) => false,
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Stats"),
              Tab(icon: Icon(Icons.people), text: "Users"),
              Tab(icon: Icon(Icons.calendar_today), text: "Bookings"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStatsTab(),
            _buildUsersTab(),
            _buildAppointmentsTab(),
          ],
        ),
      ),
    );
  }

  //==========================================================
  // STATS TAB
  //==========================================================

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Stats",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: StreamBuilder<int>(
                  stream: _firestoreService.getUserCount('doctor'),
                  builder: (context, snapshot) {
                    return _statCard(
                      "Doctors",
                      (snapshot.data ?? 0).toString(),
                      Icons.medical_services,
                      Colors.blue,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: StreamBuilder<int>(
                  stream: _firestoreService.getUserCount('patient'),
                  builder: (context, snapshot) {
                    return _statCard(
                      "Patients",
                      (snapshot.data ?? 0).toString(),
                      Icons.people,
                      Colors.green,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('appointments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    return _statCard(
                      "Appointments",
                      snapshot.hasData
                          ? snapshot.data!.docs.length.toString()
                          : "0",
                      Icons.calendar_today,
                      Colors.orange,
                    );
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _firestoreService.getDepartments(),
                  builder: (context, snapshot) {
                    return _statCard(
                      "Departments",
                      (snapshot.data ?? []).length.toString(),
                      Icons.apartment,
                      Colors.indigo,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            "Quick Management",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  title: "Add Doctor",
                  subtitle: "Register a new doctor",
                  icon: Icons.person_add,
                  color: Colors.blue,
                  onTap: _showAddDoctorDialog,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _actionBtn(
                  title: "Departments",
                  subtitle: "Manage departments",
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

  //==========================================================
  // USERS TAB
  //==========================================================

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found."));
        }

        final users = snapshot.data!.docs.map((doc) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];

            Color roleColor;

            switch (user.role) {
              case "doctor":
                roleColor = Colors.blue;
                break;

              case "admin":
                roleColor = Colors.red;
                break;

              default:
                roleColor = Colors.green;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor.withOpacity(.12),
                  child: Icon(
                    user.role == "doctor"
                        ? Icons.medical_services
                        : user.role == "admin"
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    color: roleColor,
                  ),
                ),

                title: Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Text("${user.email}\n${user.role.toUpperCase()}"),

                trailing: user.role == "doctor"
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          user.department ?? "",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
  //==========================================================
  // APPOINTMENTS TAB
  //==========================================================

  Widget _buildAppointmentsTab() {
    return StreamBuilder<List<AppointmentModel>>(
      stream: _firestoreService.getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data ?? [];

        if (appointments.isEmpty) {
          return const Center(child: Text("No appointments found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final app = appointments[index];

            Color statusColor;

            switch (app.status) {
              case "Approved":
                statusColor = Colors.green;
                break;

              case "Rejected":
                statusColor = Colors.red;
                break;

              case "Completed":
                statusColor = Colors.blue;
                break;

              default:
                statusColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            app.patientName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            app.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons.medical_services,
                          size: 18,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text("${app.doctorName} (${app.department})"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(app.date),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(app.time),
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

  //==========================================================
  // STAT CARD
  //==========================================================

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 14),

          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  //==========================================================
  // ACTION BUTTON
  //==========================================================

  Widget _actionBtn({
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  // PART 3 OF AdminDashboard.dart

  //==========================================================
  // MANAGE DEPARTMENTS DIALOG
  //==========================================================

  void _showManageDepartmentsDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Manage Departments"),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Department Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: _firestoreService.getDepartments(),
                  builder: (context, snapshot) {
                    final depts = snapshot.data ?? [];
                    if (depts.isEmpty) {
                      return const Center(child: Text("No departments"));
                    }

                    return ListView.builder(
                      itemCount: depts.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.apartment),
                          title: Text(depts[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _firestoreService.deleteDepartment(
                                depts[index],
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              final dept = nameController.text.trim();
              if (dept.isEmpty) return;
              await _firestoreService.addDepartment(dept);
              nameController.clear();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  //==========================================================
  // ADD DOCTOR DIALOG (FIXED DROPDOWN)
  //==========================================================

  void _showAddDoctorDialog() {
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Doctor Name",
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
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

                        if (selectedDept == null ||
                            !depts.contains(selectedDept)) {
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: specializationController,
                      decoration: const InputDecoration(
                        labelText: "Specialization",
                      ),
                    ),
                  ],
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
                    if (nameController.text.trim().isEmpty ||
                        emailController.text.trim().isEmpty ||
                        passwordController.text.trim().isEmpty ||
                        specializationController.text.trim().isEmpty ||
                        selectedDept == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fill all fields")),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
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
                        Navigator.pop(context);
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Doctor registered successfully"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
}
