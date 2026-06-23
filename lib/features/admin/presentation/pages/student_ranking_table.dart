import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

// ═══════════════════════════════════════════════════════════════════════════════
//  STUDENT RANKING TABLE — Enterprise-grade data table with:
//  • Sticky headers  • Sorting  • Pagination  • Search filtering
//  • Responsive scrolling  • Hover effects  • Medal/badge system
// ═══════════════════════════════════════════════════════════════════════════════

class StudentRankingTable extends StatefulWidget {
  final List<Map<String, dynamic>> rankings;
  final String searchQuery;
  final String sortBy;
  final bool isMobile;
  final bool isDesktop;

  const StudentRankingTable({
    super.key,
    required this.rankings,
    required this.searchQuery,
    required this.sortBy,
    required this.isMobile,
    required this.isDesktop,
  });

  @override
  State<StudentRankingTable> createState() => _StudentRankingTableState();
}

class _StudentRankingTableState extends State<StudentRankingTable> {
  int _currentPage = 0;
  final int _itemsPerPage = 15;

  // ── Theme ──
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filterAndSortRankings();
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    final pageItems = _getPageItems(filtered);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.01)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(widget.isMobile ? 14.w : 18.w),
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered, color: _examPrimary, size: 20.sp),
                    SizedBox(width: 10.w),
                    Text("Student Rankings", style: TextStyle(
                      color: _textPrimary, fontSize: widget.isMobile ? 15.sp : 17.sp, fontWeight: FontWeight.w800,
                    )),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _examPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: _examPrimary.withOpacity(0.3)),
                      ),
                      child: Text(
                        "${filtered.length} students",
                        style: TextStyle(color: _examPrimary, fontSize: 11.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              // Table
              if (widget.isMobile)
                _buildMobileList(pageItems)
              else
                _buildDesktopTable(pageItems),
              // Pagination
              if (totalPages > 1) _buildPagination(totalPages, filtered.length),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  // ── Mobile Card List ──
  Widget _buildMobileList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final r = items[i];
        final globalIndex = _currentPage * _itemsPerPage + i;
        return _mobileCard(r, globalIndex);
      },
    );
  }

  Widget _mobileCard(Map<String, dynamic> r, int index) {
    final isPassed = (r['average'] ?? 0) >= 50;
    final isTop3 = index < 3;
    final medalColors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isTop3 ? medalColors[index].withOpacity(0.08) : _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isTop3 ? medalColors[index].withOpacity(0.3) : _border,
          width: isTop3 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              gradient: isTop3 ? LinearGradient(colors: [medalColors[index], medalColors[index].withOpacity(0.7)]) : null,
              color: isTop3 ? null : _textMuted.withOpacity(0.15),
              shape: BoxShape.circle,
              boxShadow: isTop3 ? [BoxShadow(color: medalColors[index].withOpacity(0.3), blurRadius: 8)] : null,
            ),
            child: Center(
              child: isTop3
                  ? Icon(Icons.star, color: _bgCard, size: 16.sp)
                  : Text("${index + 1}", style: TextStyle(color: _textMuted, fontSize: 13.sp, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(width: 12.w),
          // Avatar
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_examPrimary, _examLight]),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Center(
              child: Text(
                (r['name'] ?? '?')[0].toUpperCase(),
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['name'] ?? 'Unknown',
                  style: TextStyle(color: _textPrimary, fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Roll: ${r['rollNumber'] ?? '--'}  •  ${r['subjectsCount'] ?? 0} subjects",
                  style: TextStyle(color: _textMuted, fontSize: 10.sp),
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${(r['average'] ?? 0).toStringAsFixed(1)}%",
                style: TextStyle(
                  color: isPassed ? _accentSuccess : _accentDanger,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isPassed ? _accentSuccess.withOpacity(0.1) : _accentDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isPassed ? "PASS" : "FAIL",
                  style: TextStyle(
                    color: isPassed ? _accentSuccess : _accentDanger,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Desktop Table ──
  Widget _buildDesktopTable(List<Map<String, dynamic>> items) {
    return Column(
      children: [
        // Sticky Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: _bgCard,
            border: Border(bottom: BorderSide(color: _border, width: 1)),
          ),
          child: Row(
            children: [
              SizedBox(width: 50.w, child: Text("RANK", style: _thStyle())),
              SizedBox(width: 50.w, child: Text("ROLL", style: _thStyle())),
              SizedBox(width: 12.w),
              Expanded(flex: 3, child: Text("STUDENT", style: _thStyle())),
              Expanded(flex: 2, child: Text("SUBJECTS", style: _thStyle(), textAlign: TextAlign.center)),
              Expanded(child: Text("AVG%", style: _thStyle(), textAlign: TextAlign.center)),
              SizedBox(width: 60.w, child: Text("GRADE", style: _thStyle(), textAlign: TextAlign.center)),
              SizedBox(width: 70.w, child: Text("STATUS", style: _thStyle(), textAlign: TextAlign.center)),
              SizedBox(width: 70.w, child: Text("GPA", style: _thStyle(), textAlign: TextAlign.center)),
            ],
          ),
        ),
        // Rows
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final globalIndex = _currentPage * _itemsPerPage + i;
          final isPassed = (r['average'] ?? 0) >= 50;
          final isTop3 = globalIndex < 3;
          final medalColors = [const Color(0xFFFFD700), const Color(0xFFC0C0C0), const Color(0xFFCD7F32)];
          final gpa = _calculateGPA(r['average'] ?? 0);

          return MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _border, width: 0.5)),
                color: i.isEven ? null : _bgCard.withOpacity(0.3),
                gradient: isTop3
                    ? LinearGradient(
                  colors: [medalColors[globalIndex].withOpacity(0.06), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 50.w,
                    child: Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        gradient: isTop3
                            ? LinearGradient(colors: [medalColors[globalIndex], medalColors[globalIndex].withOpacity(0.7)])
                            : null,
                        color: isTop3 ? null : _textMuted.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: isTop3 ? [BoxShadow(color: medalColors[globalIndex].withOpacity(0.3), blurRadius: 6)] : null,
                      ),
                      child: Center(
                        child: isTop3
                            ? Icon(Icons.star, color: _bgCard, size: 14.sp)
                            : Text("${globalIndex + 1}", style: TextStyle(
                          color: _textMuted, fontSize: 12.sp, fontWeight: FontWeight.w700,
                        )),
                      ),
                    ),
                  ),
                  // Roll
                  SizedBox(
                    width: 50.w,
                    child: Text(
                      "${r['rollNumber'] ?? '--'}",
                      style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Student
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_examPrimary, _examLight]),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Text(
                              (r['name'] ?? '?')[0].toUpperCase(),
                              style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            r['name'] ?? 'Unknown',
                            style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subjects
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${r['subjectsCount'] ?? 0} subjects",
                      style: TextStyle(color: _textMuted, fontSize: 12.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Avg%
                  Expanded(
                    child: Text(
                      "${(r['average'] ?? 0).toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: isPassed ? _accentSuccess : _accentDanger,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Grade
                  SizedBox(
                    width: 60.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _getGradeColor(r['grade'] ?? 'F').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        r['grade'] ?? '--',
                        style: TextStyle(
                          color: _getGradeColor(r['grade'] ?? 'F'),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Status
                  SizedBox(
                    width: 70.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: isPassed ? _accentSuccess.withOpacity(0.1) : _accentDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: isPassed ? _accentSuccess.withOpacity(0.3) : _accentDanger.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isPassed ? "PASS" : "FAIL",
                        style: TextStyle(
                          color: isPassed ? _accentSuccess : _accentDanger,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // GPA
                  SizedBox(
                    width: 70.w,
                    child: Text(
                      gpa.toStringAsFixed(2),
                      style: TextStyle(
                        color: gpa >= 3.0 ? _accentSuccess : gpa >= 2.0 ? _accentWarning : _accentDanger,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // ── Pagination ──
  Widget _buildPagination(int totalPages, int totalItems) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _bgCard,
        border: Border(top: BorderSide(color: _border)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: Icon(Icons.chevron_left, color: _currentPage > 0 ? _textPrimary : _textMuted, size: 20.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: 12.w),
          ...List.generate(totalPages, (i) {
            final isActive = i == _currentPage;
            return GestureDetector(
              onTap: () => setState(() => _currentPage = i),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  gradient: isActive ? const LinearGradient(colors: [_examPrimary, _examLight]) : null,
                  color: isActive ? null : _bgElevated,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  "${i + 1}",
                  style: TextStyle(
                    color: isActive ? Colors.white : _textMuted,
                    fontSize: 12.sp,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
          SizedBox(width: 12.w),
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
            icon: Icon(Icons.chevron_right, color: _currentPage < totalPages - 1 ? _textPrimary : _textMuted, size: 20.sp),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(
            "Showing ${_currentPage * _itemsPerPage + 1}-${(_currentPage + 1) * _itemsPerPage > totalItems ? totalItems : (_currentPage + 1) * _itemsPerPage} of $totalItems",
            style: TextStyle(color: _textMuted, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  // ── Data Processing ──
  List<Map<String, dynamic>> _filterAndSortRankings() {
    var filtered = widget.rankings.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final roll = (r['rollNumber'] ?? '').toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return name.contains(query) || roll.contains(query);
    }).toList();

    switch (widget.sortBy) {
      case 'name':
        filtered.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      case 'percentage':
        filtered.sort((a, b) => (b['average'] ?? 0).compareTo(a['average'] ?? 0));
        break;
      case 'grade':
        filtered.sort((a, b) => _gradeValue(b['grade'] ?? 'F').compareTo(_gradeValue(a['grade'] ?? 'F')));
        break;
      case 'rank':
      default:
        filtered.sort((a, b) => (b['average'] ?? 0).compareTo(a['average'] ?? 0));
        break;
    }

    return filtered;
  }

  List<Map<String, dynamic>> _getPageItems(List<Map<String, dynamic>> all) {
    final start = _currentPage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, all.length);
    return all.sublist(start, end);
  }

  // ── Helpers ──
  double _calculateGPA(double average) {
    if (average >= 90) return 4.0;
    if (average >= 85) return 3.7;
    if (average >= 80) return 3.3;
    if (average >= 75) return 3.0;
    if (average >= 70) return 2.7;
    if (average >= 65) return 2.3;
    if (average >= 60) return 2.0;
    if (average >= 55) return 1.7;
    if (average >= 50) return 1.3;
    if (average >= 45) return 1.0;
    return 0.0;
  }

  int _gradeValue(String grade) {
    const values = {'A+': 11, 'A': 10, 'A-': 9, 'B+': 8, 'B': 7, 'B-': 6, 'C+': 5, 'C': 4, 'C-': 3, 'D': 2, 'F': 1};
    return values[grade] ?? 0;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+': case 'A': return _accentSuccess;
      case 'A-': case 'B+': case 'B': return const Color(0xFF22D3EE);
      case 'B-': case 'C+': case 'C': return _accentWarning;
      case 'C-': case 'D': return const Color(0xFFF97316);
      default: return _accentDanger;
    }
  }

  TextStyle _thStyle() => TextStyle(color: _textSecondary, fontSize: 11.sp, fontWeight: FontWeight.w700, letterSpacing: 0.5);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TOP 3 STUDENT HIGHLIGHT CARDS — Premium podium cards for top performers
// ═══════════════════════════════════════════════════════════════════════════════

class TopThreePodium extends StatelessWidget {
  final List<Map<String, dynamic>> topStudents;
  final bool isMobile;

  const TopThreePodium({
    super.key,
    required this.topStudents,
    required this.isMobile,
  });

  static const Color _bgCard       = Color(0xFF151B2B);
  static const Color _bgElevated   = Color(0xFF1E2538);
  static const Color _accentSuccess = Color(0xFF22C55E);
  static const Color _textPrimary   = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted     = Color(0xFF64748B);
  static const Color _border        = Color(0xFF2D3748);
  static const Color _examPrimary   = Color(0xFF8B5CF6);
  static const Color _examLight     = Color(0xFFA78BFA);

  @override
  Widget build(BuildContext context) {
    if (topStudents.isEmpty) return const SizedBox.shrink();

    final medals = [
      _MedalData("1st", const Color(0xFFFFD700), Icons.emoji_events, 1.0),
      _MedalData("2nd", const Color(0xFFC0C0C0), Icons.emoji_events, 0.9),
      _MedalData("3rd", const Color(0xFFCD7F32), Icons.emoji_events, 0.85),
    ];

    return isMobile
        ? Column(
      children: topStudents.take(3).toList().asMap().entries.map((e) {
        return _podiumCard(e.value, medals[e.key], isMobile);
      }).toList(),
    )
        : Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (topStudents.length > 1) Expanded(child: _podiumCard(topStudents[1], medals[1], isMobile)),
        SizedBox(width: 12.w),
        if (topStudents.isNotEmpty) Expanded(child: _podiumCard(topStudents[0], medals[0], isMobile)),
        SizedBox(width: 12.w),
        if (topStudents.length > 2) Expanded(child: _podiumCard(topStudents[2], medals[2], isMobile)),
      ],
    );
  }

  Widget _podiumCard(Map<String, dynamic> student, _MedalData medal, bool isMobile) {
    final avg = (student['average'] ?? 0) as double;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10.h : 0),
      padding: EdgeInsets.all(isMobile ? 16.w : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [medal.color.withOpacity(0.15), _bgCard],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: medal.color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: medal.color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Medal Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [medal.color, medal.color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(color: medal.color.withOpacity(0.4), blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(medal.icon, color: _bgCard, size: 14.sp),
                SizedBox(width: 4.w),
                Text(medal.label ?? "", style: TextStyle(color: _bgCard, fontSize: 12.sp, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          // Avatar
          Container(
            width: isMobile ? 56.w : 64.w,
            height: isMobile ? 56.w : 64.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_examPrimary, _examLight]),
              shape: BoxShape.circle,
              border: Border.all(color: medal.color, width: 3.w),
              boxShadow: [BoxShadow(color: _examPrimary.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Center(
              child: Text(
                (student['name'] ?? '?')[0].toUpperCase(),
                style: TextStyle(color: Colors.white, fontSize: isMobile ? 22.sp : 26.sp, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Name
          Text(
            student['name'] ?? 'Unknown',
            style: TextStyle(color: _textPrimary, fontSize: isMobile ? 15.sp : 16.sp, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            "Roll: ${student['rollNumber'] ?? '--'}",
            style: TextStyle(color: _textMuted, fontSize: 11.sp),
          ),
          SizedBox(height: 10.h),
          // Score
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _accentSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _accentSuccess.withOpacity(0.3)),
            ),
            child: Text(
              "${avg.toStringAsFixed(1)}%",
              style: TextStyle(color: _accentSuccess, fontSize: isMobile ? 18.sp : 20.sp, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            "Grade: ${student['grade'] ?? '--'}",
            style: TextStyle(color: medal.color, fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (medal.scale * 200).toInt().ms)
        .scale(duration: 600.ms, begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}

class _MedalData {
  final String label;
  final Color color;
  final IconData icon;
  final double scale;
  _MedalData(this.label, this.color, this.icon, this.scale);
}
