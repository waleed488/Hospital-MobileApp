import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineReminderModel {
  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String time;
  final String frequency;
  final bool isTaken;
  final String lastTakenDate; // e.g. "2026-07-02" to reset status daily
  final DateTime? createdAt;

  MedicineReminderModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.time,
    required this.frequency,
    this.isTaken = false,
    this.lastTakenDate = '',
    this.createdAt,
  });

  factory MedicineReminderModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicineReminderModel(
      id: id,
      patientId: map['patientId'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      time: map['time'] ?? '',
      frequency: map['frequency'] ?? 'Daily',
      isTaken: map['isTaken'] ?? false,
      lastTakenDate: map['lastTakenDate'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'dosage': dosage,
      'time': time,
      'frequency': frequency,
      'isTaken': isTaken,
      'lastTakenDate': lastTakenDate,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  MedicineReminderModel copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dosage,
    String? time,
    String? frequency,
    bool? isTaken,
    String? lastTakenDate,
    DateTime? createdAt,
  }) {
    return MedicineReminderModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      isTaken: isTaken ?? this.isTaken,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
