import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import 'package:edumanage/features/admin/data/models/announcement_model.dart';
import 'package:edumanage/features/admin/data/models/calender_event_model.dart';

class StudentDashboardPage extends StatefulWidget {
  final String studentId;
  const StudentDashboardPage({super.key, required this.studentId});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _currentIndex = 0;
  Map<String, dynamic>? studentData;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _updateOnlineStatus();
  }

  Future<void> _loadStudentData() async {
    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.studentId)
        .get();

    if (doc.exists) {
      setState(() {
        studentData = doc.data();
      });
    }
  }

  Future<void> _updateOnlineStatus() async {
    // Update online status every 5 minutes
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.studentId)
        .update({
      'isOnline': true,
      'lastActive': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: AppTheme.successColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: studentData == null
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildAnnouncementsTab(),
          _buildAttendanceTab(),
          _buildResultsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.successColor,
        unselectedItemColor: AppTheme.greyColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Results'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.successColor, AppTheme.primaryColor],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  studentData!['fullName'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Class ${studentData!['className']}${studentData!['section']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Roll: ${studentData!['rollNumber']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Quick Info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Attendance',
                  '92%',
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoCard(
                  'Fee Status',
                  'Paid',
                  Icons.payment,
                  AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Upcoming Events
          Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          SizedBox(height: 12.h),
          _buildUpcomingEvents(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('calendar_events')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30))))
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                'No upcoming events',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
          );
        }

        final events = snapshot.data!.docs
            .map((d) => CalendarEventModel.fromFirestore(d))
            .where((e) => e.className == null || e.className == studentData!['className'])
            .take(3)
            .toList();

        return Column(
          children: events.map((e) => Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _getEventColor(e.type).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: _getEventColor(e.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _getEventIcon(e.type),
                    color: _getEventColor(e.type),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${e.date.day}/${e.date.month}/${e.date.year}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildAnnouncementsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where('targetAudience', whereIn: ['all', 'students'])
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final announcements = snapshot.data!.docs
            .map((d) => AnnouncementModel.fromFirestore(d))
            .toList();

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final a = announcements[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: _getAnnouncementColor(a.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          _getAnnouncementIcon(a.type),
                          color: _getAnnouncementColor(a.type),
                          size: 20.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          a.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    a.message,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '${a.createdAt.day}/${a.createdAt.month}/${a.createdAt.year}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.lightGreyColor,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('className', isEqualTo: studentData!['className'])
          .where('section', isEqualTo: studentData!['section'])
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final attendanceRecords = snapshot.data!.docs;

        // Calculate stats
        int totalDays = 0;
        int presentDays = 0;

        final studentAttendance = <Map<String, dynamic>>[];

        for (var record in attendanceRecords) {
          final students = record['students'] as Map<String, dynamic>;
          if (students.containsKey(widget.studentId)) {
            totalDays++;
            final status = students[widget.studentId]['status'];
            if (status == 'present') presentDays++;

            studentAttendance.add({
              'date': (record['date'] as Timestamp).toDate(),
              'status': status,
            });
          }
        }

        final percentage = totalDays > 0 ? (presentDays / totalDays * 100) : 0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Stats Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStat('Total Days', totalDays.toString(), AppTheme.darkColor),
                    _buildAttendanceStat('Present', presentDays.toString(), AppTheme.successColor),
                    _buildAttendanceStat('Percentage', '${percentage.toStringAsFixed(1)}%', AppTheme.primaryColor),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Recent Attendance
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Attendance',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkColor,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              ...studentAttendance.take(10).map((a) {
                final isPresent = a['status'] == 'present';
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isPresent
                          ? AppTheme.successColor.withOpacity(0.3)
                          : AppTheme.dangerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${a['date'].day}/${a['date'].month}/${a['date'].year}',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isPresent ? AppTheme.successColor : AppTheme.dangerColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          a['status'].toString().toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('className', isEqualTo: studentData!['className'])
          .where('section', isEqualTo: studentData!['section'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs;
        final myResults = <Map<String, dynamic>>[];

        for (var result in results) {
          final marks = result['marks'] as List<dynamic>;
          for (var mark in marks) {
            if (mark['studentId'] == widget.studentId) {
              myResults.add({
                'examName': result['examName'],
                'subject': result['subject'],
                'obtained': mark['obtainedMarks'],
                'total': mark['totalMarks'],
                'grade': mark['grade'],
                'percentage': mark['percentage'],
              });
            }
          }
        }

        if (myResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment_outlined, size: 64.w, color: AppTheme.lightGreyColor),
                SizedBox(height: 16.h),
                Text(
                  'No results available',
                  style: TextStyle(color: AppTheme.greyColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: myResults.length,
          itemBuilder: (context, index) {
            final r = myResults[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        r['examName'],
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _getGradeColor(r['grade']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          r['grade'],
                          style: TextStyle(
                            color: _getGradeColor(r['grade']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    r['subject'],
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  Divider(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultStat('Marks', '${r['obtained']}/${r['total']}'),
                      _buildResultStat('Percentage', '${r['percentage'].toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getAnnouncementColor(String type) {
    switch (type) {
      case 'urgent': return AppTheme.dangerColor;
      case 'exam': return AppTheme.warningColor;
      case 'fee': return AppTheme.successColor;
      case 'holiday': return AppTheme.infoColor;
      default: return AppTheme.primaryColor;
    }
  }

  IconData _getAnnouncementIcon(String type) {
    switch (type) {
      case 'urgent': return Icons.warning;
      case 'exam': return Icons.school;
      case 'fee': return Icons.payment;
      case 'holiday': return Icons.beach_access;
      default: return Icons.campaign;
    }
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'fee_due': return AppTheme.dangerColor;
      case 'exam': return AppTheme.warningColor;
      case 'holiday': return AppTheme.infoColor;
      default: return AppTheme.primaryColor;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'fee_due': return Icons.payment;
      case 'exam': return Icons.school;
      case 'holiday': return Icons.beach_access;
      default: return Icons.event;
    }
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return AppTheme.successColor;
      case 'B':
      case 'C':
        return AppTheme.warningColor;
      case 'D':
        return AppTheme.infoColor;
      default:
        return AppTheme.dangerColor;
    }
  }
}