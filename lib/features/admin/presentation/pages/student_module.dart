import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ═══════════════════════════════════════════════════════════════════════════════
//                    ANIMATION HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

/// Hover scale + glow effect for desktop/web mouse hover
class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double scaleAmount;
  final BorderRadius? borderRadius;
  const _HoverCard({
    required this.child,
    required this.glowColor,
    this.scaleAmount = 1.018,
    this.borderRadius,
  });
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: widget.scaleAmount)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glow = Tween<double>(begin: 0.0, end: 1.0)
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
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              boxShadow: _hovered
                  ? [
                BoxShadow(
                  color: widget.glowColor.withOpacity(0.18 * _glow.value),
                  blurRadius: 18,
                  spreadRadius: 2,
                )
              ]
                  : [],
            ),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Staggered fade+slide-up for list items
class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedListItem({required this.child, required this.index});
  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 60).clamp(0, 400);
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: delay), () {
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
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Pulsing glow on header icon
class _PulseIcon extends StatefulWidget {
  final Widget child;
  const _PulseIcon({required this.child});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _pulse, child: widget.child);
  }
}

/// Press scale micro-feedback for buttons
class _PressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  const _PressButton(
      {required this.child, this.onTap, this.borderRadius});
  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Page-level fade in on first build
class _FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeIn({required this.child, this.delay = Duration.zero});
  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
        begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
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
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child));
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
///                    HYBRID STUDENT MODULE (SaaS READY)
/// ═══════════════════════════════════════════════════════════════════════════════
///
/// FEATURES:
/// 1. COMPLETE CRUD: Create, Read, Update, Delete + Soft Delete
/// 2. AUTO ROLL NUMBER: Unique roll generation per class
/// 3. PARENT PORTAL: Father/Mother info with contact
/// 4. FEE INTEGRATION: Real-time fee status from fees collection
/// 5. ATTENDANCE %: Live calculation from attendance collection
/// 6. DOCUMENT READY: Firebase Storage hooks for photo/docs
/// 7. BULK IMPORT: CSV/Excel ready structure
/// 8. ADVANCED FILTER: Multi-class, status, fee status search
/// 9. ID CARD GEN: Auto-generate with QR code placeholder

class StudentModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final Function(String message, {bool isError}) showSnackBar;

  const StudentModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<StudentModule> createState() => _StudentModuleState();
}

