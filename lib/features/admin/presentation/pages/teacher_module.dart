import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 MIDNIGHT SAAS — DESIGN SYSTEM (Embedded for standalone use)
// ═══════════════════════════════════════════════════════════════════════════

// ─── Background Colors ────────────────────────────────────
const Color _bgDark      = Color(0xFF0F1117);
const Color _bgCard      = Color(0xFF161922);
const Color _bgElevated  = Color(0xFF1E212E);

// ─── Border Colors ────────────────────────────────────────
const Color _border      = Color(0xFF2A2E3B);
const Color _borderLight = Color(0xFF353A4A);

// ─── Text Colors ──────────────────────────────────────────
const Color _textPrimary   = Color(0xFFEEF1F8);
const Color _textSecondary = Color(0xFF8B92A8);
const Color _textMuted     = Color(0xFF5A6072);

// ─── Accent Colors ────────────────────────────────────────
const Color _primary      = Color(0xFF7C8CF0);
const Color _primaryLight = Color(0xFF9AA5F3);
const Color _primaryDark  = Color(0xFF5E6BE8);

const Color _accentSuccess = Color(0xFF3DD68B);
const Color _accentWarning = Color(0xFFF2A93B);
const Color _accentDanger  = Color(0xFFF2657A);
const Color _accentInfo    = Color(0xFF4DBEF7);
const Color _accentViolet  = Color(0xFFB084F5);
const Color _accentSlate   = Color(0xFF8B92A8);

// ═══════════════════════════════════════════════════════════════════════════
// 📋 TEACHER MODEL
// ═══════════════════════════════════════════════════════════════════════════

class TeacherModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> subjects;
  final List<String> classes;
  final String? classTeacherOf;
  final int weeklyPeriods;
  final String status;
  final String schoolId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.subjects,
    required this.classes,
    this.classTeacherOf,
    this.weeklyPeriods = 0,
    this.status = 'active',
    required this.schoolId,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TeacherModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      subjects: List<String>.from(data['subjects'] ?? []),
      classes: List<String>.from(data['classes'] ?? []),
      classTeacherOf: data['classTeacherOf'] as String?,
      weeklyPeriods: data['weeklyPeriods'] ?? 0,
      status: data['status'] ?? 'active',
      schoolId: data['schoolId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'subjects': subjects,
      'classes': classes,
      'classTeacherOf': classTeacherOf,
      'weeklyPeriods': weeklyPeriods,
      'status': status,
      'schoolId': schoolId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 ANIMATION WIDGETS (Embedded for standalone use)
// ═══════════════════════════════════════════════════════════════════════════

/// Hover scale + glow border card
class _HoverCard extends StatefulWidget {
  final Widget child;
  final double scaleUp;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final bool enableGlow;

  const _HoverCard({
    required this.child,
    this.scaleUp = 1.025,
    this.glowColor,
    this.borderRadius,
    this.enableGlow = true,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleUp).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: widget.enableGlow && _hovered
                ? BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (widget.glowColor ?? _primary).withOpacity(0.28),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            )
                : const BoxDecoration(),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Staggered fade+slide-up item for lists
class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _StaggeredItem({required this.child, required this.index});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Hover action button (scale + color lift)
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _HoverIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_hovered ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.color.withOpacity(_hovered ? 0.5 : 0.2)),
            boxShadow: _hovered
                ? [BoxShadow(color: widget.color.withOpacity(0.25), blurRadius: 10)]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Count-up animated number
class _AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;
  const _AnimatedCounter({required this.value, required this.style});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prev = old.value;
      _anim = Tween<double>(
          begin: _prev.toDouble(), end: widget.value.toDouble())
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) =>
          Text(_anim.value.toInt().toString(), style: widget.style),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 🎓 TEACHER MODULE — Complete Standalone Widget
// ═══════════════════════════════════════════════════════════════════════════

class TeacherModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final Function(String, {bool isError})? showSnackBar;

  const TeacherModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    this.isMobile = false,
    this.isTablet = false,
    this.isDesktop = true,
    this.showSnackBar,
  });

  @override
  State<TeacherModule> createState() => _TeacherModuleState();
}

class _TeacherModuleState extends State<TeacherModule> {
  // ─── State ────────────────────────────────────────────────
  String searchQuery = "";
  String? selectedFilter;
  String? selectedClassFilter;
  int currentPage = 1;
  final int itemsPerPage = 10;

  // ─── Data ─────────────────────────────────────────────────
  final List<String> availableClasses = [
    "1A","1B","1C","2A","2B","2C","3A","3B","3C",
    "4A","4B","4C","5A","5B","5C","6A","6B","6C",
    "7A","7B","7C","8A","8B","8C","9A","9B","9C",
    "10A","10B","10C",
  ];

  final List<String> allSubjects = [
    "Mathematics","Physics","Chemistry","Biology",
    "Computer Science","English","History","Geography",
    "Urdu","Islamiat","Pakistan Studies"
  ];

  // ─── Firestore Reference ──────────────────────────────────
  CollectionReference get _teachersRef => FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('teachers');

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  bool get isMobile => widget.isMobile || ScreenUtil().screenWidth <= 768;
  bool get isTablet => widget.isTablet ||
      (ScreenUtil().screenWidth > 768 && ScreenUtil().screenWidth <= 1200);
  bool get isDesktop => widget.isDesktop || ScreenUtil().screenWidth > 1200;

