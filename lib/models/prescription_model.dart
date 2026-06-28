import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionModel {
  final String id;
  final String appointmentId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String medicine;
  final String dosage;
  final String duration;
  final String notes;
  final String date;
  final DateTime? createdAt;

  PrescriptionModel({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicine,
    required this.dosage,
    required this.duration,
    required this.notes,
    required this.date,
    this.createdAt,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return PrescriptionModel(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medicine: map['medicine'] ?? '',
      dosage: map['dosage'] ?? '',
      duration: map['duration'] ?? '',
      notes: map['notes'] ?? '',
      date: map['date'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'medicine': medicine,
      'dosage': dosage,
      'duration': duration,
      'notes': notes,
      'date': date,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
