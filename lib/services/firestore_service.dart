import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/appointment_model.dart';
import '../models/medical_record_model.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= DEPARTMENTS =================

  Stream<List<String>> getDepartments() {
    return _db
        .collection('departments')
        .snapshots()
        .map((snap) => snap.docs.map((e) => e.id).toList());
  }

  Future<void> addDepartment(String name) async {
    await _db.collection('departments').doc(name.trim()).set({});
  }

  Future<void> deleteDepartment(String name) async {
    await _db.collection('departments').doc(name.trim()).delete();
  }

  // ================= USERS =================

  Stream<List<UserModel>> getDoctors() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<UserModel>> getPatients() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<UserModel>> getDoctorsByDepartment(String department) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('department', isEqualTo: department)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<int> getUserCount(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

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

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // ================= APPOINTMENTS =================

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
      throw Exception("Slot already booked");
    }

    await _db.collection('appointments').add(appointment.toMap());
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    final normalized = status.toLowerCase();

    const allowed = [
      'pending',
      'approved',
      'in_consultation',
      'completed',
      'rejected',
      'cancelled',
    ];

    if (!allowed.contains(normalized)) {
      throw Exception("Invalid status");
    }

    await _db.collection('appointments').doc(id).update({'status': normalized});
  }

  Future<void> startConsultation(String id) async {
    await _db.collection('appointments').doc(id).update({
      'status': 'in_consultation',
    });
  }

  Future<void> completeConsultation({
    required String appointmentId,
    required String diagnosis,
    required String symptoms,
    required String notes,
  }) async {
    final doc = await _db.collection('appointments').doc(appointmentId).get();
    if (!doc.exists) throw Exception("Appointment not found");
    final app = AppointmentModel.fromMap(doc.data()!, doc.id);

    final medicalRecord = MedicalRecordModel(
      id: '',
      patientId: app.patientId,
      patientName: app.patientName,
      doctorId: app.doctorId,
      doctorName: app.doctorName,
      diagnosis: diagnosis,
      symptoms: symptoms,
      notes: notes,
      date: DateTime.now().toString().split(' ')[0],
    );
    await addMedicalRecord(medicalRecord);

    await _db.collection('appointments').doc(appointmentId).update({
      'status': 'completed',
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'consultationNotes': notes,
    });
  }

  Future<void> cancelAppointmentIfAllowed(AppointmentModel app) async {
    final status = app.status.toLowerCase();

    if (status != 'pending' && status != 'approved') {
      throw Exception("Can only cancel pending or approved appointments");
    }

    await _db.collection('appointments').doc(app.id).update({
      'status': 'cancelled',
    });
  }

  Future<void> updateAppointment(AppointmentModel app) async {
    await _db.collection('appointments').doc(app.id).set(app.toMap());
  }

  Future<void> deleteAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
  }

  // ================= STREAMS =================

  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => AppointmentModel.fromMap(d.data(), d.id))
                .toList();
            list.sort((a, b) {
              final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA); // newest first
            });
            return list;
          },
        );
  }

  Stream<List<AppointmentModel>> getDoctorAppointments(String doctorId) {
    return _db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => AppointmentModel.fromMap(d.data(), d.id))
                .toList();
            list.sort((a, b) {
              final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA); // newest first
            });
            return list;
          },
        );
  }

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _db.collection('appointments').snapshots().map(
      (snap) {
        final list = snap.docs
            .map((d) => AppointmentModel.fromMap(d.data(), d.id))
            .toList();
        list.sort((a, b) {
          final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA); // newest first
        });
        return list;
      },
    );
  }

  // ================= PRESCRIPTIONS =================

  Future<void> addPrescription(PrescriptionModel prescription) async {
    await _db.collection('prescriptions').add(prescription.toMap());
    if (prescription.appointmentId.isNotEmpty) {
      await _db
          .collection('appointments')
          .doc(prescription.appointmentId)
          .update({'prescriptionCreated': true});
    }
  }

  Stream<List<PrescriptionModel>> getPatientPrescriptions(String patientId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => PrescriptionModel.fromMap(d.data(), d.id))
                .toList();
            list.sort((a, b) {
              final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA); // newest first
            });
            return list;
          },
        );
  }

  // ================= MEDICAL RECORDS =================

  Future<void> addMedicalRecord(MedicalRecordModel record) async {
    await _db.collection('medical_records').add(record.toMap());
  }

  Stream<List<MedicalRecordModel>> getPatientMedicalRecords(String patientId) {
    return _db
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => MedicalRecordModel.fromMap(d.data(), d.id))
                .toList();
            list.sort((a, b) {
              final dateA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final dateB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return dateB.compareTo(dateA); // newest first
            });
            return list;
          },
        );
  }
}
