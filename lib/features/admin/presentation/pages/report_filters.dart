import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

// ═══════════════════════════════════════════════════════════════════════════════
//  REPORT FILTERS — Enterprise-grade filter bar with glassmorphism effects
//  Supports: Exam, Class, Subject, Date Range, Search, Sort, Generate, Reset
// ═══════════════════════════════════════════════════════════════════════════════

class ReportFilters extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final CollectionReference examsRef;
  final String? selectedExam;
  final String? selectedClass;
  final String? selectedSubject;
  final String searchQuery;
  final String sortBy; // Non-nullable: 'rank' | 'name' | 'percentage' | 'grade' // Always 'rank', 'name', 'percentage', or 'grade'
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool isGenerating;
  final ValueChanged<String?> onExamChanged;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;
  final VoidCallback onGenerate;
  final VoidCallback onReset;

  const ReportFilters({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.examsRef,
    required this.selectedExam,
    required this.selectedClass,
    required this.selectedSubject,
    required this.searchQuery,
    required this.sortBy,
    required this.dateFrom,
    required this.dateTo,
    required this.isGenerating,
    required this.onExamChanged,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.onGenerate,
    required this.onReset,
  });

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
    return _glassCard(
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Report Filters"),
          SizedBox(height: 12.h),
          _buildExamSelector(),
          SizedBox(height: 10.h),
          _buildClassSelector(),
          SizedBox(height: 10.h),
          _buildSubjectSelector(),
          SizedBox(height: 10.h),
          _buildSearchField(),
          SizedBox(height: 10.h),
          _buildSortDropdown(),
          SizedBox(height: 10.h),
          _buildDateRangeFilters(context),
          SizedBox(height: 14.h),
          _buildActionButtons(),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_alt, color: _examPrimary, size: 18.sp),
              SizedBox(width: 8.w),
              Text("Report Filters", style: TextStyle(
                color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700,
              )),
              const Spacer(),
              if (selectedExam != null || selectedClass != null)
                _textButton("Reset All", Icons.refresh, onReset),
            ],
          ),
          SizedBox(height: 14.h),
          // Row 1: Core selectors
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildExamSelector()),
              SizedBox(width: 12.w),
              Expanded(child: _buildClassSelector()),
              SizedBox(width: 12.w),
              Expanded(child: _buildSubjectSelector()),
              SizedBox(width: 12.w),
              Expanded(child: _buildSortDropdown()),
            ],
          ),
          SizedBox(height: 12.h),
          // Row 2: Search + Date + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(flex: 2, child: _buildSearchField()),
              SizedBox(width: 12.w),
              Expanded(child: _buildDateRangeFilters(context)),
              SizedBox(width: 16.w),
              _buildGenerateButton(),
            ],
          ),
        ],
      ),
    );
  }

  // ── Glassmorphism Card Wrapper ──
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14.w : 18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.03),
                Colors.white.withOpacity(0.01),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Section Title ──
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(Icons.filter_list_alt, color: _examPrimary, size: 18.sp),
        SizedBox(width: 8.w),
        Text(title ?? "", style: TextStyle(
          color: _textPrimary, fontSize: 15.sp, fontWeight: FontWeight.w700,
        )),
        const Spacer(),
        if (selectedExam != null || selectedClass != null)
          _textButton("Reset", Icons.refresh, onReset),
      ],
    );
  }

  // ── Exam Selector ──
  Widget _buildExamSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: examsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _buildErrorField("Error loading exams");
        if (!snapshot.hasData) return _buildShimmerField();
        final exams = snapshot.data!.docs;
        final ids = exams.map((e) => e.id).toSet();
        final safe = ids.contains(selectedExam) ? selectedExam : null;
        return _dropdownField(
          label: "Select Exam *",
          value: safe,
          hint: "Choose exam",
          items: exams.map((e) {
            final d = e.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: e.id,
              child: Text("${d['name'] ?? 'Unnamed'} (${d['type'] ?? '--'})",
                  style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
            );
          }).toList(),
          onChanged: onExamChanged,
          icon: Icons.assignment_outlined,
        );
      },
    );
  }

  // ── Class Selector ──
  Widget _buildClassSelector() {
    if (selectedExam == null) {
      return _disabledField("Select Class *", "Select exam first", Icons.class_);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: examsRef.doc(selectedExam!).collection('classSubjects').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _disabledField("Select Class *", "No classes found", Icons.info_outline, isWarning: true);
        }
        final classes = snap.data!.docs
            .map((d) => ((d.data() as Map<String, dynamic>)['className'] ?? '').toString())
            .toSet().toList()..sort();
        return _dropdownField(
          label: "Select Class *",
          value: classes.contains(selectedClass) ? selectedClass : null,
          hint: "Choose class",
          items: classes.map((c) => DropdownMenuItem(
            value: c,
            child: Text("Class $c", style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
          )).toList(),
          onChanged: onClassChanged,
          icon: Icons.school_outlined,
        );
      },
    );
  }

  // ── Subject Selector ──
  Widget _buildSubjectSelector() {
    if (selectedExam == null || selectedClass == null) {
      return _disabledField("Subject (Optional)", "Select exam & class", Icons.filter_list);
    }
    return StreamBuilder<QuerySnapshot>(
      stream: examsRef.doc(selectedExam!).collection('classSubjects')
          .where('className', isEqualTo: selectedClass).snapshots(),
      builder: (context, snap) {
        final subjects = (snap.data?.docs ?? [])
            .map((d) => ((d.data() as Map<String, dynamic>)['subject'] ?? '').toString())
            .toList();
        return _dropdownField(
          label: "Subject (Optional)",
          value: selectedSubject,
          hint: "All Subjects",
          items: [
            DropdownMenuItem(value: null, child: Text("All Subjects", style: TextStyle(color: _textPrimary, fontSize: 13.sp))),
            ...subjects.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s ?? "", style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
            )),
          ],
          onChanged: onSubjectChanged,
          icon: Icons.book_outlined,
        );
      },
    );
  }

  // ── Sort Dropdown ──
  Widget _buildSortDropdown() {
    // ✅ SAHI:
    final safeSort = (sortBy?.isNotEmpty ?? false) ? sortBy : 'rank';
    return _dropdownField(
      label: "Sort By",
      value: safeSort,
      hint: "Sort by",
      items: [
        DropdownMenuItem(value: 'rank', child: Text("Rank", style: TextStyle(color: _textPrimary, fontSize: 13.sp))),
        DropdownMenuItem(value: 'name', child: Text("Name", style: TextStyle(color: _textPrimary, fontSize: 13.sp))),
        DropdownMenuItem(value: 'percentage', child: Text("Percentage", style: TextStyle(color: _textPrimary, fontSize: 13.sp))),
        DropdownMenuItem(value: 'grade', child: Text("Grade", style: TextStyle(color: _textPrimary, fontSize: 13.sp))),
      ],
      onChanged: (val) => onSortChanged(val?.isNotEmpty == true ? val! : 'rank'),
      icon: Icons.sort,
    );
  }

  // ── Search Field ──
  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Search Student", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: _textMuted, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  style: TextStyle(color: _textPrimary, fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: "Search by name or roll...",
                    hintStyle: TextStyle(color: _textMuted, fontSize: 13.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              if (searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () => onSearchChanged(''),
                  child: Icon(Icons.close, color: _textMuted, size: 16.sp),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Date Range Filters ──
  Widget _buildDateRangeFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date Range", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(
              child: _dateChip(
                label: dateFrom != null ? "${_formatDate(dateFrom!)}" : "From",
                icon: Icons.calendar_today,
                onTap: () => _pickDate(context, true),
                isActive: dateFrom != null,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _dateChip(
                label: dateTo != null ? "${_formatDate(dateTo!)}" : "To",
                icon: Icons.calendar_today,
                onTap: () => _pickDate(context, false),
                isActive: dateTo != null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateChip({required String label, required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive ? _accentInfo.withOpacity(0.1) : _bgElevated,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: isActive ? _accentInfo.withOpacity(0.4) : _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? _accentInfo : _textMuted, size: 14.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(label ?? "", style: TextStyle(
                color: isActive ? _accentInfo : _textMuted,
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _examPrimary,
            surface: _bgCard,
            onSurface: _textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      isFrom ? onDateFromChanged(picked) : onDateToChanged(picked);
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  // ── Action Buttons ──
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _secondaryBtn("Reset", Icons.refresh, onReset),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: _primaryBtn(
            isGenerating ? "Generating..." : "Generate Report",
            Icons.assessment,
            (selectedExam != null && selectedClass != null && !isGenerating) ? onGenerate : null,
            isLoading: isGenerating,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return _primaryBtn(
      isGenerating ? "Generating..." : "Generate Report",
      Icons.assessment,
      (selectedExam != null && selectedClass != null && !isGenerating) ? onGenerate : null,
      isLoading: isGenerating,
    );
  }

  // ── Reusable Dropdown ──
  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label ?? "", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              dropdownColor: _bgElevated,
              hint: Row(
                children: [
                  Icon(icon, color: _textMuted, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(hint ?? "", style: TextStyle(color: _textMuted, fontSize: 13.sp)),
                ],
              ),
              style: TextStyle(color: _textPrimary, fontSize: 13.sp),
              icon: Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 18.sp),
              items: items,
              onChanged: onChanged,
              selectedItemBuilder: (context) => items.map((item) {
                return Row(
                  children: [
                    Icon(icon, color: _examPrimary, size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item.value == null ? hint : (item.child as Text).data!,
                        style: TextStyle(color: _textPrimary, fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Disabled Field ──
  Widget _disabledField(String label, String message, IconData icon, {bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label ?? "", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: isWarning ? _accentWarning.withOpacity(0.3) : _border),
          ),
          child: Row(
            children: [
              Icon(icon, color: isWarning ? _accentWarning : _textMuted, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(message ?? "", style: TextStyle(
                  color: isWarning ? _accentWarning : _textMuted,
                  fontSize: 13.sp,
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shimmer Loading ──
  Widget _buildShimmerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Exam *", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Shimmer.fromColors(
          baseColor: _bgCard,
          highlightColor: _bgElevated,
          child: Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _border),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error Field ──
  Widget _buildErrorField(String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Exam *", style: TextStyle(color: _textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: _accentDanger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _accentDanger.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: _accentDanger, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(child: Text(message ?? "", style: TextStyle(color: _accentDanger, fontSize: 12.sp))),
            ],
          ),
        ),
      ],
    );
  }

  // ── Buttons ──
  Widget _primaryBtn(String label, IconData icon, VoidCallback? onTap, {bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: onTap == null ? null : const LinearGradient(colors: [_examPrimary, _examLight]),
        color: onTap == null ? _bgElevated : null,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: isLoading
                ? SizedBox(
              width: 18.w, height: 18.w,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: onTap == null ? _textMuted : Colors.white, size: 16.sp),
                SizedBox(width: 6.w),
                Text(label ?? "", style: TextStyle(
                  color: onTap == null ? _textMuted : Colors.white,
                  fontSize: 13.sp, fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _secondaryBtn(String label, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: _textPrimary, size: 16.sp),
                SizedBox(width: 6.w),
                Text(label ?? "", style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accentInfo, size: 14.sp),
          SizedBox(width: 4.w),
          Text(label ?? "", style: TextStyle(color: _accentInfo, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
