// ─────────────────────────────────────────────────────────────────────────────
// subjects_module.dart
// lib/features/admin/presentation/pages/subjects_module.dart
//
// Subjects Management Module — EduManage Pro
// Visual identity: table-first, department-grouped, curriculum-focused.
// Deliberately different from ClassesModule (card/grid) in every way.
//
// Firestore Path:
//   schools/{schoolId}/subjects/{subjectId}
//
// Document fields:
//   name          String   e.g. "Mathematics"
//   code          String   e.g. "MATH-10"
//   department    String   e.g. "Science", "Languages"
//   type          String   "Core" | "Elective" | "Lab" | "Co-curricular"
//   grades        List     grades this subject is taught in e.g. ["9","10"]
//   weeklyPeriods int      periods per week
//   creditHours   int
//   passMark      int      e.g. 50
//   totalMarks    int      e.g. 100
//   description   String
//   assignedTeacherId   String (optional)
//   assignedTeacherName String (optional)
//   isActive      bool
//   createdAt     Timestamp
//   updatedAt     Timestamp
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

// ─── COLOUR TOKENS (same palette as dashboard) ────────────────────────────────
const Color _bgDark      = Color(0xFF0B0F19);
const Color _bgCard      = Color(0xFF151B2B);
const Color _bgElevated  = Color(0xFF1E2538);
const Color _bgHover     = Color(0xFF242B40);
const Color _border      = Color(0xFF2D3748);
const Color _primary     = Color(0xFF6366F1);
const Color _primaryLight= Color(0xFF818CF8);
const Color _green       = Color(0xFF22C55E);
const Color _amber       = Color(0xFFF59E0B);
const Color _red         = Color(0xFFEF4444);
const Color _blue        = Color(0xFF3B82F6);
const Color _violet      = Color(0xFFA855F7);
const Color _teal        = Color(0xFF14B8A6);
const Color _rose        = Color(0xFFF43F5E);
const Color _textPrimary = Color(0xFFF8FAFC);
const Color _textSecondary=Color(0xFF94A3B8);
const Color _textMuted   = Color(0xFF64748B);

// ─── DEPARTMENT CONFIG ────────────────────────────────────────────────────────
class _Dept {
  final String name;
  final Color color;
  final IconData icon;
  const _Dept(this.name, this.color, this.icon);
}

const List<_Dept> _departments = [
  _Dept('Science',        _blue,   Icons.science_outlined),
  _Dept('Mathematics',    _primary,Icons.calculate_outlined),
  _Dept('Languages',      _green,  Icons.translate_outlined),
  _Dept('Social Studies', _amber,  Icons.public_outlined),
  _Dept('Arts',           _violet, Icons.palette_outlined),
  _Dept('Physical Ed.',   _teal,   Icons.sports_outlined),
  _Dept('Computer',       _rose,   Icons.computer_outlined),
  _Dept('Religious',      _red,    Icons.menu_book_outlined),
  _Dept('Other',          _textMuted, Icons.folder_outlined),
];

_Dept _deptFor(String name) =>
    _departments.firstWhere((d) => d.name == name,
        orElse: () => _departments.last);

// ─── SUBJECT TYPE CONFIG ──────────────────────────────────────────────────────
class _TypeConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _TypeConfig(this.label, this.color, this.icon);
}

const Map<String, _TypeConfig> _typeConfigs = {
  'Core'         : _TypeConfig('Core',          _primary, Icons.star_outlined),
  'Elective'     : _TypeConfig('Elective',       _green,   Icons.tune_outlined),
  'Lab'          : _TypeConfig('Lab',            _amber,   Icons.biotech_outlined),
  'Co-curricular': _TypeConfig('Co-curricular',  _violet,  Icons.emoji_events_outlined),
};

_TypeConfig _typeFor(String t) =>
    _typeConfigs[t] ?? const _TypeConfig('Core', _primary, Icons.star_outlined);

// ─────────────────────────────────────────────────────────────────────────────
// SubjectsModule
// ─────────────────────────────────────────────────────────────────────────────
class SubjectsModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final void Function(String msg, {bool isError}) showSnackBar;

  const SubjectsModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<SubjectsModule> createState() => _SubjectsModuleState();
}

