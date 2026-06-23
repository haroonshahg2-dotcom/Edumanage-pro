import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  final String id;
  final String title;
  final String description;
  final String type; // fee_due, exam, meeting, holiday, event
  final DateTime date;
  final String? relatedUserId; // For fee events - student id
  final String? className;
  final String? section;
  final String createdBy;
  final DateTime createdAt;

  CalendarEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    this.relatedUserId,
    this.className,
    this.section,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isFeeEvent => type == 'fee_due';
  bool get isExam => type == 'exam';
  bool get isHoliday => type == 'holiday';

  factory CalendarEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'event',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedUserId: data['relatedUserId'],
      className: data['className'],
      section: data['section'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'date': Timestamp.fromDate(date),
      'relatedUserId': relatedUserId,
      'className': className,
      'section': section,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}