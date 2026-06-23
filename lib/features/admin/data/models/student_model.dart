import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String rollNumber;
  final String className;
  final String section;
  final String? guardianName;
  final String? guardianPhone;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  StudentModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.rollNumber,
    required this.className,
    required this.section,
    this.guardianName,
    this.guardianPhone,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
  }) : fullName = '$firstName $lastName';

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      className: data['className'] ?? '',
      section: data['section'] ?? '',
      guardianName: data['guardianName'],
      guardianPhone: data['guardianPhone'],
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'rollNumber': rollNumber,
      'className': className,
      'section': section,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}