// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';

// import '../models/appointment_model.dart';
// import '../models/medical_record_model.dart';
// import '../models/prescription_model.dart';
// import '../models/user_model.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // ================= DEPARTMENTS =================

//   // Get departments
//   Stream<List<String>> getDepartments() {
//     return _db.collection('departments').snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) => doc.id).toList();
//     });
//   }

//   // Add department
//   Future<void> addDepartment(String name) async {
//     await _db.collection('departments').doc(name.trim()).set({});
//   }

//   // ================= DOCTORS =================

//   // Get all doctors
//   Stream<List<UserModel>> getDoctors() {
//     return _db
//         .collection('users')
//         .where('role', isEqualTo: 'doctor')
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => UserModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }

//   // Get doctors by department
//   Stream<List<UserModel>> getDoctorsByDepartment(String department) {
//     return _db
//         .collection('users')
//         .where('role', isEqualTo: 'doctor')
//         .where('department', isEqualTo: department)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => UserModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }

//   // Add a new doctor (uses secondary FirebaseApp to avoid signing out Admin)
//   Future<void> addDoctor({
//     required String name,
//     required String email,
//     required String password,
//     required String department,
//     required String specialization,
//   }) async {
//     String tempAppName =
//         "TempDoctorRegister_${DateTime.now().millisecondsSinceEpoch}";

//     // Create temporary app instance
//     FirebaseApp tempApp = await Firebase.initializeApp(
//       name: tempAppName,
//       options: Firebase.app().options,
//     );

//     try {
//       // Create doctor auth account in temporary app
//       UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp)
//           .createUserWithEmailAndPassword(
//             email: email.trim(),
//             password: password.trim(),
//           );

//       // Save user record under target uid in main Firestore
//       UserModel doctor = UserModel(
//         uid: cred.user!.uid,
//         name: name.trim(),
//         email: email.trim(),
//         role: 'doctor',
//         department: department,
//         specialization: specialization,
//       );

//       await _db.collection('users').doc(cred.user!.uid).set(doctor.toMap());
//     } finally {
//       // Clean up temporary app instance
//       await tempApp.delete();
//     }
//   }

//   // ================= APPOINTMENTS =================

//   // // Book an appointment
//   // Future<void> bookAppointment(AppointmentModel appointment) async {
//   //   await _db.collection('appointments').add(appointment.toMap());
//   // }

//   // // Update appointment status
//   // Future<void> updateAppointmentStatus(String id, String status) async {
//   //   await _db.collection('appointments').doc(id).update({'status': status});
//   // }

//   // // Get appointments for patient
//   // Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
//   //   return _db
//   //       .collection('appointments')
//   //       .where('patientId', isEqualTo: patientId)
//   //       .snapshots()
//   //       .map((snapshot) {
//   //     return snapshot.docs
//   //         .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
//   //         .toList();
//   //   });
//   // }

//   // // Get appointments for doctor
//   // Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
//   //   return _db
//   //       .collection('appointments')
//   //       .where('doctorId', isEqualTo: doctorId)
//   //       .snapshots()
//   //       .map((snapshot) {
//   //     return snapshot.docs
//   //         .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
//   //         .toList();
//   //   });
//   // }

//   // // Get all appointments (Admin)
//   // Stream<List<AppointmentModel>> getAllAppointments() {
//   //   return _db.collection('appointments').snapshots().map((snapshot) {
//   //     return snapshot.docs
//   //         .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
//   //         .toList();
//   //   });
//   // }

//   // ================= APPOINTMENTS =================

//   // Book an appointment
//   Future<void> bookAppointment(AppointmentModel appointment) async {
//     await _db.collection('appointments').add(appointment.toMap());
//   }

//   // Update appointment status
//   Future<void> updateAppointmentStatus(String id, String status) async {
//     await _db.collection('appointments').doc(id).update({
//       'status': status.toLowerCase(),
//     });
//   }

//   // Get appointments for patient
//   Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
//     return _db
//         .collection('appointments')
//         .where('patientId', isEqualTo: patientId)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }

//   // Get appointments for doctor
//   Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
//     return _db
//         .collection('appointments')
//         .where('doctorId', isEqualTo: doctorId)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }

//   // Get all appointments (Admin)
//   Stream<List<AppointmentModel>> getAllAppointments() {
//     return _db.collection('appointments').snapshots().map((snapshot) {
//       return snapshot.docs
//           .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
//           .toList();
//     });
//   }

//   // ================= PRESCRIPTIONS =================

//   // Save prescription
//   Future<void> addPrescription(PrescriptionModel prescription) async {
//     await _db.collection('prescriptions').add(prescription.toMap());
//   }

//   // Stream patient prescriptions
//   Stream<List<PrescriptionModel>> getPatientPrescriptions(String patientId) {
//     return _db
//         .collection('prescriptions')
//         .where('patientId', isEqualTo: patientId)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => PrescriptionModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }

//   // ================= MEDICAL RECORDS =================

//   // Save medical record
//   Future<void> addMedicalRecord(MedicalRecordModel record) async {
//     await _db.collection('medical_records').add(record.toMap());
//   }