  void _showSnackBar(String message, {bool isError = false}) {
    if (widget.showSnackBar != null) {
      widget.showSnackBar!(message, isError: isError);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(isMobile ? 16.w : 24.w),
          content: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: isError ? _accentDanger : _bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: isError ? _accentDanger : _border),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.white : _accentSuccess,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(message,
                      style: TextStyle(
                          color: isError ? Colors.white : _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModuleHeader(),
        SizedBox(height: isMobile ? 16.h : 24.h),
        _buildSearchAndFilterBar(),
        SizedBox(height: 16.h),
        Expanded(
          child: _buildPaginatedTeacherList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 MODULE HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModuleHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: _teachersRef.snapshots(),
      builder: (context, snapshot) {
        final totalCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final activeCount = snapshot.hasData
            ? snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>?;
          return data?['status'] == 'active';
        }).length
            : 0;

        return isMobile
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.school_rounded,
                      color: _primary, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Teacher Management",
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Manage faculty, classes & subjects",
                        style: TextStyle(
                            color: _textSecondary, fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildStatPill(
                  icon: Icons.people,
                  label: 'Total',
                  value: totalCount,
                  color: _primary,
                ),
                SizedBox(width: 8.w),
                _buildStatPill(
                  icon: Icons.check_circle,
                  label: 'Active',
                  value: activeCount,
                  color: _accentSuccess,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: _HoverCard(
                scaleUp: 1.03,
                glowColor: _primary,
                enableGlow: true,
                child: _industrialButton(
                  "Add Teacher",
                  icon: Icons.add,
                  onPressed: () => _showAddTeacherDialog(),
                ),
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: _primary.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.school_rounded,
                      color: _primary, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Teacher Management",
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Manage faculty, classes & subjects",
                      style: TextStyle(
                          color: _textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _buildStatPill(
                          icon: Icons.people,
                          label: 'Total Teachers',
                          value: totalCount,
                          color: _primary,
                        ),
                        SizedBox(width: 12.w),
                        _buildStatPill(
                          icon: Icons.check_circle,
                          label: 'Active',
                          value: activeCount,
                          color: _accentSuccess,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            _HoverCard(
              scaleUp: 1.04,
              glowColor: _primary,
              enableGlow: true,
              child: _industrialButton(
                "Add Teacher",
                icon: Icons.add,
                onPressed: () => _showAddTeacherDialog(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
            label,
            style: TextStyle(
                color: _textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 4.w),
          _AnimatedCounter(
            value: value,
            style: TextStyle(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 SEARCH & FILTER BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: isMobile
          ? Column(
        children: [
          _industrialSearchField(
            hint: "Search teachers...",
            onChanged: (query) => setState(() {
              searchQuery = query;
              currentPage = 1;
            }),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _HoverCard(
                  scaleUp: 1.03,
                  enableGlow: false,
                  child: _industrialButton(
                    "Filters",
                    icon: Icons.filter_list,
                    onPressed: () => _showFilterDialog(),
                    isSecondary: true,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _HoverCard(
                  scaleUp: 1.03,
                  enableGlow: false,
                  child: _industrialButton(
                    "Sort",
                    icon: Icons.sort,
                    onPressed: () {},
                    isSecondary: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            flex: 2,
            child: _industrialSearchField(
              hint: "Search by name, email, subject or class...",
              onChanged: (query) => setState(() {
                searchQuery = query;
                currentPage = 1;
              }),
            ),
          ),
          SizedBox(width: 16.w),
          _HoverCard(
            scaleUp: 1.04,
            enableGlow: false,
            child: _industrialButton(
              "Filters",
              icon: Icons.filter_list,
              onPressed: () => _showFilterDialog(),
              isSecondary: true,
            ),
          ),
          SizedBox(width: 8.w),
          _HoverCard(
            scaleUp: 1.04,
            enableGlow: false,
            child: _industrialButton(
              "Export",
              icon: Icons.download,
              onPressed: () {},
              isSecondary: true,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 PAGINATED TEACHER LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPaginatedTeacherList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _teachersRef.orderBy("createdAt", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerList();

        final allTeachers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final name = (data['name'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          final subjects =
              (data['subjects'] as List<dynamic>?)?.join(' ') ?? '';
          final classes =
              (data['classes'] as List<dynamic>?)?.join(' ') ?? '';
          final query = searchQuery.toLowerCase();
          return name.contains(query) ||
              email.contains(query) ||
              subjects.toLowerCase().contains(query) ||
              classes.toLowerCase().contains(query);
        }).toList();

        if (allTeachers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: "No teachers found",
            subtitle: searchQuery.isEmpty
                ? "Add your first teacher to get started"
                : "Try adjusting your search",
          );
        }

        final totalPages = (allTeachers.length / itemsPerPage).ceil();
        final startIndex = (currentPage - 1) * itemsPerPage;
        final endIndex =
        (startIndex + itemsPerPage).clamp(0, allTeachers.length);
        final teachers = allTeachers.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: isMobile
                  ? ListView.builder(
                itemCount: teachers.length,
                itemBuilder: (context, index) => _StaggeredItem(
                  index: index,
                  child: _buildTeacherCard(
                    teacher: teachers[index],
                    onEdit: () => _showEditTeacherDialog(teachers[index]),
                    onDelete: () => _confirmDeleteTeacher(teachers[index]),
                  ),
                ),
              )
                  : _buildDataTable(teachers),
            ),
            if (totalPages > 1)
              Container(
                margin: EdgeInsets.only(top: 16.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _industrialIconButton(
                      Icons.chevron_left,
                      onPressed: currentPage > 1
                          ? () => setState(() => currentPage--)
                          : null,
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      "Page $currentPage of $totalPages",
                      style: TextStyle(
                          color: _textSecondary, fontSize: 14.sp),
                    ),
                    SizedBox(width: 16.w),
                    _industrialIconButton(
                      Icons.chevron_right,
                      onPressed: currentPage < totalPages
                          ? () => setState(() => currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 DATA TABLE (Desktop/Tablet)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDataTable(List<DocumentSnapshot> teachers) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildSortableHeader("Teacher", Icons.person)),
                Expanded(flex: 2, child: _buildSortableHeader("Classes", Icons.school)),
                Expanded(flex: 2, child: _buildSortableHeader("Subjects", Icons.book)),
                Expanded(child: _buildSortableHeader("Status", Icons.circle)),
                SizedBox(width: 100.w),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: teachers.length,
              separatorBuilder: (_, __) => Divider(color: _border, height: 1),
              itemBuilder: (context, index) => _StaggeredItem(
                index: index,
                child: _HoverCard(
                  scaleUp: 1.008,
                  enableGlow: false,
                  child: _buildTeacherTableRow(
                    teacher: teachers[index],
                    onEdit: () => _showEditTeacherDialog(teachers[index]),
                    onDelete: () => _confirmDeleteTeacher(teachers[index]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String label, IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: _textMuted, size: 16.sp),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
                color: _textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 4.w),
          Icon(Icons.unfold_more, color: _textMuted, size: 14.sp),
        ],
      ),
    );
  }

  Widget _buildTeacherTableRow({
    required DocumentSnapshot teacher,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final data = teacher.data() as Map<String, dynamic>? ?? {};
    final subjects = List<String>.from(data['subjects'] ?? []);
    final classes = List<String>.from(data['classes'] ?? []);
    final classTeacherOf = data['classTeacherOf'] as String?;
    final status = data['status'] ?? 'active';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_primary, _primaryLight]),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      (data['name'] ?? '')[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (classTeacherOf != null)
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: _accentInfo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                                color: _accentInfo.withOpacity(0.3)),
                          ),
                          child: Text(
                            "CT: $classTeacherOf",
                            style: TextStyle(
                                color: _accentInfo,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: [
                ...classes.take(3).map((c) => _miniClassChip(c)),
                if (classes.length > 3) _miniClassChip("+${classes.length - 3}"),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children: [
                ...subjects.take(2).map((s) => _miniSubjectChip(s)),
                if (subjects.length > 2)
                  _miniSubjectChip("+${subjects.length - 2}"),
              ],
            ),
          ),
          Expanded(child: _buildStatusBadge(status)),
          SizedBox(
            width: 100.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _HoverIconButton(
                    icon: Icons.edit_outlined,
                    color: _primary,
                    onPressed: onEdit),
                SizedBox(width: 8.w),
                _HoverIconButton(
                    icon: Icons.delete_outline,
                    color: _accentDanger,
                    onPressed: onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📱 TEACHER CARD (Mobile)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTeacherCard({
    required DocumentSnapshot teacher,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final data = teacher.data() as Map<String, dynamic>? ?? {};
    final subjects = List<String>.from(data['subjects'] ?? []);
    final classes = List<String>.from(data['classes'] ?? []);
    final classTeacherOf = data['classTeacherOf'] as String?;
    final status = data['status'] ?? 'active';
    final weeklyPeriods = data['weeklyPeriods'] ?? 0;

    return _HoverCard(
      scaleUp: 1.018,
      glowColor: _primary,
      enableGlow: true,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_primary, _primaryLight]),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      (data['name'] ?? '')[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        data['email'] ?? '',
                        style: TextStyle(
                            color: _textMuted, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 12.h),
            if (classTeacherOf != null) ...[
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(
                    horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _accentInfo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                      color: _accentInfo.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: _accentInfo, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Class Teacher: $classTeacherOf",
                      style: TextStyle(
                          color: _accentInfo,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
            if (classes.isNotEmpty) ...[
              Text(
                "Classes",
                style: TextStyle(
                    color: _textMuted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: classes.map((c) => _classChip(c)).toList(),
              ),
              SizedBox(height: 8.h),
            ],
            Text(
              "Subjects",
              style: TextStyle(
                  color: _textMuted,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: subjects.map((s) => _subjectChip(s)).toList(),
            ),
            if (weeklyPeriods > 0) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.schedule, color: _textMuted, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    "$weeklyPeriods periods/week",
                    style: TextStyle(color: _textMuted, fontSize: 11.sp),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _HoverIconButton(
                    icon: Icons.edit_outlined,
                    color: _primary,
                    onPressed: onEdit),
                SizedBox(width: 8.w),
                _HoverIconButton(
                    icon: Icons.delete_outline,
                    color: _accentDanger,
                    onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🏷️ CHIPS & BADGES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _miniClassChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _accentWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: _accentWarning.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: _accentWarning,
            fontSize: 10.sp,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _miniSubjectChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: _primary, fontSize: 11.sp, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _classChip(String className) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _accentWarning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: _accentWarning.withOpacity(0.3)),
      ),
      child: Text(
        className,
        style: TextStyle(
            color: _accentWarning,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _subjectChip(String subject) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: _primary.withOpacity(0.2)),
      ),
      child: Text(
        subject,
        style: TextStyle(
            color: _primary, fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isActive = status == 'active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isActive
            ? _accentSuccess.withOpacity(0.1)
            : _accentDanger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive
              ? _accentSuccess.withOpacity(0.2)
              : _accentDanger.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: isActive ? _accentSuccess : _accentDanger,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
                color: isActive ? _accentSuccess : _accentDanger,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ➕ ADD TEACHER DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddTeacherDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    List<String> selectedSubjects = [];
    List<String> selectedClasses = [];
    String? classTeacherOf;
    int weeklyPeriods = 0;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          child: Container(
            width: isMobile ? double.infinity : 600.w,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: EdgeInsets.all(24.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.person_add,
                            color: _primary, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Add New Teacher",
                              style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              "Fill in the details below",
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 13.sp),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  _industrialTextField("Full Name *", nameController),
                  SizedBox(height: 16.h),
                  _industrialTextField("Email Address *", emailController,
                      type: TextInputType.emailAddress),
                  SizedBox(height: 16.h),
                  _industrialTextField("Phone Number", phoneController,
                      type: TextInputType.phone),
                  SizedBox(height: 20.h),
                  Text(
                    "Select Subjects *",
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: allSubjects.map((subject) {
                      final isSelected = selectedSubjects.contains(subject);
                      return _industrialChip(
                        label: subject,
                        isSelected: isSelected,
                        onTap: () {
                          dialogSetState(() {
                            isSelected
                                ? selectedSubjects.remove(subject)
                                : selectedSubjects.add(subject);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Assign Classes *",
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: availableClasses.map((className) {
                      final isSelected = selectedClasses.contains(className);
                      return _industrialChip(
                        label: className,
                        isSelected: isSelected,
                        onTap: () {
                          dialogSetState(() {
                            isSelected
                                ? selectedClasses.remove(className)
                                : selectedClasses.add(className);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                  if (selectedClasses.isNotEmpty) ...[
                    Text(
                      "Class Teacher Of",
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: _bgElevated,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: classTeacherOf,
                          isExpanded: true,
                          dropdownColor: _bgElevated,
                          hint: Text(
                            "Select main class (optional)",
                            style: TextStyle(
                                color: _textMuted, fontSize: 14.sp),
                          ),
                          items: selectedClasses.map((className) {
                            return DropdownMenuItem(
                              value: className,
                              child: Text(
                                className,
                                style: TextStyle(
                                    color: _textPrimary, fontSize: 14.sp),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            dialogSetState(() => classTeacherOf = value);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  _industrialTextField(
                    "Weekly Periods",
                    TextEditingController(
                        text: weeklyPeriods > 0 ? weeklyPeriods.toString() : ''),
                    type: TextInputType.number,
                    hint: "e.g., 24",
                    onChanged: (value) {
                      weeklyPeriods = int.tryParse(value) ?? 0;
                    },
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: _industrialButton(
                          "Cancel",
                          onPressed: () => Navigator.pop(context),
                          isSecondary: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _HoverCard(
                          scaleUp: 1.03,
                          glowColor: _primary,
                          enableGlow: true,
                          child: _industrialButton(
                            isSaving ? "Saving..." : "Save Teacher",
                            onPressed: isSaving
                                ? null
                                : () async {
                              if (nameController.text.isEmpty ||
                                  emailController.text.isEmpty ||
                                  selectedSubjects.isEmpty ||
                                  selectedClasses.isEmpty) {
                                _showSnackBar(
                                    "Please fill all required fields",
                                    isError: true);
                                return;
                              }
                              dialogSetState(() => isSaving = true);
                              try {
                                await _teachersRef.add({
                                  "name": nameController.text.trim(),
                                  "email": emailController.text.trim(),
                                  "phone": phoneController.text.trim(),
                                  "subjects": selectedSubjects,
                                  "classes": selectedClasses,
                                  "classTeacherOf": classTeacherOf,
                                  "weeklyPeriods": weeklyPeriods,
                                  "schoolId": widget.schoolId,
                                  "status": "active",
                                  "createdAt": FieldValue.serverTimestamp(),
                                });
                                Navigator.pop(context);
                                _showSnackBar(
                                    "Teacher added successfully");
                              } catch (e) {
                                dialogSetState(() => isSaving = false);
                                _showSnackBar("Error: $e",
                                    isError: true);
                              }
                            },
                            isLoading: isSaving,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✏️ EDIT TEACHER DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditTeacherDialog(DocumentSnapshot teacher) {
    final data = teacher.data() as Map<String, dynamic>? ?? {};
    final nameController = TextEditingController(text: data['name']);
    final emailController = TextEditingController(text: data['email']);
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    List<String> selectedSubjects = List<String>.from(data['subjects'] ?? []);
    List<String> selectedClasses = List<String>.from(data['classes'] ?? []);
    String? classTeacherOf = data['classTeacherOf'] as String?;
    int weeklyPeriods = data['weeklyPeriods'] ?? 0;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          child: Container(
            width: isMobile ? double.infinity : 600.w,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: EdgeInsets.all(24.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Teacher",
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 24.h),
                  _industrialTextField("Full Name", nameController),
                  SizedBox(height: 16.h),
                  _industrialTextField("Email Address", emailController,
                      type: TextInputType.emailAddress),
                  SizedBox(height: 16.h),
                  _industrialTextField("Phone Number", phoneController,
                      type: TextInputType.phone),
                  SizedBox(height: 20.h),
                  Text(
                    "Subjects",
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: allSubjects.map((subject) {
                      final isSelected = selectedSubjects.contains(subject);
                      return _industrialChip(
                        label: subject,
                        isSelected: isSelected,
                        onTap: () {
                          dialogSetState(() {
                            isSelected
                                ? selectedSubjects.remove(subject)
                                : selectedSubjects.add(subject);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Assign Classes",
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: availableClasses.map((className) {
                      final isSelected = selectedClasses.contains(className);
                      return _industrialChip(
                        label: className,
                        isSelected: isSelected,
                        onTap: () {
                          dialogSetState(() {
                            isSelected
                                ? selectedClasses.remove(className)
                                : selectedClasses.add(className);
                            if (!selectedClasses.contains(classTeacherOf)) {
                              classTeacherOf = null;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),
                  if (selectedClasses.isNotEmpty) ...[
                    Text(
                      "Class Teacher Of",
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: _bgElevated,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: _border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: classTeacherOf,
                          isExpanded: true,
                          dropdownColor: _bgElevated,
                          hint: Text(
                            "Select main class (optional)",
                            style: TextStyle(
                                color: _textMuted, fontSize: 14.sp),
                          ),
                          items: selectedClasses.map((className) {
                            return DropdownMenuItem(
                              value: className,
                              child: Text(
                                className,
                                style: TextStyle(
                                    color: _textPrimary, fontSize: 14.sp),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            dialogSetState(() => classTeacherOf = value);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  _industrialTextField(
                    "Weekly Periods",
                    TextEditingController(
                        text: weeklyPeriods > 0 ? weeklyPeriods.toString() : ''),
                    type: TextInputType.number,
                    hint: "e.g., 24",
                    onChanged: (value) {
                      weeklyPeriods = int.tryParse(value) ?? 0;
                    },
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: _industrialButton(
                          "Cancel",
                          onPressed: () => Navigator.pop(context),
                          isSecondary: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _HoverCard(
                          scaleUp: 1.03,
                          glowColor: _primary,
                          enableGlow: true,
                          child: _industrialButton(
                            isSaving ? "Saving..." : "Update",
                            onPressed: isSaving
                                ? null
                                : () async {
                              dialogSetState(() => isSaving = true);
                              try {
                                await teacher.reference.update({
                                  "name": nameController.text.trim(),
                                  "email": emailController.text.trim(),
                                  "phone": phoneController.text.trim(),
                                  "subjects": selectedSubjects,
                                  "classes": selectedClasses,
                                  "classTeacherOf": classTeacherOf,
                                  "weeklyPeriods": weeklyPeriods,
                                  "updatedAt": FieldValue.serverTimestamp(),
                                });
                                Navigator.pop(context);
                                _showSnackBar(
                                    "Teacher updated successfully");
                              } catch (e) {
                                dialogSetState(() => isSaving = false);
                                _showSnackBar("Error: $e",
                                    isError: true);
                              }
                            },
                            isLoading: isSaving,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🗑️ DELETE CONFIRMATION
  // ═══════════════════════════════════════════════════════════════════════════

  void _confirmDeleteTeacher(DocumentSnapshot teacher) {
    final data = teacher.data() as Map<String, dynamic>? ?? {};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: _accentWarning, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              "Delete Teacher?",
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete ${data['name']}? This action cannot be undone.",
          style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        ),
        actions: [
          _industrialButton(
            "Cancel",
            onPressed: () => Navigator.pop(context),
            isSecondary: true,
          ),
          SizedBox(width: 8.w),
          _industrialButton(
            "Delete",
            onPressed: () async {
              try {
                await teacher.reference.delete();
                Navigator.pop(context);
                _showSnackBar("Teacher deleted successfully");
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar("Error: $e", isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔽 FILTER DIALOG
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Filter Teachers",
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 20.h),
            Text(
              "Status",
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: [
                _filterChip("All", true),
                _filterChip("Active", false),
                _filterChip("Inactive", false),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              "Classes",
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: availableClasses
                  .take(8)
                  .map((c) => _filterChip(c, false))
                  .toList(),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: _industrialButton(
                "Apply Filters",
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      backgroundColor: _bgElevated,
      selectedColor: _primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : _textSecondary,
        fontSize: 13.sp,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: isSelected ? _primary : _border),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🧩 SHARED UI COMPONENTS (Embedded)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _industrialTextField(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
        String? hint,
        Function(String)? onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: _textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            onChanged: onChanged,
            style: TextStyle(color: _textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp),
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _industrialSearchField({
    required String hint,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: _textPrimary, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: _textMuted, size: 20.sp),
          border: InputBorder.none,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _industrialChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_primary, _primaryLight])
              : null,
          color: isSelected ? null : _bgElevated,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
              color: isSelected ? Colors.transparent : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.white : _textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _industrialButton(
      String label, {
        IconData? icon,
        VoidCallback? onPressed,
        bool isSecondary = false,
        bool isLoading = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSecondary || onPressed == null
            ? null
            : const LinearGradient(colors: [_primary, _primaryLight]),
        color: isSecondary ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(10.r),
        border: isSecondary ? Border.all(color: _border) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: isLoading
                ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      color: isSecondary ? _textPrimary : Colors.white,
                      size: 18.sp),
                  SizedBox(width: 8.w),
                ],
                Text(
                  label,
                  style: TextStyle(
                      color: isSecondary ? _textPrimary : Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _industrialIconButton(
      IconData icon, {
        Color? color,
        VoidCallback? onPressed,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(10.w),
            child: Icon(icon,
                color: color ?? _textSecondary, size: 20.sp),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24.w : 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 16.w : 24.w),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: _primary, size: compact ? 32.sp : 48.sp),
            ),
            SizedBox(height: compact ? 12.h : 20.h),
            Text(
              title,
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: compact ? 16.sp : 20.sp,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: compact ? 12.sp : 14.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: _bgCard,
        highlightColor: _bgElevated,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r))),
                    SizedBox(height: 8.h),
                    Container(
                        width: 150.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.r))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
