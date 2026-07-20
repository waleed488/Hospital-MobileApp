import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/review_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/empty_state.dart';
import 'book_appointment_screen.dart';

class PatientViewDoctorProfileScreen extends StatefulWidget {
  final UserModel doctor;

  const PatientViewDoctorProfileScreen({super.key, required this.doctor});

  @override
  State<PatientViewDoctorProfileScreen> createState() =>
      _PatientViewDoctorProfileScreenState();
}

class _PatientViewDoctorProfileScreenState
    extends State<PatientViewDoctorProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();

  double _userRating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingReview = false;
  String patientName = "Patient";

  @override
  void initState() {
    super.initState();
    _loadPatientName();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientName() async {
    if (uid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          patientName = doc.data()?['name'] ?? "Patient";
        });
      }
    }
  }

  void _showAddReviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rate your Experience",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "How was your consultation with Dr. ${widget.doctor.name}?",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      icon: Icon(
                        _userRating >= starIndex ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 38,
                      ),
                      onPressed: () {
                        setModalState(() {
                          _userRating = starIndex.toDouble();
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Write a short review about the doctor...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmittingReview
                        ? null
                        : () async {
                            final reviewText = _reviewController.text.trim();
                            if (reviewText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please write a review")),
                              );
                              return;
                            }

                            setModalState(() => _isSubmittingReview = true);

                            final newReview = ReviewModel(
                              id: '',
                              doctorId: widget.doctor.uid,
                              patientId: uid,
                              patientName: patientName,
                              rating: _userRating,
                              reviewText: reviewText,
                              createdAt: DateTime.now(),
                            );

                            try {
                              await _firestoreService.addDoctorReview(newReview);
                              if (mounted) {
                                Navigator.pop(ctx);
                                _reviewController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Review Submitted Successfully"),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Failed to submit review: $e")),
                                );
                              }
                            } finally {
                              setModalState(() => _isSubmittingReview = false);
                            }
                          },
                    child: _isSubmittingReview
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Review"),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Availability Badge Color
    final availStatus = widget.doctor.availabilityStatus ?? "Available Today";
    Color badgeColor = AppColors.success;
    if (availStatus == "Busy") {
      badgeColor = AppColors.warning;
    } else if (availStatus == "On Leave") {
      badgeColor = AppColors.error;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Doctor Details"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= HEADER CARD =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.doctor.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.doctor.specialization ?? "General Practitioner",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  availStatus,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                          builder: (context, userSnapshot) {
                            final favorites = <String>[];
                            if (userSnapshot.hasData && userSnapshot.data!.exists) {
                              final uData = userSnapshot.data!.data() as Map<String, dynamic>;
                              if (uData['favoriteDoctors'] != null) {
                                favorites.addAll(List<String>.from(uData['favoriteDoctors']));
                              }
                            }
                            final isFavorite = favorites.contains(widget.doctor.uid);

                            return IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey.shade400,
                                size: 28,
                              ),
                              onPressed: () async {
                                await _firestoreService.toggleFavoriteDoctor(
                                  uid,
                                  widget.doctor.uid,
                                  !isFavorite,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ================= STATS ROW =================
                  Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          icon: Icons.work,
                          color: Colors.blue,
                          title: "Experience",
                          value: widget.doctor.experience ?? "5 Years",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statBox(
                          icon: Icons.attach_money,
                          color: Colors.teal,
                          title: "Consultation Fee",
                          value: "\$${widget.doctor.consultationFee ?? '50'}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    "Qualification",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.doctor.qualification ?? "MBBS, MD Clinical Residency",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Patient Reviews",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.rate_review, size: 16),
                        label: const Text("Write Review"),
                        onPressed: _showAddReviewBottomSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ================= REVIEWS STREAM =================
                  StreamBuilder<List<ReviewModel>>(
                    stream: _firestoreService.getDoctorReviews(widget.doctor.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reviews = snapshot.data ?? [];

                      if (reviews.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              "No reviews yet. Be the first to review!",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final rev = reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            borderOnForeground: false,
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        rev.patientName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < rev.rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 14,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rev.reviewText,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // ================= BOOK VISIT BUTTON =================
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookAppointmentScreen(
                        preSelectedDoctorId: widget.doctor.uid,
                        preSelectedDepartment: widget.doctor.department,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Book Consultation Visit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