//   // Stream patient medical records
//   Stream<List<MedicalRecordModel>> getPatientMedicalRecords(String patientId) {
//     return _db
//         .collection('medical_records')
//         .where('patientId', isEqualTo: patientId)
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }

//   // ================= STATS HELPERS =================

//   // Stream user counts (Admin dashboard/doctor stats)
//   Stream<int> getUserCount(String role) {
//     return _db
//         .collection('users')
//         .where('role', isEqualTo: role)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length);
//   }

//   // Stream patient list (for dropdowns/lists)
//   Stream<List<UserModel>> getPatients() {
//     return _db
//         .collection('users')
//         .where('role', isEqualTo: 'patient')
//         .snapshots()
//         .map((snapshot) {
//           return snapshot.docs
//               .map((doc) => UserModel.fromMap(doc.data(), doc.id))
//               .toList();
//         });
//   }
// }

// // ================= DASHBOARD =================

// Stream<int> totalDoctors() {
//   return getUserCount('doctor');
// }

// Stream<int> totalPatients() {
//   return getUserCount('patient');
// }

// Stream<int> totalAppointments() {
//   return _db
//       .collection('appointments')
//       .snapshots()
//       .map((e) => e.docs.length);
// }

// Stream<int> totalPrescriptions() {
//   return _db
//       .collection('prescriptions')
//       .snapshots()
//       .map((e) => e.docs.length);
// }

// // ================= APPOINTMENT CHECK =================

// Future<bool> slotAlreadyBooked({
//   required String doctorId,
//   required String date,
//   required String time,
// }) async {
//   final result = await _db
//       .collection('appointments')
//       .where('doctorId', isEqualTo: doctorId)
//       .where('date', isEqualTo: date)
//       .where('time', isEqualTo: time)
//       .get();

//   return result.docs.isNotEmpty;
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/appointment_model.dart';
import '../models/medical_record_model.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =====================================
  // DEPARTMENTS
  // ====================================

  Stream<List<String>> getDepartments() {
    return _db
        .collection('departments')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => e.id).toList());
  }

  Future<void> addDepartment(String name) async {
    await _db.collection('departments').doc(name.trim()).set({});
  }

  // =====================================
  // USERS / DOCTORS / PATIENTS
  // =====================================

  Stream<List<UserModel>> getDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<UserModel>> getPatients() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<UserModel>> getDoctorsByDepartment(String department) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('department', isEqualTo: department)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<UserModel>> searchPatients(String keyword) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .where(
                (u) => u.name.toLowerCase().contains(keyword.toLowerCase()),
              )
              .toList();
        });
  }

  // =====================================
  // DOCTOR CREATION (ADMIN)
  // =====================================

  Future<void> addDoctor({
    required String name,
    required String email,
    required String password,
    required String department,
    required String specialization,
  }) async {
    final tempAppName = "TempDoctor_${DateTime.now().millisecondsSinceEpoch}";

    final tempApp = await Firebase.initializeApp(
      name: tempAppName,
      options: Firebase.app().options,
    );

    try {
      final cred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      final doctor = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        role: 'doctor',
        department: department,
        specialization: specialization,
      );

      await _db.collection('users').doc(doctor.uid).set(doctor.toMap());
    } finally {
      await tempApp.delete();
    }
  }

  // =====================================
  // APPOINTMENTS CORE
  // =====================================

  Future<bool> isSlotBooked({
    required String doctorId,
    required String date,
    required String time,
  }) async {
    final snap = await _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isEqualTo: date)
        .where('time', isEqualTo: time)
        .get();

    return snap.docs.isNotEmpty;
  }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    final conflict = await isSlotBooked(
      doctorId: appointment.doctorId,
      date: appointment.date,
      time: appointment.time,
    );

    if (conflict) {
      throw Exception("This time slot is already booked");
    }

    await _db.collection('appointments').add(appointment.toMap());
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _db.collection('appointments').doc(id).update({
      'status': status.toLowerCase(),
    });
  }

  Future<void> cancelAppointment(String id) async {
    await _db.collection('appointments').doc(id).update({
      'status': 'cancelled',
    });
  }

  Future<void> deleteAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
  }

  // =====================================
  // APPOINTMENT STREAMS
  // =====================================

  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _db
        .collection('appointments')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getCompletedAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<AppointmentModel>> getPendingAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // =====================================
  // PRESCRIPTIONS
  // =====================================

  Future<void> addPrescription(PrescriptionModel prescription) async {
    await _db.collection('prescriptions').add(prescription.toMap());
  }

  Stream<List<PrescriptionModel>> getPatientPrescriptions(String patientId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PrescriptionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // =====================================
  // MEDICAL RECORDS
  // =====================================

  Future<void> addMedicalRecord(MedicalRecordModel record) async {
    await _db.collection('medical_records').add(record.toMap());
  }

  Stream<List<MedicalRecordModel>> getPatientMedicalRecords(String patientId) {
    return _db
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MedicalRecordModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // =====================================
  // DASHBOARD STATS
  // =====================================

  Stream<int> getUserCount(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> getTotalAppointments() {
    return _db
        .collection('appointments')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> getTotalPrescriptions() {
    return _db
        .collection('prescriptions')
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
