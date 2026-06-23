import 'package:edumanage/features/admin/presentation/pages/report_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dmc_service.dart';
// REMOVE this old import:
// import 'reports_tab.dart';

// KEEP existing imports, add these new ones:
import 'report_tab.dart';

class ExamResultsModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final Function(String message, {bool isError}) showSnackBar;

  const ExamResultsModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<ExamResultsModule> createState() => _ExamResultsModuleState();
}

class _ExamResultsModuleState extends State<ExamResultsModule>
    with TickerProviderStateMixin {
// Add these getters if missing
  bool get _isMobile => MediaQuery.of(context).size.width < 600;
  bool get _isTablet => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

// Replace _buildReportsView()
  Widget _buildReportsView() {
    return Container(
      color: _bgDark,
      child: ReportsTab(
        schoolId: widget.schoolId,
        isMobile: _isMobile,
        isTablet: _isTablet,
        isDesktop: _isDesktop,

        // Ab (theek) - null check add karein:
        showSnackBar: (msg, {isError = false}) => _showSnackBar(msg, isError: isError ?? false),
      ),
    );
  }
  static const Color _bgDark       = Color(0xFF0B0F19);
  static const Color _bgCard       = Color(0xFF151B2B);
  static const Color _bgElevated   = Color(0xFF1E2538);
  static const Color _accentSuccess = Color(0xFF22C55E);
  static const Color _accentWarning = Color(0xFFF59E0B);
  static const Color _accentDanger  = Color(0xFFEF4444);
  static const Color _accentInfo    = Color(0xFF3B82F6);
  static const Color _textPrimary   = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted     = Color(0xFF64748B);
  static const Color _border        = Color(0xFF2D3748);
  static const Color _examPrimary   = Color(0xFF8B5CF6);
  static const Color _examLight     = Color(0xFFA78BFA);

  late TabController _tabController;
  String? _selectedClass;
  String? _selectedExam;
  String? _selectedSubject;
  Map<String, dynamic>? _selectedCombo;
  String _searchQuery = '';
  String? _meExam;
  String? _meClass;

  Map<String, dynamic> _gradingScale = {
    'A+': {'min': 90, 'max': 100, 'gpa': 4.0},
    'A':  {'min': 85, 'max': 89,  'gpa': 4.0},
    'A-': {'min': 80, 'max': 84,  'gpa': 3.7},
    'B+': {'min': 75, 'max': 79,  'gpa': 3.3},
    'B':  {'min': 70, 'max': 74,  'gpa': 3.0},
    'B-': {'min': 65, 'max': 69,  'gpa': 2.7},
    'C+': {'min': 60, 'max': 64,  'gpa': 2.3},
    'C':  {'min': 55, 'max': 59,  'gpa': 2.0},
    'C-': {'min': 50, 'max': 54,  'gpa': 1.7},
    'D':  {'min': 45, 'max': 49,  'gpa': 1.0},
    'F':  {'min': 0,  'max': 33,  'gpa': 0.0},
  };

  final List<String> _availableClasses = [
    "1A","1B","1C","2A","2B","2C","3A","3B","3C",
    "4A","4B","4C","5A","5B","5C","6A","6B","6C",
    "7A","7B","7C","8A","8B","8C","9A","9B","9C",
    "10A","10B","10C",
  ];

  CollectionReference get _resultsRef => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId)
      .collection('results');

  CollectionReference get _examsRef => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId)
      .collection('exams');

  CollectionReference get _studentsRef => FirebaseFirestore.instance
      .collection('schools').doc(widget.schoolId)
      .collection('students');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeExamSystem();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeExamSystem() async {
    try { await _createDefaultGradingStructure(); }
    catch (e) { print("Exam init error: $e"); }
  }

  Future<void> _createDefaultGradingStructure() async {
    final ref = FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('examConfig').doc('grading');
    try {
      final existing = await ref.get();
      if (existing.exists && existing.data() != null) {
        final loadedScale = existing.data()!['scale'];
        if (loadedScale != null && loadedScale is Map) {
          final converted = <String, dynamic>{};
          loadedScale.forEach((grade, values) {
            if (values is Map) {
              converted[grade.toString()] = {
                'min': ((values['min'] ?? 0)   as num).toInt(),
                'max': ((values['max'] ?? 100) as num).toInt(),
                'gpa': ((values['gpa'] ?? 0.0) as num).toDouble(),
              };
            }
          });
          if (converted.isNotEmpty) setState(() => _gradingScale = converted);
        }
        return;
      }
      await ref.set({
        'scale': _gradingScale,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) { print("Grading init error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildModuleHeader().animate().fadeIn(duration: 400.ms).slideX(begin: -30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
        SizedBox(height: 16.h),
        _buildTabNavigation().animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: -20, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
        SizedBox(height: 16.h),
        Expanded(child: Container(
          color: _bgDark,
          child: TabBarView(controller: _tabController, children: [
            _buildExamsView(),
            _buildResultsView(),
            _buildMarkEntryView(),
            _buildAnalyticsView(),
            _buildReportsView(),
          ]),
        )),
      ]),
    );
  }

  Widget _buildModuleHeader() {
    return widget.isMobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [_headerIcon(), SizedBox(width: 12.w), Expanded(child: _headerText())]),
      SizedBox(height: 12.h),
      Row(children: [
        Expanded(child: _btn("Create Exam", icon: Icons.add, onTap: _showCreateExamDialog)),
        SizedBox(width: 8.w),
        Expanded(child: _btn("Settings", icon: Icons.settings, onTap: _showGradingSettings, secondary: true)),
      ]),
    ])
        : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [_headerIcon(), SizedBox(width: 16.w), _headerText(desktop: true)]),
      Row(children: [
        _btn("Settings", icon: Icons.settings, onTap: _showGradingSettings, secondary: true),
        SizedBox(width: 12.w),
        _btn("Create Exam", icon: Icons.add, onTap: _showCreateExamDialog),
      ]),
    ]);
  }

  Widget _headerIcon() => Container(
    padding: EdgeInsets.all(widget.isMobile ? 10.w : 12.w),
    decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(12.r)),
    child: Icon(Icons.assignment, color: Colors.white, size: widget.isMobile ? 24.sp : 28.sp),
  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
      .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3));

  Widget _headerText({bool desktop = false}) => desktop
      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Exam & Results Management", style: TextStyle(color: _textPrimary, fontSize: 28.sp, fontWeight: FontWeight.w800)),
    Text("hybrid grading system", style: TextStyle(color: _textSecondary, fontSize: 14.sp)),
  ])
      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("Exam & Results", style: TextStyle(color: _textPrimary, fontSize: 22.sp, fontWeight: FontWeight.w800)),
    Text("Multi-class grading", style: TextStyle(color: _examPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
  ]);

  Widget _buildTabNavigation() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(colors: [_examPrimary, _examLight]),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [BoxShadow(color: _examPrimary.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))],
        ),
        labelColor: Colors.white, unselectedLabelColor: _textSecondary,
        labelStyle: TextStyle(fontSize: widget.isMobile ? 11.sp : 13.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: widget.isMobile ? 11.sp : 13.sp, fontWeight: FontWeight.w500),
        isScrollable: widget.isMobile,
        tabs: const [
          Tab(icon: Icon(Icons.assignment), text: "Exams"),
          Tab(icon: Icon(Icons.scoreboard), text: "Results"),
          Tab(icon: Icon(Icons.edit_note), text: "Mark Entry"),
          Tab(icon: Icon(Icons.analytics), text: "Analytics"),
          Tab(icon: Icon(Icons.summarize), text: "Reports"),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -20, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 1: EXAMS
  // ═══════════════════════════════════════════════════════════



  Widget _buildExamFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
      child: widget.isMobile
          ? Column(children: [_buildClassDropdown(), SizedBox(height: 12.h), _buildSearchField()])
          : Row(children: [
        Expanded(child: _buildClassDropdown()), SizedBox(width: 12.w),
        Expanded(child: _buildExamTypeDropdown()), SizedBox(width: 12.w),
        Expanded(child: _buildSearchField()), SizedBox(width: 12.w),
        _btn("Filter", icon: Icons.filter_list, onTap: () {}, secondary: true),
      ]),
    );
  }

  Widget _buildExamsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _shimmerList();
        final exams = snapshot.data!.docs.where((doc) {
          final name = ((doc.data() as Map)['name'] ?? '').toString().toLowerCase();
          return _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
        }).toList();
        if (exams.isEmpty) return _emptyState(icon: Icons.assignment_outlined, title: "No exams found", subtitle: "Create your first exam");
        return widget.isMobile
            ? ListView.builder(
          itemCount: exams.length,
          itemBuilder: (_, i) => _buildExamCard(exams[i])
              .animate(delay: (i * 80).ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
        )
            : _buildExamsTable(exams).animate().fadeIn(duration: 500.ms);
      },
    );
  }

  Widget _buildExamCard(DocumentSnapshot exam) {
    final d = exam.data() as Map<String, dynamic>;
    final status      = (d['status'] ?? 'draft').toString();
    final isPublished = d['isPublished'] == true;
    final statusColor = status == 'published' ? _accentSuccess : status == 'ongoing' ? _accentWarning : _textMuted;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h), padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: status == 'published' ? _accentSuccess.withOpacity(0.3) : _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(_examIcon(d['type']), color: _examPrimary, size: 24.sp)),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d['name'] ?? 'Unnamed', style: TextStyle(color: _textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)),
            Text("${d['type']} • Max ${d['maxMarks']} marks", style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
          ])),
          _statusChip(status, statusColor),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          _miniStat(Icons.calendar_today, _fmtDate(d['examDate'])),
          SizedBox(width: 16.w), _miniStat(Icons.access_time, "${d['duration'] ?? 0} min"),
          SizedBox(width: 16.w), _miniStat(Icons.grade, "Max: ${d['maxMarks'] ?? 100}"),
        ]),
        SizedBox(height: 12.h),
        _buildCombosList(exam.id),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(child: _btn("+ Add Class/Subject", icon: Icons.add_circle_outline, onTap: () => _showAddClassSubjectDialog(exam), secondary: true)),
          SizedBox(width: 8.w),
          Expanded(child: _btn(isPublished ? "Published" : "Publish", icon: isPublished ? Icons.check_circle : Icons.publish, onTap: isPublished ? null : () => _publishExam(exam))),
        ]),
      ]),
    );
  }

  Widget _buildCombosList(String examId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.doc(examId).collection('classSubjects').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: _border)),
              child: Row(children: [Icon(Icons.info_outline, color: _textMuted, size: 16.sp), SizedBox(width: 8.w), Text("No class-subject added yet", style: TextStyle(color: _textMuted, fontSize: 13.sp))]));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Classes & Subjects (${snap.data!.docs.length})", style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 8.h),
          Wrap(spacing: 8.w, runSpacing: 8.h, children: snap.data!.docs.map((c) => _comboChip(examId, c.id, c.data() as Map<String, dynamic>)).toList()),
        ]);
      },
    );
  }

  Widget _comboChip(String examId, String comboId, Map<String, dynamic> d) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCombo = {'examId': examId, 'comboId': comboId, 'classId': d['className'], 'subject': d['subject'], 'maxMarks': d['maxMarks'] ?? 100};
          _selectedClass = d['className']?.toString(); _selectedExam = examId;
        });
        _tabController.animateTo(1);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: _examPrimary.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.class_, color: _examPrimary, size: 14.sp), SizedBox(width: 6.w),
          Text("${d['className']} • ${d['subject']}", style: TextStyle(color: _examPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          SizedBox(width: 6.w),
          Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(10.r)),
              child: Text("Pass: ${d['passingMarks'] ?? '--'}/${d['maxMarks'] ?? 100}", style: TextStyle(color: _examPrimary, fontSize: 9.sp, fontWeight: FontWeight.w700))),
          SizedBox(width: 4.w),
          Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: _examPrimary, borderRadius: BorderRadius.circular(10.r)),
              child: Text("${d['marksEntered'] ?? 0}/${d['totalStudents'] ?? 0}", style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w700))),
        ]),
      ),
    ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack).fadeIn(duration: 300.ms);
  }

  Widget _buildExamsTable(List<DocumentSnapshot> exams) {
    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
      child: Column(children: [
        Container(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.vertical(top: Radius.circular(12.r))),
            child: Row(children: [Expanded(flex: 2, child: Text("Exam Name", style: _thStyle())), Expanded(child: Text("Type", style: _thStyle())), Expanded(child: Text("Date", style: _thStyle())), Expanded(child: Text("Classes", style: _thStyle())), Expanded(child: Text("Status", style: _thStyle())), SizedBox(width: 120.w)])),
        Expanded(child: ListView.separated(
          itemCount: exams.length,
          separatorBuilder: (_, __) => Divider(color: _border, height: 1),
          itemBuilder: (_, i) => _examTableRow(exams[i])
              .animate(delay: (i * 60).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -20, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
        )),
      ]),
    );
  }

  Widget _examTableRow(DocumentSnapshot exam) {
    final d = exam.data() as Map<String, dynamic>;
    final status = (d['status'] ?? 'draft').toString();
    final statusColor = status == 'published' ? _accentSuccess : status == 'ongoing' ? _accentWarning : _textMuted;
    return Container(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(children: [
        Expanded(flex: 2, child: Row(children: [
          Container(padding: EdgeInsets.all(8.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)), child: Icon(_examIcon(d['type']), color: _examPrimary, size: 18.sp)),
          SizedBox(width: 12.w),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['name'] ?? '', style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis), Text("Max ${d['maxMarks']} marks", style: TextStyle(color: _textMuted, fontSize: 11.sp))])),
        ])),
        Expanded(child: Text(d['type'] ?? '', style: TextStyle(color: _textSecondary, fontSize: 13.sp))),
        Expanded(child: Text(_fmtDate(d['examDate']), style: TextStyle(color: _textSecondary, fontSize: 13.sp))),
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: _examsRef.doc(exam.id).collection('classSubjects').snapshots(),
          builder: (_, s) => Row(children: [Icon(Icons.class_, color: _examPrimary, size: 14.sp), SizedBox(width: 4.w), Text("${s.data?.docs.length ?? 0} classes", style: TextStyle(color: _examPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600))]),
        )),
        Expanded(child: _statusChip(status, statusColor)),
        SizedBox(width: 120.w, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _iconBtn(Icons.add_circle_outline, _examPrimary, () => _showAddClassSubjectDialog(exam)),
          SizedBox(width: 4.w),
          _iconBtn(Icons.visibility, _textSecondary, () => _showExamDetails(exam)),
        ])),
      ]),
    );
  }

  void _showAddClassSubjectDialog(DocumentSnapshot exam) {
    final ed = exam.data() as Map<String, dynamic>;
    String? localClass; String? localSubject;
    final newSubCtrl  = TextEditingController();
    final maxMarksCtrl= TextEditingController(text: "${ed['maxMarks'] ?? 100}");
    final passMarksCtrl= TextEditingController(text: "${ed['passingMarks'] ?? ((ed['maxMarks'] ?? 100) as num) * 0.5 ~/ 1}");
    bool isAddingNew  = false;

    Future<void> saveNewSubject(String name, StateSetter ss) async {
      final t = name.trim(); if (t.isEmpty) return;
      await FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('subjects').add({'name': t, 'createdAt': FieldValue.serverTimestamp()});
      ss(() { localSubject = t; isAddingNew = false; newSubCtrl.clear(); });
      widget.showSnackBar("Subject '$t' added!");
    }

    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, ss) => Dialog(
      backgroundColor: _bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(width: widget.isMobile ? double.infinity : 500.w, constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92), padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.add_circle, color: _examPrimary, size: 22.sp)), SizedBox(width: 12.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Add Class & Subject", style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700)), Text(ed['name'] ?? '', style: TextStyle(color: _textSecondary, fontSize: 13.sp))])), IconButton(icon: Icon(Icons.close, color: _textMuted), onPressed: () => Navigator.pop(context))]),
          SizedBox(height: 20.h),
          StreamBuilder<QuerySnapshot>(
            stream: _examsRef.doc(exam.id).collection('classSubjects').snapshots(),
            builder: (context, s) {
              final combos = s.data?.docs ?? [];
              if (combos.isEmpty) return SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Already added:", style: TextStyle(color: _textMuted, fontSize: 12.sp)), SizedBox(height: 8.h),
                Wrap(spacing: 8.w, runSpacing: 6.h, children: combos.map((c) { final cd = c.data() as Map<String, dynamic>; return Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: _accentSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: _accentSuccess.withOpacity(0.3))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text("${cd['className']} • ${cd['subject']}", style: TextStyle(color: _accentSuccess, fontSize: 12.sp, fontWeight: FontWeight.w600)), SizedBox(width: 6.w), GestureDetector(onTap: () => c.reference.delete(), child: Icon(Icons.close, color: _accentSuccess, size: 14.sp))])); }).toList()),
                SizedBox(height: 16.h), Divider(color: _border), SizedBox(height: 16.h),
              ]);
            },
          ),
          Text("Select Class *", style: TextStyle(color: _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600)), SizedBox(height: 8.h),
          Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: localClass, isExpanded: true, dropdownColor: _bgElevated, hint: Text("Choose class", style: TextStyle(color: _textMuted, fontSize: 14.sp)),
                  items: _availableClasses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: _textPrimary, fontSize: 14.sp)))).toList(),
                  onChanged: (val) => ss(() => localClass = val)))),
          SizedBox(height: 16.h),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("Select Subject *", style: TextStyle(color: _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
            GestureDetector(onTap: () => ss(() => isAddingNew = !isAddingNew), child: Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isAddingNew ? Icons.list : Icons.add, color: _examPrimary, size: 14.sp), SizedBox(width: 4.w), Text(isAddingNew ? "Pick existing" : "+ New Subject", style: TextStyle(color: _examPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600))]))),
          ]),
          SizedBox(height: 8.h),
          if (isAddingNew)
            Container(decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _examPrimary.withOpacity(0.5))),
                child: Row(children: [
                  Expanded(child: TextField(controller: newSubCtrl, style: TextStyle(color: _textPrimary, fontSize: 14.sp), textCapitalization: TextCapitalization.words, decoration: InputDecoration(hintText: "e.g. Mathematics...", hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h)), onSubmitted: (v) => saveNewSubject(v, ss))),
                  GestureDetector(onTap: () => saveNewSubject(newSubCtrl.text, ss), child: Container(margin: EdgeInsets.only(right: 6.w), padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: _examPrimary, borderRadius: BorderRadius.circular(8.r)), child: Icon(Icons.check, color: Colors.white, size: 18.sp))),
                ]))
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('subjects').orderBy('name').snapshots(),
              builder: (context, subSnap) {
                final subjects = subSnap.data?.docs ?? [];
                if (subjects.isEmpty) return GestureDetector(onTap: () => ss(() => isAddingNew = true), child: Container(width: double.infinity, padding: EdgeInsets.all(16.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline, color: _examPrimary, size: 20.sp), SizedBox(width: 8.w), Text("No subjects yet — tap to add", style: TextStyle(color: _examPrimary, fontSize: 13.sp))])));
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8.w, runSpacing: 8.h, children: subjects.map((s) { final sd = s.data() as Map<String, dynamic>; final n = sd['name'] ?? ''; final isSel = localSubject == n; return GestureDetector(onTap: () => ss(() => localSubject = n), onLongPress: () => _confirmDeleteSubject(s, ss), child: AnimatedContainer(duration: Duration(milliseconds: 180), padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), decoration: BoxDecoration(color: isSel ? _examPrimary : _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isSel ? _examPrimary : _border, width: isSel ? 2 : 1), boxShadow: isSel ? [BoxShadow(color: _examPrimary.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))] : null), child: Text(n, style: TextStyle(color: isSel ? Colors.white : _textPrimary, fontSize: 13.sp, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)))); }).toList()),
                  SizedBox(height: 6.h), Text("Long press to delete", style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                ]);
              },
            ),
          if (localSubject != null) ...[SizedBox(height: 12.h), Container(padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h), decoration: BoxDecoration(color: _accentSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: _accentSuccess.withOpacity(0.3))), child: Row(children: [Icon(Icons.check_circle, color: _accentSuccess, size: 16.sp), SizedBox(width: 8.w), Text("Selected: $localSubject", style: TextStyle(color: _accentSuccess, fontSize: 13.sp, fontWeight: FontWeight.w600))]))],
          SizedBox(height: 16.h),
          widget.isMobile ? Column(children: [
            _textField("Max Marks *", maxMarksCtrl, type: TextInputType.number),
            SizedBox(height: 12.h),
            _textField("Passing Marks *", passMarksCtrl, type: TextInputType.number),
          ]) : Row(children: [
            Expanded(child: _textField("Max Marks *", maxMarksCtrl, type: TextInputType.number)),
            SizedBox(width: 12.w),
            Expanded(child: _textField("Passing Marks *", passMarksCtrl, type: TextInputType.number)),
          ]),
          SizedBox(height: 24.h),
          Row(children: [
            Expanded(child: _btn("Cancel", onTap: () => Navigator.pop(context), secondary: true)), SizedBox(width: 12.w),
            Expanded(child: _btn("Add Combo", icon: Icons.add, onTap: () async {
              if (localClass == null || localSubject == null) { widget.showSnackBar("Please select class and subject", isError: true); return; }
              try {
                final studSnap = await _studentsRef.where('class', isEqualTo: localClass).get();
                final comboMaxMarks = int.tryParse(maxMarksCtrl.text) ?? 100;
                final comboPassingMarks = int.tryParse(passMarksCtrl.text) ?? 0;
                if (comboPassingMarks <= 0) { widget.showSnackBar("Passing marks cannot be empty", isError: true); return; }
                if (comboPassingMarks > comboMaxMarks) { widget.showSnackBar("Passing marks cannot exceed total marks", isError: true); return; }
                await _examsRef.doc(exam.id).collection('classSubjects').add({'className': localClass, 'subject': localSubject, 'maxMarks': comboMaxMarks, 'passingMarks': comboPassingMarks, 'examName': ed['name'], 'examType': ed['type'], 'totalStudents': studSnap.docs.length, 'marksEntered': 0, 'createdAt': FieldValue.serverTimestamp()});
                widget.showSnackBar("$localClass • $localSubject added!");
                ss(() { localClass = null; localSubject = null; });
              } catch (e) { widget.showSnackBar("Error: $e", isError: true); }
            })),
          ]),
        ])),
      ),
    ))).animate().fadeIn(duration: 300.ms).scale(duration: 400.ms, begin: Offset(0.9, 0.9), end: Offset(1, 1), curve: Curves.easeOutBack);
  }

  void _confirmDeleteSubject(DocumentSnapshot subDoc, StateSetter ss) {
    final name = ((subDoc.data() as Map<String, dynamic>)['name'] ?? '').toString();
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: _bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), title: Text("Delete Subject?", style: TextStyle(color: _textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700)), content: Text('Remove "$name"?', style: TextStyle(color: _textSecondary, fontSize: 14.sp)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: _textMuted))), TextButton(onPressed: () async { await subDoc.reference.delete(); Navigator.pop(context); widget.showSnackBar("Subject removed"); }, child: Text("Delete", style: TextStyle(color: _accentDanger, fontWeight: FontWeight.w700)))]));
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 2: RESULTS VIEW
  // ═══════════════════════════════════════════════════════════



  Widget _buildResultsFilters() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("1. Select Exam", style: TextStyle(color: _textMuted, fontSize: 12.sp, fontWeight: FontWeight.w600)), SizedBox(height: 8.h),
        _buildExamSelectorDropdown(), SizedBox(height: 12.h),
        if (_selectedExam != null) ...[Text("2. Select Class", style: TextStyle(color: _textMuted, fontSize: 12.sp, fontWeight: FontWeight.w600)), SizedBox(height: 8.h), _buildClassSelectorForExam(_selectedExam!)],
        if (_selectedExam != null && _selectedClass != null) ...[SizedBox(height: 12.h), _subjectInfoBar()],
      ]),
    );
  }

  Widget _subjectInfoBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.doc(_selectedExam).collection('classSubjects').where('className', isEqualTo: _selectedClass).snapshots(),
      builder: (context, snap) {
        final subjects = snap.data?.docs ?? [];
        return Container(padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _examPrimary.withOpacity(0.3))),
            child: Row(children: [Icon(Icons.class_, color: _examPrimary, size: 16.sp), SizedBox(width: 8.w), Text("Class $_selectedClass", style: TextStyle(color: _examPrimary, fontSize: 13.sp, fontWeight: FontWeight.w700)), SizedBox(width: 8.w), Text("•  ${subjects.length} subjects", style: TextStyle(color: _textSecondary, fontSize: 13.sp)), const Spacer(),
              Wrap(spacing: 4.w, children: subjects.take(4).map((s) { final sd = s.data() as Map<String, dynamic>; return Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(20.r)), child: Text(sd['subject'] ?? '', style: TextStyle(color: _examPrimary, fontSize: 10.sp, fontWeight: FontWeight.w600))); }).toList()),
              if (subjects.length > 4) Text("  +${subjects.length - 4}", style: TextStyle(color: _textMuted, fontSize: 11.sp)),
            ]));
      },
    );
  }

  Widget _buildExamSelectorDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        final seen = <String>{}; final exams = (snapshot.data?.docs ?? []).where((e) => seen.add(e.id)).toList();
        final ids = exams.map((e) => e.id).toSet();
        final safe = ids.contains(_selectedExam) ? _selectedExam : null;
        if (safe != _selectedExam) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() { _selectedExam = null; _selectedClass = null; _selectedCombo = null; }); });
        return Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: safe, isExpanded: true, dropdownColor: _bgElevated, hint: Text("Select exam", style: TextStyle(color: _textMuted, fontSize: 14.sp)),
                items: exams.map((e) { final d = e.data() as Map<String, dynamic>; return DropdownMenuItem(value: e.id, child: Text("${d['name'] ?? 'Unnamed'} (${d['type'] ?? '--'})", style: TextStyle(color: _textPrimary, fontSize: 14.sp))); }).toList(),
                onChanged: (val) => setState(() { _selectedExam = val; _selectedClass = null; _selectedCombo = null; }))));
      },
    );
  }

  Widget _buildClassSelectorForExam(String examId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.doc(examId).collection('classSubjects').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8.r)), child: Text("No classes added yet. Add from Exams tab.", style: TextStyle(color: _textMuted, fontSize: 13.sp)));
        final classes = snap.data!.docs.map((d) => ((d.data() as Map<String, dynamic>)['className'] ?? '').toString()).toSet().toList()..sort();
        return Wrap(spacing: 8.w, runSpacing: 8.h, children: classes.map((cls) {
          final isSel = _selectedClass == cls;
          return GestureDetector(onTap: () => setState(() { _selectedClass = cls; _selectedCombo = null; }),
              child: AnimatedContainer(duration: Duration(milliseconds: 180), padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), decoration: BoxDecoration(color: isSel ? _examPrimary : _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isSel ? _examPrimary : _border, width: isSel ? 2 : 1), boxShadow: isSel ? [BoxShadow(color: _examPrimary.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))] : null),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.class_, color: isSel ? Colors.white : _textSecondary, size: 14.sp), SizedBox(width: 6.w), Text("Class $cls", style: TextStyle(color: isSel ? Colors.white : _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600))])));
        }).toList());
      },
    );
  }

  Widget _selectPrompt() {
    return Center(child: Container(padding: EdgeInsets.all(48.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(24.r), border: Border.all(color: _border)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.touch_app, color: _examPrimary, size: 64.sp), SizedBox(height: 24.h), Text("Select Exam & Class", style: TextStyle(color: _textPrimary, fontSize: 24.sp, fontWeight: FontWeight.w800)), SizedBox(height: 12.h), Text("Select an exam then pick a class", style: TextStyle(color: _textSecondary, fontSize: 14.sp), textAlign: TextAlign.center)])))
        .animate().fadeIn(duration: 600.ms).scale(duration: 500.ms, begin: Offset(0.85, 0.85), end: Offset(1, 1), curve: Curves.easeOutBack);
  }

  Widget _buildResultsList() {
    final classId = _selectedClass!; final examId = _selectedExam!;
    return StreamBuilder<QuerySnapshot>(
      stream: _studentsRef.where('class', isEqualTo: classId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _shimmerList();
        if (!snap.hasData || snap.data!.docs.isEmpty) return _emptyState(icon: Icons.people_outline, title: "No students found", subtitle: "No students in class $classId");
        final students = List.from(snap.data!.docs)..sort((a, b) { final aR = int.tryParse(((a.data() as Map)['rollNumber'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; final bR = int.tryParse(((b.data() as Map)['rollNumber'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; return aR.compareTo(bR); });
        return StreamBuilder<QuerySnapshot>(
          stream: _examsRef.doc(examId).collection('classSubjects').where('className', isEqualTo: classId).snapshots(),
          builder: (context, subSnap) {
            final subjectCombos = subSnap.data?.docs ?? [];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
                  child: Row(children: [_headerStat(Icons.people, "${students.length}", "Students"), _headerDivider(), _headerStat(Icons.book, "${subjectCombos.length}", "Subjects"), _headerDivider(), _headerStat(Icons.assignment, "${students.length * subjectCombos.length}", "Entries"), const Spacer(), _btn("Bulk Entry", icon: Icons.edit_note, onTap: subjectCombos.isEmpty ? null : () => _showBulkMarksEntry(students.cast<DocumentSnapshot>(), subjectCombos, examId, classId), secondary: true)])).animate().fadeIn(duration: 400.ms).slideY(begin: -10, end: 0, duration: 500.ms),
              SizedBox(height: 12.h),
              Expanded(child: widget.isMobile
                  ? ListView.builder(
                itemCount: students.length,
                itemBuilder: (_, i) => _buildStudentMarksCard(students[i] as DocumentSnapshot, subjectCombos, examId, classId)
                    .animate(delay: (i * 70).ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 25, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
              )
                  : _buildStudentsMarksTable(students.cast<DocumentSnapshot>(), subjectCombos, examId, classId).animate().fadeIn(duration: 500.ms)),
            ]);
          },
        );
      },
    );
  }

  Widget _headerStat(IconData icon, String value, String label) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: _examPrimary, size: 16.sp), SizedBox(width: 6.w), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w800)), Text(label, style: TextStyle(color: _textMuted, fontSize: 10.sp))])]);
  Widget _headerDivider() => Container(margin: EdgeInsets.symmetric(horizontal: 16.w), width: 1, height: 32.h, color: _border);

  // ═══════════════════════════════════════════════════════════
  //  PROFESSIONAL STUDENT CARD — RESULTS TAB
  // ═══════════════════════════════════════════════════════════

  Widget _buildStudentMarksCard(DocumentSnapshot student, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    final data = student.data() as Map<String, dynamic>;
    return StreamBuilder<QuerySnapshot>(
      stream: _resultsRef
          .where('studentId', isEqualTo: student.id)
          .where('examId',    isEqualTo: examId)
          .snapshots(),
      builder: (context, resultsSnap) {
        final results      = resultsSnap.data?.docs ?? [];
        final enteredCount = results.length;
        final totalSubjects= subjectCombos.length;
        final isComplete   = enteredCount == totalSubjects && totalSubjects > 0;
        final progress     = totalSubjects > 0 ? enteredCount / totalSubjects : 0.0;

        double totalPerc = 0;
        for (var r in results) { totalPerc += (((r.data() as Map)['percentage'] ?? 0) as num).toDouble(); }
        final avg          = results.isNotEmpty ? totalPerc / results.length : 0.0;
        final overallGrade = results.isNotEmpty ? _calculateGrade(avg, 100) : '--';
        final gradeColor   = _getGradeColor(overallGrade);
        final accentColor  = isComplete ? _accentSuccess : enteredCount > 0 ? _examPrimary : _border;

        return GestureDetector(
          onTap: () => _showStudentMarksSheet(student, subjectCombos, examId, classId),
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: accentColor.withOpacity(0.25)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: Offset(0, 4))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16.r), child: Column(children: [
              IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(width: 5.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isComplete ? [_accentSuccess, Color(0xFF16A34A)] : enteredCount > 0 ? [_examPrimary, _examLight] : [_border, _border], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                Expanded(child: Padding(padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Stack(children: [
                      Container(width: 50.w, height: 50.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isComplete ? [_accentSuccess, Color(0xFF16A34A)] : [_examPrimary, _examLight], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14.r)), child: Center(child: Text((data['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800)))),
                      Positioned(bottom: -1, right: -1, child: Container(padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h), decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.circular(6.r), border: Border.all(color: accentColor.withOpacity(0.5))), child: Text("${data['rollNumber'] ?? '?'}", style: TextStyle(color: accentColor, fontSize: 9.sp, fontWeight: FontWeight.w800)))),
                    ]),
                    SizedBox(width: 12.w),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['name'] ?? 'Unknown', style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4.h),
                      Row(children: [Icon(Icons.menu_book_rounded, color: _textMuted, size: 12.sp), SizedBox(width: 4.w), Text("$enteredCount / $totalSubjects subjects", style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                        if (isComplete) ...[SizedBox(width: 8.w), Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: _accentSuccess.withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_rounded, color: _accentSuccess, size: 10.sp), SizedBox(width: 3.w), Text("Done", style: TextStyle(color: _accentSuccess, fontSize: 9.sp, fontWeight: FontWeight.w700))]))],
                      ]),
                    ])),
                    results.isNotEmpty
                        ? Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), decoration: BoxDecoration(color: gradeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: gradeColor.withOpacity(0.3))), child: Column(children: [Text(overallGrade, style: TextStyle(color: gradeColor, fontSize: 18.sp, fontWeight: FontWeight.w900)), Text("${avg.toStringAsFixed(0)}%", style: TextStyle(color: gradeColor.withOpacity(0.8), fontSize: 9.sp, fontWeight: FontWeight.w600))]))
                        : Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)), child: Column(children: [Text("--", style: TextStyle(color: _textMuted, fontSize: 18.sp, fontWeight: FontWeight.w800)), Text("avg", style: TextStyle(color: _textMuted, fontSize: 9.sp))])),
                  ]),
                  SizedBox(height: 10.h),
                  results.isNotEmpty
                      ? Wrap(spacing: 6.w, runSpacing: 6.h, children: results.map((r) { final rd = r.data() as Map<String, dynamic>; final perc = ((rd['percentage'] ?? 0) as num).toDouble(); final passingM = ((rd['passingMarks'] ?? rd['maxMarks'] ?? 100) as num).toInt(); final maxM = ((rd['maxMarks'] ?? 100) as num).toInt(); final gc = perc >= 80 ? _accentSuccess : perc >= (passingM / maxM * 100) ? _accentWarning : _accentDanger; final subj = (rd['subject'] ?? '').toString(); final obt = ((rd['marksObtained'] ?? 0) as num).toInt(); final max = ((rd['maxMarks'] ?? 100) as num).toInt(); return Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: gc.withOpacity(0.08), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: gc.withOpacity(0.25))), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(subj.length > 4 ? subj.substring(0, 4) : subj, style: TextStyle(color: _textMuted, fontSize: 9.sp, fontWeight: FontWeight.w600)), SizedBox(width: 4.w), Text("$obt/$max", style: TextStyle(color: gc, fontSize: 10.sp, fontWeight: FontWeight.w800))])); }).toList())
                      : Row(children: [Icon(Icons.touch_app_rounded, color: _textMuted, size: 12.sp), SizedBox(width: 6.w), Text("Tap to enter marks", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontStyle: FontStyle.italic))]),
                ]))),
              ])),
              SizedBox(height: 3.h, child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => LinearProgressIndicator(value: value, backgroundColor: _bgElevated, valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
              )),
            ])),
          ),
        );
      },
    );
  }

  Widget _buildStudentsMarksTable(List<DocumentSnapshot> students, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    return Container(
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
      child: Column(children: [
        Container(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.vertical(top: Radius.circular(12.r))),
            child: Row(children: [SizedBox(width: 40.w, child: Text("#", style: _thStyle())), SizedBox(width: 12.w), Expanded(flex: 2, child: Text("Student", style: _thStyle())), ...subjectCombos.map((s) { final sd = s.data() as Map<String, dynamic>; return Expanded(child: Text(sd['subject'] ?? '', style: _thStyle(), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)); }), Expanded(child: Text("Avg%", style: _thStyle(), textAlign: TextAlign.center)), SizedBox(width: 60.w, child: Text("Action", style: _thStyle(), textAlign: TextAlign.center))])),
        Expanded(child: ListView.separated(
          itemCount: students.length,
          separatorBuilder: (_, __) => Divider(color: _border, height: 1),
          itemBuilder: (_, i) => _studentTableRow(students[i], subjectCombos, examId, classId)
              .animate(delay: (i * 50).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: -15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
        )),
      ]),
    );
  }

  Widget _studentTableRow(DocumentSnapshot student, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    final data = student.data() as Map<String, dynamic>;
    return StreamBuilder<QuerySnapshot>(
      stream: _resultsRef.where('studentId', isEqualTo: student.id).where('examId', isEqualTo: examId).snapshots(),
      builder: (context, rSnap) {
        final results = rSnap.data?.docs ?? [];
        final Map<String, Map<String, dynamic>> bySubject = {};
        for (var r in results) { final rd = r.data() as Map<String, dynamic>; bySubject[(rd['subject'] ?? '').toString()] = rd; }
        double totalPerc = 0; int cnt = 0;
        for (var r in results) { totalPerc += (((r.data() as Map)['percentage'] ?? 0) as num).toDouble(); cnt++; }
        final avg = cnt > 0 ? totalPerc / cnt : null;
        final isComplete = cnt == subjectCombos.length && subjectCombos.isNotEmpty;

        return Container(color: isComplete ? _accentSuccess.withOpacity(0.03) : null, padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            child: Row(children: [
              Container(width: 40.w, height: 40.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isComplete ? [_accentSuccess, Color(0xFF16A34A)] : [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(10.r)), child: Center(child: Text("${data['rollNumber'] ?? '?'}", style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w800)))),
              SizedBox(width: 12.w),
              Expanded(flex: 2, child: Text(data['name'] ?? '', style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ...subjectCombos.map((s) { final sd = s.data() as Map<String, dynamic>; final subject = (sd['subject'] ?? '').toString(); final maxM = ((sd['maxMarks'] ?? 100) as num).toInt(); final res = bySubject[subject]; final marks = res?['marksObtained']; final perc = ((res?['percentage'] ?? 0) as num).toDouble(); final grade = (res?['grade'] ?? '').toString(); final gc = perc >= 80 ? _accentSuccess : perc >= 60 ? _accentWarning : _accentDanger; return Expanded(child: Center(child: marks != null ? Column(mainAxisSize: MainAxisSize.min, children: [Text("${(marks as num).toInt()}/$maxM", style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)), Container(margin: EdgeInsets.only(top: 2.h), padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h), decoration: BoxDecoration(color: gc.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)), child: Text(grade, style: TextStyle(color: gc, fontSize: 10.sp, fontWeight: FontWeight.w700)))]) : Text("--", style: TextStyle(color: _textMuted, fontSize: 14.sp)))); }),
              Expanded(child: Center(child: avg != null ? Text("${avg.toStringAsFixed(1)}%", style: TextStyle(color: avg >= 50 ? _accentSuccess : _accentDanger, fontSize: 13.sp, fontWeight: FontWeight.w700)) : Text("--", style: TextStyle(color: _textMuted, fontSize: 13.sp)))),
              SizedBox(width: 60.w, child: Center(child: _iconBtn(isComplete ? Icons.edit : Icons.add_circle_outline, isComplete ? _accentSuccess : _examPrimary, () => _showStudentMarksSheet(student, subjectCombos, examId, classId)))),
            ]));
      },
    );
  }

  void _showStudentMarksSheet(DocumentSnapshot student, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    final studentData = student.data() as Map<String, dynamic>;
    final Map<String, TextEditingController> controllers = {};
    for (var combo in subjectCombos) { final sd = combo.data() as Map<String, dynamic>; controllers[(sd['subject'] ?? '').toString()] = TextEditingController(); }

    _resultsRef.where('studentId', isEqualTo: student.id).where('examId', isEqualTo: examId).get().then((snap) {
      for (var doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final subj  = (d['subject'] ?? '').toString();
        final marks = d['marksObtained'];
        if (controllers.containsKey(subj) && marks != null) controllers[subj]!.text = (marks as num).toInt().toString();
      }
    });

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(builder: (context, ss) => Container(
          height: MediaQuery.of(context).size.height * (widget.isMobile ? 0.92 : 0.85),
          decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)), border: Border.all(color: _border)),
          child: Column(children: [
            Container(margin: EdgeInsets.only(top: 12.h), width: 40.w, height: 4.h, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2.r))),
            SizedBox(height: 16.h),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Row(children: [
              Container(width: 52.w, height: 52.w, decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(14.r)), child: Center(child: Text((studentData['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)))),
              SizedBox(width: 14.w),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(studentData['name'] ?? 'Unknown', style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w800)), Text("Roll: ${studentData['rollNumber'] ?? '--'}  •  Class $classId", style: TextStyle(color: _textSecondary, fontSize: 13.sp)), Text("${subjectCombos.length} subjects", style: TextStyle(color: _examPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600))])),
              IconButton(icon: Icon(Icons.close, color: _textMuted), onPressed: () => Navigator.pop(context)),
            ])).animate().fadeIn(duration: 400.ms).slideY(begin: -20, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
            SizedBox(height: 16.h), Divider(color: _border, height: 1),
            Expanded(child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h), itemCount: subjectCombos.length,
              itemBuilder: (context, i) {
                final sd = subjectCombos[i].data() as Map<String, dynamic>;
                final subject  = (sd['subject'] ?? '').toString();
                final maxMarks = ((sd['maxMarks'] ?? 100) as num).toInt();
                final ctrl     = controllers[subject]!;
                return ValueListenableBuilder<TextEditingValue>(valueListenable: ctrl, builder: (context, val, _) {
                  final marks   = double.tryParse(val.text) ?? -1;
                  final hasVal  = marks >= 0;
                  final perc    = hasVal && maxMarks > 0 ? (marks / maxMarks) * 100 : 0.0;
                  final grade   = hasVal ? _calculateGrade(marks, maxMarks.toDouble()) : '';
                  final gc      = perc >= 80 ? _accentSuccess : perc >= 60 ? _accentWarning : _accentDanger;
                  final isValid = hasVal && marks <= maxMarks;
                  return Container(margin: EdgeInsets.only(bottom: 12.h), padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: hasVal ? (isValid ? gc.withOpacity(0.4) : _accentDanger.withOpacity(0.5)) : _border, width: hasVal ? 1.5 : 1)),
                      child: Row(children: [
                        Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.book_outlined, color: _examPrimary, size: 20.sp)),
                        SizedBox(width: 12.w),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject, style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700)), Text("Max: $maxMarks marks", style: TextStyle(color: _textMuted, fontSize: 11.sp))])),
                        if (hasVal && isValid) ...[Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: gc.withOpacity(0.3))), child: Column(children: [Text(grade, style: TextStyle(color: gc, fontSize: 16.sp, fontWeight: FontWeight.w800)), Text("${perc.toStringAsFixed(0)}%", style: TextStyle(color: gc.withOpacity(0.8), fontSize: 9.sp))])), SizedBox(width: 12.w)],
                        Container(width: 80.w, decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: hasVal ? (isValid ? gc : _accentDanger) : _border, width: hasVal ? 2 : 1)),
                            child: TextField(controller: ctrl, keyboardType: TextInputType.number, textInputAction: i < subjectCombos.length - 1 ? TextInputAction.next : TextInputAction.done, textAlign: TextAlign.center, style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w800), decoration: InputDecoration(hintText: "--", hintStyle: TextStyle(color: _textMuted, fontSize: 18.sp), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12.h)))),
                      ]));
                });
              },
            )),
            Container(padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h), decoration: BoxDecoration(color: _bgCard, border: Border(top: BorderSide(color: _border))),
                child: Row(children: [Expanded(child: _btn("Cancel", onTap: () => Navigator.pop(context), secondary: true)), SizedBox(width: 12.w), Expanded(flex: 2, child: _btn("Save All Marks", icon: Icons.save_rounded, onTap: () => _saveAllSubjectMarks(student, controllers, subjectCombos, examId, classId, onDone: () => Navigator.pop(context))))])),
          ]),
        )));
  }

  Future<void> _saveAllSubjectMarks(
      DocumentSnapshot student,
      Map<String, TextEditingController> controllers,
      List<QueryDocumentSnapshot> subjectCombos,
      String examId,
      String classId, {
        required VoidCallback onDone,
      }) async {
    if (examId.isEmpty || classId.isEmpty) { widget.showSnackBar("Exam ya class select nahi hai", isError: true); return; }

    final studentData = student.data() as Map<String, dynamic>? ?? {};
    final studentName = (studentData['name']       ?? '').toString();
    final studentRoll = (studentData['rollNumber'] ?? '').toString();

    bool hasAnyMark = false; bool hasError = false;

    for (var combo in subjectCombos) {
      final sd       = combo.data() as Map<String, dynamic>? ?? {};
      final subject  = (sd['subject']  ?? '').toString();
      final maxMarks = ((sd['maxMarks'] ?? 100) as num).toInt();
      final text     = controllers[subject]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final marks    = double.tryParse(text);
      if (marks == null || marks < 0 || marks > maxMarks) {
        widget.showSnackBar("$subject ki marks galat hain (0-$maxMarks)", isError: true);
        hasError = true; break;
      }
      hasAnyMark = true;
    }
    if (hasError) return;
    if (!hasAnyMark) { widget.showSnackBar("Kam az kam ek subject ki marks daalo", isError: true); return; }

    try {
      final existingSnap = await _resultsRef
          .where('studentId', isEqualTo: student.id)
          .where('examId',    isEqualTo: examId)
          .get();

      final Map<String, String> existingDocIds = {};
      for (var doc in existingSnap.docs) {
        final d       = doc.data() as Map<String, dynamic>? ?? {};
        final subject = (d['subject'] ?? '').toString();
        if (subject.isNotEmpty) existingDocIds[subject] = doc.id;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (var combo in subjectCombos) {
        final sd       = combo.data() as Map<String, dynamic>? ?? {};
        final subject  = (sd['subject']  ?? '').toString();
        final maxMarks = ((sd['maxMarks'] ?? 100) as num).toInt();
        if (subject.isEmpty) continue;
        final text = controllers[subject]?.text.trim() ?? '';
        if (text.isEmpty) continue;

        final marks      = double.tryParse(text) ?? 0.0;
        final percentage = maxMarks > 0 ? (marks / maxMarks) * 100 : 0.0;

        final comboSnap = await _examsRef.doc(examId).collection('classSubjects')
            .where('className', isEqualTo: classId)
            .where('subject', isEqualTo: subject)
            .limit(1)
            .get();
        final comboData = comboSnap.docs.isNotEmpty ? comboSnap.docs.first.data() as Map<String, dynamic> : {};
        final passingMarks = ((comboData['passingMarks'] ?? comboData['maxMarks'] ?? maxMarks) as num).toInt();
        final isPassed = marks >= passingMarks;

        final resultData = <String, dynamic>{
          'studentId'       : student.id,
          'studentName'     : studentName,
          'rollNumber'      : studentRoll,
          'className'       : classId,
          'examId'          : examId,
          'subject'         : subject,
          'maxMarks'        : maxMarks,
          'passingMarks'    : passingMarks,
          'marksObtained'   : marks,
          'percentage'      : percentage,
          'grade'           : _calculateGrade(marks, maxMarks.toDouble()),
          'gpa'             : _calculateGPA(percentage),
          'isPassed'        : isPassed,
          'isAutoCalculated': true,
          'updatedAt'       : FieldValue.serverTimestamp(),
          'updatedBy'       : FirebaseAuth.instance.currentUser?.uid ?? '',
        };

        if (existingDocIds.containsKey(subject)) {
          batch.update(_resultsRef.doc(existingDocIds[subject]!), resultData);
        } else {
          resultData['createdAt'] = FieldValue.serverTimestamp();
          batch.set(_resultsRef.doc(), resultData);
        }
      }

      await batch.commit();

      for (var combo in subjectCombos) {
        final sd      = combo.data() as Map<String, dynamic>? ?? {};
        final subject = (sd['subject'] ?? '').toString();
        if (subject.isNotEmpty) await _updateComboProgress(examId, classId, subject);
      }

      widget.showSnackBar("${studentName.isNotEmpty ? studentName : 'Student'} ki marks save ho gayi!");
      onDone();

    } catch (e, st) {
      print("Marks save error: $e\n$st");
      widget.showSnackBar("Error saving marks: $e", isError: true);
    }
  }

  Future<void> _updateComboProgress(String examId, String classId, String subject) async {
    if (examId.isEmpty || classId.isEmpty || subject.isEmpty) return;
    try {
      final resultsSnap = await _resultsRef
          .where('examId',    isEqualTo: examId)
          .where('className', isEqualTo: classId)
          .where('subject',   isEqualTo: subject)
          .get();

      final combosSnap = await _examsRef.doc(examId).collection('classSubjects')
          .where('className', isEqualTo: classId)
          .where('subject',   isEqualTo: subject).get();

      for (var doc in combosSnap.docs) {
        await doc.reference.update({'marksEntered': resultsSnap.docs.length, 'updatedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) { print("Combo progress error: $e"); }
  }

  void _showBulkMarksEntry(List<DocumentSnapshot> students, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    final Map<String, Map<String, TextEditingController>> allCtrl = {};
    for (var s in students) { allCtrl[s.id] = {}; for (var c in subjectCombos) { final sd = c.data() as Map<String, dynamic>; allCtrl[s.id]![(sd['subject'] ?? '').toString()] = TextEditingController(); } }

    _resultsRef.where('examId', isEqualTo: examId).where('className', isEqualTo: classId).get().then((snap) {
      for (var doc in snap.docs) { final d = doc.data() as Map<String, dynamic>; final sid = (d['studentId'] ?? '').toString(); final subj = (d['subject'] ?? '').toString(); final marks = d['marksObtained']; if (allCtrl.containsKey(sid) && allCtrl[sid]!.containsKey(subj) && marks != null) allCtrl[sid]![subj]!.text = (marks as num).toInt().toString(); }
    });

    showDialog(context: context, builder: (context) => Dialog(
      backgroundColor: _bgDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(width: MediaQuery.of(context).size.width * 0.95, height: MediaQuery.of(context).size.height * 0.9, padding: EdgeInsets.all(20.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.table_chart, color: _examPrimary, size: 24.sp), SizedBox(width: 12.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Bulk Marks Entry", style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w800)), Text("Class $classId  •  ${students.length} students", style: TextStyle(color: _textSecondary, fontSize: 12.sp))])), IconButton(icon: Icon(Icons.close, color: _textMuted), onPressed: () => Navigator.pop(context))]),
          SizedBox(height: 12.h),
          Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r)),
              child: Row(children: [SizedBox(width: 36.w, child: Text("#", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w700))), SizedBox(width: 8.w), SizedBox(width: 110.w, child: Text("Student", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w700))), ...subjectCombos.map((c) { final sd = c.data() as Map<String, dynamic>; return Expanded(child: Text(sd['subject'] ?? '', style: TextStyle(color: _examPrimary, fontSize: 11.sp, fontWeight: FontWeight.w700), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)); })])),
          SizedBox(height: 8.h),
          Expanded(child: ListView.builder(itemCount: students.length, itemBuilder: (context, i) {
            final s = students[i]; final d = s.data() as Map<String, dynamic>;
            return Container(margin: EdgeInsets.only(bottom: 6.h), padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h), decoration: BoxDecoration(color: i.isEven ? _bgCard : _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
                child: Row(children: [
                  Container(width: 36.w, height: 36.w, decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(8.r)), child: Center(child: Text("${d['rollNumber'] ?? i + 1}", style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w800)))),
                  SizedBox(width: 8.w),
                  SizedBox(width: 110.w, child: Text(d['name'] ?? '', style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  ...subjectCombos.map((c) { final sd = c.data() as Map<String, dynamic>; final subject = (sd['subject'] ?? '').toString(); final maxM = ((sd['maxMarks'] ?? 100) as num).toInt(); final ctrl = allCtrl[s.id]![subject]!; return Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 4.w), child: TextField(controller: ctrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w700), decoration: InputDecoration(hintText: "0-$maxM", hintStyle: TextStyle(color: _textMuted, fontSize: 11.sp), filled: true, fillColor: _bgCard, contentPadding: EdgeInsets.symmetric(vertical: 8.h), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: _border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: _border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: _examPrimary, width: 2)))))); }),
                ]));
          })),
          SizedBox(height: 12.h),
          SizedBox(width: double.infinity, child: _btn("Save All (${students.length} x ${subjectCombos.length})", icon: Icons.save_rounded, onTap: () async {
            int saved = 0;
            for (var s in students) { final ctrls = allCtrl[s.id]!; if (!ctrls.values.any((c) => c.text.trim().isNotEmpty)) continue; await _saveAllSubjectMarks(s, ctrls, subjectCombos, examId, classId, onDone: () {}); saved++; }
            Navigator.pop(context); widget.showSnackBar("$saved students ke marks save ho gaye!");
          })),
        ]),
      ),
    )).animate().fadeIn(duration: 300.ms).scale(duration: 400.ms, begin: Offset(0.9, 0.9), end: Offset(1, 1), curve: Curves.easeOutBack);
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 3: MARK ENTRY VIEW
  // ═══════════════════════════════════════════════════════════


  Widget _entryModeCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(padding: EdgeInsets.all(16.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: color.withOpacity(0.4), width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)), child: Icon(icon, color: color, size: 24.sp)), SizedBox(height: 12.h), Text(title, style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w800)), SizedBox(height: 4.h), Text(subtitle, style: TextStyle(color: _textMuted, fontSize: 11.sp, height: 1.4)), SizedBox(height: 12.h), Container(padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h), decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(8.r)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text("Open", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700)), SizedBox(width: 4.w), Icon(Icons.arrow_forward, color: Colors.white, size: 14.sp)]))])));
  }

  Widget _buildMeExamDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        final seen = <String>{}; final exams = (snap.data?.docs ?? []).where((e) => seen.add(e.id)).toList();
        final ids = exams.map((e) => e.id).toSet(); final safe = ids.contains(_meExam) ? _meExam : null;
        if (safe != _meExam) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() { _meExam = null; _meClass = null; }); });
        return Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: safe, isExpanded: true, dropdownColor: _bgElevated, hint: Text("Select exam", style: TextStyle(color: _textMuted, fontSize: 14.sp)),
                items: exams.map((e) { final d = e.data() as Map<String, dynamic>; return DropdownMenuItem(value: e.id, child: Text("${d['name'] ?? 'Unnamed'} (${d['type'] ?? '--'})", style: TextStyle(color: _textPrimary, fontSize: 14.sp))); }).toList(),
                onChanged: (val) => setState(() { _meExam = val; _meClass = null; }))));
      },
    );
  }

  Widget _buildMeClassChips(String examId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _examsRef.doc(examId).collection('classSubjects').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(8.r)), child: Text("No classes in this exam. Add from Exams tab.", style: TextStyle(color: _textMuted, fontSize: 13.sp)));
        final classes = snap.data!.docs.map((d) => ((d.data() as Map<String, dynamic>)['className'] ?? '').toString()).toSet().toList()..sort();
        return Wrap(spacing: 8.w, runSpacing: 8.h, children: classes.map((cls) { final isSel = _meClass == cls; return GestureDetector(onTap: () => setState(() => _meClass = cls), child: AnimatedContainer(duration: Duration(milliseconds: 180), padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h), decoration: BoxDecoration(color: isSel ? _examPrimary : _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isSel ? _examPrimary : _border, width: isSel ? 2 : 1), boxShadow: isSel ? [BoxShadow(color: _examPrimary.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))] : null), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.class_, color: isSel ? Colors.white : _textSecondary, size: 14.sp), SizedBox(width: 6.w), Text("Class $cls", style: TextStyle(color: isSel ? Colors.white : _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600))]))); }).toList());
      },
    );
  }

  Widget _buildMarkEntryStudentList(String examId, String classId) {
    return Expanded(child: StreamBuilder<QuerySnapshot>(
      stream: _studentsRef.where('class', isEqualTo: classId).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _shimmerList();
        final students = List.from(snap.data?.docs ?? []);
        if (students.isEmpty) return _emptyState(icon: Icons.people_outline, title: "No students", subtitle: "No students in class $classId");
        students.sort((a, b) { final aR = int.tryParse(((a.data() as Map)['rollNumber'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; final bR = int.tryParse(((b.data() as Map)['rollNumber'] ?? '0').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0; return aR.compareTo(bR); });
        return StreamBuilder<QuerySnapshot>(
          stream: _examsRef.doc(examId).collection('classSubjects').where('className', isEqualTo: classId).snapshots(),
          builder: (context, subSnap) {
            final subjectCombos = subSnap.data?.docs ?? [];
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(bottom: 10.h), child: Row(children: [Text("${students.length} Students", style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700)), SizedBox(width: 8.w), Text("• ${subjectCombos.length} subjects", style: TextStyle(color: _textMuted, fontSize: 13.sp))])).animate().fadeIn(duration: 400.ms),
              Expanded(child: ListView.builder(itemCount: students.length, itemBuilder: (_, i) => _buildMarkEntryStudentCard(students[i] as DocumentSnapshot, subjectCombos, examId, classId)
                  .animate(delay: (i * 70).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 25, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
              )),
            ]);
          },
        );
      },
    ));
  }

  Widget _buildMarkEntryStudentCard(DocumentSnapshot student, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    final data = student.data() as Map<String, dynamic>;
    return StreamBuilder<QuerySnapshot>(
      stream: _resultsRef.where('studentId', isEqualTo: student.id).where('examId', isEqualTo: examId).snapshots(),
      builder: (context, rSnap) {
        final results  = rSnap.data?.docs ?? [];
        final entered  = results.length; final total = subjectCombos.length;
        final isComplete = entered == total && total > 0;
        final hasAny   = entered > 0;
        final progress = total > 0 ? entered / total : 0.0;

        double totalPerc = 0;
        for (var r in results) { totalPerc += (((r.data() as Map)['percentage'] ?? 0) as num).toDouble(); }
        final avg   = results.isNotEmpty ? totalPerc / results.length : 0.0;
        final grade = results.isNotEmpty ? _calculateGrade(avg, 100) : '--';
        final gc    = avg >= 80 ? _accentSuccess : avg >= 50 ? _accentWarning : _accentDanger;
        final barColor = isComplete ? _accentSuccess : hasAny ? _examPrimary : _border;

        final Map<String, Map<String, dynamic>> bySubject = {};
        for (var r in results) { final rd = r.data() as Map<String, dynamic>; bySubject[(rd['subject'] ?? '').toString()] = rd; }

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: barColor.withOpacity(0.22)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: Offset(0, 3))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(16.r), child: Column(children: [
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 5.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isComplete ? [_accentSuccess, Color(0xFF16A34A)] : hasAny ? [_examPrimary, _examLight] : [_border, _border], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              Expanded(child: Padding(padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Stack(children: [
                    Container(width: 48.w, height: 48.w, decoration: BoxDecoration(gradient: LinearGradient(colors: isComplete ? [_accentSuccess, Color(0xFF16A34A)] : [_examPrimary, _examLight], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(13.r)), child: Center(child: Text((data['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.w800)))),
                    Positioned(bottom: -1, right: -1, child: Container(padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h), decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.circular(5.r), border: Border.all(color: barColor.withOpacity(0.5))), child: Text("#${data['rollNumber'] ?? '?'}", style: TextStyle(color: barColor, fontSize: 8.sp, fontWeight: FontWeight.w800)))),
                  ]),
                  SizedBox(width: 12.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(data['name'] ?? 'Unknown', style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)), if (isComplete) Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), decoration: BoxDecoration(color: _accentSuccess.withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, color: _accentSuccess, size: 10.sp), SizedBox(width: 3.w), Text("Complete", style: TextStyle(color: _accentSuccess, fontSize: 9.sp, fontWeight: FontWeight.w700))]))]),
                    SizedBox(height: 3.h), Text("$entered/$total subjects entered", style: TextStyle(color: _textMuted, fontSize: 10.sp)),
                  ])),
                  if (hasAny) ...[SizedBox(width: 8.w), Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: gc.withOpacity(0.10), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: gc.withOpacity(0.3))), child: Column(children: [Text(grade, style: TextStyle(color: gc, fontSize: 16.sp, fontWeight: FontWeight.w900)), Text("${avg.toStringAsFixed(0)}%", style: TextStyle(color: gc.withOpacity(0.75), fontSize: 8.sp, fontWeight: FontWeight.w600))]))],
                ]),
                if (subjectCombos.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: subjectCombos.map((c) { final sd = c.data() as Map<String, dynamic>; final subject = (sd['subject'] ?? '').toString(); final maxM = ((sd['maxMarks'] ?? 100) as num).toInt(); final res = bySubject[subject]; final obt = res != null ? ((res['marksObtained'] ?? 0) as num).toInt() : null; final pct = obt != null ? obt / maxM * 100 : 0.0; final pillColor = obt != null ? (pct >= 80 ? _accentSuccess : pct >= 50 ? _accentWarning : _accentDanger) : _border; return Container(margin: EdgeInsets.only(right: 6.w), padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: obt != null ? pillColor.withOpacity(0.08) : _bgElevated, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: obt != null ? pillColor.withOpacity(0.3) : _border)), child: Column(children: [Text(subject.length > 5 ? subject.substring(0, 5) : subject, style: TextStyle(color: _textMuted, fontSize: 8.sp, fontWeight: FontWeight.w600)), SizedBox(height: 2.h), Text(obt != null ? "$obt/$maxM" : "--/$maxM", style: TextStyle(color: obt != null ? pillColor : _textMuted, fontSize: 10.sp, fontWeight: FontWeight.w800))])); }).toList())),
                ],
              ]))),
            ])),
            SizedBox(height: 3.h, child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(value: value, backgroundColor: _bgElevated, valueColor: AlwaysStoppedAnimation<Color>(barColor)),
            )),
            Padding(padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h), child: Row(children: [
              Expanded(child: GestureDetector(onTap: () => _showStudentMarksSheet(student, subjectCombos, examId, classId), child: Container(padding: EdgeInsets.symmetric(vertical: 9.h), decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(10.r)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isComplete ? Icons.edit_rounded : Icons.add_rounded, color: Colors.white, size: 15.sp), SizedBox(width: 6.w), Text(isComplete ? "Edit Marks" : "Enter Marks", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700))])))),
              SizedBox(width: 8.w),
              GestureDetector(onTap: isComplete ? () => _showDMC(student, results, subjectCombos, examId, classId) : null, child: Container(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h), decoration: BoxDecoration(color: isComplete ? _accentSuccess.withOpacity(0.10) : _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isComplete ? _accentSuccess.withOpacity(0.4) : _border)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium_rounded, color: isComplete ? _accentSuccess : _textMuted, size: 15.sp), SizedBox(width: 5.w), Text("DMC", style: TextStyle(color: isComplete ? _accentSuccess : _textMuted, fontSize: 12.sp, fontWeight: FontWeight.w700))]))),
            ])),
          ])),
        );
      },
    );
  }

  void _launchBulkFromMarkEntry(String examId, String classId) async {
    final studSnap = await _studentsRef.where('class', isEqualTo: classId).get();
    final subSnap  = await _examsRef.doc(examId).collection('classSubjects').where('className', isEqualTo: classId).get();
    if (studSnap.docs.isEmpty) { widget.showSnackBar("No students in class $classId", isError: true); return; }
    if (subSnap.docs.isEmpty)  { widget.showSnackBar("No subjects added for this class", isError: true); return; }
    _showBulkMarksEntry(studSnap.docs.cast<DocumentSnapshot>(), subSnap.docs, examId, classId);
  }

  void _showDMC(DocumentSnapshot student, List<QueryDocumentSnapshot> results, List<QueryDocumentSnapshot> subjectCombos, String examId, String classId) {
    DmcService.showAndPrint(context: context, schoolId: widget.schoolId, student: student, results: results, subjectCombos: subjectCombos, examId: examId, classId: classId);
  }

  // ═══════════════════════════════════════════════════════════
  //  ROLL NUMBER MARKS ENTRY
  // ═══════════════════════════════════════════════════════════



  // ═══════════════════════════════════════════════════════════
  //  ANALYTICS
  // ═══════════════════════════════════════════════════════════

  Widget _buildAnalyticsView() {
    return Container(
      color: _bgDark,
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildAnalyticsFilters().animate().fadeIn(duration: 400.ms).slideY(begin: -15, end: 0, duration: 500.ms),
        SizedBox(height: 16.h), _buildAnalyticsStats(), SizedBox(height: 16.h),
        if (widget.isMobile) ...[_gradeChart(), SizedBox(height: 16.h), _subjectChart(), SizedBox(height: 16.h), _topPerformers()]
        else ...[Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _gradeChart()), SizedBox(width: 16.w), Expanded(child: _subjectChart())]), SizedBox(height: 16.h), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: _topPerformers()), SizedBox(width: 16.w), Expanded(child: _classCompare())])],
      ])),
    );
  }

  Widget _buildAnalyticsFilters() {
    return Container(padding: EdgeInsets.all(16.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
        child: widget.isMobile ? Column(children: [_buildClassDropdown(), SizedBox(height: 12.h), _buildExamTypeDropdown()])
            : Row(children: [Expanded(child: _buildClassDropdown()), SizedBox(width: 12.w), Expanded(child: _buildExamTypeDropdown()), SizedBox(width: 12.w), Expanded(child: _buildSubjectDropdown()), SizedBox(width: 12.w), _btn("Generate Report", icon: Icons.assessment, onTap: () {})]));
  }

  Widget _buildAnalyticsStats() {
    final classId = _selectedClass ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: classId.isEmpty ? const Stream.empty() : _resultsRef.where('className', isEqualTo: classId).snapshots(),
      builder: (context, snap) {
        final results = snap.data?.docs ?? []; double totalPerc = 0; double highestM = 0; double lowestM = 9999; int passCount = 0;
        for (var doc in results) { final d = doc.data() as Map<String, dynamic>; final perc = ((d['percentage'] ?? 0) as num).toDouble(); final marks = ((d['marksObtained'] ?? 0) as num).toDouble(); final passingM = ((d['passingMarks'] ?? d['maxMarks'] ?? 100) as num).toInt(); totalPerc += perc; if (marks > highestM) highestM = marks; if (marks < lowestM) lowestM = marks; if (marks >= passingM) passCount++; }
        final avg = results.isNotEmpty ? totalPerc / results.length : 0; final passPerc = results.isNotEmpty ? (passCount / results.length) * 100 : 0; if (lowestM == 9999) lowestM = 0;
        return GridView.count(shrinkWrap: true, physics: NeverScrollableScrollPhysics(), crossAxisCount: widget.isMobile ? 2 : 4, crossAxisSpacing: 16.w, mainAxisSpacing: 16.h, childAspectRatio: widget.isMobile ? 1.2 : 1.4,
            children: [
              _statCard("Average", "${avg.toStringAsFixed(1)}%", Icons.trending_up, _examPrimary, "Class Average").animate(delay: 0.ms).fadeIn(duration: 400.ms).slideY(begin: 30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
              _statCard("Pass Rate", "${passPerc.toStringAsFixed(1)}%", Icons.check_circle, _accentSuccess, "$passCount students").animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
              _statCard("Highest", "${highestM.toStringAsFixed(0)}", Icons.emoji_events, _accentWarning, "Top Score").animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
              _statCard("Lowest", "${lowestM.toStringAsFixed(0)}", Icons.trending_down, _accentDanger, "Needs Attention").animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 30, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
            ]);
      },
    );
  }

  Widget _gradeChart() {
    final classId = _selectedClass ?? '';
    return _chartCard(title: "Grade Distribution", subtitle: "Student count by grade",
        child: SizedBox(height: 250.h, child: StreamBuilder<QuerySnapshot>(
          stream: classId.isEmpty ? const Stream.empty() : _resultsRef.where('className', isEqualTo: classId).snapshots(),
          builder: (context, snap) {
            final results = snap.data?.docs ?? []; final gradeCounts = <String, int>{};
            for (var doc in results) { final d = doc.data() as Map<String, dynamic>; final grade = (d['grade'] ?? 'F').toString(); gradeCounts[grade] = (gradeCounts[grade] ?? 0) + 1; }
            return BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, maxY: (gradeCounts.values.isEmpty ? 0 : gradeCounts.values.reduce((a, b) => a > b ? a : b)) + 5, gridData: FlGridData(show: false), titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) { final g = ['A+', 'A', 'B', 'C', 'D', 'F']; if (v.toInt() < g.length) return Text(g[v.toInt()], style: TextStyle(color: _textMuted, fontSize: 11.sp)); return const SizedBox(); }))), borderData: FlBorderData(show: false),
                barGroups: ['A+', 'A', 'B', 'C', 'D', 'F'].asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: (gradeCounts[e.value] ?? 0).toDouble(), color: _getGradeColor(e.value), width: 20.w, borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)))])).toList()));
          },
        )));
  }

  Widget _subjectChart() => _chartCard(title: "Subject Performance", subtitle: "Average marks by subject",
      child: SizedBox(height: 250.h, child: LineChart(LineChartData(gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (v) => FlLine(color: _border, strokeWidth: 1)), titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: TextStyle(color: _textMuted, fontSize: 10.sp)))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) { final s = ['Math', 'Phy', 'Chem', 'Bio', 'Eng']; if (v.toInt() < s.length) return Text(s[v.toInt()], style: TextStyle(color: _textMuted, fontSize: 10.sp)); return const SizedBox(); }))), borderData: FlBorderData(show: false),
          lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 85), FlSpot(1, 78), FlSpot(2, 82), FlSpot(3, 75), FlSpot(4, 88)], isCurved: true, gradient: LinearGradient(colors: [_examPrimary, _examLight]), barWidth: 3, belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [_examPrimary.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)))]))));

  Widget _topPerformers() {
    final classId = _selectedClass ?? '';
    return _chartCard(title: "Top Performers", subtitle: "Highest scoring students",
        child: StreamBuilder<QuerySnapshot>(
          stream: classId.isEmpty ? const Stream.empty() : _resultsRef.where('className', isEqualTo: classId).orderBy('marksObtained', descending: true).limit(5).snapshots(),
          builder: (context, snap) {
            final results = snap.data?.docs ?? [];
            return Column(children: results.asMap().entries.map((e) { final i = e.key; final d = e.value.data() as Map<String, dynamic>; final isTop3 = i < 3;
            return Container(margin: EdgeInsets.only(bottom: 8.h), padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: isTop3 ? _examPrimary.withOpacity(0.1) : _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isTop3 ? _examPrimary.withOpacity(0.3) : _border)),
                child: Row(children: [Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: isTop3 ? _examPrimary : _textMuted, shape: BoxShape.circle), child: Center(child: Text("${i + 1}", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700)))), SizedBox(width: 12.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((d['studentName'] ?? 'Unknown').toString(), style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)), Text("${d['marksObtained']}/${d['maxMarks']} | ${d['subject'] ?? ''}", style: TextStyle(color: _textMuted, fontSize: 12.sp))])), Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: _accentSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)), child: Text((d['grade'] ?? '--').toString(), style: TextStyle(color: _accentSuccess, fontSize: 12.sp, fontWeight: FontWeight.w700)))]));
            }).toList());
          },
        ));
  }

  Widget _classCompare() => _chartCard(title: "Class Comparison", subtitle: "Performance across classes",
      child: SizedBox(height: 250.h, child: BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, maxY: 100, gridData: FlGridData(show: false), titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) { final c = ['1A', '2A', '3A', '4A', '5A']; if (v.toInt() < c.length) return Text(c[v.toInt()], style: TextStyle(color: _textMuted, fontSize: 11.sp)); return const SizedBox(); }))), borderData: FlBorderData(show: false),
          barGroups: [75, 82, 78, 88, 85].asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), color: e.value >= 80 ? _accentSuccess : _accentWarning, width: 25.w, borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)))])).toList()))));

  // ═══════════════════════════════════════════════════════════
  //  REPORTS
  // ═══════════════════════════════════════════════════════════



  // ═══════════════════════════════════════════════════════════
  //  DIALOGS
  // ═══════════════════════════════════════════════════════════

  void _showCreateExamDialog() {
    final nameCtrl = TextEditingController(); final maxCtrl = TextEditingController(text: '100'); final passCtrl = TextEditingController(text: '50'); final durCtrl = TextEditingController(text: '60');
    DateTime? selDate; String selType = 'Mid-Term'; final types = ['Mid-Term', 'Final', 'Quiz', 'Assignment', 'Practical'];
    showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, ss) => Dialog(
      backgroundColor: _bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(width: widget.isMobile ? double.infinity : 600.w, constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9), padding: EdgeInsets.all(24.w),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)), child: Icon(Icons.add_circle, color: _examPrimary, size: 24.sp)), SizedBox(width: 16.w), Expanded(child: Text("Create New Exam", style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700))), IconButton(icon: Icon(Icons.close, color: _textMuted), onPressed: () => Navigator.pop(context))]),
            SizedBox(height: 16.h),
            Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: _accentInfo.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _accentInfo.withOpacity(0.3))), child: Row(children: [Icon(Icons.info_outline, color: _accentInfo, size: 18.sp), SizedBox(width: 10.w), Expanded(child: Text("After creating, add Class+Subject combos from the exam card", style: TextStyle(color: _accentInfo, fontSize: 12.sp)))])),
            SizedBox(height: 16.h),
            _textField("Exam Name *", nameCtrl), SizedBox(height: 16.h),
            _dropdown("Exam Type", types, selType, (val) => ss(() => selType = val!)), SizedBox(height: 16.h),
            GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(Duration(days: 365)), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: _examPrimary, surface: _bgCard)), child: child!)); if (d != null) ss(() => selDate = d); },
                child: Container(padding: EdgeInsets.all(16.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)), child: Row(children: [Icon(Icons.calendar_today, color: _textMuted, size: 20.sp), SizedBox(width: 12.w), Text(selDate == null ? "Select Exam Date *" : DateFormat('dd MMM yyyy').format(selDate!), style: TextStyle(color: selDate == null ? _textMuted : _textPrimary, fontSize: 14.sp))]))),
            SizedBox(height: 16.h),
            widget.isMobile ? Column(children: [
              _textField("Total Marks *", maxCtrl, type: TextInputType.number),
              SizedBox(height: 12.h),
              _textField("Passing Marks *", passCtrl, type: TextInputType.number),
              SizedBox(height: 12.h),
              _textField("Duration (min) *", durCtrl, type: TextInputType.number),
            ])
                : Column(children: [
              Row(children: [Expanded(child: _textField("Total Marks *", maxCtrl, type: TextInputType.number)), SizedBox(width: 12.w), Expanded(child: _textField("Passing Marks *", passCtrl, type: TextInputType.number))]),
              SizedBox(height: 12.h),
              _textField("Duration (min) *", durCtrl, type: TextInputType.number),
            ]),
            SizedBox(height: 24.h),
            Row(children: [
              Expanded(child: _btn("Cancel", onTap: () => Navigator.pop(context), secondary: true)), SizedBox(width: 12.w),
              Expanded(child: _btn("Create Exam", icon: Icons.check, onTap: () async {
                if (nameCtrl.text.isEmpty || selDate == null) { widget.showSnackBar("Please fill all required fields", isError: true); return; }
                final totalMarks = int.tryParse(maxCtrl.text) ?? 0;
                final passingMarks = int.tryParse(passCtrl.text) ?? 0;
                if (totalMarks <= 0) { widget.showSnackBar("Total marks must be greater than 0", isError: true); return; }
                if (passingMarks <= 0) { widget.showSnackBar("Passing marks cannot be empty", isError: true); return; }
                if (passingMarks > totalMarks) { widget.showSnackBar("Passing marks cannot exceed total marks", isError: true); return; }
                try { await _examsRef.add({'name': nameCtrl.text.trim(), 'type': selType, 'examDate': Timestamp.fromDate(selDate!), 'maxMarks': totalMarks, 'passingMarks': passingMarks, 'duration': int.tryParse(durCtrl.text) ?? 60, 'status': 'draft', 'isPublished': false, 'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser?.uid ?? ''}); Navigator.pop(context); widget.showSnackBar("Exam created! Now add class-subject combos."); }
                catch (e) { widget.showSnackBar("Error: $e", isError: true); }
              })),
            ]),
          ]))),
    ))).animate().fadeIn(duration: 300.ms).scale(duration: 400.ms, begin: Offset(0.9, 0.9), end: Offset(1, 1), curve: Curves.easeOutBack);
  }

  void _showGradingSettings() {
    showDialog(context: context, builder: (context) => Dialog(
      backgroundColor: _bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(width: widget.isMobile ? double.infinity : 600.w, constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9), padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Grading Scale", style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)), SizedBox(height: 16.h),
            Expanded(child: SingleChildScrollView(child: Column(children: _gradingScale.entries.map((entry) => Container(margin: EdgeInsets.only(bottom: 8.h), padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r)), child: Row(children: [Container(width: 40.w, height: 40.w, decoration: BoxDecoration(color: _getGradeColor(entry.key).withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)), child: Center(child: Text(entry.key, style: TextStyle(color: _getGradeColor(entry.key), fontSize: 16.sp, fontWeight: FontWeight.w700)))), SizedBox(width: 16.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${entry.value['min']}-${entry.value['max']}%", style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600)), Text("GPA: ${entry.value['gpa']}", style: TextStyle(color: _textMuted, fontSize: 12.sp))]))])
            )).toList()))),
            SizedBox(height: 16.h), _btn("Close", onTap: () => Navigator.pop(context), secondary: true),
          ])),
    )).animate().fadeIn(duration: 300.ms).scale(duration: 400.ms, begin: Offset(0.9, 0.9), end: Offset(1, 1), curve: Curves.easeOutBack);
  }

  void _showExamDetails(DocumentSnapshot exam) {
    final d = exam.data() as Map<String, dynamic>;
    showDialog(context: context, builder: (context) => Dialog(
      backgroundColor: _bgCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(width: widget.isMobile ? double.infinity : 500.w, padding: EdgeInsets.all(24.w),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)), child: Icon(_examIcon(d['type']), color: _examPrimary, size: 28.sp)), SizedBox(width: 16.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['name'] ?? '', style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)), Text("${d['type']}", style: TextStyle(color: _textSecondary, fontSize: 14.sp))]))]),
            SizedBox(height: 24.h),
            _detailRow("Date", _fmtDate(d['examDate'])), _detailRow("Duration", "${d['duration']} minutes"), _detailRow("Max Marks", "${d['maxMarks']}"),
            SizedBox(height: 24.h),
            Row(children: [Expanded(child: _btn("Close", onTap: () => Navigator.pop(context), secondary: true)), SizedBox(width: 12.w), Expanded(child: _btn("Add Class", icon: Icons.add, onTap: () { Navigator.pop(context); _showAddClassSubjectDialog(exam); }))]),
          ])),
    )).animate().fadeIn(duration: 300.ms).scale(duration: 400.ms, begin: Offset(0.9, 0.9), end: Offset(1, 1), curve: Curves.easeOutBack);
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS — FIXED NULL SAFE
  // ═══════════════════════════════════════════════════════════

  String _calculateGrade(double marks, double maxMarks) {
    if (maxMarks <= 0) return 'F';
    final percentage = (marks / maxMarks) * 100;
    for (var entry in _gradingScale.entries) {
      final min = ((entry.value['min'] ?? 0)   as num).toInt();
      final max = ((entry.value['max'] ?? 100) as num).toInt();
      if (percentage >= min && percentage <= max) return entry.key;
    }
    return 'F';
  }

  double _calculateGPA(double percentage) {
    for (var entry in _gradingScale.entries) {
      final min = ((entry.value['min'] ?? 0)   as num).toInt();
      final max = ((entry.value['max'] ?? 100) as num).toInt();
      if (percentage >= min && percentage <= max) {
        return ((entry.value['gpa'] ?? 0.0) as num).toDouble();
      }
    }
    return 0.0;
  }

  Color _getGradeColor(String grade) {
    switch (grade) { case 'A+': case 'A': return _accentSuccess; case 'A-': case 'B+': case 'B': return _accentWarning; case 'B-': case 'C+': case 'C': return _accentInfo; default: return _accentDanger; }
  }

  IconData _examIcon(dynamic type) {
    switch (type?.toString()) { case 'Mid-Term': return Icons.assignment; case 'Final': return Icons.school; case 'Quiz': return Icons.quiz; case 'Assignment': return Icons.description; case 'Practical': return Icons.science; default: return Icons.assignment; }
  }

  Future<void> _publishExam(DocumentSnapshot exam) async {
    try { await exam.reference.update({'status': 'published', 'isPublished': true, 'publishedAt': FieldValue.serverTimestamp(), 'publishedBy': FirebaseAuth.instance.currentUser?.uid ?? ''}); widget.showSnackBar("Exam published!"); }
    catch (e) { widget.showSnackBar("Error: $e", isError: true); }
  }

  String _fmtDate(dynamic ts) { if (ts == null) return 'N/A'; if (ts is Timestamp) return DateFormat('dd MMM yyyy').format(ts.toDate()); return ts.toString(); }

  // ── UI Components ─────────────────────────────────────────

  Widget _buildClassDropdown() {
    return Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedClass, isExpanded: true, dropdownColor: _bgElevated, hint: Text("Select Class", style: TextStyle(color: _textMuted, fontSize: 14.sp)),
            items: _availableClasses.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: _textPrimary, fontSize: 14.sp)))).toList(),
            onChanged: (v) => setState(() => _selectedClass = v))));
  }

  Widget _buildSubjectDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schools').doc(widget.schoolId).collection('subjects').orderBy('name').snapshots(),
      builder: (context, snap) {
        final subjects = snap.data?.docs.map((d) => ((d.data() as Map<String, dynamic>)['name'] ?? '').toString()).toList() ?? [];
        if (_selectedSubject != null && subjects.isNotEmpty && !subjects.contains(_selectedSubject)) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _selectedSubject = null));
        return Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: subjects.contains(_selectedSubject) ? _selectedSubject : null, isExpanded: true, dropdownColor: _bgElevated, hint: Text(subjects.isEmpty ? "No subjects yet" : "Select Subject", style: TextStyle(color: _textMuted, fontSize: 14.sp)),
                items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: _textPrimary, fontSize: 14.sp)))).toList(),
                onChanged: subjects.isEmpty ? null : (v) => setState(() => _selectedSubject = v))));
      },
    );
  }

  Widget _buildExamTypeDropdown() {
    final types = ['All', 'Mid-Term', 'Final', 'Quiz', 'Assignment', 'Practical'];
    return Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: 'All', isExpanded: true, dropdownColor: _bgElevated,
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(color: _textPrimary, fontSize: 14.sp)))).toList(), onChanged: (v) {})));
  }

  Widget _buildSearchField() {
    return Container(decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
        child: TextField(onChanged: (v) => setState(() => _searchQuery = v), style: TextStyle(color: _textPrimary, fontSize: 14.sp), decoration: InputDecoration(hintText: "Search exams...", hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp), prefixIcon: Icon(Icons.search, color: _textMuted, size: 20.sp), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h))));
  }

  Widget _dropdown(String hint, List<String> items, String? value, Function(String?) onChanged) {
    return Container(padding: EdgeInsets.symmetric(horizontal: 12.w), decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: _bgElevated, hint: Text(hint, style: TextStyle(color: _textMuted, fontSize: 14.sp)),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(color: _textPrimary, fontSize: 14.sp)))).toList(), onChanged: onChanged)));
  }

  Widget _statusChip(String status, Color color) {
    return Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6.w, height: 6.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), SizedBox(width: 6.w), Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w700))]));
  }

  Widget _miniStat(IconData icon, String value) => Row(children: [Icon(icon, color: _textMuted, size: 14.sp), SizedBox(width: 4.w), Text(value, style: TextStyle(color: _textSecondary, fontSize: 12.sp))]);

  Widget _detailRow(String label, String value) => Padding(padding: EdgeInsets.only(bottom: 12.h), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: _textSecondary, fontSize: 14.sp)), Text(value, style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600))]));

  TextStyle _thStyle() => TextStyle(color: _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600);

  Widget _btn(String label, {IconData? icon, VoidCallback? onTap, bool secondary = false, bool isLoading = false}) {
    return Container(
        decoration: BoxDecoration(gradient: secondary || onTap == null ? null : LinearGradient(colors: [_examPrimary, _examLight]), color: secondary ? Colors.transparent : null, borderRadius: BorderRadius.circular(10.r), border: secondary ? Border.all(color: _border) : null),
        child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10.r),
            child: Container(padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: isLoading ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (icon != null) ...[Icon(icon, color: secondary ? _textPrimary : Colors.white, size: 18.sp), SizedBox(width: 8.w)],
                  Text(label, style: TextStyle(color: secondary ? _textPrimary : Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ])))));
  }

  Widget _textField(String label, TextEditingController ctrl, {TextInputType type = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600)), SizedBox(height: 8.h),
      Container(decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: _border)),
          child: TextField(controller: ctrl, keyboardType: type, style: TextStyle(color: _textPrimary, fontSize: 14.sp), decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h)))),
    ]);
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => Material(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8.r), child: Container(padding: EdgeInsets.all(8.w), child: Icon(icon, color: color, size: 18.sp))));

  Widget _statCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(padding: EdgeInsets.all(widget.isMobile ? 16.w : 20.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)), child: Icon(icon, color: color, size: widget.isMobile ? 20.sp : 24.sp)), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(color: _textPrimary, fontSize: widget.isMobile ? 18.sp : 22.sp, fontWeight: FontWeight.w800)), SizedBox(height: 6.h), Text(title, style: TextStyle(color: _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500)), SizedBox(height: 4.h), Text(subtitle, style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w600))])]));
  }

  Widget _chartCard({required String title, required String subtitle, required Widget child}) {
    return Container(padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: _border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: _textPrimary, fontSize: widget.isMobile ? 16.sp : 18.sp, fontWeight: FontWeight.w700)), SizedBox(height: 4.h), Text(subtitle, style: TextStyle(color: _textMuted, fontSize: widget.isMobile ? 11.sp : 12.sp)), SizedBox(height: widget.isMobile ? 16.h : 24.h), child]));
  }

  Widget _emptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(child: Padding(padding: EdgeInsets.all(40.w), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(padding: EdgeInsets.all(24.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: _examPrimary, size: 48.sp)), SizedBox(height: 20.h), Text(title, style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)), SizedBox(height: 4.h), Text(subtitle, style: TextStyle(color: _textSecondary, fontSize: 14.sp), textAlign: TextAlign.center)])));
  }

  Widget _shimmerList() {
    return ListView.builder(itemCount: 5, itemBuilder: (_, i) => Shimmer.fromColors(baseColor: _bgCard, highlightColor: _bgElevated,
        child: Container(margin: EdgeInsets.only(bottom: 12.h), padding: EdgeInsets.all(16.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r)),
            child: Row(children: [Container(width: 48.w, height: 48.w, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)), SizedBox(width: 12.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: double.infinity, height: 16.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r))), SizedBox(height: 8.h), Container(width: 150.w, height: 12.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r)))]))]))));
  }


  // ═══════════════════════════════════════════════════════════
  //  PULL TO REFRESH — WRAPPER WIDGET
  // ═══════════════════════════════════════════════════════════

  Widget _withRefresh({required Widget child, required Future<void> Function() onRefresh}) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _examPrimary,
      backgroundColor: _bgCard,
      strokeWidth: 2.5.w,
      displacement: 20.h,
      child: child,
    );
  }

  Future<void> _refreshExams() async {
    await Future.delayed(Duration(milliseconds: 800));
    setState(() {});
  }

  Future<void> _refreshResults() async {
    await Future.delayed(Duration(milliseconds: 800));
    setState(() {});
  }

  Future<void> _refreshMarkEntry() async {
    await Future.delayed(Duration(milliseconds: 800));
    setState(() {});
  }

  // ═══════════════════════════════════════════════════════════
  //  CONFETTI SUCCESS ANIMATION
  // ═══════════════════════════════════════════════════════════

  void _showConfettiSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Animate(
        autoPlay: true,
        effects: [
          FadeEffect(duration: 400.ms, begin: 0, end: 1),
          FadeEffect(delay: 1500.ms, duration: 400.ms, begin: 1, end: 0),
        ],
        onComplete: (controller) => Navigator.pop(context),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _accentSuccess.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: _accentSuccess, size: 64.sp)
                    .animate()
                    .scale(duration: 500.ms, begin: Offset(0, 0), end: Offset(1, 1), curve: Curves.elasticOut)
                    .then(delay: 100.ms)
                    .shake(duration: 300.ms, hz: 3),
                SizedBox(height: 16.h),
                Text("Saved!", style: TextStyle(color: _accentSuccess, fontSize: 24.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 8.h),
                Text("Marks saved successfully", style: TextStyle(color: _textSecondary, fontSize: 14.sp)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SHAKE VALIDATION — WRAPPER FOR TEXT FIELDS
  // ═══════════════════════════════════════════════════════════

  Widget _shakeField({required Widget child, required bool shouldShake, VoidCallback? onShakeComplete}) {
    return Animate(
      target: shouldShake ? 1 : 0,
      effects: [
        ShakeEffect(duration: 400.ms, hz: 4, offset: Offset(8.w, 0), curve: Curves.easeInOut),
      ],
      onComplete: (controller) => onShakeComplete?.call(),
      child: child,
    );
  }


  // ═══════════════════════════════════════════════════════════
  //  TAB 1: EXAMS (with Pull-to-Refresh)
  // ═══════════════════════════════════════════════════════════

  Widget _buildExamsView() {
    return Container(
      color: _bgDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildExamFilters().animate().fadeIn(duration: 400.ms).slideY(begin: -15, end: 0, duration: 500.ms),
        SizedBox(height: 16.h),
        Expanded(child: _withRefresh(
          onRefresh: _refreshExams,
          child: _buildExamsList(),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 2: RESULTS (with Pull-to-Refresh)
  // ═══════════════════════════════════════════════════════════

  Widget _buildResultsView() {
    return Container(
      color: _bgDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildResultsFilters().animate().fadeIn(duration: 400.ms).slideY(begin: -15, end: 0, duration: 500.ms),
        SizedBox(height: 16.h),
        Expanded(child: (_selectedExam == null || _selectedClass == null)
            ? _selectPrompt()
            : _withRefresh(
          onRefresh: _refreshResults,
          child: _buildResultsList(),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB 3: MARK ENTRY (with Pull-to-Refresh)
  // ═══════════════════════════════════════════════════════════

  Widget _buildMarkEntryView() {
    return Container(
      color: _bgDark,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(padding: EdgeInsets.all(6.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)), child: Icon(Icons.edit_note, color: _examPrimary, size: 18.sp)), SizedBox(width: 8.w), Text("Select Exam & Class", style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700))]),
              SizedBox(height: 10.h),
              Text("Exam", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)), SizedBox(height: 4.h),
              _buildMeExamDropdown(),
              if (_meExam != null) ...[SizedBox(height: 8.h), Text("Class", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)), SizedBox(height: 4.h), _buildMeClassChips(_meExam!)],
            ])).animate().fadeIn(duration: 400.ms).slideY(begin: -10, end: 0, duration: 500.ms),
        SizedBox(height: 10.h),
        if (_meExam != null && _meClass != null) ...[
          Row(children: [
            Expanded(child: _entryModeCardCompact(icon: Icons.pin, title: "Roll Entry", subtitle: "One by one", color: _examPrimary, onTap: () => _showRollNumberMarksEntry(_meExam!, _meClass!))),
            SizedBox(width: 8.w),
            Expanded(child: _entryModeCardCompact(icon: Icons.table_chart, title: "Bulk Entry", subtitle: "All at once", color: _accentInfo, onTap: () => _launchBulkFromMarkEntry(_meExam!, _meClass!))),
          ]).animate().fadeIn(duration: 400.ms).slideY(begin: 10, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
          SizedBox(height: 10.h),
          Expanded(child: _withRefresh(
            onRefresh: _refreshMarkEntry,
            child: _buildMarkEntryStudentList(_meExam!, _meClass!),
          )),
        ] else
          Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_note, color: _examPrimary.withOpacity(0.3), size: 56.sp), SizedBox(height: 12.h), Text("Select Exam & Class", style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700)), SizedBox(height: 6.h), Text("Choose above to start", style: TextStyle(color: _textMuted, fontSize: 13.sp))])))
              .animate().fadeIn(duration: 600.ms).scale(duration: 500.ms, begin: Offset(0.85, 0.85), end: Offset(1, 1), curve: Curves.easeOutBack),
      ]),
    );
  }

  Widget _entryModeCardCompact({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w800)),
                  SizedBox(height: 1.h),
                  Text(subtitle, style: TextStyle(color: _textMuted, fontSize: 10.sp)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.6), size: 12.sp),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ROLL NUMBER ENTRY (with Shake Validation)
  // ═══════════════════════════════════════════════════════════

  void _showRollNumberMarksEntry(String examId, String classId) {
    final rollCtrl   = TextEditingController();
    final subStream  = _examsRef.doc(examId).collection('classSubjects').where('className', isEqualTo: classId).snapshots();
    Map<String, dynamic>? foundStudent; String? foundStudentId;
    Map<String, TextEditingController> markCtrl = {};
    bool isLoading = false; bool isSaving = false; bool autoIncrement = true;
    List<bool> shakeFields = [];

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {

        Future<void> fetchStudent(String roll) async {
          if (roll.trim().isEmpty) return;
          setSheet(() { isLoading = true; foundStudent = null; foundStudentId = null; markCtrl = {}; shakeFields = []; });
          try {
            final snap = await _studentsRef.where('class', isEqualTo: classId).where('rollNumber', isEqualTo: roll.trim()).limit(1).get();
            if (snap.docs.isEmpty) { setSheet(() { isLoading = false; }); widget.showSnackBar("Roll #${roll.trim()} not found in Class $classId", isError: true); return; }
            foundStudentId = snap.docs.first.id;
            foundStudent   = snap.docs.first.data() as Map<String, dynamic>;
            setSheet(() { isLoading = false; });
          } catch (e) { setSheet(() { isLoading = false; }); widget.showSnackBar("Error: $e", isError: true); }
        }

        Future<void> saveAndNext(List<QueryDocumentSnapshot> subjectCombos) async {
          if (foundStudent == null || foundStudentId == null) return;
          setSheet(() { isSaving = true; shakeFields = List.filled(subjectCombos.length, false); });
          bool hasAny = markCtrl.values.any((c) => c.text.trim().isNotEmpty);
          if (!hasAny) { widget.showSnackBar("Kam az kam ek subject ki marks daalo", isError: true); setSheet(() => isSaving = false); return; }
          bool hasErr = false;
          for (var i = 0; i < subjectCombos.length; i++) {
            final c = subjectCombos[i];
            final sd = c.data() as Map<String, dynamic>;
            final subject = (sd['subject'] ?? '').toString();
            final maxM = ((sd['maxMarks'] ?? 100) as num).toInt();
            final text = markCtrl[subject]?.text.trim() ?? '';
            if (text.isEmpty) continue;
            final m = double.tryParse(text);
            if (m == null || m < 0 || m > maxM) {
              setSheet(() => shakeFields[i] = true);
              widget.showSnackBar("$subject ki marks galat hain (0-$maxM)", isError: true);
              hasErr = true;
              break;
            }
          }
          if (hasErr) { setSheet(() => isSaving = false); return; }
          try {
            final existSnap = await _resultsRef.where('studentId', isEqualTo: foundStudentId).where('examId', isEqualTo: examId).get();
            final Map<String, String> existIds = {};
            for (var doc in existSnap.docs) { final d = doc.data() as Map<String, dynamic>; existIds[(d['subject'] ?? '').toString()] = doc.id; }
            final batch = FirebaseFirestore.instance.batch();
            for (var c in subjectCombos) {
              final sd      = c.data() as Map<String, dynamic>;
              final subject = (sd['subject'] ?? '').toString();
              final maxM    = ((sd['maxMarks'] ?? 100) as num).toInt();
              final text    = markCtrl[subject]?.text.trim() ?? ''; if (text.isEmpty) continue;
              final marks   = double.tryParse(text) ?? 0.0;
              final perc    = maxM > 0 ? (marks / maxM) * 100 : 0.0;
              final comboSnap = await _examsRef.doc(examId).collection('classSubjects')
                  .where('className', isEqualTo: classId)
                  .where('subject', isEqualTo: subject)
                  .limit(1)
                  .get();
              final comboData = comboSnap.docs.isNotEmpty ? comboSnap.docs.first.data() as Map<String, dynamic> : {};
              final passingMarks = ((comboData['passingMarks'] ?? comboData['maxMarks'] ?? maxM) as num).toInt();
              final isPassed = marks >= passingMarks;

              final d = <String, dynamic>{
                'studentId': foundStudentId, 'studentName': (foundStudent!['name'] ?? '').toString(),
                'rollNumber': (foundStudent!['rollNumber'] ?? '').toString(), 'className': classId,
                'subject': subject, 'examId': examId, 'marksObtained': marks, 'maxMarks': maxM,
                'passingMarks': passingMarks,
                'percentage': perc, 'grade': _calculateGrade(marks, maxM.toDouble()),
                'gpa': _calculateGPA(perc), 'isPassed': isPassed, 'isAutoCalculated': true,
                'updatedAt': FieldValue.serverTimestamp(), 'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
              };
              if (existIds.containsKey(subject)) { batch.update(_resultsRef.doc(existIds[subject]!), d); }
              else { d['createdAt'] = FieldValue.serverTimestamp(); batch.set(_resultsRef.doc(), d); }
            }
            await batch.commit();
            for (var c in subjectCombos) { await _updateComboProgress(examId, classId, ((c.data() as Map<String, dynamic>)['subject'] ?? '').toString()); }
            _showConfettiSuccess();
            widget.showSnackBar("${foundStudent!['name']} ki marks save ho gayi!");
            if (autoIncrement) { final cur = int.tryParse(rollCtrl.text.trim()); final next = cur != null ? (cur + 1).toString() : ''; rollCtrl.text = next; setSheet(() { foundStudent = null; foundStudentId = null; markCtrl = {}; shakeFields = []; isSaving = false; }); if (next.isNotEmpty) await fetchStudent(next); }
            else { rollCtrl.clear(); setSheet(() { foundStudent = null; foundStudentId = null; markCtrl = {}; shakeFields = []; isSaving = false; }); }
          } catch (e, st) { print("Save error: $e\n$st"); setSheet(() => isSaving = false); widget.showSnackBar("Error: $e", isError: true); }
        }

        return Container(
          height: MediaQuery.of(ctx).size.height * (widget.isMobile ? 0.94 : 0.88),
          decoration: BoxDecoration(color: _bgDark, borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)), border: Border.all(color: _border)),
          child: Column(children: [
            Container(margin: EdgeInsets.only(top: 12.h), width: 40.w, height: 4.h, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2.r))),
            SizedBox(height: 16.h),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Row(children: [Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(12.r)), child: Icon(Icons.pin, color: Colors.white, size: 22.sp)), SizedBox(width: 14.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Roll Number Entry", style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w800)), Text("Class $classId", style: TextStyle(color: _textSecondary, fontSize: 12.sp))])), IconButton(icon: Icon(Icons.close, color: _textMuted), onPressed: () => Navigator.pop(ctx))])),
            SizedBox(height: 12.h),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Container(padding: EdgeInsets.all(4.w), decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _border)), child: Row(children: [
              Expanded(child: GestureDetector(onTap: () => setSheet(() => autoIncrement = true), child: AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 10.h), decoration: BoxDecoration(gradient: autoIncrement ? LinearGradient(colors: [_examPrimary, _examLight]) : null, borderRadius: BorderRadius.circular(8.r)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.skip_next_rounded, color: autoIncrement ? Colors.white : _textMuted, size: 16.sp), SizedBox(width: 6.w), Text("Auto Next", style: TextStyle(color: autoIncrement ? Colors.white : _textMuted, fontSize: 13.sp, fontWeight: FontWeight.w700))])))),
              Expanded(child: GestureDetector(onTap: () => setSheet(() => autoIncrement = false), child: AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(vertical: 10.h), decoration: BoxDecoration(gradient: !autoIncrement ? LinearGradient(colors: [_accentInfo, Color(0xFF60A5FA)]) : null, borderRadius: BorderRadius.circular(8.r)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.backspace_outlined, color: !autoIncrement ? Colors.white : _textMuted, size: 16.sp), SizedBox(width: 6.w), Text("Manual", style: TextStyle(color: !autoIncrement ? Colors.white : _textMuted, fontSize: 13.sp, fontWeight: FontWeight.w700))])))),
            ]))),
            SizedBox(height: 6.h),
            Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Text(autoIncrement ? "Save -> roll auto-increments" : "Save -> field clears manually", style: TextStyle(color: _textMuted, fontSize: 11.sp))),
            SizedBox(height: 12.h), Divider(color: _border, height: 1),
            Padding(padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0), child: Row(children: [
              Expanded(child: Container(decoration: BoxDecoration(color: _bgElevated, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: foundStudent != null ? _accentSuccess.withOpacity(0.6) : _border, width: 1.5)), child: TextField(controller: rollCtrl, keyboardType: TextInputType.text, textInputAction: TextInputAction.search, onSubmitted: fetchStudent, autofocus: true, style: TextStyle(color: _textPrimary, fontSize: 22.sp, fontWeight: FontWeight.w800), decoration: InputDecoration(hintText: "Roll Number", hintStyle: TextStyle(color: _textMuted, fontSize: 16.sp), prefixIcon: Icon(Icons.tag, color: _examPrimary, size: 20.sp), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 16.h))))),
              SizedBox(width: 12.w),
              GestureDetector(onTap: () => fetchStudent(rollCtrl.text), child: Container(padding: EdgeInsets.all(16.w), decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(12.r)), child: isLoading ? SizedBox(width: 20.w, height: 20.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.search, color: Colors.white, size: 22.sp))),
            ])),
            if (foundStudent != null) ...[
              SizedBox(height: 10.h),
              Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: Container(padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h), decoration: BoxDecoration(color: _accentSuccess.withOpacity(0.08), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: _accentSuccess.withOpacity(0.3))),
                  child: Row(children: [Container(width: 40.w, height: 40.w, decoration: BoxDecoration(gradient: LinearGradient(colors: [_examPrimary, _examLight]), borderRadius: BorderRadius.circular(10.r)), child: Center(child: Text((foundStudent!['name'] ?? '?')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w800)))), SizedBox(width: 10.w), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((foundStudent!['name'] ?? 'Unknown').toString(), style: TextStyle(color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w800)), Text("Roll: ${foundStudent!['rollNumber'] ?? '--'}  •  Class $classId", style: TextStyle(color: _textSecondary, fontSize: 12.sp))])), Icon(Icons.check_circle, color: _accentSuccess, size: 20.sp)]))),
            ],
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: subStream,
              builder: (ctx, subSnap) {
                final combos = subSnap.data?.docs ?? [];
                if (foundStudent == null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.pin, color: _examPrimary.withOpacity(0.25), size: 64.sp), SizedBox(height: 14.h), Text("Roll number daalo upar", style: TextStyle(color: _textMuted, fontSize: 16.sp, fontWeight: FontWeight.w600)), SizedBox(height: 4.h), Text("${combos.length} subjects ready", style: TextStyle(color: _textMuted, fontSize: 12.sp))]));
                if (combos.isEmpty) return Center(child: Text("Koi subject nahi mila. Exams tab se add karo.", style: TextStyle(color: _textMuted, fontSize: 14.sp)));
                for (var c in combos) { final subject = ((c.data() as Map<String, dynamic>)['subject'] ?? '').toString(); if (!markCtrl.containsKey(subject)) markCtrl[subject] = TextEditingController(); }
                if (shakeFields.isEmpty) shakeFields = List.filled(combos.length, false);
                return StreamBuilder<QuerySnapshot>(
                  stream: _resultsRef.where('studentId', isEqualTo: foundStudentId).where('examId', isEqualTo: examId).snapshots(),
                  builder: (ctx, mSnap) {
                    if (mSnap.hasData) { for (var doc in mSnap.data!.docs) { final d = doc.data() as Map<String, dynamic>; final subj = (d['subject'] ?? '').toString(); final marks = d['marksObtained']; if (markCtrl.containsKey(subj) && marks != null) { final nv = (marks as num).toInt().toString(); if (markCtrl[subj]!.text != nv) markCtrl[subj]!.text = nv; } } }
                    return Column(children: [
                      Expanded(child: ListView.builder(padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h), itemCount: combos.length, itemBuilder: (ctx, i) {
                        final sd = combos[i].data() as Map<String, dynamic>;
                        final subject  = (sd['subject'] ?? '').toString();
                        final maxMarks = ((sd['maxMarks'] ?? 100) as num).toInt();
                        final ctrl     = markCtrl[subject]!;
                        return ValueListenableBuilder<TextEditingValue>(valueListenable: ctrl, builder: (ctx, val, _) {
                          final marks   = double.tryParse(val.text) ?? -1; final hasVal = marks >= 0;
                          final perc    = hasVal && maxMarks > 0 ? (marks / maxMarks) * 100 : 0.0;
                          final grade   = hasVal ? _calculateGrade(marks, maxMarks.toDouble()) : '';
                          final gc      = perc >= 80 ? _accentSuccess : perc >= 60 ? _accentWarning : _accentDanger;
                          final isValid = hasVal && marks <= maxMarks;
                          return _shakeField(
                            shouldShake: shakeFields.length > i ? shakeFields[i] : false,
                            onShakeComplete: () => setSheet(() { if (shakeFields.length > i) shakeFields[i] = false; }),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: _bgCard,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: hasVal ? (isValid ? gc.withOpacity(0.4) : _accentDanger.withOpacity(0.5)) : _border, width: hasVal ? 1.5 : 1),
                              ),
                              child: Row(children: [
                                Container(padding: EdgeInsets.all(8.w), decoration: BoxDecoration(color: _examPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)), child: Icon(Icons.book_outlined, color: _examPrimary, size: 18.sp)),
                                SizedBox(width: 10.w),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject, style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w700)), Text("Max: $maxMarks", style: TextStyle(color: _textMuted, fontSize: 11.sp))])),
                                if (hasVal && isValid) ...[Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: gc.withOpacity(0.3))), child: Column(children: [Text(grade, style: TextStyle(color: gc, fontSize: 14.sp, fontWeight: FontWeight.w800)), Text("${perc.toStringAsFixed(0)}%", style: TextStyle(color: gc.withOpacity(0.8), fontSize: 9.sp))])), SizedBox(width: 10.w)],
                                Container(
                                  width: 76.w,
                                  decoration: BoxDecoration(
                                    color: _bgElevated,
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: hasVal ? (isValid ? gc : _accentDanger) : _border, width: hasVal ? 2 : 1),
                                  ),
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    textInputAction: i < combos.length - 1 ? TextInputAction.next : TextInputAction.done,
                                    onSubmitted: i == combos.length - 1 ? (_) => saveAndNext(combos) : null,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w800),
                                    decoration: InputDecoration(hintText: "--", hintStyle: TextStyle(color: _textMuted, fontSize: 16.sp), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 10.h)),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        });
                      })),
                      if (foundStudent != null) Container(padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h), decoration: BoxDecoration(color: _bgCard, border: Border(top: BorderSide(color: _border))),
                          child: Row(children: [Expanded(child: _btn("Cancel", onTap: () => Navigator.pop(ctx), secondary: true)), SizedBox(width: 12.w), Expanded(flex: 2, child: _btn(isSaving ? "Saving..." : (autoIncrement ? "Save & Next ->" : "Save & Clear"), icon: autoIncrement ? Icons.navigate_next : Icons.check_circle_outline, onTap: isSaving ? null : () => saveAndNext(combos), isLoading: isSaving))])),
                    ]);
                  },
                );
              },
            )),
          ]),
        );
      }),
    );
  }


}

extension on Future<dynamic> {
  animate() {}
}
