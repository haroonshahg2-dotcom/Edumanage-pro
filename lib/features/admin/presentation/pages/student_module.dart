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
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';


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
  void _showStudentProfile(
      DocumentSnapshot student, Map<String, dynamic>? preFetchedStats) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: StudentProfilePage(
            student: student,
            schoolId: widget.schoolId,
            isMobile: widget.isMobile,
            showSnackBar: widget.showSnackBar,
            preFetchedStats: preFetchedStats,
            onEdit: () => _showEditStudentDialog(student),
            onGenerateIdCard: () => _generateIDCard(student),
          ),
        ),
      ),
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
            .collection('feePayments')
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
  bool    _isSaving      = false;
  XFile?  _pickedPhoto;           // ← newly picked photo (not yet uploaded)
  String? _uploadedPhotoUrl;      // ← existing photoUrl from Firestore
  bool    _isUploadingPhoto = false;

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
    _uploadedPhotoUrl   = data?['photoUrl'];
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

  // Call this to let user pick photo from gallery or camera
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file   = await picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (file == null) return;
      setState(() {
        _pickedPhoto = file;
      });
    } catch (e) {
      widget.showSnackBar('❌ Could not pick image: $e', isError: true);
    }
  }

  // Uploads photo to Firebase Storage and returns download URL
  Future<String?> _uploadPhoto(String studentId) async {
    if (_pickedPhoto == null) return _uploadedPhotoUrl; // no new photo
    setState(() => _isUploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance
          .ref('schools/${widget.schoolId}/students/$studentId/photo.jpg');

      if (kIsWeb) {
        final bytes = await _pickedPhoto!.readAsBytes();
        await ref.putData(bytes,
            SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(_pickedPhoto!.path));
      }
      final url = await ref.getDownloadURL();
      setState(() => _isUploadingPhoto = false);
      return url;
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      widget.showSnackBar('❌ Photo upload failed: $e', isError: true);
      return _uploadedPhotoUrl; // keep old url on failure
    }
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
  // ═══════════════════════════════════════════════════════════════════════════
// 🔧 FIX — Replace your _handleSave() method (line 4423 to 4494)
//
// HOW:
//   Press Ctrl+G → type 4423 → Enter
//   Select from line 4423 all the way to the closing } on line 4494
//   Delete → paste this
// ═══════════════════════════════════════════════════════════════════════════

  Future<void> _handleSave() async {
    final className = _classController.text.trim();

    // ── Validation ───────────────────────────────────────────────────────
    if (_nameController.text.isEmpty ||
        className.isEmpty ||
        _selectedGender == null ||
        _dobController.text.isEmpty ||
        _fatherNameController.text.isEmpty ||
        _fatherPhoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _emergencyContactController.text.isEmpty) {
      widget.showSnackBar('Please fill all required fields (*)', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // ── STEP 1: Generate roll number ─────────────────────────────────
      String rollNumber = _rollController.text;
      if (!_isEdit || rollNumber.isEmpty) {
        rollNumber = await _generateRollNumber(className);
      }

      // ── STEP 2: Save student to Firestore FIRST (without photo) ──────
      // This way student is always saved even if photo upload fails
      final studentData = <String, dynamic>{
        'name':             _nameController.text.trim(),
        'rollNumber':       rollNumber,
        'class':            className,
        'gender':           _selectedGender,
        'bloodGroup':       _selectedBloodGroup,
        'dob':              _dobController.text,
        'fatherName':       _fatherNameController.text.trim(),
        'fatherPhone':      _fatherPhoneController.text.trim(),
        'fatherCNIC':       _fatherCNICController.text.trim(),
        'address':          _addressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'status':           'active',
        'session':          _getCurrentSession(),
        'updatedAt':        FieldValue.serverTimestamp(),
      };

      String savedStudentId;

      if (_isEdit) {
        savedStudentId = widget.existingStudent!.id;
        await widget.existingStudent!.reference.update(studentData);
      } else {
        studentData['schoolId']  = widget.schoolId;
        studentData['createdAt'] = FieldValue.serverTimestamp();
        studentData['createdBy'] = FirebaseAuth.instance.currentUser?.uid;

        final docRef = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('students')
            .add(studentData);

        savedStudentId = docRef.id;
      }

      // ── STEP 3: Upload photo AFTER student is saved ───────────────────
      // Now we have a real studentId to use in Storage path
      if (_pickedPhoto != null) {
        try {
          final ref = FirebaseStorage.instance.ref(
            'schools/${widget.schoolId}/students/$savedStudentId/photo.jpg',
          );

          // Upload
          if (kIsWeb) {
            final bytes = await _pickedPhoto!.readAsBytes();
            await ref.putData(
              bytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
          } else {
            await ref.putFile(File(_pickedPhoto!.path));
          }

          // Get URL and update Firestore doc with photoUrl
          final photoUrl = await ref.getDownloadURL();
          await FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('students')
              .doc(savedStudentId)
              .update({'photoUrl': photoUrl});

        } catch (photoError) {
          // Student was already saved — just warn about photo
          debugPrint('Photo upload error: $photoError');
          widget.showSnackBar(
            '✅ Student saved! But photo failed to upload. Try editing to add photo.',
          );
          if (!_isEdit) _clearForm();
          return; // exit early, student IS saved
        }
      }

      // ── STEP 4: Success ───────────────────────────────────────────────
      if (_isEdit) {
        widget.showSnackBar('✅ Student updated successfully!');
      } else {
        widget.showSnackBar('✅ Student added with Roll: $rollNumber');
        _clearForm();
        widget.onSaved?.call();
      }

    } catch (e) {
      debugPrint('Save error: $e');
      widget.showSnackBar('❌ Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving         = false;
          _isUploadingPhoto = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── SECTION 1: Basic Information ──────────────────────────────────
        _FadeIn(
          delay: const Duration(milliseconds: 80),
          child: _sectionHeader('Basic Information', Icons.person_outline_rounded,
              const Color(0xFF7C8CF0)),
        ),
        SizedBox(height: 16.h),

        // Full Name
        _FadeIn(
          delay: const Duration(milliseconds: 120),
          child: _formField(
            label: 'Full Name',
            hint: 'e.g. Muhammad Ali',
            icon: Icons.badge_outlined,
            controller: _nameController,
            isRequired: true,
          ),
        ),
        SizedBox(height: 12.h),

        // Class + Gender + Blood Group
        _FadeIn(
          delay: const Duration(milliseconds: 160),
          child: widget.isMobile
              ? Column(children: [
            _formField(
              label: 'Class', hint: 'e.g. 5A',
              icon: Icons.class_outlined,
              controller: _classController, isRequired: true,
            ),
            SizedBox(height: 12.h),
            _styledDropdown(
              label: 'Gender', hint: 'Select gender',
              icon: Icons.wc_rounded,
              value: _selectedGender,
              items: widget.genders,
              isRequired: true,
              onChanged: (v) => setState(() => _selectedGender = v),
            ),
            SizedBox(height: 12.h),
            _styledDropdown(
              label: 'Blood Group', hint: 'Select blood group',
              icon: Icons.bloodtype_outlined,
              value: _selectedBloodGroup,
              items: widget.bloodGroups,
              onChanged: (v) => setState(() => _selectedBloodGroup = v),
            ),
          ])
              : Row(children: [
            Expanded(child: _formField(
              label: 'Class', hint: 'e.g. 5A',
              icon: Icons.class_outlined,
              controller: _classController, isRequired: true,
            )),
            SizedBox(width: 12.w),
            Expanded(child: _styledDropdown(
              label: 'Gender', hint: 'Select gender',
              icon: Icons.wc_rounded,
              value: _selectedGender,
              items: widget.genders,
              isRequired: true,
              onChanged: (v) => setState(() => _selectedGender = v),
            )),
            SizedBox(width: 12.w),
            Expanded(child: _styledDropdown(
              label: 'Blood Group', hint: 'Select blood group',
              icon: Icons.bloodtype_outlined,
              value: _selectedBloodGroup,
              items: widget.bloodGroups,
              onChanged: (v) => setState(() => _selectedBloodGroup = v),
            )),
          ]),
        ),
        SizedBox(height: 12.h),

        // Date of Birth
        _FadeIn(
          delay: const Duration(milliseconds: 200),
          child: _dobPicker(),
        ),
        SizedBox(height: 28.h),

        // ── SECTION 2: Parent Information ─────────────────────────────────
        _FadeIn(
          delay: const Duration(milliseconds: 240),
          child: _sectionHeader('Parent Information', Icons.family_restroom_rounded,
              const Color(0xFF3DD68B)),
        ),
        SizedBox(height: 16.h),

        _FadeIn(
          delay: const Duration(milliseconds: 270),
          child: _formField(
            label: "Father's Name", hint: 'e.g. Muhammad Usman',
            icon: Icons.person_2_outlined,
            controller: _fatherNameController, isRequired: true,
          ),
        ),
        SizedBox(height: 12.h),

        _FadeIn(
          delay: const Duration(milliseconds: 300),
          child: widget.isMobile
              ? Column(children: [
            _formField(
              label: "Father's Phone", hint: '03XX-XXXXXXX',
              icon: Icons.phone_outlined,
              controller: _fatherPhoneController,
              type: TextInputType.phone, isRequired: true,
            ),
            SizedBox(height: 12.h),
            _formField(
              label: "Father's CNIC", hint: 'XXXXX-XXXXXXX-X',
              icon: Icons.credit_card_outlined,
              controller: _fatherCNICController,
            ),
          ])
              : Row(children: [
            Expanded(child: _formField(
              label: "Father's Phone", hint: '03XX-XXXXXXX',
              icon: Icons.phone_outlined,
              controller: _fatherPhoneController,
              type: TextInputType.phone, isRequired: true,
            )),
            SizedBox(width: 12.w),
            Expanded(child: _formField(
              label: "Father's CNIC", hint: 'XXXXX-XXXXXXX-X',
              icon: Icons.credit_card_outlined,
              controller: _fatherCNICController,
            )),
          ]),
        ),
        SizedBox(height: 28.h),

        // ── SECTION 3: Address & Emergency ────────────────────────────────
        _FadeIn(
          delay: const Duration(milliseconds: 340),
          child: _sectionHeader('Address & Emergency', Icons.location_on_outlined,
              const Color(0xFF4DBEF7)),
        ),
        SizedBox(height: 16.h),

        _FadeIn(
          delay: const Duration(milliseconds: 370),
          child: _formField(
            label: 'Complete Address', hint: 'Street, City, Province',
            icon: Icons.home_outlined,
            controller: _addressController,
            maxLines: 2, isRequired: true,
          ),
        ),
        SizedBox(height: 12.h),

        _FadeIn(
          delay: const Duration(milliseconds: 400),
          child: _formField(
            label: 'Emergency Contact', hint: '03XX-XXXXXXX',
            icon: Icons.emergency_outlined,
            controller: _emergencyContactController,
            type: TextInputType.phone, isRequired: true,
          ),
        ),
        SizedBox(height: 28.h),

        // ── SECTION 4: Student Photo ──────────────────────────────────────
        _FadeIn(
          delay: const Duration(milliseconds: 430),
          child: _sectionHeader('Student Photo',
              Icons.photo_camera_outlined, const Color(0xFFF2A93B)),
        ),
        SizedBox(height: 16.h),
        _FadeIn(
          delay: const Duration(milliseconds: 460),
          child: _photoPicker(),
        ),

        SizedBox(height: 32.h),

        // ── Save / Update Button ──────────────────────────────────────────
        _FadeIn(
          delay: const Duration(milliseconds: 500),
          child: SizedBox(
            width: double.infinity,
            child: _saveButton(),
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS (replace the old ones at the bottom of the class)
  // ─────────────────────────────────────────────────────────────────────────

  /// Section header with colored left bar + icon
  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w, height: 22.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: TextStyle(
            color: widget.textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  /// Styled text field with floating label + left icon
  Widget _formField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return _FocusField(
      border: widget.border,
      focusColor: widget.studentPrimary,
      bgElevated: widget.bgElevated,
      builder: (isFocused) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(children: [
            Text(
              label,
              style: TextStyle(
                color: isFocused ? widget.studentPrimary : widget.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 3.w),
              Text('*', style: TextStyle(color: widget.accentDanger, fontSize: 12.sp, fontWeight: FontWeight.w700)),
            ],
          ]),
          SizedBox(height: 6.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: widget.bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isFocused ? widget.studentPrimary : widget.border,
                width: isFocused ? 1.5 : 1,
              ),
              boxShadow: isFocused
                  ? [BoxShadow(color: widget.studentPrimary.withOpacity(0.12), blurRadius: 8)]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 14.w, top: maxLines > 1 ? 14.h : 0),
                  child: Icon(
                    icon,
                    color: isFocused ? widget.studentPrimary : widget.textMuted,
                    size: 18.sp,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: type,
                    maxLines: maxLines,
                    style: TextStyle(color: widget.textPrimary, fontSize: 14.sp),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: TextStyle(color: widget.textMuted, fontSize: 13.sp),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: maxLines > 1 ? 12.h : 14.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Styled dropdown with label + icon (matches _formField visually)
  Widget _styledDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            label,
            style: TextStyle(
              color: widget.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (isRequired) ...[
            SizedBox(width: 3.w),
            Text('*', style: TextStyle(color: widget.accentDanger, fontSize: 12.sp, fontWeight: FontWeight.w700)),
          ],
        ]),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.only(left: 12.w, right: 4.w),
          decoration: BoxDecoration(
            color: widget.bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: widget.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: widget.textMuted, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: widget.bgElevated,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: widget.textMuted, size: 20.sp),
                    hint: Text(hint, style: TextStyle(color: widget.textMuted, fontSize: 13.sp)),
                    items: items.map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: TextStyle(color: widget.textPrimary, fontSize: 14.sp)),
                    )).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Date of birth picker row
  Widget _dobPicker() {
    final hasDob = _dobController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Date of Birth',
              style: TextStyle(color: widget.textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600)),
          SizedBox(width: 3.w),
          Text('*', style: TextStyle(color: widget.accentDanger, fontSize: 12.sp, fontWeight: FontWeight.w700)),
        ]),
        SizedBox(height: 6.h),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
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
              setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(date));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: widget.bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: hasDob ? widget.studentPrimary.withOpacity(0.5) : widget.border,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: hasDob ? widget.studentPrimary : widget.textMuted,
                    size: 18.sp),
                SizedBox(width: 12.w),
                Text(
                  hasDob ? _dobController.text : 'Select date of birth',
                  style: TextStyle(
                    color: hasDob ? widget.textPrimary : widget.textMuted,
                    fontSize: 14.sp,
                  ),
                ),
                const Spacer(),
                if (hasDob)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: widget.studentPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text('Change',
                        style: TextStyle(color: widget.studentPrimary, fontSize: 10.sp, fontWeight: FontWeight.w600)),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded, color: widget.textMuted, size: 20.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoPicker() {
    // Decide what to show as preview
    final hasNewPhoto   = _pickedPhoto != null;
    final hasExisting   = _uploadedPhotoUrl != null && !hasNewPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ── Photo preview box ───────────────────────────────────────
            GestureDetector(
              onTap: () => _showPhotoSourceSheet(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: widget.bgElevated,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: hasNewPhoto || hasExisting
                        ? const Color(0xFFF2A93B).withOpacity(0.5)
                        : widget.border,
                    width: hasNewPhoto || hasExisting ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13.r),
                  child: _isUploadingPhoto
                      ? Center(
                    child: CircularProgressIndicator(
                        color: const Color(0xFFF2A93B), strokeWidth: 2),
                  )
                      : hasNewPhoto
                      ? kIsWeb
                      ? Image.network(_pickedPhoto!.path,
                      fit: BoxFit.cover)
                      : Image.file(File(_pickedPhoto!.path),
                      fit: BoxFit.cover)
                      : hasExisting
                      ? CachedNetworkImage(
                    imageUrl: _uploadedPhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Center(
                      child: CircularProgressIndicator(
                        color: const Color(0xFFF2A93B),
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        _photoPlaceholder(),
                  )
                      : _photoPlaceholder(),
                ),
              ),
            ),
            SizedBox(width: 16.w),

            // ── Action buttons ──────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasNewPhoto || hasExisting
                        ? 'Photo selected'
                        : 'No photo yet',
                    style: TextStyle(
                      color: hasNewPhoto || hasExisting
                          ? widget.textPrimary
                          : widget.textMuted,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'JPG, PNG · max 2MB\nSquare photo recommended',
                    style: TextStyle(
                        color: widget.textMuted, fontSize: 11.sp, height: 1.5),
                  ),
                  SizedBox(height: 12.h),
                  Row(children: [
                    // Camera
                    _photoBtn(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () => _pickPhoto(ImageSource.camera),
                    ),
                    SizedBox(width: 8.w),
                    // Gallery
                    _photoBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () => _pickPhoto(ImageSource.gallery),
                    ),
                    // Remove (only show if photo exists)
                    if (hasNewPhoto || hasExisting) ...[
                      SizedBox(width: 8.w),
                      _photoBtn(
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove',
                        isRemove: true,
                        onTap: () => setState(() {
                          _pickedPhoto     = null;
                          _uploadedPhotoUrl = null;
                        }),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: widget.bgElevated,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_outline_rounded,
              color: widget.textMuted, size: 32.sp),
          SizedBox(height: 4.h),
          Text('Tap to add', style: TextStyle(
              color: widget.textMuted, fontSize: 9.sp)),
        ]),
      ),
    );
  }

  Widget _photoBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isRemove = false,
  }) {
    final color = isRemove
        ? widget.accentDanger
        : const Color(0xFFF2A93B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14.sp),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(
              color: color, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36.w, height: 4.h,
            decoration: BoxDecoration(
              color: widget.border,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text('Select Photo Source',
              style: TextStyle(
                  color: widget.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 20.h),
          Row(children: [
            Expanded(child: _sourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              sub: 'Take a new photo',
              color: const Color(0xFF7C8CF0),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            )),
            SizedBox(width: 12.w),
            Expanded(child: _sourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              sub: 'Choose existing',
              color: const Color(0xFF3DD68B),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            )),
          ]),
          SizedBox(height: 8.h),
        ]),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(
              color: widget.textPrimary,
              fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 2.h),
          Text(sub, style: TextStyle(
              color: widget.textMuted, fontSize: 11.sp)),
        ]),
      ),
    );
  }



  /// Save / Update button with gradient + loading state
  Widget _saveButton() {
    return _PressButton(
      onTap: _isSaving ? () {} : _handleSave,
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          gradient: _isSaving
              ? null
              : LinearGradient(
            colors: [widget.studentPrimary, widget.studentLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          color: _isSaving ? widget.bgElevated : null,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: _isSaving
              ? []
              : [BoxShadow(color: widget.studentPrimary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              SizedBox(
                width: 18.w, height: 18.w,
                child: CircularProgressIndicator(
                  color: widget.textPrimary, strokeWidth: 2,
                ),
              )
            else ...[
              Icon(
                _isEdit ? Icons.check_circle_outline_rounded : Icons.save_alt_rounded,
                color: Colors.white, size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                _isEdit ? 'Update Student' : 'Save Student',
                style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FocusField extends StatefulWidget {
  final Widget Function(bool isFocused) builder;
  final Color border;
  final Color focusColor;
  final Color bgElevated;

  const _FocusField({
    required this.builder,
    required this.border,
    required this.focusColor,
    required this.bgElevated,
  });

  @override
  State<_FocusField> createState() => _FocusFieldState();
}

class _FocusFieldState extends State<_FocusField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_isFocused);
}

// ─── STEP 1: Paste this ENTIRE class at the bottom of student_module.dart ──

class StudentProfilePage extends StatefulWidget {
  final DocumentSnapshot student;
  final Map<String, dynamic>? preFetchedStats;
  final String schoolId;
  final bool isMobile;
  final Function(String, {bool isError}) showSnackBar;
  final VoidCallback onEdit;
  final VoidCallback onGenerateIdCard;

  const StudentProfilePage({
    super.key,
    required this.student,
    required this.schoolId,
    required this.isMobile,
    required this.showSnackBar,
    required this.onEdit,
    required this.onGenerateIdCard,
    this.preFetchedStats,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with SingleTickerProviderStateMixin {

  // ── Colors (same as parent module) ─────────────────────────────────────
  static const Color _bgDark       = Color(0xFF0F1117);
  static const Color _bgCard       = Color(0xFF151821);
  static const Color _bgElevated   = Color(0xFF1A1D29);
  static const Color _border       = Color(0xFF2A2E3B);
  static const Color _textPrimary  = Color(0xFFEEF1F8);
  static const Color _textSecondary= Color(0xFF8B92A8);
  static const Color _textMuted    = Color(0xFF5A6072);
  static const Color _primary      = Color(0xFF7C8CF0);
  static const Color _primaryLight = Color(0xFF9AA5F3);
  static const Color _success      = Color(0xFF10B981);
  static const Color _warning      = Color(0xFFF59E0B);
  static const Color _danger       = Color(0xFFEF4444);

  late TabController _tabController;
  late Map<String, dynamic> _data;
  late String _studentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _data      = widget.student.data() as Map<String, dynamic>;
    _studentId = widget.student.id;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calcAge(String? dob) {
    if (dob == null) return 0;
    try {
      final d = DateTime.parse(dob);
      final n = DateTime.now();
      int age = n.year - d.year;
      if (n.month < d.month || (n.month == d.month && n.day < d.day)) age--;
      return age;
    } catch (_) { return 0; }
  }

  String _fmtCurrency(double v) {
    if (v >= 100000) return '₨${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₨${(v / 1000).toStringAsFixed(1)}K';
    return '₨${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final attPct   = widget.preFetchedStats?['attendancePercent'] ?? 0.0;
    final feeStatus = widget.preFetchedStats?['feeStatus'] ?? 'unknown';

    return Scaffold(
      backgroundColor: _bgDark,
      body: Column(
        children: [
          _buildHeader(attPct, feeStatus),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAttendanceTab(),
                _buildFeeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader(double attPct, String feeStatus) {
    final feeColor = feeStatus == 'paid'
        ? _success : feeStatus == 'partial' ? _warning : _danger;
    final feeLabel = feeStatus == 'paid'
        ? 'Paid' : feeStatus == 'partial' ? 'Partial' : 'Pending';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      decoration: BoxDecoration(
        color: _bgCard,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          // ── Top bar ──────────────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _bgElevated,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: _border),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: _textSecondary, size: 16.sp),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text('Student Profile',
                    style: TextStyle(color: _textPrimary,
                        fontSize: 18.sp, fontWeight: FontWeight.w700)),
              ),
              // Edit button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onEdit();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: _primary.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_outlined, color: _primary, size: 15.sp),
                    SizedBox(width: 6.w),
                    Text('Edit', style: TextStyle(
                        color: _primary, fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              SizedBox(width: 8.w),
              // ID Card button
              GestureDetector(
                onTap: widget.onGenerateIdCard,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: _success.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.badge_outlined, color: _success, size: 15.sp),
                    SizedBox(width: 6.w),
                    Text('ID Card', style: TextStyle(
                        color: _success, fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Avatar + name + badges ───────────────────────────────────
          Row(
            children: [
              // Avatar
              Container(
                width: 72.w, height: 72.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_primary, _primaryLight]),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: _data['photoUrl'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.network(_data['photoUrl'],
                      fit: BoxFit.cover),
                )
                    : Center(
                  child: Text(
                    (_data['name'] ?? 'S')[0].toUpperCase(),
                    style: TextStyle(color: Colors.white,
                        fontSize: 30.sp, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_data['name'] ?? 'Unknown',
                        style: TextStyle(color: _textPrimary,
                            fontSize: 20.sp, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4.h),
                    Text(
                      'Roll: ${_data['rollNumber'] ?? 'N/A'} · Class ${_data['class'] ?? 'N/A'}',
                      style: TextStyle(color: _textSecondary, fontSize: 13.sp),
                    ),
                    SizedBox(height: 8.h),
                    Row(children: [
                      _badge(feeLabel, feeColor),
                      SizedBox(width: 6.w),
                      _badge(
                        '${attPct.toStringAsFixed(0)}% Att.',
                        attPct >= 75 ? _success : _warning,
                      ),
                      SizedBox(width: 6.w),
                      _badge(
                        (_data['status'] ?? 'active').toUpperCase(),
                        _data['status'] == 'active' ? _success : _danger,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(
          color: color, fontSize: 10.sp, fontWeight: FontWeight.w700)),
    );
  }

  // ── TAB BAR ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: _bgCard,
      child: TabBar(
        controller: _tabController,
        labelColor: _primary,
        unselectedLabelColor: _textMuted,
        indicatorColor: _primary,
        indicatorWeight: 2,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Attendance'),
          Tab(text: 'Fee History'),
        ],
      ),
    );
  }

  // ── TAB 1: OVERVIEW ─────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // KPI row
          Row(children: [
            Expanded(child: _kpiCard('Attendance',
                '${(widget.preFetchedStats?['attendancePercent'] ?? 0.0).toStringAsFixed(0)}%',
                Icons.fact_check_rounded, _warning)),
            SizedBox(width: 10.w),
            Expanded(child: _kpiCard('Age',
                '${_calcAge(_data['dob'])} yrs',
                Icons.cake_outlined, _primary)),
            SizedBox(width: 10.w),
            Expanded(child: _kpiCard('Session',
                _data['session'] ?? 'N/A',
                Icons.calendar_month_outlined, _success)),
          ]),
          SizedBox(height: 16.h),

          // Personal info
          _infoCard('Personal Information', Icons.person_outline_rounded, _primary, [
            _infoRow(Icons.badge_outlined,         'Full Name',    _data['name']),
            _infoRow(Icons.wc_rounded,             'Gender',       _data['gender']),
            _infoRow(Icons.cake_outlined,          'Date of Birth',_data['dob']),
            _infoRow(Icons.bloodtype_outlined,     'Blood Group',  _data['bloodGroup'] ?? 'N/A'),
            _infoRow(Icons.class_outlined,         'Class',        _data['class']),
            _infoRow(Icons.numbers_outlined,       'Roll Number',  _data['rollNumber']),
          ]),
          SizedBox(height: 12.h),

          // Parent info
          _infoCard('Parent Information', Icons.family_restroom_rounded, _success, [
            _infoRow(Icons.person_2_outlined,      "Father's Name",  _data['fatherName']),
            _infoRow(Icons.phone_outlined,         "Father's Phone", _data['fatherPhone']),
            _infoRow(Icons.credit_card_outlined,   "Father's CNIC",  _data['fatherCNIC'] ?? 'N/A'),
            _infoRow(Icons.person_3_outlined,      "Mother's Name",  _data['motherName'] ?? 'N/A'),
            _infoRow(Icons.phone_android_outlined, "Mother's Phone", _data['motherPhone'] ?? 'N/A'),
          ]),
          SizedBox(height: 12.h),

          // Contact
          _infoCard('Address & Emergency', Icons.location_on_outlined, _warning, [
            _infoRow(Icons.home_outlined,      'Address',           _data['address']),
            _infoRow(Icons.emergency_outlined, 'Emergency Contact', _data['emergencyContact']),
          ]),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(7.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(height: 10.h),
          Text(value, style: TextStyle(
              color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(color: _textMuted, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, IconData icon, Color color,
      List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
            child: Row(children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 15.sp),
              ),
              SizedBox(width: 10.w),
              Text(title, style: TextStyle(
                  color: _textPrimary, fontSize: 14.sp,
                  fontWeight: FontWeight.w700)),
            ]),
          ),
          Divider(color: _border, height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _textMuted, size: 15.sp),
          SizedBox(width: 10.w),
          SizedBox(
            width: 110.w,
            child: Text(label, style: TextStyle(
                color: _textSecondary, fontSize: 12.sp)),
          ),
          Expanded(
            child: Text(value ?? 'N/A',
                style: TextStyle(
                    color: _textPrimary, fontSize: 13.sp,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: ATTENDANCE HISTORY ────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    // Fetch last 30 days attendance from
    // schools/{schoolId}/attendance/{yyyy-MM-dd}/records/{studentId}
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAttendanceHistory(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return _loadingState('Loading attendance...');
        }
        final records = snap.data!;
        if (records.isEmpty) {
          return _emptyState(Icons.fact_check_outlined, 'No attendance records');
        }

        // Calculate summary
        final present = records.where((r) => r['status'] == 'present').length;
        final absent  = records.where((r) => r['status'] == 'absent').length;
        final late    = records.where((r) => r['status'] == 'late').length;
        final total   = records.length;
        final pct     = total > 0 ? ((present / total) * 100) : 0.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Summary row
              Row(children: [
                Expanded(child: _attKpi('Present', present, _success)),
                SizedBox(width: 8.w),
                Expanded(child: _attKpi('Absent', absent, _danger)),
                SizedBox(width: 8.w),
                Expanded(child: _attKpi('Late', late, _warning)),
                SizedBox(width: 8.w),
                Expanded(child: _attKpi('Rate',
                    '${pct.toStringAsFixed(0)}%', _primary, isStr: true)),
              ]),
              SizedBox(height: 16.h),

              // Progress bar
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last 30 Days', style: TextStyle(
                            color: _textPrimary, fontSize: 13.sp,
                            fontWeight: FontWeight.w600)),
                        Text('${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                color: pct >= 75 ? _success : _warning,
                                fontSize: 13.sp, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 6.h,
                        backgroundColor: _bgElevated,
                        valueColor: AlwaysStoppedAnimation(
                            pct >= 75 ? _success : _warning),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              // Day-by-day list
              Container(
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: records.asMap().entries.map((e) {
                    final r   = e.value;
                    final status = r['status'] as String;
                    final color = status == 'present'
                        ? _success
                        : status == 'late' ? _warning : _danger;
                    final isLast = e.key == records.length - 1;
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          child: Row(children: [
                            Container(
                              width: 8.w, height: 8.w,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(r['date'],
                                  style: TextStyle(
                                      color: _textPrimary, fontSize: 13.sp)),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(
                                    color: color, fontSize: 11.sp,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ]),
                        ),
                        if (!isLast) Divider(color: _border, height: 1),
                      ],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _attKpi(String label, dynamic value, Color color,
      {bool isStr = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(isStr ? value : value.toString(),
            style: TextStyle(color: color,
                fontSize: 18.sp, fontWeight: FontWeight.w800)),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(color: _textMuted, fontSize: 10.sp)),
      ]),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceHistory() async {
    final results = <Map<String, dynamic>>[];
    final now     = DateTime.now();
    final fmt     = DateFormat('yyyy-MM-dd');

    // Check last 30 days
    final futures = <Future<void>>[];
    for (int i = 0; i < 30; i++) {
      final dateStr = fmt.format(now.subtract(Duration(days: i)));
      futures.add(
        FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('attendance')
            .doc(dateStr)
            .collection('records')
            .doc(_studentId)
            .get()
            .then((doc) {
          if (doc.exists) {
            final status = (doc.data()?['status'] ?? 'absent')
                .toString().toLowerCase();
            results.add({'date': dateStr, 'status': status});
          }
        }).catchError((_) {}),
      );
    }
    await Future.wait(futures);
    results.sort((a, b) => b['date'].compareTo(a['date']));
    return results;
  }

  // ── TAB 3: FEE HISTORY ──────────────────────────────────────────────────
  Widget _buildFeeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('feePayments')
          .where('studentId', isEqualTo: _studentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return _loadingState('Loading fee history...');

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(Icons.receipt_long_outlined, 'No fee payments found');
        }

        // Calculate total paid
        double totalPaid = 0;
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          totalPaid += ((d['amount'] ?? 0) as num).toDouble();
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Total paid summary
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _success.withOpacity(0.25)),
                ),
                child: Row(children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.account_balance_wallet_outlined,
                        color: _success, size: 24.sp),
                  ),
                  SizedBox(width: 14.w),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Total Paid', style: TextStyle(
                        color: _textSecondary, fontSize: 12.sp)),
                    Text(_fmtCurrency(totalPaid), style: TextStyle(
                        color: _success, fontSize: 22.sp,
                        fontWeight: FontWeight.w800)),
                    Text('${docs.length} payment${docs.length > 1 ? 's' : ''}',
                        style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                  ]),
                ]),
              ),
              SizedBox(height: 14.h),

              // Payment list
              Container(
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: docs.asMap().entries.map((e) {
                    final d       = e.value.data() as Map<String, dynamic>;
                    final amount  = ((d['amount'] ?? 0) as num).toDouble();
                    final isLast  = e.key == docs.length - 1;
                    final ts      = d['createdAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat('dd MMM yyyy').format(ts.toDate())
                        : 'N/A';
                    final month   = d['month'] ?? d['forMonth'] ?? '';
                    final method  = d['paymentMethod'] ?? d['method'] ?? 'Cash';

                    return Column(children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        child: Row(children: [
                          // Receipt icon
                          Container(
                            width: 40.w, height: 40.w,
                            decoration: BoxDecoration(
                              color: _success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(Icons.receipt_outlined,
                                color: _success, size: 18.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    month.isNotEmpty
                                        ? 'Fee — $month' : 'Fee Payment',
                                    style: TextStyle(
                                        color: _textPrimary, fontSize: 13.sp,
                                        fontWeight: FontWeight.w600)),
                                Text('$dateStr · $method',
                                    style: TextStyle(
                                        color: _textMuted, fontSize: 11.sp)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_fmtCurrency(amount),
                                  style: TextStyle(
                                      color: _success, fontSize: 14.sp,
                                      fontWeight: FontWeight.w700)),
                              Container(
                                margin: EdgeInsets.only(top: 3.h),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 7.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: _success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text('Paid', style: TextStyle(
                                    color: _success, fontSize: 10.sp,
                                    fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ]),
                      ),
                      if (!isLast) Divider(color: _border, height: 1),
                    ]);
                  }).toList(),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  // ── Shared states ────────────────────────────────────────────────────────
  Widget _loadingState(String msg) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primary, strokeWidth: 2),
        SizedBox(height: 16.h),
        Text(msg, style: TextStyle(color: _textMuted, fontSize: 13.sp)),
      ],
    ));
  }

  Widget _emptyState(IconData icon, String msg) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: _border, size: 48.sp),
        SizedBox(height: 12.h),
        Text(msg, style: TextStyle(color: _textMuted, fontSize: 14.sp)),
      ],
    ));
  }
}

