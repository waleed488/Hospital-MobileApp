import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/skeleton_loader.dart';
import 'patient_view_doctor_profile_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();

  String searchQuery = '';
  String selectedDept = 'All';
  bool showFavoritesOnly = false;

  List<String> departments = ['All'];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    FirebaseFirestore.instance
        .collection('departments')
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          departments = ['All'] + snap.docs.map((doc) => doc.id).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Doctors"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ================= SEARCH & TOGGLES =================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: "Search doctor by name...",
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filter by Favorites Only",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Switch.adaptive(
                      value: showFavoritesOnly,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => showFavoritesOnly = v),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================= DEPARTMENT CHIPS =================
          Container(
            height: 52,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: departments.length,
              itemBuilder: (context, idx) {
                final dept = departments[idx];
                final isSelected = selectedDept == dept;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(dept),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        selectedDept = dept;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // ================= DOCTORS STREAM =================
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, userSnapshot) {
                final favoriteList = <String>[];
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final uData = userSnapshot.data!.data() as Map<String, dynamic>;
                  if (uData['favoriteDoctors'] != null) {
                    favoriteList.addAll(List<String>.from(uData['favoriteDoctors']));
                  }
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'doctor')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonList(itemCount: 4, cardHeight: 120);
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const EmptyState(
                        title: "No Doctors Found",
                        message: "There are no doctors registered in the system.",
                        icon: Icons.person_off,
                      );
                    }

                    // Map to UserModel list
                    var doctors = snapshot.data!.docs.map((doc) {
                      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                    }).where((d) => d.isApproved).toList();

                    // Apply Client-Side Filters (Search Query, Department, Favorites Only)
                    if (searchQuery.isNotEmpty) {
                      doctors = doctors
                          .where((d) => d.name.toLowerCase().contains(searchQuery.toLowerCase()))
                          .toList();
                    }

                    if (selectedDept != 'All') {
                      doctors = doctors.where((d) => d.department == selectedDept).toList();
                    }

                    if (showFavoritesOnly) {
                      doctors = doctors.where((d) => favoriteList.contains(d.uid)).toList();
                    }

                    if (doctors.isEmpty) {
                      return const EmptyState(
                        title: "No Results Match Filters",
                        message: "Try modifying your search or filters to see doctors.",
                        icon: Icons.search_off,
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: doctors.length,
                      itemBuilder: (context, index) {
                        final doc = doctors[index];
                        final isFavorite = favoriteList.contains(doc.uid);

                        // Availability configurations
                        final availStatus = doc.availabilityStatus ?? "Available Today";
                        Color badgeColor = AppColors.success;
                        if (availStatus == "Busy") {
                          badgeColor = AppColors.warning;
                        } else if (availStatus == "On Leave") {
                          badgeColor = AppColors.error;
                        }

                        // Average Rating fallback
                        final ratingValue = doc.toMap()['rating'] ?? 4.8;
                        final double rating = ratingValue is int
                            ? ratingValue.toDouble()
                            : (ratingValue as double);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientViewDoctorProfileScreen(doctor: doc),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doc.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            // Availability badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                availStatus,
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${doc.specialization} • ${doc.department}",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.work, color: Colors.indigo, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              doc.experience ?? "5 Years",
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.attach_money, color: Colors.teal, size: 16),
                                            Text(
                                              "${doc.consultationFee ?? '50'}/Consultation",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey.shade400,
                                    ),
                                    onPressed: () async {
                                      await _firestoreService.toggleFavoriteDoctor(
                                        uid,
                                        doc.uid,
                                        !isFavorite,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
