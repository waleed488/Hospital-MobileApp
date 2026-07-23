import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/appointment_model.dart';
import '../models/medical_record_model.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';
import '../models/medicine_reminder_model.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';

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
    // Get user to check role
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final role = userDoc.data()?['role'];
      if (role == 'doctor') {
        // Cascade delete doctor-related collections
        
        // Delete appointments
        final appointments = await _db.collection('appointments').where('doctorId', isEqualTo: uid).get();
        for (var doc in appointments.docs) {
          await doc.reference.delete();
        }

        // Delete prescriptions
        final prescriptions = await _db.collection('prescriptions').where('doctorId', isEqualTo: uid).get();
        for (var doc in prescriptions.docs) {
          await doc.reference.delete();
        }

        // Delete medical records
        final medicalRecords = await _db.collection('medical_records').where('doctorId', isEqualTo: uid).get();
        for (var doc in medicalRecords.docs) {
          await doc.reference.delete();
        }

        // Delete reviews
        final reviews = await _db.collection('reviews').where('doctorId', isEqualTo: uid).get();
        for (var doc in reviews.docs) {
          await doc.reference.delete();
        }

        // Remove from patients' favorites list
        final patients = await _db.collection('users').where('favoriteDoctors', arrayContains: uid).get();
        for (var doc in patients.docs) {
          await doc.reference.update({
            'favoriteDoctors': FieldValue.arrayRemove([uid])
          });
        }
      } else if (role == 'patient') {
        // Cascade delete patient-related collections
        
        // Delete appointments
        final appointments = await _db.collection('appointments').where('patientId', isEqualTo: uid).get();
        for (var doc in appointments.docs) {
          await doc.reference.delete();
        }

        // Delete prescriptions
        final prescriptions = await _db.collection('prescriptions').where('patientId', isEqualTo: uid).get();
        for (var doc in prescriptions.docs) {
          await doc.reference.delete();
        }

        // Delete medical records
        final medicalRecords = await _db.collection('medical_records').where('patientId', isEqualTo: uid).get();
        for (var doc in medicalRecords.docs) {
          await doc.reference.delete();
        }

        // Delete reviews
        final reviews = await _db.collection('reviews').where('patientId', isEqualTo: uid).get();
        for (var doc in reviews.docs) {
          await doc.reference.delete();
        }

        // Delete medicine reminders
        final reminders = await _db.collection('medicine_reminders').where('patientId', isEqualTo: uid).get();
        for (var doc in reminders.docs) {
          await doc.reference.delete();
        }

        // Delete notifications
        final notifications = await _db.collection('notifications').where('userId', isEqualTo: uid).get();
        for (var doc in notifications.docs) {
          await doc.reference.delete();
        }
      }
    }
    // Delete the user record itself
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // ================= ADMIN & STORAGE EXTENSIONS =================

  Future<String> uploadProfileImage(String uid, Uint8List imageBytes, String fileName) async {
    try {
      debugPrint("Starting profile image conversion to Base64 for user: $uid");
      final base64Str = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';

      debugPrint("Updating Firestore user record with Base64 image...");
      await _db.collection('users').doc(uid).update({
        'profileImage': base64Str,
      });

      debugPrint("Firestore user record updated with Base64 image successfully.");
      return base64Str;
    } catch (e) {
      debugPrint("Error storing profile image: $e");
      throw Exception("Failed to upload image: $e");
    }
  }

  Future<void> approveDoctor(String uid, bool approve) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': approve,
    });
  }

  Future<void> verifyDoctor(String uid, bool verify) async {
    await _db.collection('users').doc(uid).update({
      'isVerified': verify,
    });
  }

  Future<void> featureDoctor(String uid, bool feature) async {
    await _db.collection('users').doc(uid).update({
      'isFeatured': feature,
    });
  }

  Future<void> deleteReview(String reviewId, String doctorId) async {
    await _db.collection('reviews').doc(reviewId).delete();
    await recalculateDoctorRating(doctorId);
  }

  Future<void> recalculateDoctorRating(String doctorId) async {
    final reviewsSnap = await _db
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final approvedReviews = reviewsSnap.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .where((r) => r.isApproved)
        .toList();

    double avg = 5.0;
    if (approvedReviews.isNotEmpty) {
      double total = 0;
      for (var r in approvedReviews) {
        total += r.rating;
      }
      avg = total / approvedReviews.length;
    }

    await _db.collection('users').doc(doctorId).update({
      'rating': avg,
    });
  }

  Stream<List<ReviewModel>> getAllReviews() {
    return _db.collection('reviews').snapshots().map((snap) {
      return snap.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
          .toList();
    });
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
      'expired',
    ];

    if (!allowed.contains(normalized)) {
      throw Exception("Invalid status");
    }

    final doc = await _db.collection('appointments').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final app = AppointmentModel.fromMap(doc.data()!, doc.id);
      if (app.isExpired) {
        throw Exception("Cannot update status of an expired appointment");
      }
    }

    await _db.collection('appointments').doc(id).update({'status': normalized});
    await _createStatusNotification(id, normalized);
  }

  Future<void> _createStatusNotification(String appointmentId, String normalizedStatus) async {
    try {
      final doc = await _db.collection('appointments').doc(appointmentId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final patientId = data['patientId'] ?? '';
        final doctorName = data['doctorName'] ?? 'Doctor';
        final date = data['date'] ?? '';
        if (patientId.isNotEmpty) {
          String title = "Appointment Updated";
          String body = "Your appointment with Dr. $doctorName on $date is now $normalizedStatus.";
          if (normalizedStatus == 'approved') {
            title = "Appointment Approved 🎉";
            body = "Good news! Dr. $doctorName approved your appointment for $date.";
          } else if (normalizedStatus == 'cancelled') {
            title = "Appointment Cancelled ❌";
            body = "Your appointment with Dr. $doctorName on $date was cancelled.";
          } else if (normalizedStatus == 'rejected') {
            title = "Appointment Declined ⚠️";
            body = "Dr. $doctorName declined your appointment on $date.";
          } else if (normalizedStatus == 'completed') {
            title = "Appointment Completed ✅";
            body = "Your consultation with Dr. $doctorName is completed. Take care!";
          }
          await addNotification(
            userId: patientId,
            title: title,
            body: body,
            type: normalizedStatus,
          );
        }
      }
    } catch (e) {
      print("Failed to create status notification: $e");
    }
  }

  Future<void> startConsultation(String id) async {
    final doc = await _db.collection('appointments').doc(id).get();
    if (doc.exists && doc.data() != null) {
      final app = AppointmentModel.fromMap(doc.data()!, doc.id);
      if (app.isExpired) {
        throw Exception("Cannot start consultation for an expired appointment");
      }
    }
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
    await _createStatusNotification(appointmentId, 'completed');
  }

  Future<void> cancelAppointmentIfAllowed(AppointmentModel app) async {
    if (app.isExpired) {
      throw Exception("Cannot cancel an expired appointment");
    }
    final status = app.status.toLowerCase();

    if (status != 'pending' && status != 'approved') {
      throw Exception("Can only cancel pending or approved appointments");
    }

    await _db.collection('appointments').doc(app.id).update({
      'status': 'cancelled',
    });
    await _createStatusNotification(app.id, 'cancelled');
  }

  Future<void> updateAppointment(AppointmentModel app) async {
    await _db.collection('appointments').doc(app.id).set(app.toMap());
  }

  Future<void> deleteAppointment(String id) async {
    await _db.collection('appointments').doc(id).delete();
  }

  void _checkAndMarkExpired(AppointmentModel app) {
    if (app.status == 'pending' && app.isExpired) {
      app.status = 'expired';
      _db.collection('appointments').doc(app.id).update({'status': 'expired'}).catchError((e) {
        debugPrint("Failed to auto-expire appointment: $e");
      });
    }
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
                .map((d) {
                  final app = AppointmentModel.fromMap(d.data(), d.id);
                  _checkAndMarkExpired(app);
                  return app;
                })
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
                .map((d) {
                  final app = AppointmentModel.fromMap(d.data(), d.id);
                  _checkAndMarkExpired(app);
                  return app;
                })
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
            .map((d) {
              final app = AppointmentModel.fromMap(d.data(), d.id);
              _checkAndMarkExpired(app);
              return app;
            })
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
    await addNotification(
      userId: prescription.patientId,
      title: "Prescription Uploaded 💊",
      body: "Dr. ${prescription.doctorName} uploaded a new prescription for you.",
      type: 'prescription',
    );
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

  // ================= MEDICINE REMINDERS =================

  Stream<List<MedicineReminderModel>> getPatientMedicineReminders(String patientId) {
    return _db
        .collection('medicine_reminders')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => MedicineReminderModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => (a.time).compareTo(b.time));
          return list;
        });
  }

  Future<void> addMedicineReminder(MedicineReminderModel reminder) async {
    await _db.collection('medicine_reminders').add(reminder.toMap());
  }

  Future<void> deleteMedicineReminder(String id) async {
    await _db.collection('medicine_reminders').doc(id).delete();
  }

  Future<void> updateMedicineReminder(MedicineReminderModel reminder) async {
    await _db.collection('medicine_reminders').doc(reminder.id).update(reminder.toMap());
  }

  Future<void> markMedicineReminderAsTaken(String id, String todayDateStr, bool isTaken) async {
    await _db.collection('medicine_reminders').doc(id).update({
      'isTaken': isTaken,
      'lastTakenDate': todayDateStr,
    });
  }

  // ================= NOTIFICATIONS =================

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
    );
    await _db.collection('notifications').add(notification.toMap());
  }

  Future<void> markNotificationAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }

  Future<void> addDoctorReview(ReviewModel review) async {
    // Add review as pending status (default in review.toMap() isApproved=false)
    await _db.collection('reviews').add(review.toMap());
  }

  Future<void> approveReview(String reviewId, String doctorId) async {
    await _db.collection('reviews').doc(reviewId).update({'isApproved': true});
    await recalculateDoctorRating(doctorId);
  }

  Stream<List<ReviewModel>> getDoctorReviews(String doctorId) {
    return _db
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ReviewModel.fromMap(d.data(), d.id))
              .where((r) => r.isApproved) // Return only approved reviews for patient/public view
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<String> uploadDoctorDocument({
    required String uid,
    required String docType, // 'license', 'degree', 'certificate'
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      debugPrint("Starting doctor document conversion to Base64 for doctor: $uid, type: $docType");
      final base64Str = 'data:image/jpeg;base64,${base64Encode(fileBytes)}';

      String mappedFieldName = docType;
      if (docType == 'license') mappedFieldName = 'medicalLicenseUrl';
      else if (docType == 'degree') mappedFieldName = 'degreeUrl';
      else if (docType == 'certificate') mappedFieldName = 'certificateUrl';

      debugPrint("Updating Firestore doctor record with Base64 document...");
      await _db.collection('users').doc(uid).update({
        mappedFieldName: base64Str,
        'verificationStatus': 'pending',
      });

      debugPrint("Firestore doctor record updated with Base64 document successfully.");
      return base64Str;
    } catch (e) {
      debugPrint("Error storing doctor document: $e");
      throw Exception("Failed to upload document: $e");
    }
  }

  Future<void> updateDoctorVerification(String uid, String status) async {
    final bool isVerified = (status == 'verified');
    await _db.collection('users').doc(uid).update({
      'verificationStatus': status,
      'isVerified': isVerified,
    });
  }

  // ================= FAVORITE DOCTORS =================

  Future<void> toggleFavoriteDoctor(String patientId, String doctorId, bool isFavorite) async {
    final docRef = _db.collection('users').doc(patientId);
    if (isFavorite) {
      await docRef.update({
        'favoriteDoctors': FieldValue.arrayUnion([doctorId]),
      });
    } else {
      await docRef.update({
        'favoriteDoctors': FieldValue.arrayRemove([doctorId]),
      });
    }
  }

  // ================= ADMIN STATS HELPERS =================

  Stream<int> getTodaysAppointmentsCount() {
    final todayStr = DateTime.now().toString().split(' ')[0];
    return _db
        .collection('appointments')
        .where('date', isEqualTo: todayStr)
        .snapshots()
        .map((snap) => snap.size);
  }

  Stream<int> getAppointmentsCountByStatus(String status) {
    return _db
        .collection('appointments')
        .where('status', isEqualTo: status.toLowerCase())
        .snapshots()
        .map((snap) => snap.size);
  }
}
