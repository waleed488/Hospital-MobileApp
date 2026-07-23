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
      case 'expired':
        return 'expired';
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
  bool get isExpiredStatus => status == 'expired';

  DateTime? get scheduledDateTime {
    if (date.isEmpty) return null;
    try {
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate == null) return null;

      int hour = 0;
      int minute = 0;
      if (time.isNotEmpty) {
        final timeTrimmed = time.trim().toUpperCase();
        final isPm = timeTrimmed.contains('PM');
        final isAm = timeTrimmed.contains('AM');
        final cleanTime = timeTrimmed.replaceAll(RegExp(r'[^\d:]'), '');
        final parts = cleanTime.split(':');
        if (parts.isNotEmpty) {
          hour = int.tryParse(parts[0]) ?? 0;
          if (parts.length > 1) {
            minute = int.tryParse(parts[1]) ?? 0;
          }
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      }
      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool get isExpired {
    if (status == 'expired') return true;
    if (status == 'pending') {
      final dt = scheduledDateTime;
      if (dt != null && DateTime.now().isAfter(dt)) {
        return true;
      }
    }
    return false;
  }
}
