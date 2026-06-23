import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edumanage/core/theme/app_theme.dart';

class AttendanceMarkerPage extends StatefulWidget {
  final String teacherId;
  final String className;
  final String section;

  const AttendanceMarkerPage({
    super.key,
    required this.teacherId,
    required this.className,
    required this.section,
  });

  @override
  State<AttendanceMarkerPage> createState() => _AttendanceMarkerPageState();
}

class _AttendanceMarkerPageState extends State<AttendanceMarkerPage> {
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {}; // studentId -> status
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('className', isEqualTo: widget.className)
        .where('section', isEqualTo: widget.section)
        .where('isActive', isEqualTo: true)
        .orderBy('rollNumber')
        .get();

    setState(() {
      students = snapshot.docs.map((d) => {
        'id': d.id,
        'name': d['fullName'],
        'rollNumber': d['rollNumber'],
      }).toList();

      // Default all to absent
      for (var s in students) {
        attendanceStatus[s['id']] = 'absent';
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month}-${today.day}';
    final docId = '${widget.className}_${widget.section}_$dateStr';

    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance - ${widget.className}${widget.section}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _submitAttendance,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Quick Actions
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _markAll('present'),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('ALL PRESENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _markAll('absent'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('ALL ABSENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            color: AppTheme.bgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', students.length.toString(), AppTheme.darkColor),
                _buildStat(
                  'Present',
                  attendanceStatus.values.where((s) => s == 'present').length.toString(),
                  AppTheme.successColor,
                ),
                _buildStat(
                  'Absent',
                  attendanceStatus.values.where((s) => s == 'absent').length.toString(),
                  AppTheme.dangerColor,
                ),
              ],
            ),
          ),

          // Students List
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final s = students[index];
                final status = attendanceStatus[s['id']] ?? 'absent';

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(s['name']),
                    subtitle: Text('Roll: ${s['rollNumber']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusButton(s['id'], 'present', Icons.check_circle, AppTheme.successColor),
                        SizedBox(width: 8.w),
                        _buildStatusButton(s['id'], 'leave', Icons.time_to_leave, AppTheme.warningColor),
                        SizedBox(width: 8.w),
                        _buildStatusButton(s['id'], 'absent', Icons.cancel, AppTheme.dangerColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24.sp,
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

  Widget _buildStatusButton(String studentId, String status, IconData icon, Color color) {
    final isSelected = attendanceStatus[studentId] == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          attendanceStatus[studentId] = status;
        });
      },
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : color,
          size: 20.w,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return AppTheme.successColor;
      case 'leave': return AppTheme.warningColor;
      default: return AppTheme.dangerColor;
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var s in students) {
        attendanceStatus[s['id']] = status;
      }
    });
  }

  Future<void> _submitAttendance() async {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final docId = '${widget.className}_${widget.section}_$dateStr';

    final presentCount = attendanceStatus.values.where((s) => s == 'present').length;
    final absentCount = attendanceStatus.values.where((s) => s == 'absent').length;

    // Build students map
    final studentsMap = <String, dynamic>{};
    for (var s in students) {
      studentsMap[s['id']] = {
        'rollNumber': s['rollNumber'],
        'name': s['name'],
        'status': attendanceStatus[s['id']],
      };
    }

    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'date': Timestamp.fromDate(today),
      'className': widget.className,
      'section': widget.section,
      'markedBy': widget.teacherId,
      'totalStudents': students.length,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'students': studentsMap,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Attendance saved successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      Navigator.pop(context);
    }
  }
}