import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String type; // general, urgent, exam, fee, holiday
  final String targetAudience; // all, teachers, students
  final String createdBy;
  final DateTime createdAt;
  final bool isActive;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.targetAudience,
    required this.createdBy,
    required this.createdAt,
    this.isActive = true,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      targetAudience: data['targetAudience'] ?? 'all',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetAudience': targetAudience,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}