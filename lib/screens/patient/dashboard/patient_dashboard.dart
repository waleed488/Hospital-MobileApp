// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// import '../../../core/constants/app_colors.dart';
// import '../../../models/medicine_reminder_model.dart';
// import '../../../models/notification_model.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/firestore_service.dart';
// import '../appointments/book_appointment_screen.dart';
// import '../appointments/doctor_search_screen.dart';
// import '../appointments/my_appointments_screen.dart';
// import '../emergency/emergency_contacts_screen.dart';
// import '../notifications/notifications_screen.dart';
// import '../profile/patient_medical_profile_screen.dart';
// import '../profile/patient_profile_screen.dart';
// import '../records/medical_records_screen.dart';
// import '../records/prescriptions_screen.dart';
// import '../reminders/medicine_reminders_screen.dart';

// class PatientDashboard extends StatefulWidget {
//   const PatientDashboard({super.key});

//   @override
//   State<PatientDashboard> createState() => _PatientDashboardState();
// }

// class _PatientDashboardState extends State<PatientDashboard> {
//   final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
//   String patientName = "Patient";
//   final AuthService _authService = AuthService();
//   final FirestoreService _firestoreService = FirestoreService();

//   final List<String> _healthTips = [
//     "Drink at least 8-10 glasses of water daily to stay hydrated.",
//     "Walk 30 minutes daily to maintain a healthy cardiovascular system.",
//     "Sleep at least 7-8 hours each night for optimal body and brain recovery.",
//     "Eat a balanced diet rich in fibers, fresh fruits, and green vegetables.",
//     "Practice posture correction; sit upright and take stretch breaks regularly.",
//     "Limit processed sugar and excess caffeine intake.",
//     "Sanitize your hands regularly and maintain proper hygiene.",
//   ];

//   String getTodayTip() {
//     final dayOfYear = DateTime.now()
//         .difference(DateTime(DateTime.now().year, 1, 1))
//         .inDays;
//     return _healthTips[dayOfYear % _healthTips.length];
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadPatientName();
//   }

//   Future<void> _loadPatientName() async {
//     if (uid.isNotEmpty) {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .get();
//       if (doc.exists && doc.data() != null) {
//         setState(() {
//           patientName = doc.data()?['name'] ?? "Patient";
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final todayStr = DateTime.now().toString().split(' ')[0];

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         title: const Text("Patient Portal"),
//         centerTitle: false,
//         automaticallyImplyLeading: true,
//         actions: [
//           // Notification bell with unread badge
//           StreamBuilder<List<NotificationModel>>(
//             stream: _firestoreService.getUserNotifications(uid),
//             builder: (context, snapshot) {
//               final unreadCount = snapshot.hasData
//                   ? snapshot.data!.where((n) => !n.isRead).length
//                   : 0;
//               return IconButton(
//                 icon: Badge(
//                   label: unreadCount > 0 ? Text(unreadCount.toString()) : null,
//                   isLabelVisible: unreadCount > 0,
//                   backgroundColor: AppColors.error,
//                   child: const Icon(Icons.notifications_outlined, size: 26),
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => const NotificationsScreen(),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//           PopupMenuButton<String>(
//             icon: CircleAvatar(
//               backgroundColor: AppColors.primary.withOpacity(0.15),
//               child: const Icon(Icons.person, color: AppColors.primary),
//             ),
//             onSelected: (value) async {
//               if (value == 'profile') {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => const PatientProfileScreen(),
//                   ),
//                 );
//               } else if (value == 'logout') {
//                 await _authService.signOut();
//                 if (mounted) {
//                   Navigator.pushNamedAndRemoveUntil(
//                     context,
//                     '/landing',
//                     (_) => false,
//                   );
//                 }
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'profile',
//                 child: Row(
//                   children: [
//                     Icon(Icons.person_outline, color: AppColors.textPrimary),
//                     SizedBox(width: 8),
//                     Text('My Profile'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'logout',
//                 child: Row(
//                   children: [
//                     Icon(Icons.logout, color: Colors.red),
//                     SizedBox(width: 8),
//                     Text('Logout', style: TextStyle(color: Colors.red)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 16),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ================= WELCOME HEADER =================
//               Container(
//                 padding: const EdgeInsets.all(22),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [AppColors.primary, AppColors.secondary],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundColor: Colors.white.withOpacity(0.2),
//                       child: const Icon(
//                         Icons.person,
//                         size: 32,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(width: 15),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             "Welcome Back 👋",
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             patientName,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // ================= DAILY HEALTH TIP =================
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.teal.shade50,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(color: Colors.teal.shade100),
//                 ),
//                 child: Row(
//                   children: [
//                     const CircleAvatar(
//                       backgroundColor: AppColors.secondary,
//                       child: Icon(Icons.wb_sunny, color: Colors.white),
//                     ),
//                     const SizedBox(width: 14),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             "Daily Health Tip",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 14,
//                               color: AppColors.secondary,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             getTodayTip(),
//                             style: TextStyle(
//                               fontSize: 13,
//                               color: Colors.teal.shade900,
//                               height: 1.3,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 25),

