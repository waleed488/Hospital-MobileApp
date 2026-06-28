import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;

  final String patientId;
  final String patientName;

  final String doctorId;
  final String doctorName;

  final String department;

  final String date;
  final String time;

  String status;

  final String? diagnosis;
  final String? symptoms;
  final String? consultationNotes;

  final bool prescriptionCreated;
  final DateTime? createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.date,
    required this.time,
    required this.status,
    this.diagnosis,
    this.symptoms,
    this.consultationNotes,
    this.prescriptionCreated = false,
    this.createdAt,
  });

  // ================= SAFE FROM FIRESTORE =================

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      department: map['department'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      status: _normalizeStatus(map['status']),
      diagnosis: map['diagnosis'],
      symptoms: map['symptoms'],
      consultationNotes: map['consultationNotes'],
      prescriptionCreated: map['prescriptionCreated'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'department': department,
      'date': date,
      'time': time,
      'status': status.toLowerCase(),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'consultationNotes': consultationNotes,
      'prescriptionCreated': prescriptionCreated,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // ================= STATUS NORMALIZATION =================

  static String _normalizeStatus(dynamic status) {
    final s = (status ?? 'pending').toString().toLowerCase();

    switch (s) {
      case 'pending':
        return 'pending';
      case 'approved':
        return 'approved';
      case 'in_consultation':
        return 'in_consultation';
      case 'completed':
        return 'completed';
      case 'rejected':
        return 'rejected';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  // ================= HELPER GETTERS (IMPORTANT FOR UI) =================

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isInConsultation => status == 'in_consultation';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
}
