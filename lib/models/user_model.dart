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

      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