//               const Text(
//                 "Health Summary",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 15),

//               // ================= STATS ROW =================
//               Row(
//                 children: [
//                   Expanded(
//                     child: _statStreamCard(
//                       stream: FirebaseFirestore.instance
//                           .collection('appointments')
//                           .where('patientId', isEqualTo: uid)
//                           .snapshots(),
//                       title: "Appointments",
//                       icon: Icons.event_note,
//                       color: Colors.blue,
//                     ),
//                   ),
//                   const SizedBox(width: 15),
//                   Expanded(
//                     child: _statStreamCard(
//                       stream: FirebaseFirestore.instance
//                           .collection('prescriptions')
//                           .where('patientId', isEqualTo: uid)
//                           .snapshots(),
//                       title: "Prescriptions",
//                       icon: Icons.medication,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 25),

//               // ================= MEDICINES CHECKLIST FOR TODAY =================
//               StreamBuilder<List<MedicineReminderModel>>(
//                 stream: _firestoreService.getPatientMedicineReminders(uid),
//                 builder: (context, snapshot) {
//                   final list = snapshot.data ?? [];
//                   if (list.isEmpty) return const SizedBox.shrink();

//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Today's Medicine Tracker",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.03),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: ListView.separated(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: list.length > 3 ? 3 : list.length,
//                           separatorBuilder: (context, index) =>
//                               const Divider(height: 1),
//                           itemBuilder: (context, index) {
//                             final rem = list[index];
//                             final isTaken =
//                                 rem.isTaken && rem.lastTakenDate == todayStr;

//                             return CheckboxListTile(
//                               title: Text(
//                                 rem.name,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   decoration: isTaken
//                                       ? TextDecoration.lineThrough
//                                       : null,
//                                   color: isTaken
//                                       ? Colors.grey
//                                       : AppColors.textPrimary,
//                                 ),
//                               ),
//                               subtitle: Text("${rem.dosage} • ${rem.time}"),
//                               value: isTaken,
//                               activeColor: AppColors.success,
//                               onChanged: (val) async {
//                                 if (val != null) {
//                                   await _firestoreService
//                                       .markMedicineReminderAsTaken(
//                                         rem.id,
//                                         todayStr,
//                                         val,
//                                       );
//                                 }
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 25),
//                     ],
//                   );
//                 },
//               ),

//               const Text(
//                 "Quick Actions",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 15),

