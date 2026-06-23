import 'package:cloud_firestore/cloud_firestore.dart';

class StudentMark {
  final String studentId;
  final String rollNumber;
  final String studentName;
  final double obtainedMarks;
  final double totalMarks;
  final String grade;
  final double percentage;

  StudentMark({
    required this.studentId,
    required this.rollNumber,
    required this.studentName,
    required this.obtainedMarks,
    required this.totalMarks,
    required this.grade,
    required this.percentage,
  });

  factory StudentMark.fromMap(Map<String, dynamic> map) {
    return StudentMark(
      studentId: map['studentId'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      studentName: map['studentName'] ?? '',
      obtainedMarks: (map['obtainedMarks'] ?? 0).toDouble(),
      totalMarks: (map['totalMarks'] ?? 0).toDouble(),
      grade: map['grade'] ?? 'F',
      percentage: (map['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'rollNumber': rollNumber,
      'studentName': studentName,
      'obtainedMarks': obtainedMarks,
      'totalMarks': totalMarks,
      'grade': grade,
      'percentage': percentage,
    };
  }
}

class ResultModel {
  final String id;
  final String examName;
  final String className;
  final String section;
  final String subject;
  final String teacherId;
  final DateTime createdAt;
  final List<StudentMark> marks;

  ResultModel({
    required this.id,
    required this.examName,
    required this.className,
    required this.section,
    required this.subject,
    required this.teacherId,
    required this.createdAt,
    required this.marks,
  });

  double get classAverage => marks.isEmpty
      ? 0
      : marks.map((m) => m.percentage).reduce((a, b) => a + b) / marks.length;

  factory ResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final marksList = (data['marks'] as List<dynamic>?)
        ?.map((m) => StudentMark.fromMap(m as Map<String, dynamic>))
        .toList() ?? [];

    return ResultModel(
      id: doc.id,
      examName: data['examName'] ?? '',
      className: data['className'] ?? '',
      section: data['section'] ?? '',
      subject: data['subject'] ?? '',
      teacherId: data['teacherId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      marks: marksList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'examName': examName,
      'className': className,
      'section': section,
      'subject': subject,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
      'marks': marks.map((m) => m.toMap()).toList(),
    };
  }
}