class _StudentModuleState extends State<StudentModule>
    with TickerProviderStateMixin {
// 🔥 NEW HELPER METHODS for PDF Table cells
  // 🔥 HELPER METHODS for PDF Table cells
  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _pdfDataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 13),
      ),
    );
  }

  // ─── NAVY + ELECTRIC BLUE — DARK PROFESSIONAL ─────────────
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 STUDENT MODULE — Unified Midnight SaaS Colors
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 STUDENT MODULE — Sidebar Match + Dashboard Different
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── FOUNDATION (Sidebar se match) ──────────────────────────
  static const Color _bgDark      = Color(0xFF0F1117);   // ← Sidebar bg (was 0B1120)
  static const Color _bgCard      = Color(0xFF151821);   // ← Slightly lighter
  static const Color _bgElevated  = Color(0xFF1A1D29);   // ← Sidebar elevated
  static const Color _border      = Color(0xFF2A2E3B);   // ← Sidebar border

  // ─── TEXT (Sidebar se match) ────────────────────────────────
  static const Color _textPrimary   = Color(0xFFEEF1F8);   // ← Sidebar active text
  static const Color _textSecondary = Color(0xFF8B92A8);   // ← Sidebar text
  static const Color _textMuted     = Color(0xFF5A6072);   // ← Sidebar muted

  // ─── FUNCTIONAL (Shared) ────────────────────────────────────
  static const Color _accentSuccess = Color(0xFF10B981);   // Green
  static const Color _accentWarning = Color(0xFFF59E0B);   // Amber
  static const Color _accentDanger  = Color(0xFFEF4444);   // Red
  static const Color _accentInfo    = Color(0xFF06B6D4);   // Cyan

  // ─── STUDENT ACCENT (Sidebar Indigo se match, lekin different shade) ───
  static const Color _studentPrimary = Color(0xFF7C8CF0);   // ← Periwinkle (sidebar indigo)
  static const Color _studentLight   = Color(0xFF9AA5F3);   // ← Light periwinkle
  static const Color _studentDark    = Color(0xFF5E6BE8);   // ← Dark periwinkle

  // ─── STATE MANAGEMENT ─────────────────────────────────────
  late TabController _tabController;

  // Filters
  String _searchQuery = '';
  String? _selectedClass;
  String? _selectedStatus = 'active';
  String? _selectedFeeStatus;

  // 🔥 CLASS DROPDOWN: Dynamically fetched from Firestore
  List<String> _classes = [];
  bool _isLoadingClasses = false;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _isFilterExpanded = false;
  // Blood groups
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  // Gender options
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // 🔥 STATS CACHE: Map<studentId, {data: {attendancePercent, feeStatus}, timestamp: DateTime}>
  final Map<String, Map<String, dynamic>> _statsCache = {};

  // 🔥 MEMOIZED FUTURES: Store futures per-class to prevent recreation on rebuild
  final Map<String, Future<Map<String, Map<String, dynamic>>>> _statsFutures = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 🔥 FETCH classes on init
    _fetchClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         MAIN BUILD
  // ═══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎬 Header fade-in on load
          _FadeIn(
            delay: const Duration(milliseconds: 50),
            child: _buildModuleHeader(),
          ),
          SizedBox(height: 16.h),
          // 🎬 Tab bar slides in slightly after header
          _FadeIn(
            delay: const Duration(milliseconds: 150),
            child: _buildTabNavigation(),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllStudentsView(),
                _buildAddStudentView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         HEADER & NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildModuleHeader() {
    Widget headerCard({required Widget child}) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.isMobile ? 16.w : 22.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_studentPrimary.withOpacity(0.16), _bgCard],
            ),
            border: Border.all(color: _studentPrimary.withOpacity(0.25)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30.h,
                right: -20.w,
                child: Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _studentPrimary.withOpacity(0.10)),
                ),
              ),
              Positioned(
                bottom: -40.h,
                right: 70.w,
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentInfo.withOpacity(0.07)),
                ),
              ),
              child,
            ],
          ),
        ),
      );
    }

    Widget iconBadge(double size, double iconSize) => _PulseIcon(
      child: Container(
        padding: EdgeInsets.all(size),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_studentPrimary, _studentDark],
          ),
          borderRadius: BorderRadius.circular(size + 2.r),
          boxShadow: [
            BoxShadow(
                color: _studentPrimary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Icon(Icons.people, color: Colors.white, size: iconSize),
      ),
    );

    if (widget.isMobile) {
      return headerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                iconBadge(10.w, 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student Management",
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Complete student lifecycle",
                        style: TextStyle(
                          color: _studentLight,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: _industrialButton(
                    "Add Student",
                    icon: Icons.person_add,
                    onPressed: () => _tabController.index = 1,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _industrialButton(
                    "Bulk Import",
                    icon: Icons.upload_file,
                    onPressed: () => _showBulkImportDialog(),
                    isSecondary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return headerCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              iconBadge(13.w, 28.sp),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_textPrimary, _studentLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text(
                      "Student Management",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Complete student lifecycle management",
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _industrialButton(
                "Export Data",
                icon: Icons.download,
                onPressed: () => _exportStudentData(),
                isSecondary: true,
              ),
              SizedBox(width: 12.w),
              _industrialButton(
                "Bulk Import",
                icon: Icons.upload_file,
                onPressed: () => _showBulkImportDialog(),
                isSecondary: true,
              ),
              SizedBox(width: 12.w),
              _industrialButton(
                "Add Student",
                icon: Icons.person_add,
                onPressed: () => _tabController.index = 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_studentPrimary, _studentDark],
          ),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
                color: _studentPrimary.withOpacity(0.30),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.people, size: 18), text: "All Students"),
          Tab(icon: Icon(Icons.person_add, size: 18), text: "Add New"),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         TAB 1: ALL STUDENTS VIEW
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildAllStudentsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎬 Filters fade in
        _FadeIn(
          delay: const Duration(milliseconds: 200),
          child: _buildStudentFilters(),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: _buildStudentsList(),
        ),
      ],
    );
  }

  Widget _buildStudentFilters() {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: widget.isMobile
          ? Column(
        children: [
          // ── HEADER TAP ROW ──────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: _textSecondary, size: 18.sp),
                  SizedBox(width: 10.w),
                  Text(
                    "Filters",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_searchQuery.isNotEmpty ||
                      (_selectedClass != null && _selectedClass!.isNotEmpty) ||
                      _selectedFeeStatus != null)
                    Container(
                      width: 8.w,
                      height: 8.w,
                      margin: EdgeInsets.only(right: 8.w),
                      decoration: BoxDecoration(
                        color: _accentWarning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  AnimatedRotation(
                    turns: _isFilterExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: _textSecondary,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── EXPANDABLE CONTENT ──────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Column(
                children: [
                  Divider(color: _border, height: 1),
                  SizedBox(height: 12.h),
                  _buildSearchField(),
                  SizedBox(height: 10.h),
                  _buildClassFilterField(),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(child: _buildStatusDropdown()),
                      SizedBox(width: 8.w),
                      Expanded(child: _buildFeeStatusDropdown()),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    child: _industrialButton(
                      "Clear All",
                      icon: Icons.clear_all,
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _selectedClass = null;
                          _selectedStatus = 'active';
                          _selectedFeeStatus = null;
                          _currentPage = 1;
                        });
                        // 🔥 CLEAR memoized futures so stats refetch on next build
                        _clearStatsFutures();
                        // 🔥 ALSO clear the 30-sec cache for immediate refresh
                        _statsCache.clear();
                      },
                      isSecondary: true,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      )
          : Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Expanded(flex: 2, child: _buildSearchField()),
            SizedBox(width: 12.w),
            Expanded(child: _buildClassFilterField()),
            SizedBox(width: 12.w),
            Expanded(child: _buildStatusDropdown()),
            SizedBox(width: 12.w),
            Expanded(child: _buildFeeStatusDropdown()),
            SizedBox(width: 12.w),
            _industrialButton(
              "Clear",
              icon: Icons.clear_all,
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedClass = null;
                  _selectedStatus = 'active';
                  _selectedFeeStatus = null;
                  _currentPage = 1;
                });
                // 🔥 CLEAR memoized futures so stats refetch on next build
                _clearStatsFutures();
                // 🔥 ALSO clear the 30-sec cache for immediate refresh
                _statsCache.clear();
              },
              isSecondary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: _textPrimary, fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: "Search by name, roll number...",
          hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp),
          prefixIcon: Icon(Icons.search, color: _textMuted, size: 20.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildClassFilterField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClass,
          isExpanded: true,
          dropdownColor: _bgCard,
          style: TextStyle(color: _textPrimary, fontSize: 14.sp),
          icon: _isLoadingClasses
              ? SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _studentPrimary,
            ),
          )
              : Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 20.sp),
          hint: Text(
            "All Classes",
            style: TextStyle(color: _textMuted, fontSize: 14.sp),
          ),
          items: [
            // "All Classes" option
            DropdownMenuItem<String>(
              value: null,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.select_all, color: _studentPrimary, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "All Classes",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14.sp,
                        fontWeight: _selectedClass == null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Dynamic classes from Firestore
            ..._classes.map((className) {
              final isSelected = _selectedClass == className;
              return DropdownMenuItem<String>(
                value: className,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  decoration: isSelected
                      ? BoxDecoration(
                    color: _studentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  )
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        color: isSelected ? _studentPrimary : _textMuted,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        className,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(Icons.check, color: _studentPrimary, size: 16.sp),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              _selectedClass = value;
              _currentPage = 1;
            });
            _clearStatsFutures();
            _statsCache.clear();
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          dropdownColor: _bgElevated,
          hint: Text(
            "Status",
            style: TextStyle(color: _textMuted, fontSize: 14.sp),
          ),
          items: ['active', 'inactive', 'suspended', 'graduated'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14.sp,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStatus = value),
        ),
      ),
    );
  }

  Widget _buildFeeStatusDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFeeStatus,
          isExpanded: true,
          dropdownColor: _bgElevated,
          hint: Text(
            "Fee Status",
            style: TextStyle(color: _textMuted, fontSize: 14.sp),
          ),
          items: ['paid', 'pending', 'partial', 'overdue'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status.toUpperCase(),
                style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedFeeStatus = value),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('status', isEqualTo: _selectedStatus)
          .orderBy('class')
          .orderBy('rollNumber')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerList();

        var allStudents = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (_selectedClass != null && _selectedClass!.isNotEmpty) {
            final docClass = (data['class'] ?? '').toString().toLowerCase();
            final filterClass = _selectedClass!.toLowerCase();
            if (!docClass.contains(filterClass)) return false;
          }

          if (_searchQuery.isNotEmpty) {
            final name = (data['name'] ?? '').toString().toLowerCase();
            final roll = (data['rollNumber'] ?? '').toString().toLowerCase();
            final query = _searchQuery.toLowerCase();
            if (!name.contains(query) && !roll.contains(query)) return false;
          }

          return true;
        }).toList();

        if (allStudents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: "No students found",
            subtitle: _searchQuery.isEmpty && (_selectedClass == null || _selectedClass!.isEmpty)
                ? "Add your first student to get started"
                : "Try adjusting your filters",
          );
        }

        // 🔥 GROUP BY CLASS
        Map<String, List<DocumentSnapshot>> groupedStudents = {};
        for (var student in allStudents) {
          final data = student.data() as Map<String, dynamic>;
          final className = data['class']?.toString() ?? 'No Class';

          if (!groupedStudents.containsKey(className)) {
            groupedStudents[className] = [];
          }
          groupedStudents[className]!.add(student);
        }

        final sortedClasses = groupedStudents.keys.toList()..sort();

        // 🔥 PULL TO REFRESH: Clear caches and rebuild
        return RefreshIndicator(
          color: _studentPrimary,
          backgroundColor: _bgCard,
          onRefresh: () async {
            // Clear all caches to force fresh fetch
            _statsCache.clear();
            _statsFutures.clear();
            setState(() {});
          },
          child: ListView.builder(
            itemCount: sortedClasses.length,
            itemBuilder: (context, classIndex) {
              final className = sortedClasses[classIndex];
              final studentsInClass = groupedStudents[className]!;
              // 🎬 Each class section animates in staggered
              return _AnimatedListItem(
                index: classIndex,
                child: _buildClassSection(className, studentsInClass),
              );
            },
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         BATCH STATS FETCH (OPTIMIZED)
  // ═══════════════════════════════════════════════════════════════════════════════

  /// 🔥 SINGLE BATCH FETCH: Get all attendance + fee data in one go per class section
  /// Returns a Map<studentId, {attendancePercent, feeStatus}>
  Future<Map<String, Map<String, dynamic>>> _fetchAllStudentsStats(
      List<DocumentSnapshot> students) async {

    final statsMap = <String, Map<String, dynamic>>{};

    // Initialize default stats for all students
    for (final student in students) {
      statsMap[student.id] = {
        'attendancePercent': 0.0,
        'feeStatus': 'unknown',
      };
    }

    if (students.isEmpty) return statsMap;

    try {
      final studentIds = students.map((s) => s.id).toList();
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd');

      // ─── 1. BATCH: Get last 30 days attendance in PARALLEL ───
      final attendanceFutures = <Future<void>>[];
      final attendanceCounts = <String, int>{};
      final totalDaysCounts = <String, int>{};

      // Only check last 30 days (not 60) — enough for accurate %
      for (int i = 0; i < 30; i++) {
        final dateStr = dateFormat.format(now.subtract(Duration(days: i)));

        // Firestore 'whereIn' max 10 items, so we chunk studentIds
        for (int j = 0; j < studentIds.length; j += 10) {
          final chunk = studentIds.skip(j).take(10).toList();

          // 🔥 GUARD: Skip empty chunks to prevent Firestore crash
          if (chunk.isEmpty) continue;

          attendanceFutures.add(
            FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('attendance')
                .doc(dateStr)
                .collection('records')
                .where(FieldPath.documentId, whereIn: chunk)
                .get()
                .then((snapshot) {
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final status = data['status']?.toString().toLowerCase() ?? '';

                totalDaysCounts[doc.id] = (totalDaysCounts[doc.id] ?? 0) + 1;
                if (status == 'present') {
                  attendanceCounts[doc.id] = (attendanceCounts[doc.id] ?? 0) + 1;
                }
              }
            }).catchError((e) {
              // 🔥 LOG ERRORS instead of silently swallowing
              debugPrint('Attendance fetch error for $dateStr: $e');
            }),
          );
        }
      }

      await Future.wait(attendanceFutures);

      // ─── 2. BATCH: Get fee status for all students (chunked queries) ───
      final feeFutures = <Future<void>>[];

      for (int i = 0; i < studentIds.length; i += 10) {
        final chunk = studentIds.skip(i).take(10).toList();

        // 🔥 GUARD: Skip empty chunks
        if (chunk.isEmpty) continue;

        feeFutures.add(
          FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('feeVouchers')
              .where('studentId', whereIn: chunk)
              .get()
              .then((snapshot) {
            debugPrint('FeeVouchers query returned ${snapshot.docs.length} docs for chunk ${i ~/ 10 + 1}');

            // Group by studentId, find latest by createdAt
            final latestFee = <String, Map<String, dynamic>>{};
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final sid = data['studentId'] as String?;
              if (sid == null) {
                debugPrint('FeeVoucher doc ${doc.id} missing studentId field');
                continue;
              }

              // Keep the latest fee voucher per student
              if (!latestFee.containsKey(sid)) {
                latestFee[sid] = data;
              } else {
                // Compare createdAt timestamps to keep latest
                final existing = latestFee[sid]!['createdAt'] as Timestamp?;
                final current = data['createdAt'] as Timestamp?;
                if (current != null && existing != null) {
                  if (current.toDate().isAfter(existing.toDate())) {
                    latestFee[sid] = data;
                  }
                }
              }
            }

            for (final entry in latestFee.entries) {
              if (statsMap.containsKey(entry.key)) {
                final status = entry.value['status']?.toString().toLowerCase() ?? 'unknown';
                debugPrint('Student ${entry.key} fee status: $status');
                statsMap[entry.key]!['feeStatus'] = status;
              }
            }
          }).catchError((e) {
            // 🔥 LOG ERRORS with more detail
            debugPrint('❌ Fee fetch error for chunk ${i ~/ 10 + 1}: $e');
            if (e.toString().contains('failed-precondition')) {
              debugPrint('💡 HINT: You may need to create a Firestore composite index for feeVouchers collection');
              debugPrint('   Collection: schools/{schoolId}/feeVouchers');
              debugPrint('   Fields: studentId (Ascending), createdAt (Descending)');
            }
          }),
        );
      }

      await Future.wait(feeFutures);

      // ─── 3. CALCULATE attendance % ───
      for (final studentId in studentIds) {
        final total = totalDaysCounts[studentId] ?? 0;
        final present = attendanceCounts[studentId] ?? 0;

        if (total > 0) {
          statsMap[studentId]!['attendancePercent'] = (present / total) * 100;
        }
      }

    } catch (e, stackTrace) {
      debugPrint('Stats fetch error: $e');
      debugPrint(stackTrace.toString());
    }

    return statsMap;
  }

  // 🔥 GET STATS FROM CACHE OR FETCH NEW - FIXED
  Future<Map<String, Map<String, dynamic>>> _getStatsWithCache(
      List<DocumentSnapshot> students) async {

    final now = DateTime.now();
    final result = <String, Map<String, dynamic>>{};
    final missingIds = <String>[];

    // Check cache first (REDUCED TTL: 30 seconds for near real-time feel)
    for (final student in students) {
      final cached = _statsCache[student.id];
      if (cached != null &&
          now.difference(cached['timestamp'] as DateTime).inSeconds < 30) {
        result[student.id] = cached['data'] as Map<String, dynamic>;
      } else {
        missingIds.add(student.id);
        // Initialize default
        result[student.id] = {
          'attendancePercent': 0.0,
          'feeStatus': 'unknown',
        };
      }
    }

    // Fetch only missing stats
    if (missingIds.isNotEmpty) {
      final missingStudents = students.where((s) => missingIds.contains(s.id)).toList();
      final freshStats = await _fetchAllStudentsStats(missingStudents);

      // Update cache and result
      for (final entry in freshStats.entries) {
        result[entry.key] = entry.value;
        _statsCache[entry.key] = {
          'data': entry.value,
          'timestamp': DateTime.now(),
        };
      }
    }

    return result;
  }

  // 🔥 MEMOIZED: Get or create future for a class section (prevents rebuild recreation)
  Future<Map<String, Map<String, dynamic>>> _getMemoizedStatsFuture(
      String className, List<DocumentSnapshot> students) {

    // Create a cache key based on class + student count + first student ID
    final cacheKey = '${className}_${students.length}_${students.isNotEmpty ? students.first.id : ""}';

    if (!_statsFutures.containsKey(cacheKey)) {
      _statsFutures[cacheKey] = _getStatsWithCache(students);
    }

    return _statsFutures[cacheKey]!;
  }

  // 🔥 CLEAR memoized futures when filters change (call this in setState for filters)
  void _clearStatsFutures() {
    _statsFutures.clear();
  }

  Widget _buildClassSection(String className, List<DocumentSnapshot> students) {
    return _HoverCard(
      glowColor: _studentPrimary,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Positioned(
                    top: -20.h,
                    right: -10.w,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _studentPrimary.withOpacity(0.10)),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _studentPrimary.withOpacity(0.16),
                          _studentDark.withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_studentPrimary, _studentDark],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                  color: _studentPrimary.withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(Icons.school, color: Colors.white, size: 18.sp),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Class $className",
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                "${students.length} student${students.length > 1 ? 's' : ''}",
                                style: TextStyle(color: _textSecondary, fontSize: 12.sp),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _iconButton(
                              Icons.print,
                              _studentPrimary,
                                  () => _printClassList(className, students),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: _studentPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(color: _studentPrimary.withOpacity(0.3)),
                              ),
                              child: Text(
                                "Total: ${students.length}",
                                style: TextStyle(
                                  color: _studentPrimary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(color: _border, height: 1, indent: 16.w, endIndent: 16.w),

              FutureBuilder<Map<String, Map<String, dynamic>>>(
                future: _getMemoizedStatsFuture(className, students),
                builder: (context, statsSnapshot) {
                  final statsMap = statsSnapshot.data ?? {};
                  final isLoading = !statsSnapshot.hasData && !statsSnapshot.hasError;

                  return widget.isMobile
                      ? Column(
                    children: students.asMap().entries.map((entry) =>
                        _AnimatedListItem(
                          index: entry.key,
                          child: _buildStudentCard(entry.value, statsMap[entry.value.id], isLoading),
                        ),
                    ).toList(),
                  )
                      : _buildClassTable(students, statsMap, isLoading);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassTable(List<DocumentSnapshot> students,
      Map<String, Map<String, dynamic>> statsMap, bool isLoading) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: _bgElevated.withOpacity(0.6),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text("Student", style: _tableHeaderStyle())),
              Expanded(child: Text("Roll No", style: _tableHeaderStyle())),
              Expanded(child: Text("Class", style: _tableHeaderStyle())),
              Expanded(child: Text("Attendance", style: _tableHeaderStyle())),
              Expanded(child: Text("Fee Status", style: _tableHeaderStyle())),
              Expanded(child: Text("Status", style: _tableHeaderStyle())),
              SizedBox(width: 120.w),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          separatorBuilder: (_, __) => Divider(color: _border, height: 1, indent: 16.w, endIndent: 16.w),
          itemBuilder: (context, index) => _AnimatedListItem(
            index: index,
            child: _buildStudentTableRow(students[index], statsMap[students[index].id], isLoading),
          ),
        ),
      ],
    );
  }

  /// 🔥 REAL PRINT CLASS LIST - PDF + Printer (FIXED: MultiPage for large classes)
  void _printClassList(String className, List<DocumentSnapshot> students) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      widget.schoolName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "Student List - Class $className",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Date: $dateStr",
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Total Students: ${students.length}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  ),
                  pw.Text(
                    "Page ${context.pageNumber} of ${context.pagesCount}",
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    "Generated on: $dateStr",
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 25),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("_________________", style: const pw.TextStyle(color: PdfColors.grey400)),
                      pw.SizedBox(height: 6),
                      pw.Text("Class Teacher Signature", style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("_________________", style: const pw.TextStyle(color: PdfColors.grey400)),
                      pw.SizedBox(height: 4),
                      pw.Text("Principal Signature", style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.8,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(35),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2.2),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(2),
                6: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue100,
                  ),
                  children: [
                    _pdfHeaderCell("S.No"),
                    _pdfHeaderCell("Name"),
                    _pdfHeaderCell("Roll No"),
                    _pdfHeaderCell("Father"),
                    _pdfHeaderCell("Gender"),
                    _pdfHeaderCell("Phone"),
                    _pdfHeaderCell("Address"),
                  ],
                ),
                ...students.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value.data() as Map<String, dynamic>;
                  final isEven = index % 2 == 0;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : PdfColors.grey100,
                    ),
                    children: [
                      _pdfDataCell("${index + 1}"),
                      _pdfDataCell(data['name'] ?? 'Unknown'),
                      _pdfDataCell(data['rollNumber'] ?? 'N/A'),
                      _pdfDataCell(data['fatherName'] ?? 'N/A'),
                      _pdfDataCell(data['gender'] ?? 'N/A'),
                      _pdfDataCell(data['fatherPhone'] ?? 'N/A'),
                      _pdfDataCell(data['address'] ?? 'N/A'),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        insetPadding: EdgeInsets.all(16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _studentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.print, color: _studentPrimary, size: 28.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Print Class List",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "Class $className - ${students.length} students",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgElevated,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: _studentPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text("S.No", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text("Name", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text("Roll No", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text("Father", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                            Expanded(flex: 1, child: Text("Gender", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text("Phone", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                            Expanded(flex: 2, child: Text("Address", style: TextStyle(color: _studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                      Divider(color: _border, height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final data = students[index].data() as Map<String, dynamic>;
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.transparent : _bgDark.withOpacity(0.3),
                              ),
                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: Text("${index + 1}", style: TextStyle(color: _textSecondary, fontSize: 10.sp))),
                                  Expanded(flex: 2, child: Text(data['name'] ?? 'Unknown', style: TextStyle(color: _textPrimary, fontSize: 10.sp, fontWeight: FontWeight.w600))),
                                  Expanded(flex: 2, child: Text(data['rollNumber'] ?? 'N/A', style: TextStyle(color: _textPrimary, fontSize: 10.sp, fontFamily: 'monospace'))),
                                  Expanded(flex: 2, child: Text(data['fatherName'] ?? 'N/A', style: TextStyle(color: _textSecondary, fontSize: 10.sp))),
                                  Expanded(flex: 1, child: Text(data['gender'] ?? 'N/A', style: TextStyle(color: _textSecondary, fontSize: 10.sp))),
                                  Expanded(flex: 2, child: Text(data['fatherPhone'] ?? 'N/A', style: TextStyle(color: _textSecondary, fontSize: 10.sp))),
                                  Expanded(flex: 2, child: Text(data['address'] ?? 'N/A', style: TextStyle(color: _textSecondary, fontSize: 10.sp), overflow: TextOverflow.ellipsis, maxLines: 1)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // 🎬 Print options with hover
              _HoverCard(
                glowColor: _accentSuccess,
                borderRadius: BorderRadius.circular(12.r),
                child: _buildPrintOption(
                  icon: Icons.print,
                  title: "Print to Printer",
                  subtitle: "Send directly to connected printer",
                  color: _accentSuccess,
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.layoutPdf(
                      onLayout: (format) async => pdfBytes,
                      name: "Class_${className}_$dateStr.pdf",
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),

              _HoverCard(
                glowColor: _accentInfo,
                borderRadius: BorderRadius.circular(12.r),
                child: _buildPrintOption(
                  icon: Icons.download,
                  title: "Save as PDF",
                  subtitle: "Download PDF file to device",
                  color: _accentInfo,
                  onTap: () async {
                    Navigator.pop(context);
                    if (kIsWeb) {
                      final blob = html.Blob([pdfBytes], 'application/pdf');
                      final url = html.Url.createObjectUrlFromBlob(blob);
                      final anchor = html.AnchorElement(href: url)
                        ..setAttribute('download', "Class_${className}_$dateStr.pdf")
                        ..click();
                      html.Url.revokeObjectUrl(url);
                      widget.showSnackBar("📄 PDF downloaded!");
                    } else {
                      final directory = await getApplicationDocumentsDirectory();
                      final filePath = '${directory.path}/Class_${className}_$dateStr.pdf';
                      final file = File(filePath);
                      await file.writeAsBytes(pdfBytes);
                      widget.showSnackBar("📄 PDF saved: $filePath");
                    }
                  },
                ),
              ),
              SizedBox(height: 12.h),

              _HoverCard(
                glowColor: _accentWarning,
                borderRadius: BorderRadius.circular(12.r),
                child: _buildPrintOption(
                  icon: Icons.share,
                  title: "Share PDF",
                  subtitle: "Share via WhatsApp, Email, etc.",
                  color: _accentWarning,
                  onTap: () async {
                    Navigator.pop(context);
                    if (!kIsWeb) {
                      final directory = await getApplicationDocumentsDirectory();
                      final filePath = '${directory.path}/Class_${className}_$dateStr.pdf';
                      final file = File(filePath);
                      await file.writeAsBytes(pdfBytes);
                      await Share.shareXFiles(
                        [XFile(filePath)],
                        text: 'Student List - Class $className \n ${widget.schoolName}',
                      );
                    } else {
                      widget.showSnackBar("Sharing not available on web", isError: true);
                    }
                  },
                ),
              ),
              SizedBox(height: 8.h),

              SizedBox(
                width: double.infinity,
                child: _industrialButton(
                  "Cancel",
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _textMuted, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 MODIFIED: Accepts stats directly instead of StreamBuilder
  Widget _buildStudentCard(DocumentSnapshot student,
      Map<String, dynamic>? stats, bool isLoading) {
    final data = student.data() as Map<String, dynamic>;
    final studentId = student.id;
    final className = data['class']?.toString() ?? '';

    final attendancePercent = stats?['attendancePercent'] ?? 0.0;
    final feeStatus = stats?['feeStatus'] ?? 'unknown';

    // 🎬 Hover glow on each student card
    return _HoverCard(
      glowColor: _studentPrimary,
      scaleAmount: 1.012,
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
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_studentPrimary, _studentLight],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: data['photoUrl'] != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        data['photoUrl'],
                        width: 56.w,
                        height: 56.w,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Text(
                      (data['name'] ?? '')[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "Roll: ${data['rollNumber'] ?? 'N/A'} • ",
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 13.sp,
                            ),
                          ),
                          _buildInlineClassDropdown(data['class'] ?? 'N/A', student),
                        ],
                      ),
                    ],
                  ),
                ),
                isLoading
                    ? SizedBox(width: 20.w, height: 20.w,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _studentPrimary))
                    : _buildFeeStatusBadge(feeStatus),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                isLoading
                    ? _buildQuickStatShimmer()
                    : _buildQuickStat("Attendance", "${attendancePercent.toStringAsFixed(0)}%",
                    attendancePercent >= 75 ? _accentSuccess : _accentWarning),
                _buildQuickStat("Age", "${_calculateAge(data['dob'])} yrs", _textSecondary),
                _buildQuickStat("Gender", data['gender'] ?? 'N/A', _textSecondary),
              ],
            ),
            SizedBox(height: 12.h),

            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: _textMuted, size: 14.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Father: ${data['fatherPhone'] ?? 'N/A'}",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: _industrialButton(
                    "View Profile",
                    icon: Icons.visibility,
                    onPressed: () => _showStudentProfile(student, stats),
                    isSecondary: true,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: _industrialButton(
                    "Edit",
                    icon: Icons.edit,
                    onPressed: () => _showEditStudentDialog(student),
                    isSecondary: true,
                  ),
                ),
                SizedBox(width: 8.w),
                _iconButton(Icons.delete_outline, _accentDanger,
                        () => _confirmDeleteStudent(student)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatShimmer() {
    return Shimmer.fromColors(
      baseColor: _bgElevated,
      highlightColor: _bgCard,
      child: Column(
        children: [
          Container(width: 40.w, height: 16.h, color: Colors.white),
          SizedBox(height: 4.h),
          Container(width: 50.w, height: 10.h, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(List<DocumentSnapshot> students) {
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
                Expanded(flex: 2, child: Text("Student", style: _tableHeaderStyle())),
                Expanded(child: Text("Roll No", style: _tableHeaderStyle())),
                Expanded(child: Text("Class", style: _tableHeaderStyle())),
                Expanded(child: Text("Attendance", style: _tableHeaderStyle())),
                Expanded(child: Text("Fee Status", style: _tableHeaderStyle())),
                Expanded(child: Text("Status", style: _tableHeaderStyle())),
                SizedBox(width: 120.w),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => Divider(color: _border, height: 1),
              itemBuilder: (context, index) => _buildStudentTableRow(students[index], null, false),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 MODIFIED: Accepts stats directly instead of StreamBuilder
  Widget _buildStudentTableRow(DocumentSnapshot student,
      Map<String, dynamic>? stats, bool isLoading) {
    final data = student.data() as Map<String, dynamic>;
    final studentId = student.id;
    final className = data['class']?.toString() ?? '';

    final attendancePercent = stats?['attendancePercent'] ?? 0.0;
    final feeStatus = stats?['feeStatus'] ?? 'unknown';

    return _HoverCard(
      glowColor: _studentPrimary,
      scaleAmount: 1.005,
      borderRadius: BorderRadius.circular(0),
      child: Container(
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_studentPrimary, _studentLight],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                            color: _studentPrimary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (data['name'] ?? '')[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
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
                          style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          data['fatherName'] ?? '',
                          style: TextStyle(color: _textMuted, fontSize: 11.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                data['rollNumber'] ?? 'N/A',
                style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontFamily: 'monospace'),
              ),
            ),
            Expanded(
              child: _buildClassDropdownCell(data['class'] ?? 'N/A', student),
            ),
            Expanded(
              child: isLoading
                  ? SizedBox(width: 20.w, height: 20.w,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _studentPrimary))
                  : _buildProgressBar(attendancePercent),
            ),
            Expanded(
              child: isLoading
                  ? SizedBox(width: 20.w, height: 20.w,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _studentPrimary))
                  : _buildFeeStatusBadge(feeStatus),
            ),
            Expanded(
              child: _buildStatusChip(data['status'] ?? 'active'),
            ),
            SizedBox(
              width: 120.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconButton(Icons.visibility, _textSecondary, () => _showStudentProfile(student, stats)),
                  SizedBox(width: 4.w),
                  _iconButton(Icons.edit, _studentPrimary, () => _showEditStudentDialog(student)),
                  SizedBox(width: 4.w),
                  _iconButton(Icons.delete_outline, _accentDanger, () => _confirmDeleteStudent(student)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
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
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          ),
          SizedBox(width: 16.w),
          Text(
            "Page $_currentPage of $totalPages",
            style: TextStyle(color: _textSecondary, fontSize: 14.sp),
          ),
          SizedBox(width: 16.w),
          _industrialIconButton(
            Icons.chevron_right,
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         TAB 2: ADD STUDENT VIEW
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildAddStudentView() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: StudentForm(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: widget.isMobile,
          showSnackBar: widget.showSnackBar,
          bloodGroups: _bloodGroups,
          genders: _genders,
          studentPrimary: _studentPrimary,
          studentLight: _studentLight,
          bgDark: _bgDark,
          bgCard: _bgCard,
          bgElevated: _bgElevated,
          textPrimary: _textPrimary,
          textSecondary: _textSecondary,
          textMuted: _textMuted,
          border: _border,
          accentSuccess: _accentSuccess,
          accentWarning: _accentWarning,
          accentDanger: _accentDanger,
          onSaved: () {
            _tabController.index = 0;
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         DIALOGS & ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  // 🔥 MODIFIED: Accepts pre-fetched stats to avoid re-fetching
  void _showStudentProfile(DocumentSnapshot student, Map<String, dynamic>? preFetchedStats) {
    final data = student.data() as Map<String, dynamic>;
    final studentId = student.id;

    showDialog(
      context: context,
      builder: (context) {
        // Use pre-fetched stats if available, otherwise fetch
        final attendancePercent = preFetchedStats?['attendancePercent'] ?? 0.0;
        final feeStatus = preFetchedStats?['feeStatus'] ?? 'unknown';
        final feeStatusText = feeStatus == 'paid' ? 'Paid' : feeStatus == 'partial' ? 'Partial' : feeStatus == 'overdue' ? 'Overdue' : 'Pending';
        final feeColor = feeStatus == 'paid' ? _accentSuccess : feeStatus == 'partial' ? _accentWarning : _accentDanger;
        final attendanceColor = attendancePercent >= 75 ? _accentSuccess : attendancePercent >= 60 ? _accentWarning : _accentDanger;

        return Dialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Container(
            width: widget.isMobile ? double.infinity : 600.w,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: EdgeInsets.all(24.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        // 🎬 Pulse on profile avatar
                        _PulseIcon(
                          child: Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_studentPrimary, _studentLight],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Center(
                              child: Text(
                                (data['name'] ?? '')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          data['name'] ?? 'Unknown',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Roll: ${data['rollNumber']} • ${data['class']}",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Row(
                    children: [
                      // 🎬 Stat cards hover
                      Expanded(child: _HoverCard(
                        glowColor: _accentSuccess,
                        borderRadius: BorderRadius.circular(12.r),
                        child: _buildProfileStatCard("Attendance", "${attendancePercent.toStringAsFixed(0)}%", Icons.calendar_today, attendanceColor),
                      )),
                      SizedBox(width: 12.w),
                      Expanded(child: _HoverCard(
                        glowColor: _accentSuccess,
                        borderRadius: BorderRadius.circular(12.r),
                        child: _buildProfileStatCard("Fees", feeStatusText, Icons.payments, feeColor),
                      )),
                      SizedBox(width: 12.w),
                      Expanded(child: _HoverCard(
                        glowColor: _accentWarning,
                        borderRadius: BorderRadius.circular(12.r),
                        child: _buildProfileStatCard("Exams", "A Grade", Icons.school, _accentWarning),
                      )),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  _buildInfoSection("Personal Info", [
                    _buildInfoRow("Full Name", data['name']),
                    _buildInfoRow("Gender", data['gender']),
                    _buildInfoRow("Date of Birth", data['dob']),
                    _buildInfoRow("Blood Group", data['bloodGroup'] ?? 'N/A'),
                    _buildInfoRow("Age", "${_calculateAge(data['dob'])} years"),
                  ]),
                  SizedBox(height: 16.h),

                  _buildInfoSection("Parent Info", [
                    _buildInfoRow("Father", "${data['fatherName']} (${data['fatherPhone']})"),
                    _buildInfoRow("Mother", "${data['motherName'] ?? 'N/A'} ${data['motherPhone'] != null ? '(${data['motherPhone']})' : ''}"),
                  ]),
                  SizedBox(height: 16.h),

                  _buildInfoSection("Contact Info", [
                    _buildInfoRow("Address", data['address']),
                    _buildInfoRow("Emergency", data['emergencyContact']),
                  ]),

                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: _industrialButton(
                          "Generate ID Card",
                          icon: Icons.badge,
                          onPressed: () => _generateIDCard(student),
                          isSecondary: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _industrialButton(
                          "Close",
                          onPressed: () => Navigator.pop(context),
                          isSecondary: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditStudentDialog(DocumentSnapshot student) {
    final data = student.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 700.w,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: _studentPrimary, size: 28.sp),
                  SizedBox(width: 12.w),
                  Text(
                    "Edit Student",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: SingleChildScrollView(
                  child: StudentForm(
                    schoolId: widget.schoolId,
                    schoolName: widget.schoolName,
                    isMobile: widget.isMobile,
                    showSnackBar: widget.showSnackBar,
                    bloodGroups: _bloodGroups,
                    genders: _genders,
                    studentPrimary: _studentPrimary,
                    studentLight: _studentLight,
                    bgDark: _bgDark,
                    bgCard: _bgCard,
                    bgElevated: _bgElevated,
                    textPrimary: _textPrimary,
                    textSecondary: _textSecondary,
                    textMuted: _textMuted,
                    border: _border,
                    accentSuccess: _accentSuccess,
                    accentWarning: _accentWarning,
                    accentDanger: _accentDanger,
                    existingStudent: student,
                    existingData: data,
                    onSaved: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteStudent(DocumentSnapshot student) {
    final data = student.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: _accentWarning, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              "Delete Student?",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to remove ${data['name']}? This will soft-delete (mark as inactive).",
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14.sp,
          ),
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
                await student.reference.update({
                  'status': 'inactive',
                  'deletedAt': FieldValue.serverTimestamp(),
                  'deletedBy': FirebaseAuth.instance.currentUser?.uid,
                });
                Navigator.pop(context);
                widget.showSnackBar("Student marked as inactive");
              } catch (e) {
                widget.showSnackBar("Error: $e", isError: true);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBulkImportDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _studentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.upload_file, color: _studentPrimary, size: 28.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      "Bulk Import Students",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                "Upload CSV or Excel file with student data",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.download, color: _accentInfo, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        "Download Template",
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _industrialButton(
                      "Download",
                      onPressed: () {},
                      isSecondary: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, color: _textMuted, size: 48.sp),
                    SizedBox(height: 12.h),
                    Text(
                      "Drag & drop or click to upload",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Supports: CSV, XLSX (Max 5MB)",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              _industrialButton(
                "Close",
                onPressed: () => Navigator.pop(context),
                isSecondary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════════

  Future<String> _generateRollNumber(String className) async {
    final now = DateTime.now();
    final session = now.month >= 4 ? '${now.year}-${now.year + 1}' : '${now.year - 1}-${now.year}';
    String schoolPrefix = _getSchoolPrefix();

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .where('status', isEqualTo: 'active')
        .where('session', isEqualTo: session)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;
    if (snapshot.docs.isNotEmpty) {
      final lastRoll = snapshot.docs.first.data()['rollNumber'] as String?;
      if (lastRoll != null) {
        final parts = lastRoll.split('-');
        if (parts.length >= 2) {
          lastNumber = int.tryParse(parts[1]) ?? 0;
        }
      }
    }

    final newNumber = lastNumber + 1;
    return "$schoolPrefix-${newNumber.toString().padLeft(3, '0')}-$session";
  }

  String _getSchoolPrefix() {
    if (widget.schoolName.isEmpty) return "XXX";
    final words = widget.schoolName.trim().split(RegExp(r'\s+'));
    String prefix = "";
    for (int i = 0; i < words.length && i < 3; i++) {
      if (words[i].isNotEmpty) {
        prefix += words[i][0].toUpperCase();
      }
    }
    while (prefix.length < 3) {
      prefix += "X";
    }
    return prefix;
  }

  String _getCurrentSession() {
    final now = DateTime.now();
    return now.month >= 4 ? '${now.year}-${now.year + 1}' : '${now.year - 1}-${now.year}';
  }

  // 🔥 FETCH CLASSES: Get distinct classes from Firestore for dropdown
  Future<void> _fetchClasses() async {
    if (_isLoadingClasses) return;
    setState(() => _isLoadingClasses = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('status', isEqualTo: 'active')
          .get();

      final classSet = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final className = data['class']?.toString().trim();
        if (className != null && className.isNotEmpty) {
          classSet.add(className);
        }
      }

      final sortedClasses = classSet.toList()..sort();

      if (mounted) {
        setState(() {
          _classes = sortedClasses;
          _isLoadingClasses = false;
        });
      }
      debugPrint('Fetched ${_classes.length} classes: $_classes');
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      if (mounted) {
        setState(() => _isLoadingClasses = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         REAL-TIME STATS HELPERS (DEPRECATED - USE BATCH FETCH)
  // ═══════════════════════════════════════════════════════════════════════════════

  /// 🔥 OLD: Per-student stream (kept for backward compatibility if needed)
  /// NOTE: This is now replaced by _fetchAllStudentsStats for better performance
  Stream<Map<String, dynamic>> _studentStatsStream(String studentId, String className) {
    // Return cached data immediately if available
    final cached = _statsCache[studentId];
    if (cached != null) {
      return Stream.value(cached['data'] as Map<String, dynamic>);
    }

    // Fallback to old behavior (should rarely be called now)
    if (className.isEmpty || studentId.isEmpty) {
      return Stream.value({'attendancePercent': 0.0, 'feeStatus': 'unknown'});
    }

    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      double attendancePercent = 0.0;
      String feeStatus = 'unknown';

      try {
        int totalDays = 0;
        int presentDays = 0;

        final now = DateTime.now();
        final dateFormat = DateFormat('yyyy-MM-dd');

        for (int i = 0; i < 30; i++) {
          final date = now.subtract(Duration(days: i));
          final dateStr = dateFormat.format(date);

          try {
            final recordDoc = await FirebaseFirestore.instance
                .collection('schools')
                .doc(widget.schoolId)
                .collection('attendance')
                .doc(dateStr)
                .collection('records')
                .doc(studentId)
                .get();

            if (recordDoc.exists) {
              final data = recordDoc.data() as Map<String, dynamic>;
              final recordClass = data['class']?.toString() ?? '';
              if (recordClass == className) {
                totalDays++;
                final status = data['status']?.toString().toLowerCase() ?? '';
                if (status == 'present') {
                  presentDays++;
                }
              }
            }
          } catch (e) {
            continue;
          }
        }

        if (totalDays > 0) {
          attendancePercent = (presentDays / totalDays) * 100;
        }

        final feeSnapshot = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('feeVouchers')
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (feeSnapshot.docs.isNotEmpty) {
          final feeData = feeSnapshot.docs.first.data();
          feeStatus = feeData['status']?.toString().toLowerCase() ?? 'unknown';
        }
      } catch (e) {
        debugPrint('Error in stats stream: $e');
      }

      final result = {
        'attendancePercent': attendancePercent,
        'feeStatus': feeStatus,
      };

      // Cache the result
      _statsCache[studentId] = {
        'data': result,
        'timestamp': DateTime.now(),
      };

      return result;
    });
  }

  int _calculateAge(String? dobString) {
    if (dobString == null) return 0;
    try {
      final dob = DateTime.parse(dobString);
      final now = DateTime.now();
      return now.year - dob.year - (now.month < dob.month || (now.month == dob.month && now.day < dob.day) ? 1 : 0);
    } catch (e) {
      return 0;
    }
  }

  void _generateIDCard(DocumentSnapshot student) {
    widget.showSnackBar("🎫 ID Card generation coming soon!");
  }

  void _exportStudentData() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _studentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.download, color: _studentPrimary, size: 28.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      "Export Student Data",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                "Choose export format:",
                style: TextStyle(color: _textSecondary, fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              // 🎬 Export options with hover glow
              _HoverCard(
                glowColor: _accentSuccess,
                borderRadius: BorderRadius.circular(12.r),
                child: _buildExportOption(
                  icon: Icons.table_chart,
                  title: "Export as CSV",
                  subtitle: "Comma-separated values for Excel / Google Sheets",
                  color: _accentSuccess,
                  onTap: () {
                    Navigator.pop(context);
                    _performExport('csv');
                  },
                ),
              ),
              SizedBox(height: 12.h),
              _HoverCard(
                glowColor: _accentInfo,
                borderRadius: BorderRadius.circular(12.r),
                child: _buildExportOption(
                  icon: Icons.description,
                  title: "Export as JSON",
                  subtitle: "Raw data format for developers / backups",
                  color: _accentInfo,
                  onTap: () {
                    Navigator.pop(context);
                    _performExport('json');
                  },
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: _industrialButton(
                  "Cancel",
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _textMuted, size: 20.sp),
            ],
          ),
        ),
      ),
    );
  }

  void _performExport(String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.w,
                child: CircularProgressIndicator(
                  color: _studentPrimary,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "Exporting...",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Fetching student records from database",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .orderBy('rollNumber')
          .get();

      final students = snapshot.docs;

      if (students.isEmpty) {
        Navigator.pop(context);
        widget.showSnackBar("No students to export", isError: true);
        return;
      }

      String content;
      String fileName;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (format == 'csv') {
        content = _generateCsv(students);
        fileName = 'students_$timestamp.csv';
      } else {
        content = _generateJson(students);
        fileName = 'students_$timestamp.json';
      }

      if (kIsWeb) {
        final bytes = content.codeUnits;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        Navigator.pop(context);
        _showExportResultDialog(content, fileName, "Browser Download", students.length);

      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(content);

        Navigator.pop(context);
        _showExportResultWithShare(content, fileName, filePath, students.length);
      }

    } catch (e) {
      Navigator.pop(context);
      widget.showSnackBar("Export failed: $e", isError: true);
    }
  }

  String _generateCsv(List<QueryDocumentSnapshot> students) {
    final buffer = StringBuffer();
    final headers = [
      'Roll Number', 'Name', 'Class', 'Gender', 'Date of Birth',
      'Blood Group', 'Father Name', 'Father Phone', 'Father CNIC',
      'Address', 'Emergency Contact', 'Status', 'Session', 'Created At',
    ];
    buffer.writeln(headers.map(_escapeCsv).join(','));

    for (final doc in students) {
      final data = doc.data() as Map<String, dynamic>;
      final row = [
        data['rollNumber']?.toString() ?? '',
        data['name']?.toString() ?? '',
        data['class']?.toString() ?? '',
        data['gender']?.toString() ?? '',
        data['dob']?.toString() ?? '',
        data['bloodGroup']?.toString() ?? '',
        data['fatherName']?.toString() ?? '',
        data['fatherPhone']?.toString() ?? '',
        data['fatherCNIC']?.toString() ?? '',
        data['address']?.toString() ?? '',
        data['emergencyContact']?.toString() ?? '',
        data['status']?.toString() ?? '',
        data['session']?.toString() ?? '',
        data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
            : '',
      ];
      buffer.writeln(row.map(_escapeCsv).join(','));
    }
    return buffer.toString();
  }

  String _escapeCsv(dynamic value) {
    String str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
      str = str.replaceAll('"', '""');
      return '"$str"';
    }
    return str;
  }

  String _generateJson(List<QueryDocumentSnapshot> students) {
    final List<Map<String, dynamic>> data = [];
    for (final doc in students) {
      final studentData = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      studentData['id'] = doc.id;
      if (studentData['createdAt'] is Timestamp) {
        studentData['createdAt'] = (studentData['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (studentData['updatedAt'] is Timestamp) {
        studentData['updatedAt'] = (studentData['updatedAt'] as Timestamp).toDate().toIso8601String();
      }
      data.add(studentData);
    }

    final buffer = StringBuffer();
    buffer.writeln('[');
    for (int i = 0; i < data.length; i++) {
      buffer.writeln('  {');
      final entries = data[i].entries.toList();
      for (int j = 0; j < entries.length; j++) {
        final key = entries[j].key;
        final value = entries[j].value;
        final jsonValue = _jsonEncodeValue(value);
        buffer.write('    "$key": $jsonValue');
        if (j < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('  }');
      if (i < data.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.writeln(']');
    return buffer.toString();
  }

  String _jsonEncodeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"${_escapeJson(value)}"';
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return '[${value.map(_jsonEncodeValue).join(', ')}]';
    }
    if (value is Map) {
      final entries = value.entries.map((e) => '"${_escapeJson(e.key.toString())}": ${_jsonEncodeValue(e.value)}').join(', ');
      return '{$entries}';
    }
    return '"${_escapeJson(value.toString())}"';
  }

  String _escapeJson(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _getPreviewContent(String content) {
    final lines = content.split('\n');
    if (lines.length <= 50) return content;
    return lines.take(50).join('\n') + '\n\n... (${lines.length - 50} more lines)';
  }

  void _showExportResultDialog(String content, String fileName, String filePath, int count) {
    final isCsv = fileName.endsWith('.csv');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 700.w,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: _accentSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.check_circle, color: _accentSuccess, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Export Complete",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "$count students exported",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCsv ? Icons.table_chart : Icons.description,
                          color: isCsv ? _accentSuccess : _accentInfo,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _accentSuccess.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "${(content.length / 1024).toStringAsFixed(1)} KB",
                            style: TextStyle(
                              color: _accentSuccess,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Saved to: $filePath",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.sp,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Preview (first 50 lines):",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgElevated,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: _border),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: SelectableText(
                      _getPreviewContent(content),
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 12.sp,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _industrialButton(
                      "Close",
                      onPressed: () => Navigator.pop(context),
                      isSecondary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportResultWithShare(
      String content,
      String fileName,
      String filePath,
      int count,
      ) {
    final isCsv = fileName.endsWith('.csv');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 700.w,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: _accentSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.check_circle, color: _accentSuccess, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Export Complete",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "$count students exported",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCsv ? Icons.table_chart : Icons.description,
                          color: isCsv ? _accentSuccess : _accentInfo,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            fileName,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _accentSuccess.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "${(content.length / 1024).toStringAsFixed(1)} KB",
                            style: TextStyle(
                              color: _accentSuccess,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Saved to: $filePath",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.sp,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                "Preview (first 50 lines):",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgElevated,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: _border),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: SelectableText(
                      _getPreviewContent(content),
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16.sp,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _industrialButton(
                      "Share File",
                      icon: Icons.share,
                      onPressed: () {
                        Share.shareXFiles(
                          [XFile(filePath)],
                          text: 'Student Export: $fileName',
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _industrialButton(
                      "Close",
                      onPressed: () => Navigator.pop(context),
                      isSecondary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// ═══════════════════════════════════════════════════════════════════════════════
//                         UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _studentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: _studentPrimary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: _textMuted,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percentage) {
    final color = percentage >= 75 ? _accentSuccess : percentage >= 60 ? _accentWarning : _accentDanger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${percentage.toStringAsFixed(0)}%",
          style: TextStyle(
            color: color,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(2.r),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: _bgElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4.h,
          ),
        ),
      ],
    );
  }

  // 🔥 EDITABLE CLASS DROPDOWN: For table rows
  Widget _buildClassDropdownCell(String currentClass, DocumentSnapshot student) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentClass,
          isExpanded: true,
          dropdownColor: _bgCard,
          style: TextStyle(color: _textSecondary, fontSize: 13.sp),
          icon: Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 16.sp),
          items: [
            DropdownMenuItem<String>(
              value: currentClass,
              child: Text(
                currentClass,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const DropdownMenuItem<String>(
              enabled: false,
              child: Divider(height: 1),
            ),
            ..._classes.where((c) => c != currentClass).map((className) {
              return DropdownMenuItem<String>(
                value: className,
                child: Text(
                  className,
                  style: TextStyle(color: _textPrimary, fontSize: 13.sp),
                ),
              );
            }).toList(),
          ],
          onChanged: (newClass) => _updateStudentClass(student, newClass),
        ),
      ),
    );
  }

  // 🔥 INLINE CLASS DROPDOWN: For mobile cards
  Widget _buildInlineClassDropdown(String currentClass, DocumentSnapshot student) {
    return GestureDetector(
      onTap: () => _showClassChangeDialog(student, currentClass),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: _studentPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: _studentPrimary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentClass,
              style: TextStyle(
                color: _studentPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.edit, color: _studentPrimary, size: 12.sp),
          ],
        ),
      ),
    );
  }

  // 🔥 UPDATE STUDENT CLASS: Firestore update with confirmation
  Future<void> _updateStudentClass(DocumentSnapshot student, String? newClass) async {
    if (newClass == null || newClass == (student.data() as Map<String, dynamic>)['class']) return;

    final data = student.data() as Map<String, dynamic>;
    final oldClass = data['class'] ?? 'N/A';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: _studentPrimary, size: 28.sp),
            SizedBox(width: 12.w),
            Text(
              "Change Class?",
              style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          "Move ${data['name']} from Class $oldClass to Class $newClass?",
          style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        ),
        actions: [
          _industrialButton(
            "Cancel",
            onPressed: () => Navigator.pop(context, false),
            isSecondary: true,
          ),
          SizedBox(width: 8.w),
          _industrialButton(
            "Confirm",
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await student.reference.update({
        'class': newClass,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      widget.showSnackBar("✅ ${data['name']} moved to Class $newClass");
      _fetchClasses();
    } catch (e) {
      widget.showSnackBar("❌ Error: $e", isError: true);
    }
  }

  // 🔥 SHOW CLASS CHANGE DIALOG: For mobile cards
  void _showClassChangeDialog(DocumentSnapshot student, String currentClass) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: 300.w,
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: _studentPrimary, size: 24.sp),
                  SizedBox(width: 12.w),
                  Text(
                    "Change Class",
                    style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                "Select new class for ${(student.data() as Map<String, dynamic>)['name']}:",
                style: TextStyle(color: _textSecondary, fontSize: 14.sp),
              ),
              SizedBox(height: 12.h),
              ..._classes.map((className) {
                final isCurrent = className == currentClass;
                return _HoverCard(
                  glowColor: _studentPrimary,
                  borderRadius: BorderRadius.circular(8.r),
                  child: InkWell(
                    onTap: isCurrent ? null : () {
                      Navigator.pop(context);
                      _updateStudentClass(student, className);
                    },
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      margin: EdgeInsets.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        color: isCurrent ? _studentPrimary.withOpacity(0.15) : _bgElevated,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isCurrent ? _studentPrimary : _border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: isCurrent ? _studentPrimary : _textMuted,
                            size: 18.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            className,
                            style: TextStyle(
                              color: isCurrent ? _studentPrimary : _textPrimary,
                              fontSize: 14.sp,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          if (isCurrent) ...[
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _studentPrimary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                "CURRENT",
                                style: TextStyle(
                                  color: _studentPrimary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: _industrialButton(
                  "Cancel",
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFeeStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'paid':
        color = _accentSuccess;
        break;
      case 'partial':
        color = _accentWarning;
        break;
      case 'overdue':
        color = _accentDanger;
        break;
      default:
        color = _textMuted;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isActive = status == 'active';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isActive ? _accentSuccess.withOpacity(0.1) : _accentDanger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: isActive ? _accentSuccess : _accentDanger,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _studentPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.h),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: _textMuted,
                fontSize: 13.sp,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: _textMuted,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

// ═══════════════════════════════════════════════════════════════════════════════
//                         SHARED COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

  /// 🎬 industrialButton now uses _PressButton for tap feedback
  Widget _industrialButton(
      String label, {
        IconData? icon,
        VoidCallback? onPressed,
        bool isSecondary = false,
        bool isLoading = false,
      }) {
    final inner = Container(
      decoration: BoxDecoration(
        gradient: isSecondary || onPressed == null
            ? null
            : LinearGradient(colors: [_studentPrimary, _studentLight]),
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
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isSecondary ? _textPrimary : Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSecondary ? _textPrimary : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 🎬 Wrap primary buttons with press scale feedback
    if (!isSecondary && onPressed != null && !isLoading) {
      return _PressButton(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: inner,
      );
    }
    return inner;
  }

  Widget _industrialTextField(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
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
            maxLines: maxLines,
            style: TextStyle(color: _textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎬 Icon buttons get hover glow + press scale
  Widget _iconButton(IconData icon, Color color, VoidCallback onPressed) {
    return _HoverCard(
      glowColor: color,
      scaleAmount: 1.15,
      borderRadius: BorderRadius.circular(8.r),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(icon, color: color, size: 20.sp),
          ),
        ),
      ),
    );
  }

  Widget _industrialIconButton(IconData icon, {VoidCallback? onPressed}) {
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
            child: Icon(icon, color: onPressed != null ? _textSecondary : _textMuted, size: 20.sp),
          ),
        ),
      ),
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      color: _textSecondary,
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎬 Pulse on empty state icon
            _PulseIcon(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: _studentPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _studentPrimary,
                  size: 48.sp,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.sp,
              ),
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
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
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
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 150.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════════
//                         STUDENT FORM WIDGET (REFACTORED)
// ═══════════════════════════════════════════════════════════════════════════════

class StudentForm extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final Function(String message, {bool isError}) showSnackBar;
  final List<String> bloodGroups;
  final List<String> genders;
  final Color studentPrimary;
  final Color studentLight;
  final Color bgDark;
  final Color bgCard;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color accentSuccess;
  final Color accentWarning;
  final Color accentDanger;
  final DocumentSnapshot? existingStudent;
  final Map<String, dynamic>? existingData;
  final VoidCallback? onSaved;

  const StudentForm({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.showSnackBar,
    required this.bloodGroups,
    required this.genders,
    required this.studentPrimary,
    required this.studentLight,
    required this.bgDark,
    required this.bgCard,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.accentSuccess,
    required this.accentWarning,
    required this.accentDanger,
    this.existingStudent,
    this.existingData,
    this.onSaved,
  });

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _rollController;
  late final TextEditingController _dobController;
  late final TextEditingController _fatherNameController;
  late final TextEditingController _fatherPhoneController;
  late final TextEditingController _fatherCNICController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _classController;

  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isSaving = false;

  bool get _isEdit => widget.existingStudent != null;

  @override
  void initState() {
    super.initState();
    final data = widget.existingData;

    _nameController = TextEditingController(text: data?['name'] ?? '');
    _rollController = TextEditingController(text: data?['rollNumber'] ?? '');
    _dobController = TextEditingController(text: data?['dob'] ?? '');
    _fatherNameController = TextEditingController(text: data?['fatherName'] ?? '');
    _fatherPhoneController = TextEditingController(text: data?['fatherPhone'] ?? '');
    _fatherCNICController = TextEditingController(text: data?['fatherCNIC'] ?? '');
    _addressController = TextEditingController(text: data?['address'] ?? '');
    _emergencyContactController = TextEditingController(text: data?['emergencyContact'] ?? '');
    _classController = TextEditingController(text: data?['class'] ?? '');

    _selectedGender = data?['gender'];
    _selectedBloodGroup = data?['bloodGroup'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _dobController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _fatherCNICController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _classController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _rollController.clear();
    _dobController.clear();
    _fatherNameController.clear();
    _fatherPhoneController.clear();
    _fatherCNICController.clear();
    _addressController.clear();
    _emergencyContactController.clear();
    _classController.clear();

    setState(() {
      _selectedGender = null;
      _selectedBloodGroup = null;
    });
  }

  Future<String> _generateRollNumber(String className) async {
    final now = DateTime.now();
    final session = now.month >= 4 ? '${now.year}-${now.year + 1}' : '${now.year - 1}-${now.year}';
    String schoolPrefix = _getSchoolPrefix();

    final snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('students')
        .where('status', isEqualTo: 'active')
        .where('session', isEqualTo: session)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;
    if (snapshot.docs.isNotEmpty) {
      final lastRoll = snapshot.docs.first.data()['rollNumber'] as String?;
      if (lastRoll != null) {
        final parts = lastRoll.split('-');
        if (parts.length >= 2) {
          lastNumber = int.tryParse(parts[1]) ?? 0;
        }
      }
    }

    final newNumber = lastNumber + 1;
    return "$schoolPrefix-${newNumber.toString().padLeft(3, '0')}-$session";
  }

  String _getSchoolPrefix() {
    if (widget.schoolName.isEmpty) return "XXX";
    final words = widget.schoolName.trim().split(RegExp(r'\s+'));
    String prefix = "";
    for (int i = 0; i < words.length && i < 3; i++) {
      if (words[i].isNotEmpty) {
        prefix += words[i][0].toUpperCase();
      }
    }
    while (prefix.length < 3) {
      prefix += "X";
    }
    return prefix;
  }

  String _getCurrentSession() {
    final now = DateTime.now();
    return now.month >= 4 ? '${now.year}-${now.year + 1}' : '${now.year - 1}-${now.year}';
  }

  // 🔥 FETCH CLASSES: Get distinct classes from Firestore for dropdown
  Future<void> _handleSave() async {
    final className = _classController.text.trim();

    if (_nameController.text.isEmpty ||
        className.isEmpty ||
        _selectedGender == null ||
        _dobController.text.isEmpty ||
        _fatherNameController.text.isEmpty ||
        _fatherPhoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _emergencyContactController.text.isEmpty) {
      widget.showSnackBar("Please fill all required fields (*)", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      String rollNumber = _rollController.text;
      if (!_isEdit || rollNumber.isEmpty) {
        rollNumber = await _generateRollNumber(className);
      }

      final studentData = {
        'name': _nameController.text.trim(),
        'rollNumber': rollNumber,
        'class': className,
        'gender': _selectedGender,
        'bloodGroup': _selectedBloodGroup,
        'dob': _dobController.text,
        'fatherName': _fatherNameController.text.trim(),
        'fatherPhone': _fatherPhoneController.text.trim(),
        'fatherCNIC': _fatherCNICController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'status': 'active',
        'session': _getCurrentSession(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEdit) {
        await widget.existingStudent!.reference.update(studentData);
        widget.showSnackBar("✅ Student updated successfully!");
      } else {
        studentData['schoolId'] = widget.schoolId;
        studentData['createdAt'] = FieldValue.serverTimestamp();
        studentData['createdBy'] = FirebaseAuth.instance.currentUser?.uid;

        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .add(studentData);

        widget.showSnackBar("✅ Student added with Roll: $rollNumber");
        _clearForm();
      }

      if (!_isEdit) {
        widget.onSaved?.call();
      }
    } catch (e) {
      widget.showSnackBar("❌ Error: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎬 Each form section fades in staggered
        _FadeIn(
          delay: const Duration(milliseconds: 100),
          child: _buildSectionHeader("Basic Information", Icons.person),
        ),
        SizedBox(height: 16.h),

        _FadeIn(
          delay: const Duration(milliseconds: 160),
          child: _industrialTextField("Full Name *", _nameController),
        ),
        SizedBox(height: 12.h),

        _FadeIn(
          delay: const Duration(milliseconds: 200),
          child: widget.isMobile
              ? Column(
            children: [
              _industrialTextField("Class *", _classController),
              SizedBox(height: 12.h),
              _buildGenderDropdown(),
            ],
          )
              : Row(
            children: [
              Expanded(child: _industrialTextField("Class *", _classController)),
              SizedBox(width: 12.w),
              Expanded(child: _buildGenderDropdown()),
              SizedBox(width: 12.w),
              Expanded(child: _buildBloodGroupDropdown()),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        _FadeIn(
          delay: const Duration(milliseconds: 240),
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(Duration(days: 365 * 10)),
                firstDate: DateTime.now().subtract(Duration(days: 365 * 25)),
                lastDate: DateTime.now(),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: widget.studentPrimary,
                      surface: widget.bgCard,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (date != null) {
                _dobController.text = DateFormat('yyyy-MM-dd').format(date);
              }
            },
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: widget.bgElevated,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: widget.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: widget.textMuted, size: 20.sp),
                  SizedBox(width: 12.w),
                  Text(
                    _dobController.text.isEmpty ? "Date of Birth *" : _dobController.text,
                    style: TextStyle(
                      color: _dobController.text.isEmpty ? widget.textMuted : widget.textPrimary,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        _FadeIn(
          delay: const Duration(milliseconds: 280),
          child: _buildSectionHeader("Parent Information", Icons.family_restroom),
        ),
        SizedBox(height: 16.h),

        _FadeIn(
          delay: const Duration(milliseconds: 320),
          child: _industrialTextField("Father's Name *", _fatherNameController),
        ),
        SizedBox(height: 12.h),

        _FadeIn(
          delay: const Duration(milliseconds: 360),
          child: widget.isMobile
              ? Column(
            children: [
              _industrialTextField("Father's Phone *", _fatherPhoneController, type: TextInputType.phone),
              SizedBox(height: 12.h),
              _industrialTextField("Father's CNIC", _fatherCNICController),
            ],
          )
              : Row(
            children: [
              Expanded(child: _industrialTextField("Father's Phone *", _fatherPhoneController, type: TextInputType.phone)),
              SizedBox(width: 12.w),
              Expanded(child: _industrialTextField("Father's CNIC", _fatherCNICController)),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        _FadeIn(
          delay: const Duration(milliseconds: 400),
          child: _buildSectionHeader("Address & Emergency", Icons.location_on),
        ),
        SizedBox(height: 16.h),

        _FadeIn(
          delay: const Duration(milliseconds: 440),
          child: _industrialTextField("Complete Address *", _addressController, maxLines: 2),
        ),
        SizedBox(height: 12.h),
        _FadeIn(
          delay: const Duration(milliseconds: 460),
          child: _industrialTextField("Emergency Contact *", _emergencyContactController, type: TextInputType.phone),
        ),
        SizedBox(height: 24.h),

        _FadeIn(
          delay: const Duration(milliseconds: 480),
          child: _buildSectionHeader("Documents", Icons.folder),
        ),
        SizedBox(height: 16.h),

        _FadeIn(
          delay: const Duration(milliseconds: 500),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: widget.bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: widget.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload, color: widget.textMuted, size: 32.sp),
                SizedBox(height: 8.h),
                Text(
                  "Upload Photo & Documents",
                  style: TextStyle(color: widget.textSecondary, fontSize: 14.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Coming soon: Photo, Birth Certificate, etc.",
                  style: TextStyle(color: widget.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 32.h),

        // 🎬 Save button fades in last with press animation
        _FadeIn(
          delay: const Duration(milliseconds: 520),
          child: SizedBox(
            width: double.infinity,
            child: _industrialButton(
              _isEdit ? "Update Student" : "Save Student",
              icon: _isEdit ? Icons.update : Icons.save,
              onPressed: _isSaving ? null : _handleSave,
              isLoading: _isSaving,
            ),
          ),
        ),
      ],
    );
  }

  // ─── STUDENT FORM HELPER METHODS ───

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: widget.studentPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: widget.studentPrimary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: widget.bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: widget.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          dropdownColor: widget.bgElevated,
          hint: Text("Gender *", style: TextStyle(color: widget.textMuted, fontSize: 14.sp)),
          items: widget.genders.map((gender) {
            return DropdownMenuItem(
              value: gender,
              child: Text(gender, style: TextStyle(color: widget.textPrimary, fontSize: 14.sp)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedGender = val),
        ),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: widget.bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: widget.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBloodGroup,
          isExpanded: true,
          dropdownColor: widget.bgElevated,
          hint: Text("Blood Group", style: TextStyle(color: widget.textMuted, fontSize: 14.sp)),
          items: widget.bloodGroups.map((bg) {
            return DropdownMenuItem(
              value: bg,
              child: Text(bg, style: TextStyle(color: widget.textPrimary, fontSize: 14.sp)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedBloodGroup = val),
        ),
      ),
    );
  }

  Widget _industrialTextField(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: widget.bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: widget.border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            style: TextStyle(color: widget.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎬 Form's save button also gets press scale
  Widget _industrialButton(
      String label, {
        IconData? icon,
        VoidCallback? onPressed,
        bool isSecondary = false,
        bool isLoading = false,
      }) {
    final inner = Container(
      decoration: BoxDecoration(
        gradient: isSecondary || onPressed == null
            ? null
            : LinearGradient(colors: [widget.studentPrimary, widget.studentLight]),
        color: isSecondary ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(10.r),
        border: isSecondary ? Border.all(color: widget.border) : null,
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
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isSecondary ? widget.textPrimary : Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSecondary ? widget.textPrimary : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!isSecondary && onPressed != null && !isLoading) {
      return _PressButton(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: inner,
      );
    }
    return inner;
  }
}