class _SubjectsModuleState extends State<SubjectsModule>
    with SingleTickerProviderStateMixin {

  // ── View state ──────────────────────────────────────────────────────────────
  String  _searchQuery    = '';
  String? _filterDept;
  String? _filterType;
  String? _filterGrade;
  bool    _showInactive   = false;
  String  _sortBy         = 'name'; // 'name' | 'dept' | 'periods' | 'code'

  // Tab: department filter via TabBar
  late TabController _tabController;

  final List<String> _deptTabs = [
    'All',
    ..._departments.map((d) => d.name),
  ];

  // ── Firestore ───────────────────────────────────────────────────────────────
  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('subjects')
      .orderBy('name')
      .snapshots();

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _deptTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filterDept = _tabController.index == 0
              ? null
              : _deptTabs[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Filter + sort ────────────────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _filtered(List<QueryDocumentSnapshot> all) {
    var list = all.where((doc) {
      final d = doc.data() as Map<String, dynamic>;

      // Active filter
      final isActive = d['isActive'] as bool? ?? true;
      if (!_showInactive && !isActive) return false;

      // Search
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          (d['name']   ?? '').toString().toLowerCase().contains(q) ||
          (d['code']   ?? '').toString().toLowerCase().contains(q) ||
          (d['department'] ?? '').toString().toLowerCase().contains(q) ||
          (d['assignedTeacherName'] ?? '').toString().toLowerCase().contains(q);

      // Department tab
      final matchDept = _filterDept == null ||
          (d['department'] ?? '') == _filterDept;

      // Type filter
      final matchType = _filterType == null ||
          (d['type'] ?? '') == _filterType;

      // Grade filter
      final grades = List<String>.from(d['grades'] ?? []);
      final matchGrade = _filterGrade == null ||
          grades.contains(_filterGrade);

      return matchSearch && matchDept && matchType && matchGrade;
    }).toList();

    list.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      switch (_sortBy) {
        case 'dept':
          return (da['department'] ?? '').compareTo(db['department'] ?? '');
        case 'periods':
          return (db['weeklyPeriods'] ?? 0)
              .compareTo(da['weeklyPeriods'] ?? 0);
        case 'code':
          return (da['code'] ?? '').compareTo(db['code'] ?? '');
        default:
          return (da['name'] ?? '').compareTo(db['name'] ?? '');
      }
    });
    return list;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 20.h),
        _buildDeptTabs(),
        SizedBox(height: 14.h),
        _buildToolbar(),
        SizedBox(height: 16.h),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return widget.isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleBlock(),
        SizedBox(height: 14.h),
        _addBtn(fullWidth: true),
      ],
    )
        : Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _titleBlock()),
        _statsStrip(),
        SizedBox(width: 16.w),
        _addBtn(),
      ],
    );
  }

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 28.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, _teal],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Curriculum & Subjects',
              style: TextStyle(
                color: _textPrimary,
                fontSize: widget.isMobile ? 20.sp : 24.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Text(
            'Define the academic curriculum, departments and subject catalogue',
            style: TextStyle(color: _textSecondary, fontSize: 12.sp),
          ),
        ),
      ],
    );
  }

  Widget _statsStrip() {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final active = docs
            .where((d) => (d.data() as Map<String, dynamic>)['isActive'] != false)
            .length;
        final depts = docs
            .map((d) => (d.data() as Map<String, dynamic>)['department'])
            .toSet()
            .length;
        return Row(
          children: [
            _statPill(Icons.menu_book_outlined, '$active', 'subjects', _primary),
            SizedBox(width: 8.w),
            _statPill(Icons.account_tree_outlined, '$depts', 'depts', _teal),
          ],
        );
      },
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(color: _textSecondary, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  // ── Department tab bar ────────────────────────────────────────────────────────
  Widget _buildDeptTabs() {
    return SizedBox(
      height: 36.h,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.only(right: 4.w),
        indicator: const BoxDecoration(), // custom below
        tabs: List.generate(_deptTabs.length, (i) {
          final isAll = i == 0;
          final dept = isAll ? null : _deptFor(_deptTabs[i]);
          return _DeptTab(
            label: isAll ? 'All subjects' : _deptTabs[i],
            color: isAll ? _primary : dept!.color,
            icon: isAll ? Icons.apps_rounded : dept!.icon,
            isSelected: _tabController.index == i,
            controller: _tabController,
            index: i,
          );
        }),
      ),
    );
  }

  // ── Toolbar: search + filters ─────────────────────────────────────────────────
  Widget _buildToolbar() {
    return widget.isMobile
        ? Column(
      children: [
        _searchField(),
        SizedBox(height: 10.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _filterChips()),
        ),
      ],
    )
        : Row(
      children: [
        SizedBox(width: 260.w, child: _searchField()),
        SizedBox(width: 12.w),
        ..._filterChips().map((c) => Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: c,
        )),
        const Spacer(),
        _sortDropdown(),
        SizedBox(width: 10.w),
        _inactiveToggle(),
      ],
    );
  }

  Widget _searchField() {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(color: _textPrimary, fontSize: 13.sp),
        decoration: InputDecoration(
          hintText: 'Search subjects…',
          hintStyle: TextStyle(color: _textMuted, fontSize: 13.sp),
          prefixIcon: Icon(Icons.search, color: _textMuted, size: 16.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }

  List<Widget> _filterChips() => [
    _FilterChip(
      label: _filterType ?? 'Type',
      isActive: _filterType != null,
      onTap: _showTypeFilter,
    ),
    _FilterChip(
      label: _filterGrade != null ? 'Grade $_filterGrade' : 'Grade',
      isActive: _filterGrade != null,
      onTap: _showGradeFilter,
    ),
    if (_filterType != null || _filterGrade != null)
      _FilterChip(
        label: 'Clear',
        isActive: false,
        isClear: true,
        onTap: () => setState(() {
          _filterType = null;
          _filterGrade = null;
        }),
      ),
  ];

  Widget _sortDropdown() {
    return PopupMenuButton<String>(
      color: _bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: _border),
      ),
      onSelected: (v) => setState(() => _sortBy = v),
      itemBuilder: (_) => [
        _menuItem('name',    'Sort: Name'),
        _menuItem('dept',    'Sort: Department'),
        _menuItem('periods', 'Sort: Periods'),
        _menuItem('code',    'Sort: Code'),
      ],
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, color: _textMuted, size: 14.sp),
            SizedBox(width: 5.w),
            Text('Sort',
                style: TextStyle(
                    color: _textSecondary, fontSize: 12.sp)),
            Icon(Icons.arrow_drop_down,
                color: _textMuted, size: 16.sp),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, String label) => PopupMenuItem(
    value: v,
    child: Text(label,
        style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
  );

  Widget _inactiveToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showInactive = !_showInactive),
      child: Container(
        height: 36.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: _showInactive ? _primary.withOpacity(0.12) : _bgCard,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
              color: _showInactive
                  ? _primary.withOpacity(0.4)
                  : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showInactive
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _showInactive ? _primary : _textMuted,
              size: 14.sp,
            ),
            SizedBox(width: 5.w),
            Text('Inactive',
                style: TextStyle(
                  color: _showInactive ? _primary : _textSecondary,
                  fontSize: 12.sp,
                )),
          ],
        ),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shimmer();
        }
        if (snap.hasError) {
          return _centred(Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: _red, size: 40.sp),
              SizedBox(height: 10.h),
              Text('Failed to load subjects',
                  style: TextStyle(color: _textPrimary, fontSize: 15.sp)),
            ],
          ));
        }

        final all      = snap.data?.docs ?? [];
        final filtered = _filtered(all);

        if (all.isEmpty) return _emptyAll();
        if (filtered.isEmpty) return _emptyFiltered();

        // Group by department
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (final doc in filtered) {
          final dept =
              (doc.data() as Map<String, dynamic>)['department'] as String? ??
                  'Other';
          grouped.putIfAbsent(dept, () => []).add(doc);
        }

        return ListView(
          padding: EdgeInsets.only(bottom: 32.h),
          children: grouped.entries.map((entry) {
            return _DeptSection(
              deptName: entry.key,
              docs: entry.value,
              isMobile: widget.isMobile,
              schoolId: widget.schoolId,
              onEdit: (doc) => _openForm(doc),
              onToggleActive: _toggleActive,
              onDelete: _confirmDelete,
              onTap: (doc) => _openDetailSheet(doc),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Empty states ─────────────────────────────────────────────────────────────
  Widget _emptyAll() {
    return _centred(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _emptyIllustration(),
        SizedBox(height: 24.h),
        Text('No subjects in the curriculum yet',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Text(
          'Add your first subject to start building\nthe academic curriculum.',
          style: TextStyle(color: _textSecondary, fontSize: 13.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
        _addBtn(),
      ],
    ));
  }

  Widget _emptyFiltered() {
    return _centred(Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, color: _textMuted, size: 40.sp),
        SizedBox(height: 14.h),
        Text('No subjects match your filters',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Text('Try adjusting search or clearing filters.',
            style: TextStyle(color: _textSecondary, fontSize: 12.sp)),
      ],
    ));
  }

  Widget _emptyIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 90.w,
          height: 90.w,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
        ),
        Icon(Icons.menu_book_outlined, color: _primary, size: 44.sp),
      ],
    );
  }

  Widget _centred(Widget child) =>
      Center(child: Padding(padding: EdgeInsets.all(32.w), child: child));

  // ── Shimmer ──────────────────────────────────────────────────────────────────
  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: _bgCard,
      highlightColor: _bgElevated,
      child: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          height: 180.h,
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────────────
  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _BottomSheet(
        title: 'Filter by type',
        children: [
          null, // "All"
          'Core', 'Elective', 'Lab', 'Co-curricular',
        ].map((t) {
          final cfg = t == null ? null : _typeFor(t);
          final isSelected = _filterType == t;
          return ListTile(
            leading: Icon(
              cfg?.icon ?? Icons.apps_rounded,
              color: cfg?.color ?? _textMuted,
              size: 20.sp,
            ),
            title: Text(
              t ?? 'All types',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: _primary, size: 18.sp)
                : null,
            onTap: () {
              setState(() => _filterType = t);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showGradeFilter() {
    final grades = ['1','2','3','4','5','6','7','8','9','10','11','12'];
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => _BottomSheet(
        title: 'Filter by grade',
        children: [
          null,
          ...grades,
        ].map((g) {
          final isSelected = _filterGrade == g;
          return ListTile(
            title: Text(
              g == null ? 'All grades' : 'Grade $g',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: _primary, size: 18.sp)
                : null,
            onTap: () {
              setState(() => _filterGrade = g);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void _openForm(QueryDocumentSnapshot? existing) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (_) => _SubjectFormDialog(
        schoolId: widget.schoolId,
        existing: existing,
        showSnackBar: widget.showSnackBar,
      ),
    );
  }

  void _openDetailSheet(QueryDocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectDetailSheet(
        doc: doc,
        schoolId: widget.schoolId,
        onEdit: () {
          Navigator.pop(context);
          _openForm(doc);
        },
      ),
    );
  }

  Future<void> _toggleActive(QueryDocumentSnapshot doc) async {
    final d = doc.data() as Map<String, dynamic>;
    final current = d['isActive'] as bool? ?? true;
    try {
      await doc.reference.update({
        'isActive': !current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      widget.showSnackBar(
          current ? 'Subject deactivated' : 'Subject activated');
    } catch (e) {
      widget.showSnackBar('Error: $e', isError: true);
    }
  }

  void _confirmDelete(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgCard,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete subject?',
            style: TextStyle(
                color: _textPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Permanently delete "${d['name']}"? This cannot be undone.',
          style: TextStyle(color: _textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style:
                TextStyle(color: _textSecondary, fontSize: 13.sp)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await doc.reference.delete();
                widget.showSnackBar('Subject deleted');
              } catch (e) {
                widget.showSnackBar('Error: $e', isError: true);
              }
            },
            child: Text('Delete',
                style: TextStyle(
                    color: _red,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _addBtn({bool fullWidth = false}) {
    final btn = GestureDetector(
      onTap: () => _openForm(null),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryLight]),
          borderRadius: BorderRadius.circular(9.r),
          boxShadow: [
            BoxShadow(
                color: _primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 17.sp),
            SizedBox(width: 6.w),
            Text('Add Subject',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
    return btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DeptTab — animated tab chip
// ─────────────────────────────────────────────────────────────────────────────
class _DeptTab extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final TabController controller;
  final int index;

  const _DeptTab({
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(right: 6.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : const Color(0xFF151B2B),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : const Color(0xFF2D3748),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? color : const Color(0xFF64748B),
                size: 13.sp),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : const Color(0xFF94A3B8),
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterChip
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isClear;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.isClear = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: isClear
              ? _red.withOpacity(0.08)
              : isActive
              ? _primary.withOpacity(0.12)
              : _bgCard,
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(
            color: isClear
                ? _red.withOpacity(0.3)
                : isActive
                ? _primary.withOpacity(0.4)
                : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isClear) ...[
              Icon(
                isActive ? Icons.filter_list : Icons.filter_list_outlined,
                color: isActive ? _primary : _textMuted,
                size: 12.sp,
              ),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: TextStyle(
                color: isClear
                    ? _red
                    : isActive
                    ? _primary
                    : _textSecondary,
                fontSize: 12.sp,
                fontWeight: isActive || isClear ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isActive && !isClear) ...[
              SizedBox(width: 4.w),
              Icon(Icons.arrow_drop_down,
                  color: _primary, size: 14.sp),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DeptSection — one collapsible group of subjects by department
// ─────────────────────────────────────────────────────────────────────────────
class _DeptSection extends StatefulWidget {
  final String deptName;
  final List<QueryDocumentSnapshot> docs;
  final bool isMobile;
  final String schoolId;
  final void Function(QueryDocumentSnapshot) onEdit;
  final void Function(QueryDocumentSnapshot) onToggleActive;
  final void Function(QueryDocumentSnapshot) onDelete;
  final void Function(QueryDocumentSnapshot) onTap;

  const _DeptSection({
    required this.deptName,
    required this.docs,
    required this.isMobile,
    required this.schoolId,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_DeptSection> createState() => _DeptSectionState();
}

class _DeptSectionState extends State<_DeptSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final dept  = _deptFor(widget.deptName);
    final count = widget.docs.length;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // ── Section header ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 18.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: dept.color.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(14.r),
                  bottom:
                  _expanded ? Radius.zero : Radius.circular(14.r),
                ),
                border: _expanded
                    ? Border(
                    bottom: BorderSide(color: _border))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: dept.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(dept.icon,
                        color: dept.color, size: 16.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    widget.deptName,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: dept.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '$count ${count == 1 ? 'subject' : 'subjects'}',
                      style: TextStyle(
                        color: dept.color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: _textMuted, size: 20.sp),
                  ),
                ],
              ),
            ),
          ),

          // ── Subject rows ────────────────────────────────────────────────────
          if (_expanded)
            widget.isMobile
                ? Column(
              children: widget.docs
                  .map((doc) => _SubjectMobileCard(
                doc: doc,
                onEdit: () => widget.onEdit(doc),
                onToggleActive: () =>
                    widget.onToggleActive(doc),
                onDelete: () => widget.onDelete(doc),
                onTap: () => widget.onTap(doc),
              ))
                  .toList(),
            )
                : _SubjectTable(
              docs: widget.docs,
              onEdit: widget.onEdit,
              onToggleActive: widget.onToggleActive,
              onDelete: widget.onDelete,
              onTap: widget.onTap,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectTable — dense data table for desktop
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectTable extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final void Function(QueryDocumentSnapshot) onEdit;
  final void Function(QueryDocumentSnapshot) onToggleActive;
  final void Function(QueryDocumentSnapshot) onDelete;
  final void Function(QueryDocumentSnapshot) onTap;

  const _SubjectTable({
    required this.docs,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
          color: _bgElevated.withOpacity(0.5),
          child: Row(
            children: [
              _th('Subject', flex: 3),
              _th('Code',    flex: 2),
              _th('Type',    flex: 2),
              _th('Grades',  flex: 2),
              _th('Periods/wk', flex: 2),
              _th('Teacher', flex: 3),
              _th('Status',  flex: 2),
              SizedBox(width: 80.w),
            ],
          ),
        ),
        // Rows
        ...docs.asMap().entries.map((entry) {
          final i   = entry.key;
          final doc = entry.value;
          return _SubjectTableRow(
            doc: doc,
            isEven: i.isEven,
            onEdit: () => onEdit(doc),
            onToggleActive: () => onToggleActive(doc),
            onDelete: () => onDelete(doc),
            onTap: () => onTap(doc),
          );
        }),
      ],
    );
  }

  Widget _th(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: _textMuted,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectTableRow — single row in the desktop table
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectTableRow extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final bool isEven;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SubjectTableRow({
    required this.doc,
    required this.isEven,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_SubjectTableRow> createState() => _SubjectTableRowState();
}

class _SubjectTableRowState extends State<_SubjectTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d        = widget.doc.data() as Map<String, dynamic>;
    final name     = d['name']     as String? ?? '';
    final code     = d['code']     as String? ?? '—';
    final type     = d['type']     as String? ?? 'Core';
    final grades   = List<String>.from(d['grades'] ?? []);
    final periods  = d['weeklyPeriods'] as int? ?? 0;
    final teacher  = d['assignedTeacherName'] as String? ?? '—';
    final isActive = d['isActive']  as bool?   ?? true;
    final dept     = _deptFor(d['department'] as String? ?? 'Other');
    final typeCfg  = _typeFor(type);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
          decoration: BoxDecoration(
            color: _hovered
                ? _bgHover
                : widget.isEven
                ? Colors.transparent
                : _bgElevated.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: _border.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              // Subject name + icon
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: dept.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7.r),
                      ),
                      child: Icon(dept.icon,
                          color: dept.color, size: 14.sp),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isActive
                              ? _textPrimary
                              : _textMuted,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          decoration: isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Code
              Expanded(
                flex: 2,
                child: Text(
                  code,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12.sp,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              // Type badge
              Expanded(
                flex: 2,
                child: _TypeBadge(type: type),
              ),
              // Grades
              Expanded(
                flex: 2,
                child: grades.isEmpty
                    ? Text('—',
                    style: TextStyle(
                        color: _textMuted, fontSize: 12.sp))
                    : Wrap(
                  spacing: 3.w,
                  runSpacing: 3.h,
                  children: grades.take(4).map((g) =>
                      _GradeChip(grade: g)).toList(),
                ),
              ),
              // Periods
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        color: periods > 0 ? _primary : _textMuted,
                        size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      periods > 0 ? '$periods/wk' : '—',
                      style: TextStyle(
                        color: periods > 0
                            ? _textSecondary
                            : _textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Teacher
              Expanded(
                flex: 3,
                child: Text(
                  teacher,
                  style: TextStyle(
                      color: _textSecondary, fontSize: 12.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: _StatusBadge(isActive: isActive),
              ),
              // Actions
              SizedBox(
                width: 80.w,
                child: AnimatedOpacity(
                  opacity: _hovered ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _RowAction(
                        icon: Icons.edit_outlined,
                        color: _primary,
                        onTap: widget.onEdit,
                        tooltip: 'Edit',
                      ),
                      SizedBox(width: 4.w),
                      _RowAction(
                        icon: isActive
                            ? Icons.toggle_on_outlined
                            : Icons.toggle_off_outlined,
                        color: isActive ? _green : _amber,
                        onTap: widget.onToggleActive,
                        tooltip: isActive ? 'Deactivate' : 'Activate',
                      ),
                      SizedBox(width: 4.w),
                      _RowAction(
                        icon: Icons.delete_outline,
                        color: _red,
                        onTap: widget.onDelete,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectMobileCard — card layout for phones
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectMobileCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SubjectMobileCard({
    required this.doc,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d        = doc.data() as Map<String, dynamic>;
    final name     = d['name']     as String? ?? '';
    final code     = d['code']     as String? ?? '';
    final type     = d['type']     as String? ?? 'Core';
    final grades   = List<String>.from(d['grades'] ?? []);
    final periods  = d['weeklyPeriods'] as int? ?? 0;
    final teacher  = d['assignedTeacherName'] as String? ?? '';
    final isActive = d['isActive']  as bool?   ?? true;
    final dept     = _deptFor(d['department'] as String? ?? 'Other');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 1.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: _border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: dept.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Icon(dept.icon, color: dept.color, size: 16.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isActive ? _textPrimary : _textMuted,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            decoration: isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      _StatusBadge(isActive: isActive),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (code.isNotEmpty) ...[
                        Text(code,
                            style: TextStyle(
                              color: _textMuted,
                              fontSize: 11.sp,
                              fontFamily: 'monospace',
                            )),
                        SizedBox(width: 8.w),
                      ],
                      _TypeBadge(type: type),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 4.w,
                    runSpacing: 4.h,
                    children: [
                      if (periods > 0)
                        _InfoPill(
                            Icons.schedule_outlined, '$periods/wk', _primary),
                      if (teacher.isNotEmpty)
                        _InfoPill(Icons.person_outline, teacher, _textMuted),
                      ...grades.take(3).map((g) => _GradeChip(grade: g)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _RowAction(
                    icon: Icons.edit_outlined,
                    color: _primary,
                    onTap: onEdit,
                    tooltip: 'Edit'),
                SizedBox(height: 6.h),
                _RowAction(
                    icon: isActive
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    color: isActive ? _green : _amber,
                    onTap: onToggleActive,
                    tooltip: isActive ? 'Deactivate' : 'Activate'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable atoms
// ─────────────────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final cfg = _typeFor(type);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: cfg.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: cfg.color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, color: cfg.color, size: 10.sp),
          SizedBox(width: 4.w),
          Text(
            cfg.label,
            style: TextStyle(
              color: cfg.color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _green : _textMuted;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.w,
            height: 5.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
                color: color, fontSize: 10.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  final String grade;
  const _GradeChip({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: _border),
      ),
      child: Text(
        'G$grade',
        style: TextStyle(
          color: _textSecondary,
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11.sp),
        SizedBox(width: 3.w),
        Text(label,
            style: TextStyle(color: _textSecondary, fontSize: 11.sp)),
      ],
    );
  }
}

class _RowAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _RowAction(
      {required this.icon,
        required this.color,
        required this.onTap,
        required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, color: color, size: 14.sp),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectFormDialog — Add / Edit
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectFormDialog extends StatefulWidget {
  final String schoolId;
  final QueryDocumentSnapshot? existing;
  final void Function(String, {bool isError}) showSnackBar;

  const _SubjectFormDialog({
    required this.schoolId,
    required this.existing,
    required this.showSnackBar,
  });

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl    = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _periodsCtrl = TextEditingController();
  final _creditCtrl  = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _totalCtrl   = TextEditingController();

  String       _dept        = 'Science';
  String       _type        = 'Core';
  List<String> _grades      = [];
  String       _teacherId   = '';
  String       _teacherName = '';
  bool         _isActive    = true;
  bool         _isSaving    = false;

  final _allGrades = ['1','2','3','4','5','6','7','8','9','10','11','12'];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!.data() as Map<String, dynamic>;
      _nameCtrl.text    = d['name']         ?? '';
      _codeCtrl.text    = d['code']         ?? '';
      _descCtrl.text    = d['description']  ?? '';
      _periodsCtrl.text = (d['weeklyPeriods'] ?? '').toString();
      _creditCtrl.text  = (d['creditHours']   ?? '').toString();
      _passCtrl.text    = (d['passMark']       ?? '').toString();
      _totalCtrl.text   = (d['totalMarks']     ?? '').toString();
      _dept             = d['department']   ?? 'Science';
      _type             = d['type']         ?? 'Core';
      _grades           = List<String>.from(d['grades'] ?? []);
      _teacherId        = d['assignedTeacherId']   ?? '';
      _teacherName      = d['assignedTeacherName'] ?? '';
      _isActive         = d['isActive'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _codeCtrl, _descCtrl, _periodsCtrl,
      _creditCtrl, _passCtrl, _totalCtrl
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'name'               : _nameCtrl.text.trim(),
        'code'               : _codeCtrl.text.trim().toUpperCase(),
        'description'        : _descCtrl.text.trim(),
        'department'         : _dept,
        'type'               : _type,
        'grades'             : _grades,
        'weeklyPeriods'      : int.tryParse(_periodsCtrl.text) ?? 0,
        'creditHours'        : int.tryParse(_creditCtrl.text)  ?? 0,
        'passMark'           : int.tryParse(_passCtrl.text)    ?? 50,
        'totalMarks'         : int.tryParse(_totalCtrl.text)   ?? 100,
        'assignedTeacherId'  : _teacherId,
        'assignedTeacherName': _teacherName,
        'isActive'           : _isActive,
        'updatedAt'          : FieldValue.serverTimestamp(),
      };

      if (widget.existing == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('subjects')
            .add(data);
        widget.showSnackBar('Subject created!');
      } else {
        await widget.existing!.reference.update(data);
        widget.showSnackBar('Subject updated!');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Container(
        width: 600.w,
        constraints:
        BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogHeader(isEdit),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22.w, 4.h, 22.w, 22.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.h),
                      _row2(
                        _field('Subject name *', _nameCtrl,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null),
                        _field('Subject code', _codeCtrl,
                            hint: 'e.g. MATH-10'),
                      ),
                      SizedBox(height: 14.h),

                      // Department + Type
                      _sLabel('Classification'),
                      SizedBox(height: 10.h),
                      _row2(_deptPicker(), _typePicker()),
                      SizedBox(height: 14.h),

                      // Grade selector
                      _sLabel('Applicable grades'),
                      SizedBox(height: 8.h),
                      _gradeSelector(),
                      SizedBox(height: 14.h),

                      // Numerics
                      _sLabel('Scheduling & marks'),
                      SizedBox(height: 10.h),
                      _row4(
                        _numField('Periods/wk', _periodsCtrl),
                        _numField('Credit hours', _creditCtrl),
                        _numField('Pass mark', _passCtrl, hint: '50'),
                        _numField('Total marks', _totalCtrl, hint: '100'),
                      ),
                      SizedBox(height: 14.h),

                      // Teacher
                      _sLabel('Assigned teacher'),
                      SizedBox(height: 8.h),
                      _teacherPicker(),
                      SizedBox(height: 14.h),

                      // Description
                      _sLabel('Description'),
                      SizedBox(height: 8.h),
                      _textArea(),
                      SizedBox(height: 14.h),

                      // Active toggle
                      _activeToggle(),
                      SizedBox(height: 22.h),

                      _actionRow(isEdit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogHeader(bool isEdit) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.w),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Icon(Icons.menu_book_outlined, color: _teal, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit subject' : 'Add subject to curriculum',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  isEdit
                      ? 'Update the subject details below'
                      : 'New subject will be added to the catalogue',
                  style: TextStyle(color: _textSecondary, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(7.r),
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.close, color: _textMuted, size: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sLabel(String t) => Text(t,
      style: TextStyle(
          color: _textSecondary,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5));

  Widget _row2(Widget a, Widget b) => Row(
    children: [
      Expanded(child: a),
      SizedBox(width: 12.w),
      Expanded(child: b),
    ],
  );

  Widget _row4(Widget a, Widget b, Widget c, Widget d) => Row(
    children: [
      Expanded(child: a),
      SizedBox(width: 8.w),
      Expanded(child: b),
      SizedBox(width: 8.w),
      Expanded(child: c),
      SizedBox(width: 8.w),
      Expanded(child: d),
    ],
  );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: _textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 5.h),
        TextFormField(
          controller: ctrl,
          validator: validator,
          style: TextStyle(color: _textPrimary, fontSize: 13.sp),
          decoration: _dec(hint ?? label.replaceAll(' *', '')),
        ),
      ],
    );
  }

  Widget _numField(String label, TextEditingController ctrl,
      {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: _textSecondary,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 5.h),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: _textPrimary, fontSize: 13.sp),
          decoration: _dec(hint ?? '0'),
        ),
      ],
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _textMuted, fontSize: 12.sp),
    filled: true,
    fillColor: _bgElevated,
    contentPadding:
    EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: _teal, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: _red),
    ),
  );

  Widget _deptPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Department',
            style: TextStyle(
                color: _textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 5.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _dept,
              isExpanded: true,
              dropdownColor: _bgElevated,
              style: TextStyle(color: _textPrimary, fontSize: 13.sp),
              items: _departments
                  .map((d) => DropdownMenuItem(
                value: d.name,
                child: Row(
                  children: [
                    Icon(d.icon, color: d.color, size: 14.sp),
                    SizedBox(width: 8.w),
                    Text(d.name,
                        style: TextStyle(
                            color: _textPrimary, fontSize: 13.sp)),
                  ],
                ),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _dept = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject type',
            style: TextStyle(
                color: _textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 5.h),
        Row(
          children: _typeConfigs.keys.map((t) {
            final cfg      = _typeFor(t);
            final selected = _type == t;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: t != 'Co-curricular' ? 4.w : 0),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? cfg.color.withOpacity(0.12)
                        : _bgElevated,
                    borderRadius: BorderRadius.circular(7.r),
                    border: Border.all(
                      color: selected
                          ? cfg.color.withOpacity(0.5)
                          : _border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(cfg.icon,
                          color: selected ? cfg.color : _textMuted,
                          size: 14.sp),
                      SizedBox(height: 3.h),
                      Text(
                        t == 'Co-curricular' ? 'Co-curr.' : t,
                        style: TextStyle(
                          color: selected ? cfg.color : _textMuted,
                          fontSize: 9.sp,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _gradeSelector() {
    return Wrap(
      spacing: 6.w,
      runSpacing: 6.h,
      children: _allGrades.map((g) {
        final sel = _grades.contains(g);
        return GestureDetector(
          onTap: () => setState(
                  () => sel ? _grades.remove(g) : _grades.add(g)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 38.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: sel ? _teal.withOpacity(0.15) : _bgElevated,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: sel ? _teal.withOpacity(0.6) : _border,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                g,
                style: TextStyle(
                  color: sel ? _teal : _textSecondary,
                  fontSize: 12.sp,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _teacherPicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                    color: _teal, strokeWidth: 2),
              ),
            ),
          );
        }
        final teachers = snap.data!.docs;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _teacherId.isEmpty ? null : _teacherId,
              isExpanded: true,
              dropdownColor: _bgElevated,
              hint: Text('No teacher assigned',
                  style: TextStyle(color: _textMuted, fontSize: 13.sp)),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text('None',
                      style:
                      TextStyle(color: _textSecondary, fontSize: 13.sp)),
                ),
                ...teachers.map((t) {
                  final td = t.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(td['name'] ?? '',
                        style: TextStyle(
                            color: _textPrimary, fontSize: 13.sp)),
                  );
                }),
              ],
              onChanged: (v) => setState(() {
                _teacherId = v ?? '';
                if (v == null || v.isEmpty) {
                  _teacherName = '';
                } else {
                  final match =
                  teachers.firstWhere((t) => t.id == v);
                  final td = match.data() as Map<String, dynamic>;
                  _teacherName = td['name'] ?? '';
                }
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _textArea() {
    return TextFormField(
      controller: _descCtrl,
      maxLines: 3,
      style: TextStyle(color: _textPrimary, fontSize: 13.sp),
      decoration: _dec('Brief description of what this subject covers…'),
    );
  }

  Widget _activeToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: _isActive ? _green : _textMuted,
            size: 16.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject active',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
                Text('Inactive subjects are hidden from timetables',
                    style:
                    TextStyle(color: _textMuted, fontSize: 11.sp)),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: _green,
            activeTrackColor: _green.withOpacity(0.25),
            inactiveTrackColor: _bgCard,
            inactiveThumbColor: _textMuted,
          ),
        ],
      ),
    );
  }

  Widget _actionRow(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 13.h),
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(9.r),
                border: Border.all(color: _border),
              ),
              child: Center(
                child: Text('Cancel',
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isSaving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              decoration: BoxDecoration(
                gradient: _isSaving
                    ? null
                    : const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF6366F1)]),
                color: _isSaving ? _bgElevated : null,
                borderRadius: BorderRadius.circular(9.r),
                boxShadow: _isSaving
                    ? []
                    : [
                  BoxShadow(
                    color: _teal.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: _isSaving
                    ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  isEdit ? 'Save changes' : 'Add to curriculum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectDetailSheet
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectDetailSheet extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String schoolId;
  final VoidCallback onEdit;

  const _SubjectDetailSheet({
    required this.doc,
    required this.schoolId,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final d        = doc.data() as Map<String, dynamic>;
    final name     = d['name']        as String? ?? '';
    final code     = d['code']        as String? ?? '';
    final desc     = d['description'] as String? ?? '';
    final dept     = _deptFor(d['department'] as String? ?? 'Other');
    final type     = d['type']        as String? ?? 'Core';
    final grades   = List<String>.from(d['grades']  ?? []);
    final periods  = d['weeklyPeriods'] as int? ?? 0;
    final credits  = d['creditHours']   as int? ?? 0;
    final passMark = d['passMark']      as int? ?? 0;
    final total    = d['totalMarks']    as int? ?? 0;
    final teacher  = d['assignedTeacherName'] as String? ?? '';
    final isActive = d['isActive'] as bool? ?? true;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 36.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 14.h),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: dept.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: dept.color.withOpacity(0.25)),
                  ),
                  child: Icon(dept.icon, color: dept.color, size: 22.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name,
                              style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w800)),
                          SizedBox(width: 8.w),
                          _StatusBadge(isActive: isActive),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          if (code.isNotEmpty) ...[
                            Text(code,
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 12.sp,
                                  fontFamily: 'monospace',
                                )),
                            SizedBox(width: 8.w),
                          ],
                          _TypeBadge(type: type),
                          SizedBox(width: 6.w),
                          Text(dept.name,
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 12.sp)),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: _teal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            color: _teal, size: 14.sp),
                        SizedBox(width: 5.w),
                        Text('Edit',
                            style: TextStyle(
                                color: _teal,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Divider(color: _border, height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: [
                      _statCard('Periods/wk', '$periods', Icons.schedule_outlined, _primary),
                      SizedBox(width: 10.w),
                      _statCard('Credits', '$credits', Icons.stars_outlined, _teal),
                      SizedBox(width: 10.w),
                      _statCard('Pass mark', '$passMark/$total', Icons.grade_outlined, _amber),
                    ],
                  ),
                  SizedBox(height: 18.h),

                  if (teacher.isNotEmpty) ...[
                    _detailRow(Icons.person_outlined, 'Teacher', teacher),
                    SizedBox(height: 10.h),
                  ],

                  if (grades.isNotEmpty) ...[
                    _detailRow(
                      Icons.school_outlined,
                      'Taught in grades',
                      '',
                      trailing: Wrap(
                        spacing: 5.w,
                        runSpacing: 5.h,
                        children: grades
                            .map((g) => _GradeChip(grade: g))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],

                  if (desc.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text('Description',
                        style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: _bgElevated,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _border),
                      ),
                      child: Text(desc,
                          style: TextStyle(
                              color: _textSecondary, fontSize: 13.sp,
                              height: 1.6)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(height: 8.h),
            Text(value,
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style:
                TextStyle(color: _textSecondary, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _textMuted, size: 15.sp),
        SizedBox(width: 10.w),
        Text('$label: ',
            style: TextStyle(
                color: _textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600)),
        if (trailing != null) Expanded(child: trailing)
        else Expanded(
          child: Text(value,
              style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomSheet — generic bottom sheet scaffold
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BottomSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 10.h),
            width: 36.w,
            height: 3.h,
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(2.r)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 6.h),
            child: Text(title,
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700)),
          ),
          Divider(color: _border),
          ...children,
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}