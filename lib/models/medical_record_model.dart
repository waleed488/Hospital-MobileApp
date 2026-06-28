import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String diagnosis;
  final String symptoms;
  final String notes;
  final String date;
  final DateTime? createdAt;

  MedicalRecordModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.diagnosis,
    required this.symptoms,
    required this.notes,
    required this.date,
    this.createdAt,
  });

  factory MedicalRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicalRecordModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      symptoms: map['symptoms'] ?? '',
      notes: map['notes'] ?? '',
      date: map['date'] ?? '',
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
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'notes': notes,
      'date': date,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}