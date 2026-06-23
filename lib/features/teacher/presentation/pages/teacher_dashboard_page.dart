import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import 'package:edumanage/features/admin/data/models/announcement_model.dart';

import 'attendance_maker_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  final String teacherId;
  const TeacherDashboardPage({super.key, required this.teacherId});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildAnnouncementsTab(),
          _buildAttendanceTab(),
          _buildResultsTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.greyColor,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Results'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .where('targetAudience', whereIn: ['all', 'teachers'])
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
                    color: _getColor(a.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(_getIcon(a.type), color: _getColor(a.type), size: 20.w),
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
                          _formatDate(a.createdAt),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80.w, color: AppTheme.lightGreyColor),
          SizedBox(height: 16.h),
          Text(
            'Mark Attendance',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Select your class to mark attendance',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.greyColor,
            ),
          ),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: ElevatedButton.icon(
              onPressed: () => _showMarkAttendanceDialog(),
              icon: const Icon(Icons.add),
              label: const Text('MARK TODAY\'S ATTENDANCE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: Size(double.infinity, 54.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMarkAttendanceDialog() {
    String selectedClass = '9';
    String selectedSection = 'A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(labelText: 'Class'),
              items: ['9','10','11','12'].map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => selectedClass = v!,
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              value: selectedSection,
              decoration: const InputDecoration(labelText: 'Section'),
              items: ['A','B','C'].map((s) =>
                  DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => selectedSection = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openAttendanceMarker(selectedClass, selectedSection);
            },
            child: const Text('PROCEED'),
          ),
        ],
      ),
    );
  }

  void _openAttendanceMarker(String className, String section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceMarkerPage(
          teacherId: widget.teacherId,
          className: className,
          section: section,
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('results')
          .where('teacherId', isEqualTo: widget.teacherId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final r = results[index];
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
                  Text(
                    r['examName'],
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${r['subject']} • Class ${r['className']}${r['section']}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.greyColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${r['marks'].length} Students',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showAddResultDialog(r),
                        child: const Text('VIEW/EDIT'),
                      ),
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

  void _showAddResultDialog(DocumentSnapshot? existingResult) {
    // Implementation for adding/editing results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingResult == null ? 'Add New Result' : 'Edit Result'),
        content: const SingleChildScrollView(
          child: Text('Result form would go here...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50.w,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, size: 50.w, color: AppTheme.primaryColor),
          ),
          SizedBox(height: 16.h),
          Text(
            'Teacher Profile',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.teacherId,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      case 'urgent': return AppTheme.dangerColor;
      case 'exam': return AppTheme.warningColor;
      case 'fee': return AppTheme.successColor;
      case 'holiday': return AppTheme.infoColor;
      default: return AppTheme.primaryColor;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'urgent': return Icons.warning;
      case 'exam': return Icons.school;
      case 'fee': return Icons.payment;
      case 'holiday': return Icons.beach_access;
      default: return Icons.campaign;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}