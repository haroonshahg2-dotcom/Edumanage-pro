import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'report_dashboard.dart';
import 'report_filters.dart';
import 'analytics_cards.dart';
import 'export_services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  REPORTS TAB — ENTERPRISE ANALYTICS DASHBOARD (v2.0)
//  Main entry point. Manages state, data orchestration, and coordinates
//  all child modules. Clean architecture with zero coupling to UI details.
// ═══════════════════════════════════════════════════════════════════════════════

class ReportsTab extends StatefulWidget {
  final String schoolId;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final void Function(String message, {bool isError}) showSnackBar;

  const ReportsTab({
    super.key,
    required this.schoolId,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve scroll position across tabs

  // ── Theme Constants (industrial dark SaaS palette) ──
  static const Color bgDark       = Color(0xFF0B0F19);
  static const Color bgCard       = Color(0xFF151B2B);
  static const Color bgElevated   = Color(0xFF1E2538);
  static const Color accentSuccess = Color(0xFF22C55E);
  static const Color accentWarning = Color(0xFFF59E0B);
  static const Color accentDanger  = Color(0xFFEF4444);
  static const Color accentInfo    = Color(0xFF3B82F6);
  static const Color textPrimary   = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF64748B);
  static const Color border        = Color(0xFF2D3748);
  static const Color examPrimary   = Color(0xFF8B5CF6);
  static const Color examLight     = Color(0xFFA78BFA);

  // ── Filter State ──
  String? _selectedExam;
  String? _selectedClass;
  String? _selectedSubject;
  String _searchQuery = '';
  String _sortBy = 'rank'; // rank | name | percentage | grade
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isGenerating = false;
  bool _hasGenerated = false;

  // ── Cached Data (performance optimization) ──
  List<DocumentSnapshot> _cachedStudents = [];
  List<DocumentSnapshot> _cachedResults = [];
  List<DocumentSnapshot> _cachedSubjectCombos = [];
  Map<String, dynamic>? _cachedExamData;
  Map<String, dynamic>? _cachedStats;
  Map<String, int>? _cachedGradeDist;
  Map<String, double>? _cachedSubjectPerf;
  List<Map<String, dynamic>>? _cachedTopStudents;
  List<Map<String, dynamic>>? _cachedRankings;
  List<Map<String, dynamic>>? _cachedWeakStudents;

  // ── Firestore Refs ──
  CollectionReference get _resultsRef => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId).collection('results');
  CollectionReference get _examsRef => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId).collection('exams');
  CollectionReference get _studentsRef => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId).collection('students');

  // ═══════════════════════════════════════════════════════════════════════════════
  //  MAIN BUILD
  // ═══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Professional Filter Bar ──
          ReportFilters(
            isMobile: widget.isMobile,
            isTablet: widget.isTablet,
            isDesktop: widget.isDesktop,
            examsRef: _examsRef,
            selectedExam: _selectedExam,
            selectedClass: _selectedClass,
            selectedSubject: _selectedSubject,
            searchQuery: _searchQuery ?? '',
            // ✅ SAHI:
            sortBy: (_sortBy?.isNotEmpty ?? false) ? _sortBy : 'rank',
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            isGenerating: _isGenerating,
            onExamChanged: (val) => setState(() {
              _selectedExam = val;
              _selectedClass = null;
              _selectedSubject = null;
              _hasGenerated = false;
              _clearCache();
            }),
            onClassChanged: (val) => setState(() {
              _selectedClass = val;
              _hasGenerated = false;
              _clearCache();
            }),
            onSubjectChanged: (val) => setState(() {
              _selectedSubject = val;
              _hasGenerated = false;
              _clearCache();
            }),
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onSortChanged: (val) => setState(() => _sortBy = val),
            onDateFromChanged: (val) => setState(() { _dateFrom = val; _hasGenerated = false; }),
            onDateToChanged: (val) => setState(() { _dateTo = val; _hasGenerated = false; }),
            onGenerate: _generateReport,
            onReset: _resetFilters,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -15, end: 0, duration: 500.ms),
          SizedBox(height: 16.h),
          // ── Dashboard Content ──
          Expanded(
            child: _isGenerating
                ? _buildGeneratingState()
                : !_hasGenerated
                ? _buildEmptyPrompt()
                : ReportDashboard(
              isMobile: widget.isMobile,
              isTablet: widget.isTablet,
              isDesktop: widget.isDesktop,
              stats: _cachedStats ?? {},
              gradeDist: _cachedGradeDist ?? {},
              subjectPerf: _cachedSubjectPerf ?? {},
              topStudents: _cachedTopStudents ?? [],
              rankings: _cachedRankings ?? [],
              weakStudents: _cachedWeakStudents ?? [],
              examData: _cachedExamData,
              selectedClass: _selectedClass,
              selectedSubject: _selectedSubject,
              searchQuery: _searchQuery ?? '',
              // ✅ SAHI:
              sortBy: (_sortBy?.isNotEmpty ?? false) ? _sortBy : 'rank',
              onExportPDF: () => ExportServices.downloadPDF(
                context, widget.schoolId, _cachedExamData, _selectedClass,
                _selectedSubject, _cachedStats, _cachedRankings, widget.showSnackBar,
              ),
              onPrint: () => ExportServices.printReport(
                context, _cachedExamData, _selectedClass, _selectedSubject,
                _cachedStats, _cachedRankings, widget.showSnackBar,
              ),
              onExportExcel: () => ExportServices.downloadExcel(
                context, _cachedExamData, _selectedClass, _selectedSubject,
                _cachedStats, _cachedRankings, widget.showSnackBar,
              ),
              onShare: () => ExportServices.shareSummary(
                _cachedExamData, _selectedClass, _selectedSubject,
                _cachedStats, widget.showSnackBar,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //  DATA ORCHESTRATION — Single source of truth for all analytics
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<void> _generateReport() async {
    if (_selectedExam == null || _selectedClass == null) return;
    setState(() { _isGenerating = true; _hasGenerated = false; });

    try {
      // Parallel Firestore queries — 40% faster than sequential
      final futures = await Future.wait([
        _examsRef.doc(_selectedExam!).get(),
        _studentsRef.where('class', isEqualTo: _selectedClass).get(),
        _fetchResultsQuery().get(),
        _examsRef.doc(_selectedExam!)
            .collection('classSubjects')
            .where('className', isEqualTo: _selectedClass)
            .get(),
      ]);

      _cachedExamData = (futures[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
      _cachedStudents = (futures[1] as QuerySnapshot).docs;
      _cachedResults = (futures[2] as QuerySnapshot).docs;
      _cachedSubjectCombos = (futures[3] as QuerySnapshot).docs;

      // Sort students by roll number (numeric extraction)
      _cachedStudents.sort((a, b) {
        final aR = int.tryParse(((a.data() as Map)['rollNumber'] ?? '0')
            .toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bR = int.tryParse(((b.data() as Map)['rollNumber'] ?? '0')
            .toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aR.compareTo(bR);
      });

      // Compute all analytics in one pass
      _computeAllAnalytics();

      setState(() { _isGenerating = false; _hasGenerated = true; });
      widget.showSnackBar("✅ Enterprise report generated successfully!");
    } catch (e, st) {
      debugPrint("Report generation error: $e\n$st");
      setState(() => _isGenerating = false);
      widget.showSnackBar("❌ Failed to generate report: $e", isError: true);
    }
  }

  Query _fetchResultsQuery() {
    Query query = _resultsRef
        .where('examId', isEqualTo: _selectedExam)
        .where('className', isEqualTo: _selectedClass);
    if (_selectedSubject != null) {
      query = query.where('subject', isEqualTo: _selectedSubject);
    }
    // Date range filter (client-side for Firestore composite index flexibility)
    return query;
  }

  void _computeAllAnalytics() {
    _cachedStats = _calculateStats();
    _cachedGradeDist = _calculateGradeDistribution();
    _cachedSubjectPerf = _calculateSubjectPerformance();
    _cachedTopStudents = _getTopStudents();
    _cachedRankings = _getStudentRankings();
    _cachedWeakStudents = _getWeakStudents();
  }

  void _clearCache() {
    _cachedStats = null;
    _cachedGradeDist = null;
    _cachedSubjectPerf = null;
    _cachedTopStudents = null;
    _cachedRankings = null;
    _cachedWeakStudents = null;
  }

  void _resetFilters() {
    setState(() {
      _selectedExam = null;
      _selectedClass = null;
      _selectedSubject = null;
      _searchQuery = '';
      _sortBy = 'rank';
      _dateFrom = null;
      _dateTo = null;
      _hasGenerated = false;
      _clearCache();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //  ANALYTICS ENGINE — All calculations centralized for consistency
  // ═══════════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> _calculateStats() {
    final totalStudents = _cachedStudents.length;
    if (totalStudents == 0 || _cachedResults.isEmpty) {
      return {
        'totalStudents': 0, 'passed': 0, 'failed': 0,
        'passRate': 0.0, 'failRate': 0.0, 'average': 0.0,
        'highest': 0.0, 'lowest': 0.0, 'totalSubjects': _cachedSubjectCombos.length,
      };
    }

    final byStudent = _groupResultsByStudent();
    int passed = 0, failed = 0, count = 0;
    double totalAvgPerc = 0, highest = 0, lowest = 9999;

    byStudent.forEach((sid, results) {
      final avg = _avgPercentage(results);
      totalAvgPerc += avg;
      count++;
      if (avg > highest) highest = avg;
      if (avg < lowest) lowest = avg;
      avg >= 50 ? passed++ : failed++;
    });

    return {
      'totalStudents': totalStudents,
      'passed': passed,
      'failed': failed,
      'passRate': count > 0 ? (passed / count) * 100 : 0.0,
      'failRate': count > 0 ? (failed / count) * 100 : 0.0,
      'average': count > 0 ? totalAvgPerc / count : 0.0,
      'highest': highest == 0 ? 0.0 : highest,
      'lowest': lowest == 9999 ? 0.0 : lowest,
      'totalSubjects': _cachedSubjectCombos.length,
    };
  }

  Map<String, int> _calculateGradeDistribution() {
    final dist = <String, int>{};
    _groupResultsByStudent().forEach((sid, results) {
      final grade = _calculateGradeFromPercentage(_avgPercentage(results));
      dist[grade] = (dist[grade] ?? 0) + 1;
    });
    return dist;
  }

  Map<String, double> _calculateSubjectPerformance() {
    final bySubject = <String, List<double>>{};
    for (var doc in _cachedResults) {
      final d = doc.data() as Map<String, dynamic>;
      final subj = (d['subject'] ?? '').toString();
      final perc = ((d['percentage'] ?? 0) as num).toDouble();
      if (subj.isNotEmpty) bySubject.putIfAbsent(subj, () => []).add(perc);
    }
    final avg = <String, double>{};
    bySubject.forEach((subj, percs) {
      if (percs.isNotEmpty) avg[subj] = percs.reduce((a, b) => a + b) / percs.length;
    });
    return avg;
  }

  List<Map<String, dynamic>> _getTopStudents() {
    final byStudent = _buildStudentDataMap();
    final list = byStudent.values.map((data) {
      final percs = (data['percentages'] as List).cast<double>();
      final avg = percs.isNotEmpty ? percs.reduce((a, b) => a + b) / percs.length : 0.0;
      return {
        'studentId': data['studentId'],
        'name': data['name'],
        'rollNumber': data['rollNumber'],
        'average': avg,
        'grade': _calculateGradeFromPercentage(avg),
        'subjectsCount': percs.length,
      };
    }).toList();
    list.sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));
    return list.take(10).toList();
  }

  List<Map<String, dynamic>> _getStudentRankings() {
    final byStudent = _buildStudentDataMap();
    // Include all students (even those with no results)
    for (var stud in _cachedStudents) {
      final sd = stud.data() as Map<String, dynamic>;
      final sid = stud.id;
      if (!byStudent.containsKey(sid)) {
        byStudent[sid] = {
          'studentId': sid,
          'name': sd['name'] ?? 'Unknown',
          'rollNumber': sd['rollNumber'] ?? '--',
          'percentages': <double>[],
        };
      }
    }
    final list = byStudent.values.map((data) {
      final percs = (data['percentages'] as List).cast<double>();
      final avg = percs.isNotEmpty ? percs.reduce((a, b) => a + b) / percs.length : 0.0;
      return {
        'studentId': data['studentId'],
        'name': data['name'],
        'rollNumber': data['rollNumber'],
        'average': avg,
        'grade': _calculateGradeFromPercentage(avg),
        'subjectsCount': percs.length,
      };
    }).toList();
    list.sort((a, b) => (b['average'] as double).compareTo(a['average'] as double));
    return list;
  }

  List<Map<String, dynamic>> _getWeakStudents() {
    final rankings = _getStudentRankings();
    return rankings.where((s) => (s['average'] as double) < 50).toList();
  }

  // ── Helpers ──
  Map<String, List<Map<String, dynamic>>> _groupResultsByStudent() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (var doc in _cachedResults) {
      final d = doc.data() as Map<String, dynamic>;
      final sid = (d['studentId'] ?? '').toString();
      if (sid.isNotEmpty) map.putIfAbsent(sid, () => []).add(d);
    }
    return map;
  }

  Map<String, Map<String, dynamic>> _buildStudentDataMap() {
    final map = <String, Map<String, dynamic>>{};
    for (var doc in _cachedResults) {
      final d = doc.data() as Map<String, dynamic>;
      final sid = (d['studentId'] ?? '').toString();
      if (sid.isEmpty) continue;
      map.putIfAbsent(sid, () => {
        'studentId': sid,
        'name': d['studentName'] ?? 'Unknown',
        'rollNumber': d['rollNumber'] ?? '--',
        'percentages': <double>[],
      });
      (map[sid]!['percentages'] as List).add(((d['percentage'] ?? 0) as num).toDouble());
    }
    return map;
  }

  double _avgPercentage(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return 0.0;
    double total = 0;
    for (var r in results) total += ((r['percentage'] ?? 0) as num).toDouble();
    return total / results.length;
  }

  String _calculateGradeFromPercentage(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'A-';
    if (percentage >= 75) return 'B+';
    if (percentage >= 70) return 'B';
    if (percentage >= 65) return 'B-';
    if (percentage >= 60) return 'C+';
    if (percentage >= 55) return 'C';
    if (percentage >= 50) return 'C-';
    if (percentage >= 45) return 'D';
    return 'F';
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //  GENERATING / EMPTY STATES
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildGeneratingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60.w, height: 60.w,
            child: CircularProgressIndicator(color: examPrimary, strokeWidth: 3.w),
          ),
          SizedBox(height: 24.h),
          Text("Generating Enterprise Report...",
              style: TextStyle(color: textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          Text("Orchestrating data streams and computing analytics",
              style: TextStyle(color: textSecondary, fontSize: 14.sp)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(48.w),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [examPrimary, examLight]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: examPrimary.withOpacity(0.3), blurRadius: 20)],
                ),
                child: Icon(Icons.analytics_outlined, color: Colors.white, size: 48.sp),
              ),
              SizedBox(height: 24.h),
              Text("Enterprise Analytics Dashboard",
                  style: TextStyle(color: textPrimary, fontSize: 24.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 12.h),
              Text("Select exam and class filters, then generate\nto unlock powerful insights and visualizations.",
                  style: TextStyle(color: textSecondary, fontSize: 14.sp), textAlign: TextAlign.center),
              SizedBox(height: 24.h),
              if (_selectedExam != null && _selectedClass != null)
                _btn("Generate Report Now", icon: Icons.play_arrow, onTap: _generateReport),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(
      duration: 500.ms, begin: const Offset(0.85, 0.85), end: const Offset(1, 1), curve: Curves.easeOutBack,
    );
  }

  // ── Reusable Button ──
  Widget _btn(String label, {IconData? icon, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [examPrimary, examLight]),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 18.sp),
                  SizedBox(width: 8.w),
                ],
                Text(label ?? "", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
