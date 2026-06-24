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

  // ================= 🔥 ADDED: USER COUNTS =================

  Stream<int> getUserCount(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // ================= DOCTOR CREATE =================

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

  Future<void> cancelAppointmentIfAllowed(AppointmentModel app) async {
    final status = app.status.toLowerCase();

    if (status == 'completed' || status == 'in_consultation') {
      throw Exception("Cannot cancel after consultation started");
    }

    await _db.collection('appointments').doc(app.id).update({
      'status': 'cancelled',
    });
  }

  // ================= STREAMS =================

  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppointmentModel.fromMap(d.data(), d.id))
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
              .map((d) => AppointmentModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ================= 🔥 ADDED: ALL APPOINTMENTS =================

  Stream<List<AppointmentModel>> getAllAppointments() {
    return _db
        .collection('appointments')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppointmentModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  // ================= PRESCRIPTIONS =================

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
              .map((d) => PrescriptionModel.fromMap(d.data(), d.id))
              .toList(),
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
          (snap) => snap.docs
              .map((d) => MedicalRecordModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}
