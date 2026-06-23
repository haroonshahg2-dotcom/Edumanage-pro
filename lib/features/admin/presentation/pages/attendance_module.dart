import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

// ─── EXPORT HELPER ─────────────────────────────────────────
// Uses only dart:convert (no extra package needed for CSV).
// For real file saving on mobile/desktop you'd add path_provider + dart:io,
// but the CSV string is ready to be shared via any Share plugin.
class _CsvExporter {
  static String buildCsv(List<Map<String, dynamic>> records) {
    final buf = StringBuffer();
    buf.writeln('Name,Roll No,Class,Status,Date,Marked At');
    for (final r in records) {
      final ts = r['markedAt'];
      final timeStr = ts is Timestamp
          ? DateFormat('hh:mm a').format(ts.toDate())
          : '--';
      buf.writeln(
        '${_q(r['studentName'])},${_q(r['rollNumber'])},${_q(r['class'])},${_q(r['status'])},${_q(r['date'])},$timeStr',
      );
    }
    return buf.toString();
  }

  static String _q(dynamic v) {
    final s = (v ?? '').toString().replaceAll('"', '""');
    return '"$s"';
  }
}

// ─── MAIN WIDGET ───────────────────────────────────────────
class AttendanceModule extends StatefulWidget {
  final String schoolId;
  final bool isMobile;
  final Function(String, {bool isError}) showSnackBar;

  const AttendanceModule({
    super.key,
    required this.schoolId,
    required this.isMobile,
    required this.showSnackBar,
  });

  @override
  State<AttendanceModule> createState() => _AttendanceModuleState();
}

