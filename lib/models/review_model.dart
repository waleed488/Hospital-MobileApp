import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final double rating; // 1.0 to 5.0
  final String reviewText;
  final bool isApproved;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.rating,
    required this.reviewText,
    this.isApproved = false,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? 'Patient',
      rating: (map['rating'] ?? 5.0) is int
          ? (map['rating'] as int).toDouble()
          : (map['rating'] as double),
      reviewText: map['reviewText'] ?? '',
      isApproved: map['isApproved'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'rating': rating,
      'reviewText': reviewText,
      'isApproved': isApproved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
