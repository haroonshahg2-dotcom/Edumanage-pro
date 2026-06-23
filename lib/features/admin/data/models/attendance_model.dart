import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAttendance {
  final String studentId;
  final String rollNumber;
  final String name;
  final String status; // present, absent, leave

  StudentAttendance({
    required this.studentId,
    required this.rollNumber,
    required this.name,
    required this.status,
  });

  factory StudentAttendance.fromMap(Map<String, dynamic> map) {
    return StudentAttendance(
      studentId: map['studentId'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? 'absent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'rollNumber': rollNumber,
      'name': name,
      'status': status,
    };
  }
}

class AttendanceModel {
  final String id;
  final DateTime date;
  final String className;
  final String section;
  final String markedBy; // teacher uid
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final List<StudentAttendance> students;

  AttendanceModel({
    required this.id,
    required this.date,
    required this.className,
    required this.section,
    required this.markedBy,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.students,
  });

  double get attendancePercentage =>
      totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0;

  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final studentsList = (data['students'] as Map<String, dynamic>?)?.entries.map((e) {
      return StudentAttendance(
        studentId: e.key,
        rollNumber: (e.value as Map)['rollNumber'] ?? '',
        name: (e.value as Map)['name'] ?? '',
        status: (e.value as Map)['status'] ?? 'absent',
      );
    }).toList() ?? [];

    return AttendanceModel(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      className: data['className'] ?? '',
      section: data['section'] ?? '',
      markedBy: data['markedBy'] ?? '',
      totalStudents: data['totalStudents'] ?? 0,
      presentCount: data['presentCount'] ?? 0,
      absentCount: data['absentCount'] ?? 0,
      students: studentsList,
    );
  }

  Map<String, dynamic> toFirestore() {
    final studentsMap = <String, dynamic>{};
    for (var s in students) {
      studentsMap[s.studentId] = {
        'rollNumber': s.rollNumber,
        'name': s.name,
        'status': s.status,
      };
    }

    return {
      'date': Timestamp.fromDate(date),
      'className': className,
      'section': section,
      'markedBy': markedBy,
      'totalStudents': totalStudents,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'students': studentsMap,
    };
  }
}