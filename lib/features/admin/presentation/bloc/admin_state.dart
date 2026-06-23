import 'package:edumanage/features/admin/data/models/teacher_model.dart';
import 'package:edumanage/features/admin/data/models/student_model.dart';
import 'package:edumanage/features/admin/data/models/announcement_model.dart';
import 'package:edumanage/features/admin/data/models/calender_event_model.dart';
import 'package:edumanage/features/admin/data/models/attendance_model.dart';
import 'package:edumanage/features/admin/data/models/result_model.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}

// ========== EXISTING STATES ==========
class TeachersLoaded extends AdminState {
  final List<TeacherModel> teachers;
  TeachersLoaded(this.teachers);
}

class StudentsLoaded extends AdminState {
  final List<StudentModel> students;
  StudentsLoaded(this.students);
}

class TeacherCreated extends AdminState {
  final TeacherModel teacher;
  TeacherCreated(this.teacher);
}

class StudentCreated extends AdminState {
  final StudentModel student;
  StudentCreated(this.student);
}

// ========== NEW STATES ⭐ ==========

// Dashboard Stats
class DashboardStatsLoaded extends AdminState {
  final int totalStudents;
  final int totalTeachers;
  final int activeUsers;

  DashboardStatsLoaded({
    required this.totalStudents,
    required this.totalTeachers,
    required this.activeUsers,
  });
}

// Announcements
class AnnouncementsLoaded extends AdminState {
  final List<AnnouncementModel> announcements;
  AnnouncementsLoaded(this.announcements);
}

class AnnouncementCreated extends AdminState {
  final AnnouncementModel announcement;
  AnnouncementCreated(this.announcement);
}

// Calendar
class CalendarEventsLoaded extends AdminState {
  final List<CalendarEventModel> events;
  CalendarEventsLoaded(this.events);
}

class CalendarEventCreated extends AdminState {
  final CalendarEventModel event;
  CalendarEventCreated(this.event);
}

// User Updates
class TeacherNameUpdated extends AdminState {
  final String teacherId;
  TeacherNameUpdated(this.teacherId);
}

class StudentNameUpdated extends AdminState {
  final String studentId;
  StudentNameUpdated(this.studentId);
}

// Attendance
class AttendanceLoaded extends AdminState {
  final AttendanceModel? attendance;
  final String className;
  final String section;
  AttendanceLoaded(this.attendance, this.className, this.section);
}

class AttendanceHistoryLoaded extends AdminState {
  final List<AttendanceModel> attendanceList;
  AttendanceHistoryLoaded(this.attendanceList);
}

// Results
class ResultsLoaded extends AdminState {
  final List<ResultModel> results;
  ResultsLoaded(this.results);
}

class ResultDetailLoaded extends AdminState {
  final ResultModel result;
  ResultDetailLoaded(this.result);
}

// Active Users
class ActiveUsersCountLoaded extends AdminState {
  final int count;
  ActiveUsersCountLoaded(this.count);
}

// Error
class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}