import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edumanage/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:edumanage/features/admin/data/models/teacher_model.dart';
import 'package:edumanage/features/admin/data/models/student_model.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRemoteDataSource _dataSource;

  AdminBloc(this._dataSource) : super(AdminInitial()) {

    // ========== EXISTING HANDLERS ==========

    on<CreateTeacher>((event, emit) async {
      emit(AdminLoading());
      try {
        final teacher = await _dataSource.createTeacher(
          firstName: event.firstName,
          lastName: event.lastName,
          subject: event.subject,
          phone: event.phone,
          createdByAdminId: event.createdByAdminId,
        );
        emit(TeacherCreated(teacher));
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<CreateStudent>((event, emit) async {
      emit(AdminLoading());
      try {
        final student = await _dataSource.createStudent(
          firstName: event.firstName,
          lastName: event.lastName,
          className: event.className,
          section: event.section,
          guardianName: event.guardianName,
          guardianPhone: event.guardianPhone,
          createdByAdminId: event.createdByAdminId,
        );
        emit(StudentCreated(student));
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<LoadTeachers>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final teachers in _dataSource.getTeachersStream()) {
          emit(TeachersLoaded(teachers));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<LoadStudents>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final students in _dataSource.getStudentsStream()) {
          emit(StudentsLoaded(students));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: DASHBOARD STATS ⭐ ==========

    on<LoadDashboardStats>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final students in _dataSource.getTotalStudentsStream()) {
          await for (final teachers in _dataSource.getTotalTeachersStream()) {
            await for (final active in _dataSource.getActiveUsersStream()) {
              emit(DashboardStatsLoaded(
                totalStudents: students,
                totalTeachers: teachers,
                activeUsers: active,
              ));
            }
          }
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: ANNOUNCEMENTS ⭐ ==========

    on<CreateAnnouncement>((event, emit) async {
      emit(AdminLoading());
      try {
        final announcement = await _dataSource.createAnnouncement(
          title: event.title,
          message: event.message,
          type: event.type,
          targetAudience: event.targetAudience,
          createdByAdminId: event.createdByAdminId,
        );
        emit(AnnouncementCreated(announcement));
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<LoadAnnouncements>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final announcements in _dataSource.getAnnouncementsStream()) {
          emit(AnnouncementsLoaded(announcements));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: CALENDAR EVENTS ⭐ ==========

    on<CreateCalendarEvent>((event, emit) async {
      emit(AdminLoading());
      try {
        final calendarEvent = await _dataSource.createCalendarEvent(
          title: event.title,
          description: event.description,
          type: event.type,
          date: event.date,
          relatedUserId: event.relatedUserId,
          className: event.className,
          section: event.section,
          createdByAdminId: event.createdByAdminId,
        );
        emit(CalendarEventCreated(calendarEvent));
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<LoadCalendarEvents>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final events in _dataSource.getCalendarEventsStream(
          startDate: event.startDate,
          endDate: event.endDate,
        )) {
          emit(CalendarEventsLoaded(events));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: UPDATE USER NAMES ⭐ ==========

    on<UpdateTeacherName>((event, emit) async {
      emit(AdminLoading());
      try {
        await _dataSource.updateTeacherName(
          teacherId: event.teacherId,
          firstName: event.firstName,
          lastName: event.lastName,
        );
        emit(TeacherNameUpdated(event.teacherId));
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<UpdateStudentName>((event, emit) async {
      emit(AdminLoading());
      try {
        await _dataSource.updateStudentName(
          studentId: event.studentId,
          firstName: event.firstName,
          lastName: event.lastName,
        );
        emit(StudentNameUpdated(event.studentId));
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: ATTENDANCE ⭐ ==========

    on<LoadAttendanceForClass>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final attendance in _dataSource.getAttendanceForClass(
          className: event.className,
          section: event.section,
          date: event.date,
        )) {
          emit(AttendanceLoaded(attendance, event.className, event.section));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<LoadAttendanceHistory>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final history in _dataSource.getAttendanceHistory(
          className: event.className,
          section: event.section,
        )) {
          emit(AttendanceHistoryLoaded(history));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: RESULTS ⭐ ==========

    on<LoadResults>((event, emit) async {
      emit(AdminLoading());
      try {
        await for (final results in _dataSource.getResultsStream(
          className: event.className,
          section: event.section,
          examName: event.examName,
        )) {
          emit(ResultsLoaded(results));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    on<LoadResultDetail>((event, emit) async {
      emit(AdminLoading());
      try {
        final result = await _dataSource.getResultDetail(event.resultId);
        if (result != null) {
          emit(ResultDetailLoaded(result));
        } else {
          emit(AdminError('Result not found'));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });

    // ========== NEW: ACTIVE USERS ⭐ ==========

    on<LoadActiveUsersCount>((event, emit) async {
      try {
        await for (final count in _dataSource.getActiveUsersStream()) {
          emit(ActiveUsersCountLoaded(count));
        }
      } catch (e) {
        emit(AdminError(e.toString()));
      }
    });
  }
}