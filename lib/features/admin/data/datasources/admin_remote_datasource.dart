import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edumanage/core/services/password_generator.dart';
import 'package:edumanage/features/admin/data/models/teacher_model.dart';
import 'package:edumanage/features/admin/data/models/student_model.dart';
import 'package:edumanage/features/admin/data/models/announcement_model.dart';
import 'package:edumanage/features/admin/data/models/calender_event_model.dart';
import 'package:edumanage/features/admin/data/models/attendance_model.dart';
import 'package:edumanage/features/admin/data/models/result_model.dart';

class AdminRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminRemoteDataSource(this._auth, this._firestore);

  // ========== EXISTING METHODS (Unchanged) ==========

  Stream<int> getTotalStudentsStream() {
    return _firestore
        .collection('students')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalTeachersStream() {
    return _firestore
        .collection('teachers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<TeacherModel>> getTeachersStream() {
    return _firestore
        .collection('teachers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => TeacherModel.fromFirestore(doc)).toList());
  }

  Stream<List<StudentModel>> getStudentsStream() {
    return _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => StudentModel.fromFirestore(doc)).toList());
  }

  // ========== NEW: ACTIVE USERS COUNT ⭐ ==========

  Stream<int> getActiveUsersStream() {
    // Users jo last 5 minutes mai active thy
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    return _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .where('lastActive', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ========== NEW: ANNOUNCEMENTS ⭐ ==========

  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String message,
    required String type,
    required String targetAudience,
    required String createdByAdminId,
  }) async {
    final now = DateTime.now();

    final docRef = await _firestore.collection('announcements').add({
      'title': title,
      'message': message,
      'type': type,
      'targetAudience': targetAudience,
      'createdBy': createdByAdminId,
      'createdAt': Timestamp.fromDate(now),
      'isActive': true,
    });

    return AnnouncementModel(
      id: docRef.id,
      title: title,
      message: message,
      type: type,
      targetAudience: targetAudience,
      createdBy: createdByAdminId,
      createdAt: now,
      isActive: true,
    );
  }

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList());
  }

  // ========== NEW: CALENDAR EVENTS ⭐ ==========

  Future<CalendarEventModel> createCalendarEvent({
    required String title,
    required String description,
    required String type,
    required DateTime date,
    String? relatedUserId,
    String? className,
    String? section,
    required String createdByAdminId,
  }) async {
    final now = DateTime.now();

    final docRef = await _firestore.collection('calendar_events').add({
      'title': title,
      'description': description,
      'type': type,
      'date': Timestamp.fromDate(date),
      'relatedUserId': relatedUserId,
      'className': className,
      'section': section,
      'createdBy': createdByAdminId,
      'createdAt': Timestamp.fromDate(now),
    });

    return CalendarEventModel(
      id: docRef.id,
      title: title,
      description: description,
      type: type,
      date: date,
      relatedUserId: relatedUserId,
      className: className,
      section: section,
      createdBy: createdByAdminId,
      createdAt: now,
    );
  }

  Stream<List<CalendarEventModel>> getCalendarEventsStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection('calendar_events');

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CalendarEventModel.fromFirestore(doc)).toList());
  }

  // Fee specific events for a student
  Stream<List<CalendarEventModel>> getStudentFeeEvents(String studentId) {
    return _firestore
        .collection('calendar_events')
        .where('type', isEqualTo: 'fee_due')
        .where('relatedUserId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => CalendarEventModel.fromFirestore(doc)).toList());
  }

  // ========== NEW: UPDATE USER NAMES ⭐ ==========

  Future<void> updateTeacherName({
    required String teacherId,
    required String firstName,
    required String lastName,
  }) async {
    final batch = _firestore.batch();

    // Update users collection
    batch.update(_firestore.collection('users').doc(teacherId), {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': '$firstName $lastName',
    });

    // Update teachers collection
    batch.update(_firestore.collection('teachers').doc(teacherId), {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': '$firstName $lastName',
    });

    await batch.commit();
  }

  Future<void> updateStudentName({
    required String studentId,
    required String firstName,
    required String lastName,
  }) async {
    final batch = _firestore.batch();

    // Update users collection
    batch.update(_firestore.collection('users').doc(studentId), {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': '$firstName $lastName',
    });

    // Update students collection
    batch.update(_firestore.collection('students').doc(studentId), {
      'firstName': firstName,
      'lastName': lastName,
      'fullName': '$firstName $lastName',
    });

    await batch.commit();
  }

  // ========== NEW: ATTENDANCE VIEW ⭐ ==========

  Stream<AttendanceModel?> getAttendanceForClass({
    required String className,
    required String section,
    required DateTime date,
  }) {
    final docId = '${className}_${section}_${date.toIso8601String().split('T')[0]}';

    return _firestore
        .collection('attendance')
        .doc(docId)
        .snapshots()
        .map((doc) => doc.exists ? AttendanceModel.fromFirestore(doc) : null);
  }

  Stream<List<AttendanceModel>> getAttendanceHistory({
    required String className,
    required String section,
    int limit = 30,
  }) {
    return _firestore
        .collection('attendance')
        .where('className', isEqualTo: className)
        .where('section', isEqualTo: section)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList());
  }

  // ========== NEW: RESULTS ⭐ ==========

  Stream<List<ResultModel>> getResultsStream({
    String? className,
    String? section,
    String? examName,
  }) {
    Query query = _firestore.collection('results');

    if (className != null) {
      query = query.where('className', isEqualTo: className);
    }
    if (section != null) {
      query = query.where('section', isEqualTo: section);
    }
    if (examName != null) {
      query = query.where('examName', isEqualTo: examName);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => ResultModel.fromFirestore(doc)).toList());
  }

  Future<ResultModel?> getResultDetail(String resultId) async {
    final doc = await _firestore.collection('results').doc(resultId).get();
    if (doc.exists) {
      return ResultModel.fromFirestore(doc);
    }
    return null;
  }

  // ========== EXISTING METHODS (Create Teacher/Student - Unchanged) ==========

  Future<TeacherModel> createTeacher({
    required String firstName,
    required String lastName,
    required String subject,
    String? phone,
    required String createdByAdminId,
  }) async {
    try {
      final email = PasswordGenerator.generateEmail(
        firstName, lastName, 'school.edu.pk',
      );
      final password = PasswordGenerator.generate(firstName: firstName);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now();

      final teacher = TeacherModel(
        uid: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        subject: subject,
        phone: phone,
        createdBy: createdByAdminId,
        createdAt: now,
      );

      await _firestore.collection('users').doc(teacher.uid).set({
        ...teacher.toFirestore(),
        'role': 'teacher',
        'isOnline': false,
        'lastActive': Timestamp.fromDate(now),
      });

      await _firestore.collection('teachers').doc(teacher.uid).set(teacher.toFirestore());

      print('✅ Teacher created: $email / $password');
      return teacher;

    } on FirebaseAuthException catch (e) {
      print('❌ Auth Error: ${e.message}');
      throw Exception('Auth Error: ${e.message}');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error: $e');
    }
  }

  Future<StudentModel> createStudent({
    required String firstName,
    required String lastName,
    required String className,
    required String section,
    String? guardianName,
    String? guardianPhone,
    required String createdByAdminId,
  }) async {
    try {
      final email = PasswordGenerator.generateEmail(
        firstName, lastName, 'school.edu.pk',
      );
      final password = PasswordGenerator.generate(firstName: firstName);
      final rollNumber = await _generateRollNumber(className, section);

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now();

      final student = StudentModel(
        uid: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        rollNumber: rollNumber,
        className: className,
        section: section,
        guardianName: guardianName,
        guardianPhone: guardianPhone,
        createdBy: createdByAdminId,
        createdAt: now,
      );

      await _firestore.collection('users').doc(student.uid).set({
        ...student.toFirestore(),
        'role': 'student',
        'isOnline': false,
        'lastActive': Timestamp.fromDate(now),
      });

      await _firestore.collection('students').doc(student.uid).set(student.toFirestore());

      print('✅ Student created: $email / $password / Roll: $rollNumber');
      return student;

    } on FirebaseAuthException catch (e) {
      print('❌ Auth Error: ${e.message}');
      throw Exception('Auth Error: ${e.message}');
    } catch (e) {
      print('❌ Error: $e');
      throw Exception('Error: $e');
    }
  }

  Future<String> _generateRollNumber(String className, String section) async {
    final year = DateTime.now().year;
    final count = await _firestore
        .collection('students')
        .where('className', isEqualTo: className)
        .where('section', isEqualTo: section)
        .get()
        .then((s) => s.docs.length);

    final serial = (count + 1).toString().padLeft(3, '0');
    return '$year$className$section$serial';
  }
}