// import 'package:cloud_firestore/cloud_firestore.dart';

// class UserModel {
//   final String uid;
//   final String name;
//   final String email;
//   final String role;
//   final String? department;
//   final String? specialization;
//   final DateTime? createdAt;

//   UserModel({
//     required this.uid,
//     required this.name,
//     required this.email,
//     required this.role,
//     this.department,
//     this.specialization = 'null',
//     this.createdAt,
//   });

//   factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
//     return UserModel(
//       uid: uid,
//       name: map['name'] ?? '',
//       email: map['email'] ?? '',
//       role: map['role'] ?? 'patient',
//       department: map['department'] ?? '',
//       specialization: map['specialization'] ?? '',
//       createdAt: map['createdAt'] != null
//           ? (map['createdAt'] as Timestamp).toDate()
//           : null,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'name': name,
//       'email': email,
//       'role': role,
//       'department': department,
//       'specialization': specialization,
//       'createdAt': FieldValue.serverTimestamp(),
//     };
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;

  final String name;
  final String email;
  final String role;

  final String? department;
  final String? specialization;

  final String? phone;
  final String? age;
  final String? gender;
  final String? bloodGroup;

  final String? qualification;
  final String? experience;

  final String? profileImage;

  // New Patient Profile fields
  final String? height;
  final String? weight;
  final String? allergies;
  final String? chronicDiseases;
  final String? emergencyContact;
  final String? dateOfBirth;
  final List<String>? favoriteDoctors;

  // New Doctor fields
  final String? consultationFee;
  final String? availabilityStatus; // "Available Today", "Busy", "On Leave"

  // New Doctor verification document fields
  final String? medicalLicenseUrl;
  final String? degreeUrl;
  final String? certificateUrl;
  final String? verificationStatus; // "unverified", "pending", "verified", "rejected"

  // Admin & Security fields
  final bool isApproved;
  final bool isVerified;
  final bool isFeatured;
  final String? address;
  final String? bio;
  final List<String>? availableSlots;

  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,

    this.department,
    this.specialization,

    this.phone,
    this.age,
    this.gender,
    this.bloodGroup,

    this.qualification,
    this.experience,

    this.profileImage,

    this.height,
    this.weight,
    this.allergies,
    this.chronicDiseases,
    this.emergencyContact,
    this.dateOfBirth,
    this.favoriteDoctors,

    this.consultationFee,
    this.availabilityStatus,

    this.medicalLicenseUrl,
    this.degreeUrl,
    this.certificateUrl,
    this.verificationStatus = 'unverified',

    this.isApproved = true,
    this.isVerified = false,
    this.isFeatured = false,
    this.address,
    this.bio,
    this.availableSlots,

    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',

      department: map['department'],
      specialization: map['specialization'],

      phone: map['phone'],
      age: map['age'],
      gender: map['gender'],
      bloodGroup: map['bloodGroup'],

      qualification: map['qualification'],
      experience: map['experience'],

      profileImage: map['profileImage'],

      height: map['height'],
      weight: map['weight'],
      allergies: map['allergies'],
      chronicDiseases: map['chronicDiseases'],
      emergencyContact: map['emergencyContact'],
      dateOfBirth: map['dateOfBirth'],
      favoriteDoctors: map['favoriteDoctors'] != null
          ? List<String>.from(map['favoriteDoctors'])
          : [],

      consultationFee: map['consultationFee'],
      availabilityStatus: map['availabilityStatus'] ?? 'Available Today',

      medicalLicenseUrl: map['medicalLicenseUrl'],
      degreeUrl: map['degreeUrl'],
      certificateUrl: map['certificateUrl'],
      verificationStatus: map['verificationStatus'] ?? 'unverified',

      isApproved: map['isApproved'] ?? (map['role'] == 'doctor' ? false : true),
      isVerified: map['isVerified'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      address: map['address'],
      bio: map['bio'],
      availableSlots: map['availableSlots'] != null
          ? List<String>.from(map['availableSlots'])
          : null,

      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,

      'name': name,
      'email': email,
      'role': role,

      'department': department,
      'specialization': specialization,

      'phone': phone,
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,

      'qualification': qualification,
      'experience': experience,

      'profileImage': profileImage,

      'height': height,
      'weight': weight,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'emergencyContact': emergencyContact,
      'dateOfBirth': dateOfBirth,
      'favoriteDoctors': favoriteDoctors ?? [],

      'consultationFee': consultationFee,
      'availabilityStatus': availabilityStatus ?? 'Available Today',

      'medicalLicenseUrl': medicalLicenseUrl,
      'degreeUrl': degreeUrl,
      'certificateUrl': certificateUrl,
      'verificationStatus': verificationStatus ?? 'unverified',

      'isApproved': isApproved,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'address': address,
      'bio': bio,
      'availableSlots': availableSlots ?? [],

      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