class _AttendanceModuleState extends State<AttendanceModule>
    with SingleTickerProviderStateMixin {
  // ─── INDUSTRIAL COLOR PALETTE ───
  static const Color _bgDark      = Color(0xFF09090E);
  static const Color _bgCard      = Color(0xFF111318);
  static const Color _bgElevated  = Color(0xFF181C26);
  static const Color _primary     = Color(0xFF1565C0);
  static const Color _primaryLight= Color(0xFF1E88E5);
  static const Color _accentSuccess= Color(0xFF2E7D32);
  static const Color _accentWarning= Color(0xFFE65100);
  static const Color _accentDanger = Color(0xFFC62828);
  static const Color _accentInfo  = Color(0xFF00838F);
  static const Color _textPrimary = Color(0xFFD9E2EE);
  static const Color _textSecondary= Color(0xFF6E8099);
  static const Color _textMuted   = Color(0xFF3C4C5E);
  static const Color _border      = Color(0xFF1E2535);

  // ─── CONSTANTS ─────────────────────────────────────────────
  static const List<String> _statusOptions = ['present', 'absent', 'late', 'leave'];
  static const Map<String, Color> _statusColors = {
    'present': _accentSuccess,
    'absent' : _accentDanger,
    'late'   : _accentWarning,
    'leave'  : _accentInfo,
  };
  static const Map<String, IconData> _statusIcons = {
    'present': Icons.check_circle,
    'absent' : Icons.cancel,
    'late'   : Icons.access_time,
    'leave'  : Icons.beach_access,
  };

  // ─── STATE ─────────────────────────────────────────────────
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedClass;
  String _searchQuery = '';
  bool _isLoading = false;

  /// Optimistic-UI cache: studentId → status, cleared on date/class change.
  final Map<String, String> _attendanceCache = {};

  /// Classes fetched from Firestore, used across tabs.
  List<String> _availableClasses = [];

  // ─── LIFECYCLE ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── DATE HELPERS ──────────────────────────────────────────
  String _dateId(DateTime d)     => DateFormat('yyyy-MM-dd').format(d);
  String _displayDate(DateTime d)=> DateFormat('EEEE, d MMMM yyyy').format(d);
  String _monthId(DateTime d)    => '${d.year}-${d.month.toString().padLeft(2,'0')}';

  int _workingDays(int year, int month) {
    int count = 0;
    final days = DateTime(year, month + 1, 0).day;
    for (int i = 1; i <= days; i++) {
      final w = DateTime(year, month, i).weekday;
      if (w != DateTime.saturday && w != DateTime.sunday) count++;
    }
    return count;
  }

  // ─── FIRESTORE REFS ────────────────────────────────────────
  CollectionReference get _studentsCol => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId).collection('students');

  CollectionReference _recordsCol(String dateId) => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId)
      .collection('attendance').doc(dateId).collection('records');

  CollectionReference _summariesCol(String dateId) => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId)
      .collection('attendance').doc(dateId).collection('summaries');

  // ─── STREAMS ───────────────────────────────────────────────
  Stream<List<String>> _classesStream() => _studentsCol
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((s) {
    final cls = s.docs
        .map((d) => (d.data() as Map<String, dynamic>)['class']?.toString() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return cls;
  });

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: _classesStream(),
      builder: (ctx, snap) {
        _availableClasses = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            SizedBox(height: widget.isMobile ? 16.h : 24.h),
            _tabBar(),
            SizedBox(height: 16.h),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _markTab(),
                  _dailyReportTab(),
                  _analyticsTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _header() => widget.isMobile
      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _headerTitle(),
    SizedBox(height: 4.h),
    _headerSub(),
  ])
      : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _headerTitle(large: true),
      SizedBox(height: 8.h),
      _headerSub(),
    ]),
    _statusBadge('System Active', _accentSuccess),
  ]);

  Widget _headerTitle({bool large = false}) => Text(
    'Attendance Management',
    style: TextStyle(
      color: _textPrimary,
      fontSize: large ? 28.sp : 22.sp,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
  );

  Widget _headerSub() => Text(
    'Mark, track & analyze student attendance',
    style: TextStyle(color: _textSecondary, fontSize: 14.sp),
  );

  Widget _statusBadge(String label, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(children: [
      Container(
        width: 8.w, height: 8.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: 8.w),
      Text(label, style: TextStyle(color: color, fontSize: 13.sp, fontWeight: FontWeight.w600)),
    ]),
  );

  // ═══════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════
  Widget _tabBar() => Container(
    decoration: BoxDecoration(
      color: _bgCard,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: _border),
    ),
    child: TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        gradient: const LinearGradient(colors: [_primary, _primaryLight]),
        borderRadius: BorderRadius.circular(10.r),
      ),
      indicatorPadding: EdgeInsets.all(4.w),
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Colors.white,
      unselectedLabelColor: _textSecondary,
      labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
      tabs: const [
        Tab(icon: Icon(Icons.edit_calendar), text: 'Mark Attendance'),
        Tab(icon: Icon(Icons.today),          text: 'Daily Report'),
        Tab(icon: Icon(Icons.bar_chart),      text: 'Analytics'),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════
  // TAB 1 — MARK ATTENDANCE
  // ═══════════════════════════════════════════════════════════
  Widget _markTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dateClassRow(),
      SizedBox(height: 16.h),
      _searchField(),
      SizedBox(height: 16.h),
      Expanded(child: _studentList()),
    ],
  );

  // ─── DATE + CLASS ROW ───
  Widget _dateClassRow() => Container(
    padding: EdgeInsets.all(16.w),
    decoration: _cardDecor(),
    child: widget.isMobile
        ? Column(children: [
      _datePicker(),
      SizedBox(height: 12.h),
      _classDropdown(),
    ])
        : Row(children: [
      Expanded(child: _datePicker()),
      SizedBox(width: 16.w),
      Expanded(child: _classDropdown()),
      SizedBox(width: 16.w),
      _inlineQuickStats(),
    ]),
  );

  Widget _datePicker() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: _elevatedDecor(),
      child: Row(children: [
        Icon(Icons.calendar_today, color: _primary, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Selected Date', style: TextStyle(color: _textMuted, fontSize: 11.sp)),
            SizedBox(height: 2.h),
            Text(_displayDate(_selectedDate),
                style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ]),
        ),
        Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20.sp),
      ]),
    ),
  );

  Widget _classDropdown() => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w),
    decoration: _elevatedDecor(),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedClass,
        isExpanded: true,
        dropdownColor: _bgElevated,
        hint: Text('Select Class', style: TextStyle(color: _textMuted, fontSize: 14.sp)),
        icon: Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20.sp),
        style: TextStyle(color: _textPrimary, fontSize: 14.sp),
        items: _availableClasses
            .map((c) => DropdownMenuItem(
          value: c,
          child: Text('Class $c', style: TextStyle(color: _textPrimary, fontSize: 14.sp)),
        ))
            .toList(),
        onChanged: (v) => setState(() {
          _selectedClass = v;
          _attendanceCache.clear();
        }),
      ),
    ),
  );

  Widget _inlineQuickStats() {
    if (_selectedClass == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: _recordsCol(_dateId(_selectedDate))
          .where('class', isEqualTo: _selectedClass)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs  = snap.data!.docs;
        final total  = docs.length;
        final present= docs.where((d) => d['status'] == 'present').length;
        final pct    = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: _accentSuccess.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _accentSuccess.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.check_circle, color: _accentSuccess, size: 18.sp),
            SizedBox(width: 8.w),
            Text('$pct% Present',
                style: TextStyle(color: _accentSuccess, fontSize: 13.sp, fontWeight: FontWeight.w700)),
            SizedBox(width: 12.w),
            Text('($present/$total)',
                style: TextStyle(color: _textSecondary, fontSize: 12.sp)),
          ]),
        );
      },
    );
  }

  Widget _searchField() => Container(
    decoration: _elevatedDecor(),
    child: TextField(
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      style: TextStyle(color: _textPrimary, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: 'Search student by name or roll number…',
        hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp),
        prefixIcon: Icon(Icons.search, color: _textMuted, size: 20.sp),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    ),
  );

  // ─── STUDENT LIST ───
  Widget _studentList() {
    if (_selectedClass == null) {
      return _emptyState(icon: Icons.school, title: 'Select a Class',
          subtitle: 'Choose a class from the dropdown above to mark attendance');
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _studentsCol
          .where('class', isEqualTo: _selectedClass)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return _errorState('Database Error',
              '${snap.error}\n\nMake sure students have "class" and "status" fields in Firestore.');
        }
        if (!snap.hasData) return _shimmerList();

        final all = snap.data!.docs;
        if (all.isEmpty) {
          return _emptyState(
            icon: Icons.people_outline,
            title: 'No Active Students',
            subtitle: 'No active students found in Class $_selectedClass.',
          );
        }

        // Client-side filter + sort
        final students = all.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final roll = (data['rollNumber'] ?? data['roll'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || roll.contains(_searchQuery);
        }).toList()
          ..sort((a, b) {
            final aR = ((a.data() as Map)['rollNumber'] ?? (a.data() as Map)['roll'] ?? '0').toString();
            final bR = ((b.data() as Map)['rollNumber'] ?? (b.data() as Map)['roll'] ?? '0').toString();
            return aR.compareTo(bR);
          });

        if (students.isEmpty && _searchQuery.isNotEmpty) {
          return _emptyState(icon: Icons.search_off, title: 'No Matches',
              subtitle: 'No students match "$_searchQuery" in Class $_selectedClass');
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _recordsCol(_dateId(_selectedDate))
              .where('class', isEqualTo: _selectedClass)
              .snapshots(),
          builder: (ctx2, attSnap) {
            final attMap = <String, String>{};
            if (attSnap.hasData) {
              for (final d in attSnap.data!.docs) {
                attMap[d['studentId'] as String] = d['status'] as String;
              }
            }
            attMap.addAll(_attendanceCache);

            return Column(children: [
              _bulkActions(students.length, attMap),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s  = students[i];
                    final id = s.id;
                    final st = attMap[id] ?? 'not_marked';
                    return _studentCard(
                      student: s,
                      status: st,
                      onChanged: (status) => _markAttendance(
                        studentId: id,
                        studentName: (s.data() as Map)['name'] ?? '',
                        rollNumber: ((s.data() as Map)['rollNumber'] ?? (s.data() as Map)['roll'] ?? '').toString(),
                        className: _selectedClass!,
                        status: status,
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        );
      },
    );
  }

  // ─── BULK ACTIONS BAR ───
  Widget _bulkActions(int total, Map<String, String> attMap) {
    final marked = attMap.values.where((s) => s != 'not_marked').length;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: _cardDecor(),
      child: Row(children: [
        _pill('$marked / $total Marked', _primary),
        const Spacer(),
        if (_isLoading)
          SizedBox(
            width: 20.w, height: 20.w,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          )
        else if (marked < total)
          _actionBtn('Mark All Present', _accentSuccess, Icons.done_all, () => _markAll('present')),
      ]),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600)),
  );

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  // ─── STUDENT CARD ───
  Widget _studentCard({
    required DocumentSnapshot student,
    required String status,
    required Function(String) onChanged,
  }) {
    final data   = student.data() as Map<String, dynamic>;
    final name   = data['name'] ?? 'Unknown';
    final roll   = (data['rollNumber'] ?? data['roll'] ?? '--').toString();
    final gender = data['gender'] ?? 'male';
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: status == 'not_marked'
              ? _border
              : (_statusColors[status] ?? _border).withOpacity(0.3),
        ),
      ),
      child: widget.isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _studentInfo(name, roll, gender, status),
        SizedBox(height: 12.h),
        _statusSelector(status, onChanged),
      ])
          : Row(children: [
        _studentInfo(name, roll, gender, status),
        const Spacer(),
        _statusSelector(status, onChanged),
      ]),
    );
  }

  Widget _studentInfo(String name, String roll, String gender, String status) {
    final color = gender == 'female'
        ? const Color(0xFFC2185B)
        : _primary;
    return Row(children: [
      Container(
        width: 44.w, height: 44.w,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
        ),
      ),
      SizedBox(width: 12.w),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Row(children: [
          _miniBadge('Roll: $roll', _textSecondary),
          if (status != 'not_marked') ...[
            SizedBox(width: 8.w),
            _miniBadge2(status),
          ],
        ]),
      ]),
    ]);
  }

  Widget _miniBadge2(String status) {
    final color = _statusColors[status] ?? _textMuted;
    final icon  = _statusIcons[status] ?? Icons.help;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12.sp),
        SizedBox(width: 4.w),
        Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _statusSelector(String current, Function(String) onChanged) =>
      Row(mainAxisSize: MainAxisSize.min, children: _statusOptions.map((s) {
        final sel   = current == s;
        final color = _statusColors[s]!;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(left: 6.w),
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.2) : _bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: sel ? color : _border, width: sel ? 2 : 1),
            ),
            child: Icon(_statusIcons[s], color: sel ? color : _textMuted, size: 20.sp),
          ),
        );
      }).toList());

  // ─── MARK ATTENDANCE LOGIC ───
  Future<void> _markAttendance({
    required String studentId,
    required String studentName,
    required String rollNumber,
    required String className,
    required String status,
  }) async {
    // Optimistic update
    setState(() => _attendanceCache[studentId] = status);
    try {
      final dateStr = _dateId(_selectedDate);
      await _recordsCol(dateStr).doc(studentId).set({
        'studentId'  : studentId,
        'studentName': studentName,
        'rollNumber' : rollNumber,
        'class'      : className,
        'status'     : status,
        'date'       : dateStr,
        'timestamp'  : FieldValue.serverTimestamp(),
        'markedBy'   : 'admin',
        'markedAt'   : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _updateDailySummary(dateStr, className);
      widget.showSnackBar('$studentName → ${status.toUpperCase()}');
    } catch (e) {
      setState(() => _attendanceCache.remove(studentId));
      widget.showSnackBar('Error saving attendance: $e', isError: true);
    }
  }

  Future<void> _markAll(String status) async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);
    try {
      final students = await _studentsCol
          .where('class', isEqualTo: _selectedClass)
          .where('status', isEqualTo: 'active')
          .get();
      final batch  = FirebaseFirestore.instance.batch();
      final dateStr= _dateId(_selectedDate);
      int present = 0, absent = 0, late = 0, leave = 0;

      for (final s in students.docs) {
        final data = s.data() as Map<String, dynamic>;
        final ref  = _recordsCol(dateStr).doc(s.id);
        batch.set(ref, {
          'studentId'  : s.id,
          'studentName': data['name'] ?? '',
          'rollNumber' : (data['rollNumber'] ?? data['roll'] ?? '').toString(),
          'class'      : _selectedClass,
          'status'     : status,
          'date'       : dateStr,
          'timestamp'  : FieldValue.serverTimestamp(),
          'markedBy'   : 'admin',
          'markedAt'   : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (status == 'present') present++;
        else if (status == 'absent') absent++;
        else if (status == 'late') late++;
        else if (status == 'leave') leave++;
      }

      final total = students.docs.length;
      batch.set(_summariesCol(dateStr).doc(_selectedClass), {
        'class'         : _selectedClass,
        'date'          : dateStr,
        'totalStudents' : total,
        'present'       : present,
        'absent'        : absent,
        'late'          : late,
        'leave'         : leave,
        'percentage'    : total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0',
        'updatedAt'     : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      setState(() { _isLoading = false; _attendanceCache.clear(); });
      widget.showSnackBar('All students marked ${status.toUpperCase()}');
    } catch (e) {
      setState(() => _isLoading = false);
      widget.showSnackBar('Bulk mark failed: $e', isError: true);
    }
  }

  Future<void> _updateDailySummary(String dateId, String className) async {
    final snap = await _recordsCol(dateId).where('class', isEqualTo: className).get();
    int p = 0, ab = 0, la = 0, le = 0;
    for (final d in snap.docs) {
      switch (d['status'] as String) {
        case 'present': p++;  break;
        case 'absent' : ab++; break;
        case 'late'   : la++; break;
        case 'leave'  : le++; break;
      }
    }
    await _summariesCol(dateId).doc(className).set({
      'class'        : className,
      'date'         : dateId,
      'totalStudents': snap.docs.length,
      'present'      : p,
      'absent'       : ab,
      'late'         : la,
      'leave'        : le,
      'percentage'   : snap.docs.length > 0 ? (p / snap.docs.length * 100).toStringAsFixed(1) : '0.0',
      'updatedAt'    : FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2 — DAILY REPORT
  // ═══════════════════════════════════════════════════════════
  Widget _dailyReportTab() => SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _reportHeader(),
      SizedBox(height: 16.h),
      _reportDatePicker(),
      SizedBox(height: 16.h),
      _classChips(),
      SizedBox(height: 16.h),
      _dailySummaryCards(),
      SizedBox(height: 16.h),
      _recordsListHeader(),
      SizedBox(height: 12.h),
      _recordsList(),
      SizedBox(height: 16.h),
    ]),
  );

  Widget _reportHeader() => Row(children: [
    _iconBox(Icons.assessment, _primary),
    SizedBox(width: 12.w),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Daily Attendance Report',
            style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 2.h),
        Text('View detailed attendance records by date & class',
            style: TextStyle(color: _textSecondary, fontSize: 12.sp)),
      ]),
    ),
    _exportButton(),
  ]);

  Widget _iconBox(IconData icon, Color color, {bool gradient = false}) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: gradient ? null : color.withOpacity(0.1),
      gradient: gradient ? LinearGradient(colors: [color, color.withOpacity(0.7)]) : null,
      borderRadius: BorderRadius.circular(10.r),
      border: gradient ? null : Border.all(color: color.withOpacity(0.2)),
    ),
    child: Icon(icon, color: gradient ? Colors.white : color, size: 22.sp),
  );

  Widget _exportButton() => GestureDetector(
    onTap: _exportCsv,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.download, color: _textSecondary, size: 16.sp),
        SizedBox(width: 6.w),
        Text('Export CSV', style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Future<void> _exportCsv() async {
    try {
      final snap = _selectedClass != null
          ? await _recordsCol(_dateId(_selectedDate)).where('class', isEqualTo: _selectedClass).get()
          : await _recordsCol(_dateId(_selectedDate)).get();

      if (snap.docs.isEmpty) {
        widget.showSnackBar('No records to export for this date.', isError: true);
        return;
      }
      final records = snap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
      final csv = _CsvExporter.buildCsv(records);
      // Copy to clipboard as a practical cross-platform fallback
      await Clipboard.setData(ClipboardData(text: csv));
      widget.showSnackBar('CSV copied to clipboard (${records.length} records)');
    } catch (e) {
      widget.showSnackBar('Export failed: $e', isError: true);
    }
  }

  Widget _reportDatePicker() => GestureDetector(
    onTap: _pickDate,
    child: Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecor(shadow: true),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryLight]),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.calendar_month, color: Colors.white, size: 22.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Report Date', style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w500)),
            SizedBox(height: 4.h),
            Text(_displayDate(_selectedDate),
                style: TextStyle(color: _textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
          ]),
        ),
        _pill('Change', _primary),
      ]),
    ),
  );

  Widget _classChips() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Filter by Class', style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
      SizedBox(height: 10.h),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(null, 'All Classes', Icons.layers),
            ..._availableClasses.map((c) => _chip(c, c, Icons.class_)),
          ],
        ),
      ),
    ],
  );

  Widget _chip(String? value, String label, IconData icon) {
    final sel = _selectedClass == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedClass = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [_primary, _primaryLight]) : null,
          color: sel ? null : _bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: sel ? Colors.transparent : _border),
          boxShadow: sel ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: sel ? Colors.white : _textSecondary, size: 14.sp),
          SizedBox(width: 6.w),
          Text(label, style: TextStyle(color: sel ? Colors.white : _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ─── DAILY SUMMARY CARDS ───
  Widget _dailySummaryCards() {
    final dateStr = _dateId(_selectedDate);
    if (_selectedClass != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: _summariesCol(dateStr).where('class', isEqualTo: _selectedClass).snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return _shimmerSummary();
          if (snap.data!.docs.isEmpty) {
            return _infoCard('No Data for Class $_selectedClass',
                'Attendance not yet marked for this class on ${_displayDate(_selectedDate)}');
          }
          return _summaryFromData(snap.data!.docs.first.data() as Map<String, dynamic>);
        },
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _summariesCol(dateStr).snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return _shimmerSummary();
        int t = 0, p = 0, ab = 0, la = 0, le = 0;
        for (final d in snap.data!.docs) {
          final m = d.data() as Map<String, dynamic>;
          t  += (m['totalStudents'] ?? 0) as int;
          p  += (m['present']       ?? 0) as int;
          ab += (m['absent']        ?? 0) as int;
          la += (m['late']          ?? 0) as int;
          le += (m['leave']         ?? 0) as int;
        }
        return _summaryFromData({'totalStudents': t,'present': p,'absent': ab,'late': la,'leave': le});
      },
    );
  }

  Widget _summaryFromData(Map<String, dynamic> data) {
    final total   = (data['totalStudents'] ?? data['total'] ?? 0) as int;
    final present = (data['present'] ?? 0) as int;
    final absent  = (data['absent']  ?? 0) as int;
    final late    = (data['late']    ?? 0) as int;
    final leave   = (data['leave']   ?? 0) as int;
    final pct     = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';
    return Column(children: [
      _pctCard(pct, total, present),
      SizedBox(height: 12.h),
      _statGrid([
        _statCard('Present', present, _accentSuccess, Icons.check_circle),
        _statCard('Absent',  absent,  _accentDanger,  Icons.cancel),
        _statCard('Late',    late,    _accentWarning,  Icons.access_time),
        _statCard('Leave',   leave,   _accentInfo,     Icons.beach_access),
      ]),
    ]);
  }

  Widget _statGrid(List<Widget> cards) => widget.isMobile
      ? Column(children: [
    Row(children: [Expanded(child: cards[0]), SizedBox(width: 10.w), Expanded(child: cards[1])]),
    SizedBox(height: 10.h),
    Row(children: [Expanded(child: cards[2]), SizedBox(width: 10.w), Expanded(child: cards[3])]),
  ])
      : Row(children: cards
      .expand((c) => [Expanded(child: c), SizedBox(width: 10.w)])
      .toList()
    ..removeLast());

  Widget _pctCard(String percentage, int total, int present) {
    final pct   = double.tryParse(percentage) ?? 0;
    final color = pct >= 90 ? _accentSuccess : pct >= 75 ? _accentWarning : _accentDanger;
    final grade = pct >= 90 ? 'A' : pct >= 75 ? 'B' : 'C';
    final label = pct >= 90 ? 'Excellent' : pct >= 75 ? 'Good' : 'Needs Attention';
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.15), _bgCard]),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        SizedBox(
          width: 70.w, height: 70.w,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(
              value: pct / 100, strokeWidth: 6.w,
              backgroundColor: _bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Center(child: Text('$percentage%',
                style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w800))),
          ]),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Attendance Rate', style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
            SizedBox(height: 4.h),
            Text(label, style: TextStyle(color: color, fontSize: 18.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 4.h),
            Text('$present of $total students present', style: TextStyle(color: _textMuted, fontSize: 12.sp)),
          ]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(grade, style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _statCard(String title, int value, Color color, IconData icon) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: _cardDecor(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        const Spacer(),
        Text(value.toString(),
            style: TextStyle(color: _textPrimary, fontSize: 22.sp, fontWeight: FontWeight.w800)),
      ]),
      SizedBox(height: 10.h),
      Text(title, style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w500)),
    ]),
  );

  // ─── RECORDS LIST ───
  Widget _recordsListHeader() => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    decoration: _elevatedDecor(),
    child: Row(children: [
      Icon(Icons.format_list_bulleted, color: _textSecondary, size: 16.sp),
      SizedBox(width: 8.w),
      Text('Detailed Records',
          style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w700)),
      const Spacer(),
      _pill(_selectedClass ?? 'All Classes', _primary),
    ]),
  );

  Widget _recordsList() {
    Query q = _recordsCol(_dateId(_selectedDate));
    if (_selectedClass != null) q = q.where('class', isEqualTo: _selectedClass);
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return _shimmerList();
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(
            icon: Icons.event_note,
            title: 'No Records Found',
            subtitle: _selectedClass != null
                ? 'No attendance marked for Class $_selectedClass on ${_displayDate(_selectedDate)}'
                : 'No attendance marked for ${_displayDate(_selectedDate)}',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final rec   = docs[i].data() as Map<String, dynamic>;
            final status= rec['status'] ?? 'unknown';
            final color = _statusColors[status] ?? _textMuted;
            final icon  = _statusIcons[status] ?? Icons.help;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: widget.isMobile
                  ? _mobileRecord(rec, status, color, icon)
                  : _desktopRecord(rec, status, color, icon),
            );
          },
        );
      },
    );
  }

  Widget _mobileRecord(Map rec, String status, Color color, IconData icon) =>
      Padding(padding: EdgeInsets.all(14.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _statusIconBox(color, icon),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rec['studentName'] ?? 'Unknown',
                style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 3.h),
            Row(children: [
              _miniBadge('Roll: ${rec['rollNumber'] ?? '--'}', _textSecondary),
              SizedBox(width: 6.w),
              _miniBadge('Class: ${rec['class'] ?? '--'}', _textSecondary),
            ]),
          ])),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          _statusLabel(status, color, icon),
          const Spacer(),
          Text(_fmtTs(rec['markedAt']),
              style: TextStyle(color: _textMuted, fontSize: 11.sp)),
        ]),
      ]));

  Widget _desktopRecord(Map rec, String status, Color color, IconData icon) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(children: [
          _statusIconBox(color, icon),
          SizedBox(width: 14.w),
          SizedBox(width: 180.w,
              child: Text(rec['studentName'] ?? 'Unknown',
                  style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
          SizedBox(width: 12.w),
          _miniBadge('Roll: ${rec['rollNumber'] ?? '--'}', _textSecondary),
          SizedBox(width: 8.w),
          _miniBadge('Class: ${rec['class'] ?? '--'}', _textSecondary),
          const Spacer(),
          Text(_fmtTs(rec['markedAt']), style: TextStyle(color: _textMuted, fontSize: 12.sp)),
          SizedBox(width: 16.w),
          _statusLabel(status, color, icon),
        ]),
      );

  Widget _statusIconBox(Color color, IconData icon) => Container(
    width: 40.w, height: 40.w,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Center(child: Icon(icon, color: color, size: 20.sp)),
  );

  Widget _statusLabel(String status, Color color, IconData icon) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14.sp),
      SizedBox(width: 6.w),
      Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w700)),
    ]),
  );

  String _fmtTs(dynamic ts) {
    if (ts is Timestamp) return DateFormat('hh:mm a').format(ts.toDate());
    return '--:--';
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3 — MONTHLY ANALYTICS
  // ═══════════════════════════════════════════════════════════
  Widget _analyticsTab() => SingleChildScrollView(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _analyticsHeader(),
      SizedBox(height: 16.h),
      _monthSelector(),
      SizedBox(height: 16.h),
      _analyticsClassChips(),
      SizedBox(height: 16.h),
      _monthlyStats(),
      SizedBox(height: 16.h),
      _trendChart(),
      SizedBox(height: 16.h),
      _classBreakdown(),
      SizedBox(height: 16.h),
      _topPerformers(),
      SizedBox(height: 16.h),
      _lowAttendanceAlerts(),
      SizedBox(height: 16.h),
    ]),
  );

  Widget _analyticsHeader() => Row(children: [
    _iconBox(Icons.analytics, _primary, gradient: true),
    SizedBox(width: 12.w),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Attendance Analytics',
          style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700)),
      SizedBox(height: 2.h),
      Text('Deep insights into attendance patterns & trends',
          style: TextStyle(color: _textSecondary, fontSize: 12.sp)),
    ])),
  ]);

  Widget _monthSelector() {
    final now    = DateTime.now();
    final months = List.generate(12, (i) {
      final m = DateTime(now.year, now.month - i, 1);
      return {'label': DateFormat('MMMM yyyy').format(m), 'value': _monthId(m)};
    });
    final cur = _monthId(_selectedDate);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: _cardDecor(),
      child: Row(children: [
        _iconBox(Icons.calendar_month, _primary),
        SizedBox(width: 16.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Analysis Period', style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w500)),
          SizedBox(height: 4.h),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: cur,
              isExpanded: true,
              dropdownColor: _bgCard,
              icon: Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20.sp),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              items: months.map((m) => DropdownMenuItem(
                value: m['value'],
                child: Text(m['label']!, style: TextStyle(color: _textPrimary, fontSize: 14.sp)),
              )).toList(),
              onChanged: (v) {
                if (v == null) return;
                final p = v.split('-');
                setState(() => _selectedDate = DateTime(int.parse(p[0]), int.parse(p[1]), 1));
              },
            ),
          ),
        ])),
      ]),
    );
  }

  Widget _analyticsClassChips() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Filter by Class', style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
      SizedBox(height: 10.h),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _chip(null, 'All Classes', Icons.pie_chart),
          ..._availableClasses.map((c) => _chip(c, c, Icons.class_)),
        ]),
      ),
    ],
  );

  // ─── MONTHLY STATS (FutureBuilder) ───
  Widget _monthlyStats() {
    final mStr = _monthId(_selectedDate);
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return FutureBuilder<List<QuerySnapshot>>(
      future: _fetchMonthRecords(mStr, days),
      builder: (ctx, snap) {
        if (!snap.hasData) return _shimmerSummary();
        final all = snap.data!.expand((s) => s.docs).toList();
        final filtered = _selectedClass != null
            ? all.where((d) => (d.data() as Map)['class'] == _selectedClass).toList()
            : all;
        if (filtered.isEmpty) return _emptyAnalytics();
        final total   = filtered.length;
        final present = filtered.where((d) => (d.data() as Map)['status'] == 'present').length;
        final absent  = filtered.where((d) => (d.data() as Map)['status'] == 'absent').length;
        final late    = filtered.where((d) => (d.data() as Map)['status'] == 'late').length;
        final leave   = filtered.where((d) => (d.data() as Map)['status'] == 'leave').length;
        final pct     = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';
        final wDays   = _workingDays(_selectedDate.year, _selectedDate.month);
        return Column(children: [
          _kpiCard(pct, total),
          SizedBox(height: 12.h),
          _statGrid([
            _statCard('Present', present, _accentSuccess, Icons.check_circle),
            _statCard('Absent',  absent,  _accentDanger,  Icons.cancel),
            _statCard('Late',    late,    _accentWarning,  Icons.access_time),
            _statCard('Leave',   leave,   _accentInfo,     Icons.beach_access),
          ]),
          SizedBox(height: 12.h),
          _workingDaysRow(wDays, total),
        ]);
      },
    );
  }

  Widget _kpiCard(String percentage, int totalRecords) {
    final pct   = double.tryParse(percentage) ?? 0;
    final color = pct >= 90 ? _accentSuccess : pct >= 75 ? _accentWarning : _accentDanger;
    final label = pct >= 90 ? 'EXCELLENT' : pct >= 75 ? 'GOOD' : 'NEEDS ATTENTION';
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.15), _bgCard]),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
            child: Icon(Icons.trending_up, color: color, size: 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Monthly Average', style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
            SizedBox(height: 4.h),
            Text('$percentage%', style: TextStyle(color: color, fontSize: 36.sp, fontWeight: FontWeight.w800)),
          ])),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          _pill(label, color),
          SizedBox(width: 12.w),
          Text('Based on $totalRecords records', style: TextStyle(color: _textMuted, fontSize: 12.sp)),
        ]),
      ]),
    );
  }

  Widget _workingDaysRow(int wDays, int entries) => Container(
    padding: EdgeInsets.all(14.w),
    decoration: _cardDecor(),
    child: Row(children: [
      Icon(Icons.date_range, color: _primary, size: 20.sp),
      SizedBox(width: 12.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Working Days', style: TextStyle(color: _textSecondary, fontSize: 12.sp)),
        Text('$wDays days in ${DateFormat('MMMM yyyy').format(_selectedDate)}',
            style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
      ])),
      _pill('$entries entries', _primary),
    ]),
  );

  // ─── TREND CHART ───
  Widget _trendChart() {
    final mStr = _monthId(_selectedDate);
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _trendData(mStr, days),
      builder: (ctx, snap) {
        if (!snap.hasData) return _shimmerCard();
        final data = snap.data!;
        if (data.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: _cardDecor(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.show_chart, color: _primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Daily Attendance Trend',
                  style: TextStyle(color: _textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ]),
            SizedBox(height: 16.h),
            SizedBox(height: 200.h, child: _bars(data)),
            SizedBox(height: 12.h),
            _legend(),
          ]),
        );
      },
    );
  }

  Widget _bars(List<Map<String, dynamic>> data) {
    final maxTotal = data.map((d) => d['total'] as int).reduce((a, b) => a > b ? a : b);
    if (maxTotal == 0) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((d) {
        final total   = d['total']   as int;
        final present = d['present'] as int;
        final absent  = d['absent']  as int;
        final late    = d['late']    as int;
        final leave   = d['leave']   as int;
        final barH    = (total / maxTotal * 160).h;
        final ph = total > 0 ? (present / total * barH) : 0.0;
        final ah = total > 0 ? (absent  / total * barH) : 0.0;
        final lah= total > 0 ? (late    / total * barH) : 0.0;
        final leh= total > 0 ? (leave   / total * barH) : 0.0;
        return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
            decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(4.r)),
            child: Text('$present/$total', style: TextStyle(color: _textSecondary, fontSize: 7.sp)),
          ),
          SizedBox(height: 4.h),
          Container(
            height: barH, width: 12.w,
            decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(2.r)),
            clipBehavior: Clip.hardEdge,
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (ph > 0) Container(height: ph, color: _accentSuccess),
              if (ah > 0) Container(height: ah, color: _accentDanger),
              if (lah > 0) Container(height: lah, color: _accentWarning),
              if (leh > 0) Container(height: leh, color: _accentInfo),
            ]),
          ),
          SizedBox(height: 4.h),
          Text((d['day'] as int).toString(), style: TextStyle(color: _textMuted, fontSize: 8.sp)),
        ]));
      }).toList(),
    );
  }

  Widget _legend() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _legendItem('Present', _accentSuccess),
      SizedBox(width: 16.w),
      _legendItem('Absent',  _accentDanger),
      SizedBox(width: 16.w),
      _legendItem('Late',    _accentWarning),
      SizedBox(width: 16.w),
      _legendItem('Leave',   _accentInfo),
    ],
  );

  Widget _legendItem(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8.w, height: 8.w, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.r))),
    SizedBox(width: 4.w),
    Text(label, style: TextStyle(color: _textSecondary, fontSize: 11.sp)),
  ]);

  // ─── CLASS BREAKDOWN ───
  Widget _classBreakdown() {
    final mStr = _monthId(_selectedDate);
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _classData(mStr, days),
      builder: (ctx, snap) {
        if (!snap.hasData) return _shimmerCard();
        final all = snap.data!;
        if (all.isEmpty) return const SizedBox.shrink();
        final display = _selectedClass != null && all.containsKey(_selectedClass)
            ? {_selectedClass!: all[_selectedClass!]!}
            : all;
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: _cardDecor(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.donut_large, color: _primary, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Class-wise Breakdown',
                  style: TextStyle(color: _textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ]),
            SizedBox(height: 16.h),
            ...display.entries.map((e) {
              final cls = e.key;
              final d   = e.value;
              final pct = (d['percentage'] as double);
              final color = pct >= 90 ? _accentSuccess : pct >= 75 ? _accentWarning : _accentDanger;
              return Padding(padding: EdgeInsets.only(bottom: 12.h), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('Class $cls', style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(color: color, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  ]),
                  SizedBox(height: 6.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: pct / 100, backgroundColor: _bgElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8.h,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(children: [
                    Text('${d['present']}/${d['total']} present', style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                    const Spacer(),
                    _tinyBadge('${d['absent']} Abs', _accentDanger),
                    SizedBox(width: 4.w),
                    _tinyBadge('${d['late']} Late', _accentWarning),
                    SizedBox(width: 4.w),
                    _tinyBadge('${d['leave']} Leave', _accentInfo),
                  ]),
                ],
              ));
            }).toList(),
          ]),
        );
      },
    );
  }

  Widget _tinyBadge(String text, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
    child: Text(text, style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.w600)),
  );

  // ─── TOP PERFORMERS ───
  Widget _topPerformers() {
    final mStr = _monthId(_selectedDate);
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _studentRankings(mStr, days),
      builder: (ctx, snap) {
        if (!snap.hasData) return _shimmerCard();
        final all = snap.data!;
        if (all.isEmpty) return const SizedBox.shrink();
        final filtered = _selectedClass != null
            ? all.where((r) => r['class'] == _selectedClass).toList()
            : all;
        final top = filtered.take(5).toList();
        if (top.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: _cardDecor(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.emoji_events, color: _accentWarning, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Top Performers',
                  style: TextStyle(color: _textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ]),
            SizedBox(height: 16.h),
            ...top.asMap().entries.map((e) {
              final i   = e.key;
              final s   = e.value;
              final pct = s['percentage'] as double;
              final rankColors  = [_accentWarning, _textSecondary, _accentInfo, _textMuted, _textMuted];
              final medalColors = [Colors.amber, Colors.grey.shade300, Colors.orange.shade300, _bgElevated, _bgElevated];
              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: i < 3 ? rankColors[i].withOpacity(0.3) : _border),
                ),
                child: Row(children: [
                  Container(
                    width: 36.w, height: 36.w,
                    decoration: BoxDecoration(
                      color: medalColors[i], shape: BoxShape.circle,
                      border: Border.all(color: rankColors[i].withOpacity(0.5)),
                    ),
                    child: Center(child: Text('#${i+1}',
                        style: TextStyle(
                          color: i < 3 ? _bgDark : _textSecondary,
                          fontSize: 12.sp, fontWeight: FontWeight.w800,
                        ))),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['name'] as String,
                        style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    Text('Class ${s['class']} • Roll: ${s['rollNumber']}',
                        style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${pct.toStringAsFixed(1)}%',
                        style: TextStyle(color: _accentSuccess, fontSize: 16.sp, fontWeight: FontWeight.w800)),
                    Text('${s['presentDays']}/${s['totalDays']} days',
                        style: TextStyle(color: _textMuted, fontSize: 10.sp)),
                  ]),
                ]),
              );
            }).toList(),
          ]),
        );
      },
    );
  }

  // ─── LOW ATTENDANCE ALERTS ───
  Widget _lowAttendanceAlerts() {
    final mStr = _monthId(_selectedDate);
    final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _lowAttendance(mStr, days),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final all = snap.data!;
        final filtered = _selectedClass != null
            ? all.where((s) => s['class'] == _selectedClass).toList()
            : all;
        if (filtered.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_accentDanger.withOpacity(0.1), _bgCard]),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _accentDanger.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.warning_amber, color: _accentDanger, size: 20.sp),
              SizedBox(width: 8.w),
              Text('Low Attendance Alert',
                  style: TextStyle(color: _accentDanger, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            ]),
            SizedBox(height: 12.h),
            Text('${filtered.length} student(s) below 75% attendance',
                style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
            SizedBox(height: 12.h),
            ...filtered.take(5).map((s) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(children: [
                Container(
                  width: 32.w, height: 32.w,
                  decoration: BoxDecoration(color: _accentDanger.withOpacity(0.1), shape: BoxShape.circle),
                  child: Center(child: Text((s['name'] as String)[0],
                      style: TextStyle(color: _accentDanger, fontSize: 12.sp, fontWeight: FontWeight.w700))),
                ),
                SizedBox(width: 10.w),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['name'] as String,
                      style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  Text('Class ${s['class']} • ${(s['percentage'] as double).toStringAsFixed(1)}%',
                      style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                ])),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _accentDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text('${s['absentDays']} absences',
                      style: TextStyle(color: _accentDanger, fontSize: 10.sp, fontWeight: FontWeight.w600)),
                ),
              ]),
            )).toList(),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ASYNC DATA HELPERS
  // ═══════════════════════════════════════════════════════════
  Future<List<QuerySnapshot>> _fetchMonthRecords(String mStr, int days) =>
      Future.wait(List.generate(days, (i) {
        final dayStr = (i + 1).toString().padLeft(2, '0');
        return _recordsCol('$mStr-$dayStr').get();
      }));

  Future<List<Map<String, dynamic>>> _trendData(String mStr, int days) async {
    final result = <Map<String, dynamic>>[];
    for (int day = 1; day <= days; day++) {
      final id   = '$mStr-${day.toString().padLeft(2,'0')}';
      Query q    = _recordsCol(id);
      if (_selectedClass != null) q = q.where('class', isEqualTo: _selectedClass);
      final snap = await q.get();
      if (snap.docs.isNotEmpty) {
        int p = 0, ab = 0, la = 0, le = 0;
        for (final d in snap.docs) {
          switch ((d.data() as Map)['status']) {
            case 'present': p++;  break;
            case 'absent' : ab++; break;
            case 'late'   : la++; break;
            case 'leave'  : le++; break;
          }
        }
        result.add({'day': day,'total': snap.docs.length,'present': p,'absent': ab,'late': la,'leave': le});
      }
    }
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> _classData(String mStr, int days) async {
    final map = <String, Map<String, dynamic>>{};
    for (int day = 1; day <= days; day++) {
      final id   = '$mStr-${day.toString().padLeft(2,'0')}';
      final snap = await _recordsCol(id).get();
      for (final d in snap.docs) {
        final data   = d.data() as Map<String, dynamic>;
        final cls    = data['class'] as String;
        final status = data['status'] as String;
        map.putIfAbsent(cls, () => {'total':0,'present':0,'absent':0,'late':0,'leave':0});
        map[cls]!['total']  = (map[cls]!['total']  as int) + 1;
        map[cls]![status]   = ((map[cls]![status] ?? 0) as int) + 1;
      }
    }
    for (final e in map.entries) {
      final t = e.value['total'] as int;
      final p = (e.value['present'] ?? 0) as int;
      e.value['percentage'] = t > 0 ? p / t * 100 : 0.0;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> _studentRankings(String mStr, int days) async {
    final stats = <String, Map<String, dynamic>>{};
    for (int day = 1; day <= days; day++) {
      final id   = '$mStr-${day.toString().padLeft(2,'0')}';
      final snap = await _recordsCol(id).get();
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final sid  = data['studentId'] as String;
        stats.putIfAbsent(sid, () => {
          'name'       : data['studentName'],
          'class'      : data['class'],
          'rollNumber' : data['rollNumber'],
          'totalDays'  : 0,
          'presentDays': 0,
        });
        stats[sid]!['totalDays'] = (stats[sid]!['totalDays'] as int) + 1;
        if (data['status'] == 'present') {
          stats[sid]!['presentDays'] = (stats[sid]!['presentDays'] as int) + 1;
        }
      }
    }
    final list = stats.values.toList();
    for (final s in list) {
      final t = s['totalDays'] as int;
      final p = s['presentDays'] as int;
      s['percentage'] = t > 0 ? p / t * 100 : 0.0;
    }
    list.sort((a, b) => (b['percentage'] as double).compareTo(a['percentage'] as double));
    return list;
  }

  Future<List<Map<String, dynamic>>> _lowAttendance(String mStr, int days) async {
    final stats = <String, Map<String, dynamic>>{};
    for (int day = 1; day <= days; day++) {
      final id   = '$mStr-${day.toString().padLeft(2,'0')}';
      final snap = await _recordsCol(id).get();
      for (final d in snap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final sid  = data['studentId'] as String;
        stats.putIfAbsent(sid, () => {
          'name'       : data['studentName'],
          'class'      : data['class'],
          'totalDays'  : 0,
          'presentDays': 0,
          'absentDays' : 0,
        });
        stats[sid]!['totalDays']  = (stats[sid]!['totalDays']  as int) + 1;
        if (data['status'] == 'present') stats[sid]!['presentDays'] = (stats[sid]!['presentDays'] as int) + 1;
        if (data['status'] == 'absent')  stats[sid]!['absentDays']  = (stats[sid]!['absentDays']  as int) + 1;
      }
    }
    final low = <Map<String, dynamic>>[];
    for (final e in stats.entries) {
      final t   = e.value['totalDays']   as int;
      final p   = e.value['presentDays'] as int;
      final pct = t > 0 ? p / t * 100 : 0.0;
      if (pct < 75) {
        e.value['percentage'] = pct;
        low.add(e.value);
      }
    }
    low.sort((a, b) => (a['percentage'] as double).compareTo(b['percentage'] as double));
    return low;
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED UI HELPERS
  // ═══════════════════════════════════════════════════════════
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _primary, surface: _bgCard, onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() { _selectedDate = d; _attendanceCache.clear(); });
  }

  BoxDecoration _cardDecor({bool shadow = false}) => BoxDecoration(
    color: _bgCard,
    borderRadius: BorderRadius.circular(12.r),
    border: Border.all(color: _border),
    boxShadow: shadow
        ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
        : null,
  );

  BoxDecoration _elevatedDecor() => BoxDecoration(
    color: _bgElevated,
    borderRadius: BorderRadius.circular(10.r),
    border: Border.all(color: _border),
  );

  Widget _miniBadge(String text, Color textColor) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(6.r)),
    child: Text(text, style: TextStyle(color: textColor, fontSize: 11.sp, fontWeight: FontWeight.w500)),
  );

  Widget _infoCard(String title, String subtitle) => Container(
    padding: EdgeInsets.all(24.w),
    decoration: _cardDecor(),
    child: Row(children: [
      Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: _accentWarning.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.info_outline, color: _accentWarning, size: 24.sp),
      ),
      SizedBox(width: 16.w),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 4.h),
        Text(subtitle, style: TextStyle(color: _textSecondary, fontSize: 12.sp)),
      ])),
    ]),
  );

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) =>
      Center(child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: _primary, size: 48.sp),
          ),
          SizedBox(height: 20.h),
          Text(title, style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          Text(subtitle, style: TextStyle(color: _textSecondary, fontSize: 14.sp), textAlign: TextAlign.center),
        ]),
      ));

  Widget _emptyAnalytics() => Container(
    padding: EdgeInsets.all(40.w),
    decoration: _cardDecor(),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(color: _primary.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.analytics_outlined, color: _primary, size: 48.sp),
      ),
      SizedBox(height: 20.h),
      Text('No Data Available', style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)),
      SizedBox(height: 8.h),
      Text(
        'No records for ${DateFormat('MMMM yyyy').format(_selectedDate)}'
            '${_selectedClass != null ? ' in Class $_selectedClass' : ''}',
        style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        textAlign: TextAlign.center,
      ),
    ]),
  );

  Widget _errorState(String title, String msg) => Center(child: Padding(
    padding: EdgeInsets.all(40.w),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(color: _accentDanger.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(Icons.error_outline, color: _accentDanger, size: 48.sp),
      ),
      SizedBox(height: 20.h),
      Text(title, style: TextStyle(color: _accentDanger, fontSize: 20.sp, fontWeight: FontWeight.w700)),
      SizedBox(height: 8.h),
      Text(msg, style: TextStyle(color: _textSecondary, fontSize: 14.sp), textAlign: TextAlign.center),
    ]),
  ));

  Widget _shimmerList() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 5,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: _bgCard,
      highlightColor: _bgElevated,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r)),
        child: Row(children: [
          Container(width: 48.w, height: 48.w, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: double.infinity, height: 16.h,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r))),
            SizedBox(height: 8.h),
            Container(width: 150.w, height: 12.h,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r))),
          ])),
        ]),
      ),
    ),
  );

  Widget _shimmerSummary() => widget.isMobile
      ? Column(children: [
    _shimmerCard(), SizedBox(height: 8.h),
    _shimmerCard(), SizedBox(height: 8.h),
    _shimmerCard(),
  ])
      : Row(children: [
    Expanded(child: _shimmerCard()), SizedBox(width: 12.w),
    Expanded(child: _shimmerCard()), SizedBox(width: 12.w),
    Expanded(child: _shimmerCard()), SizedBox(width: 12.w),
    Expanded(child: _shimmerCard()),
  ]);

  Widget _shimmerCard() => Shimmer.fromColors(
    baseColor: _bgCard,
    highlightColor: _bgElevated,
    child: Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36.w, height: 36.w,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r))),
          const Spacer(),
          Container(width: 50.w, height: 24.h,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r))),
        ]),
        SizedBox(height: 12.h),
        Container(width: 80.w, height: 14.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r))),
      ]),
    ),
  );
}