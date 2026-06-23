import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String subject;
  final String? phone;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  TeacherModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.subject,
    this.phone,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
  }) : fullName = '$firstName $lastName';

  factory TeacherModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      subject: data['subject'] ?? '',
      phone: data['phone'],
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
      'subject': subject,
      'phone': phone,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}