//               // ================= ACTION GRID =================
//               GridView.count(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 14,
//                 mainAxisSpacing: 14,
//                 childAspectRatio: 1.05,
//                 children: [
//                   _actionCard(
//                     context,
//                     "Search Doctors",
//                     Icons.search,
//                     Colors.blue,
//                     const DoctorSearchScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "Book Visit",
//                     Icons.calendar_month,
//                     Colors.indigo,
//                     const BookAppointmentScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "My Bookings",
//                     Icons.event_note,
//                     Colors.teal,
//                     const MyAppointmentsScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "Medical Records",
//                     Icons.folder_copy,
//                     Colors.orange,
//                     const MedicalRecordsScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "Prescriptions",
//                     Icons.medication,
//                     Colors.pink,
//                     const PrescriptionsScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "Medical Profile",
//                     Icons.assignment_ind,
//                     Colors.purple,
//                     const PatientMedicalProfileScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "Medicine Reminders",
//                     Icons.alarm,
//                     Colors.deepOrange,
//                     const MedicineRemindersScreen(),
//                   ),
//                   _actionCard(
//                     context,
//                     "Emergency Page",
//                     Icons.phone_forwarded,
//                     Colors.red,
//                     const EmergencyContactsScreen(),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _statStreamCard({
//     required Stream<QuerySnapshot> stream,
//     required String title,
//     required IconData icon,
//     required Color color,
//   }) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         final count = snapshot.hasData
//             ? snapshot.data!.docs.length.toString()
//             : "0";
//         return Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               CircleAvatar(
//                 backgroundColor: color.withOpacity(0.12),
//                 child: Icon(icon, color: color),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 count,
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 title,
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _actionCard(
//     BuildContext context,
//     String title,
//     IconData icon,
//     Color color,
//     Widget screen,
//   ) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: () =>
//           Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               radius: 26,
//               backgroundColor: color.withOpacity(0.12),
//               child: Icon(icon, size: 28, color: color),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/medicine_reminder_model.dart';
import '../../../models/notification_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../appointments/book_appointment_screen.dart';
import '../appointments/doctor_search_screen.dart';
import '../appointments/my_appointments_screen.dart';
import '../emergency/emergency_contacts_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/patient_medical_profile_screen.dart';
import '../profile/patient_profile_screen.dart';
import '../records/medical_records_screen.dart';
import '../records/prescriptions_screen.dart';
import '../reminders/medicine_reminders_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String patientName = "Patient";
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _healthTips = [
    "Drink at least 8-10 glasses of water daily to stay hydrated.",
    "Walk 30 minutes daily to maintain a healthy cardiovascular system.",
    "Sleep at least 7-8 hours each night for optimal body and brain recovery.",
    "Eat a balanced diet rich in fibers, fresh fruits, and green vegetables.",
    "Practice posture correction; sit upright and take stretch breaks regularly.",
    "Limit processed sugar and excess caffeine intake.",
    "Sanitize your hands regularly and maintain proper hygiene.",
  ];

  String getTodayTip() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _healthTips[dayOfYear % _healthTips.length];
  }

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
        setState(() {
          patientName = doc.data()?['name'] ?? "Patient";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateTime.now().toString().split(' ')[0];

    return Scaffold(
      // Added the navigation drawer here. This instantly brings up the hamburger menu button.
      drawer: _buildPatientDrawer(context),
      appBar: AppBar(
        title: const Text("Patient Portal"),
        centerTitle: false,
        automaticallyImplyLeading:
            true, // Crucial for displaying the hamburger icon automatically
        actions: [
          // Notification bell with unread badge
          StreamBuilder<List<NotificationModel>>(
            stream: _firestoreService.getUserNotifications(uid),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData
                  ? snapshot.data!.where((n) => !n.isRead).length
                  : 0;
              return IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text(unreadCount.toString()) : null,
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.notifications_outlined, size: 26),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: const Icon(Icons.person, color: AppColors.primary),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientProfileScreen(),
                  ),
                );
              } else if (value == 'logout') {
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
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= WELCOME HEADER =================
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back 👋",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patientName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ================= DAILY HEALTH TIP =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.secondary,
                      child: Icon(Icons.wb_sunny, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Daily Health Tip",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            getTodayTip(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.teal.shade900,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                "Health Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // ================= STATS ROW =================
              Row(
                children: [
                  Expanded(
                    child: _statStreamCard(
                      stream: FirebaseFirestore.instance
                          .collection('appointments')
                          .where('patientId', isEqualTo: uid)
                          .snapshots(),
                      title: "Appointments",
                      icon: Icons.event_note,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _statStreamCard(
                      stream: FirebaseFirestore.instance
                          .collection('prescriptions')
                          .where('patientId', isEqualTo: uid)
                          .snapshots(),
                      title: "Prescriptions",
                      icon: Icons.medication,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // ================= MEDICINES CHECKLIST FOR TODAY =================
              StreamBuilder<List<MedicineReminderModel>>(
                stream: _firestoreService.getPatientMedicineReminders(uid),
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Medicine Tracker",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length > 3 ? 3 : list.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final rem = list[index];
                            final isTaken =
                                rem.isTaken && rem.lastTakenDate == todayStr;

                            return CheckboxListTile(
                              title: Text(
                                rem.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isTaken
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isTaken
                                      ? Colors.grey
                                      : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text("${rem.dosage} • ${rem.time}"),
                              value: isTaken,
                              activeColor: AppColors.success,
                              onChanged: (val) async {
                                if (val != null) {
                                  await _firestoreService
                                      .markMedicineReminderAsTaken(
                                        rem.id,
                                        todayStr,
                                        val,
                                      );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  );
                },
              ),

              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // ================= ACTION GRID =================
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _actionCard(
                    context,
                    "Search Doctors",
                    Icons.search,
                    Colors.blue,
                    const DoctorSearchScreen(),
                  ),
                  _actionCard(
                    context,
                    "Book Visit",
                    Icons.calendar_month,
                    Colors.indigo,
                    const BookAppointmentScreen(),
                  ),
                  _actionCard(
                    context,
                    "My Bookings",
                    Icons.event_note,
                    Colors.teal,
                    const MyAppointmentsScreen(),
                  ),
                  _actionCard(
                    context,
                    "Medical Records",
                    Icons.folder_copy,
                    Colors.orange,
                    const MedicalRecordsScreen(),
                  ),
                  _actionCard(
                    context,
                    "Prescriptions",
                    Icons.medication,
                    Colors.pink,
                    const PrescriptionsScreen(),
                  ),
                  _actionCard(
                    context,
                    "Medical Profile",
                    Icons.assignment_ind,
                    Colors.purple,
                    const PatientMedicalProfileScreen(),
                  ),
                  _actionCard(
                    context,
                    "Medicine Reminders",
                    Icons.alarm,
                    Colors.deepOrange,
                    const MedicineRemindersScreen(),
                  ),
                  _actionCard(
                    context,
                    "Emergency Page",
                    Icons.phone_forwarded,
                    Colors.red,
                    const EmergencyContactsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SIDE NAVIGATION DRAWER =================
  Widget _buildPatientDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 35, color: AppColors.primary),
            ),
            accountName: Text(
              patientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              FirebaseAuth.instance.currentUser?.email ?? 'No Email Bound',
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.blue),
            title: const Text('Search Doctors'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DoctorSearchScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.indigo),
            title: const Text('Book Visit'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookAppointmentScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note, color: Colors.teal),
            title: const Text('My Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_copy, color: Colors.orange),
            title: const Text('Medical Records'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication, color: Colors.pink),
            title: const Text('Prescriptions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrescriptionsScreen()),
              );
            },
          ),
          const Divider(),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/landing',
                  (_) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ================= EXISTING WIDGET HELPERS =================
  Widget _statStreamCard({
    required Stream<QuerySnapshot> stream,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.hasData
            ? snapshot.data!.docs.length.toString()
            : "0";
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
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
              const SizedBox(height: 10),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
