class PrescriptionModel {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String medicine;
  final String dosage;
  final String duration;
  final String notes;
  final String date;

  PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.medicine,
    required this.dosage,
    required this.duration,
    required this.notes,
    required this.date,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return PrescriptionModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      medicine: map['medicine'] ?? '',
      dosage: map['dosage'] ?? '',
      duration: map['duration'] ?? '',
      notes: map['notes'] ?? '',
      date: map['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'medicine': medicine,
      'dosage': dosage,
      'duration': duration,
      'notes': notes,
      'date': date,
    };
  }
}
