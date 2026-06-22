// class AppointmentModel {
//   final String id;
//   final String patientId;
//   final String patientName;
//   final String doctorId;
//   final String doctorName;
//   final String department;
//   final String date;
//   final String time;

//   String status;
//   // pending | approved | in_consultation | completed | rejected | cancelled

//   AppointmentModel({
//     required this.id,
//     required this.patientId,
//     required this.patientName,
//     required this.doctorId,
//     required this.doctorName,
//     required this.department,
//     required this.date,
//     required this.time,
//     required this.status,
//   });

//   factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
//     return AppointmentModel(
//       id: id,
//       patientId: map['patientId'] ?? '',
//       patientName: map['patientName'] ?? '',
//       doctorId: map['doctorId'] ?? '',
//       doctorName: map['doctorName'] ?? '',
//       department: map['department'] ?? '',
//       date: map['date'] ?? '',
//       time: map['time'] ?? '',
//       status: _normalizeStatus(map['status']),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'patientId': patientId,
//       'patientName': patientName,
//       'doctorId': doctorId,
//       'doctorName': doctorName,
//       'department': department,
//       'date': date,
//       'time': time,
//       'status': status.toLowerCase(),
//     };
//   }

//   /// Ensures old data like "Approved" or "APPROVED" still works
//   static String _normalizeStatus(dynamic status) {
//     final s = (status ?? 'pending').toString().toLowerCase();

//     switch (s) {
//       case 'approved':
//       case 'in_consultation':
//       case 'completed':
//       case 'rejected':
//       case 'cancelled':
//         return s;
//       default:
//         return 'pending';
//     }
//   }

//   /// Helper getters (VERY useful for UI later)
//   bool get isPending => status == 'pending';
//   bool get isApproved => status == 'approved';
//   bool get isInConsultation => status == 'in_consultation';
//   bool get isCompleted => status == 'completed';
//   bool get isRejected => status == 'rejected';
//   bool get isCancelled => status == 'cancelled';
// }

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
  final String? consultationNotes;

  final bool prescriptionCreated;

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
    this.consultationNotes,
    this.prescriptionCreated = false,
  });

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
      status: (map['status'] ?? 'pending').toString().toLowerCase(),
      diagnosis: map['diagnosis'],
      consultationNotes: map['consultationNotes'],
      prescriptionCreated: map['prescriptionCreated'] ?? false,
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
      'consultationNotes': consultationNotes,
      'prescriptionCreated': prescriptionCreated,
    };
  }
}
