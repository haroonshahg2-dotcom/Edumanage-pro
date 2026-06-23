abstract class AdminEvent {}

// ========== EXISTING EVENTS ==========
class LoadDashboardStats extends AdminEvent {}

class CreateTeacher extends AdminEvent {
  final String firstName;
  final String lastName;
  final String subject;
  final String? phone;
  final String createdByAdminId;

  CreateTeacher({
    required this.firstName,
    required this.lastName,
    required this.subject,
    this.phone,
    required this.createdByAdminId,
  });
}

class CreateStudent extends AdminEvent {
  final String firstName;
  final String lastName;
  final String className;
  final String section;
  final String? guardianName;
  final String? guardianPhone;
  final String createdByAdminId;

  CreateStudent({
    required this.firstName,
    required this.lastName,
    required this.className,
    required this.section,
    this.guardianName,
    this.guardianPhone,
    required this.createdByAdminId,
  });
}

class LoadTeachers extends AdminEvent {}
class LoadStudents extends AdminEvent {}

// ========== NEW EVENTS ⭐ ==========

// Announcements
class CreateAnnouncement extends AdminEvent {
  final String title;
  final String message;
  final String type;
  final String targetAudience;
  final String createdByAdminId;

  CreateAnnouncement({
    required this.title,
    required this.message,
    required this.type,
    required this.targetAudience,
    required this.createdByAdminId,
  });
}

class LoadAnnouncements extends AdminEvent {}

// Calendar Events
class CreateCalendarEvent extends AdminEvent {
  final String title;
  final String description;
  final String type;
  final DateTime date;
  final String? relatedUserId;
  final String? className;
  final String? section;
  final String createdByAdminId;

  CreateCalendarEvent({
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    this.relatedUserId,
    this.className,
    this.section,
    required this.createdByAdminId,
  });
}

class LoadCalendarEvents extends AdminEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  LoadCalendarEvents({this.startDate, this.endDate});
}

// Update User Names
class UpdateTeacherName extends AdminEvent {
  final String teacherId;
  final String firstName;
  final String lastName;

  UpdateTeacherName({
    required this.teacherId,
    required this.firstName,
    required this.lastName,
  });
}

class UpdateStudentName extends AdminEvent {
  final String studentId;
  final String firstName;
  final String lastName;

  UpdateStudentName({
    required this.studentId,
    required this.firstName,
    required this.lastName,
  });
}

// Attendance
class LoadAttendanceForClass extends AdminEvent {
  final String className;
  final String section;
  final DateTime date;

  LoadAttendanceForClass({
    required this.className,
    required this.section,
    required this.date,
  });
}

class LoadAttendanceHistory extends AdminEvent {
  final String className;
  final String section;

  LoadAttendanceHistory({
    required this.className,
    required this.section,
  });
}

// Results
class LoadResults extends AdminEvent {
  final String? className;
  final String? section;
  final String? examName;

  LoadResults({this.className, this.section, this.examName});
}

class LoadResultDetail extends AdminEvent {
  final String resultId;
  LoadResultDetail(this.resultId);
}

// Active Users
class LoadActiveUsersCount extends AdminEvent {}