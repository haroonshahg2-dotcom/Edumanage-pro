import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import 'analytics_cards.dart' show AnalyticsCards, ClassPerformanceMeter, AISummaryCard, WeakStudentsAnalysis;
import 'report_chart.dart';
import 'student_ranking_table.dart' show StudentRankingTable, TopThreePodium;

// ═══════════════════════════════════════════════════════════════════════════════
//  REPORT DASHBOARD — Main layout composing all analytics sections
//  Orchestrates: Stats, Charts, Insights, Rankings, Exports in a
//  responsive, animated, enterprise-grade dashboard grid.
// ═══════════════════════════════════════════════════════════════════════════════

class ReportDashboard extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final Map<String, dynamic> stats;
  final Map<String, int> gradeDist;
  final Map<String, double> subjectPerf;
  final List<Map<String, dynamic>> topStudents;
  final List<Map<String, dynamic>> rankings;
  final List<Map<String, dynamic>> weakStudents;
  final Map<String, dynamic>? examData;
  final String? selectedClass;
  final String? selectedSubject;
  final String searchQuery;
  final String sortBy;
  final VoidCallback onExportPDF;
  final VoidCallback onPrint;
  final VoidCallback onExportExcel;
  final VoidCallback onShare;

  const ReportDashboard({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.stats,
    required this.gradeDist,
    required this.subjectPerf,
    required this.topStudents,
    required this.rankings,
    required this.weakStudents,
    required this.examData,
    required this.selectedClass,
    required this.selectedSubject,
    required this.searchQuery,
    required this.sortBy,
    required this.onExportPDF,
    required this.onPrint,
    required this.onExportExcel,
    required this.onShare,
  });

  // ── Theme ──
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Report Header ──
          _buildReportHeader().animate().fadeIn(duration: 400.ms).slideY(
            begin: -10, end: 0, duration: 500.ms, curve: Curves.easeOutCubic,
          ),
          SizedBox(height: 16.h),

          // ── Stats Grid ──
          AnalyticsCards(isMobile: isMobile, stats: stats)
              .animate().fadeIn(duration: 400.ms, delay: 100.ms),
          SizedBox(height: 16.h),

          // ── Export Actions ──
          _buildExportActions().animate().fadeIn(duration: 400.ms, delay: 150.ms),
          SizedBox(height: 16.h),

          // ── Top 3 Podium ──
          if (topStudents.isNotEmpty) ...[
            _buildSectionTitle("🏆 Top Performers", "Highest scoring students"),
            SizedBox(height: 12.h),
            TopThreePodium(topStudents: topStudents, isMobile: isMobile),
            SizedBox(height: 16.h),
          ],

          // ── Charts Row ──
          isMobile
              ? Column(
            children: [
              ReportCharts.buildPassFailChart(stats, isMobile),
              SizedBox(height: 12.h),
              ReportCharts.buildGradeChart(gradeDist, isMobile),
              SizedBox(height: 12.h),
              ReportCharts.buildSubjectChart(subjectPerf, isMobile),
              SizedBox(height: 12.h),
              ReportCharts.buildTrendChart(subjectPerf, isMobile),
              SizedBox(height: 12.h),
              ReportCharts.buildDifficultyChart(subjectPerf, isMobile),
            ],
          )
              : Column(
            children: [
              // Row 1: Pie + Grade + Subject
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ReportCharts.buildPassFailChart(stats, isMobile)),
                  SizedBox(width: 12.w),
                  Expanded(child: ReportCharts.buildGradeChart(gradeDist, isMobile)),
                  SizedBox(width: 12.w),
                  Expanded(child: ReportCharts.buildSubjectChart(subjectPerf, isMobile)),
                ],
              ),
              SizedBox(height: 12.h),
              // Row 2: Trend + Difficulty + Performance Meter
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: ReportCharts.buildTrendChart(subjectPerf, isMobile)),
                  SizedBox(width: 12.w),
                  Expanded(child: ReportCharts.buildDifficultyChart(subjectPerf, isMobile)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _glassCard(
                      child: Column(
                        children: [
                          _chartHeader("Performance Meter", "Overall class health"),
                          SizedBox(height: 14.h),
                          ClassPerformanceMeter(
                            passRate: (stats['passRate'] ?? 0) as double,
                            isMobile: isMobile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── AI Insights + Weak Students ──
          isMobile
              ? Column(
            children: [
              AISummaryCard(
                stats: stats,
                subjectPerf: subjectPerf,
                weakStudents: weakStudents,
                isMobile: isMobile,
              ),
              SizedBox(height: 12.h),
              _buildWeakStudentsCard(),
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AISummaryCard(
                  stats: stats,
                  subjectPerf: subjectPerf,
                  weakStudents: weakStudents,
                  isMobile: isMobile,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: _buildWeakStudentsCard(),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Student Rankings Table ──
          _buildSectionTitle("📊 Student Rankings", "Complete class ranking with pagination"),
          SizedBox(height: 12.h),
          StudentRankingTable(
            rankings: rankings,
            searchQuery: searchQuery,
            sortBy: sortBy,
            isMobile: isMobile,
            isDesktop: isDesktop,
          ),
        ],
      ),
    );
  }

  // ── Report Header ──
  Widget _buildReportHeader() {
    final examName = (examData?['name'] ?? 'Unknown Exam').toString();
    final examType = (examData?['type'] ?? '--').toString();
    final examDate = examData?['examDate'];
    final dateStr = examDate is Timestamp
        ? DateFormat('dd MMM yyyy').format(examDate.toDate())
        : 'N/A';
    final passRate = (stats['passRate'] ?? 0) as double;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.w : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_examPrimary.withOpacity(0.12), _bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _examPrimary.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: _examPrimary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12.w : 14.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_examPrimary, _examLight]),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [BoxShadow(color: _examPrimary.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Icon(Icons.summarize, color: Colors.white, size: isMobile ? 24.sp : 28.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examName,
                  style: TextStyle(color: _textPrimary, fontSize: isMobile ? 18.sp : 20.sp, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Class ${selectedClass ?? '--'}  •  $examType  •  $dateStr",
                  style: TextStyle(color: _textSecondary, fontSize: isMobile ? 12.sp : 13.sp),
                ),
                if (selectedSubject != null) ...[
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _accentInfo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: _accentInfo.withOpacity(0.3)),
                    ),
                    child: Text(
                      "Subject: ${selectedSubject ?? ""}",
                      style: TextStyle(color: _accentInfo, fontSize: 11.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.w : 14.w, vertical: isMobile ? 6.h : 8.h),
            decoration: BoxDecoration(
              color: passRate >= 75
                  ? _accentSuccess.withOpacity(0.12)
                  : passRate >= 50
                  ? _accentWarning.withOpacity(0.12)
                  : _accentDanger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: passRate >= 75
                    ? _accentSuccess.withOpacity(0.3)
                    : passRate >= 50
                    ? _accentWarning.withOpacity(0.3)
                    : _accentDanger.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "${passRate.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: passRate >= 75 ? _accentSuccess : passRate >= 50 ? _accentWarning : _accentDanger,
                    fontSize: isMobile ? 20.sp : 22.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text("Pass Rate", style: TextStyle(color: _textMuted, fontSize: 10.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Export Actions ──
  Widget _buildExportActions() {
    final actions = [
      _ExportAction("Print Report", Icons.print_outlined, onPrint, _textPrimary),
      _ExportAction("Download PDF", Icons.picture_as_pdf_outlined, onExportPDF, _accentDanger),
      _ExportAction("Export Excel", Icons.table_chart_outlined, onExportExcel, _accentSuccess),
      _ExportAction("Share Summary", Icons.share_outlined, onShare, _accentInfo),
    ];

    return isMobile
        ? Column(
      children: actions.map((a) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: SizedBox(
          width: double.infinity,
          child: _exportBtn(a.label, a.icon, a.onTap, a.color),
        ),
      )).toList(),
    )
        : Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: _exportBtn(a.label, a.icon, a.onTap, a.color),
        ),
      )).toList(),
    );
  }

  Widget _exportBtn(String label, IconData icon, VoidCallback onTap, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.04), Colors.white.withOpacity(0.01)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(label ?? "", style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Weak Students Card ──
  Widget _buildWeakStudentsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14.w : 18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.01)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _accentDanger, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text("At-Risk Students", style: TextStyle(
                    color: _textPrimary, fontSize: isMobile ? 14.sp : 16.sp, fontWeight: FontWeight.w800,
                  )),
                  const Spacer(),
                  if (weakStudents.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _accentDanger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: _accentDanger.withOpacity(0.3)),
                      ),
                      child: Text(
                        "${weakStudents.length} students",
                        style: TextStyle(color: _accentDanger, fontSize: 10.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              Text("Students requiring academic intervention", style: TextStyle(color: _textMuted, fontSize: 11.sp)),
              SizedBox(height: 14.h),
              WeakStudentsAnalysis(weakStudents: weakStudents, isMobile: isMobile),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 450.ms);
  }

  // ── Section Title ──
  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Text(title ?? "", style: TextStyle(
          color: _textPrimary, fontSize: isMobile ? 15.sp : 17.sp, fontWeight: FontWeight.w800,
        )),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(subtitle ?? "", style: TextStyle(
            color: _textMuted, fontSize: isMobile ? 11.sp : 12.sp,
          ), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ── Glass Card ──
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14.w : 18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.03), Colors.white.withOpacity(0.01)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: child,
        ),
      ),
    );
  }

  // ── Chart Header ──
  Widget _chartHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title ?? "", style: TextStyle(
          color: _textPrimary, fontSize: isMobile ? 14.sp : 16.sp, fontWeight: FontWeight.w700,
        )),
        SizedBox(height: 2.h),
        Text(subtitle ?? "", style: TextStyle(color: _textMuted, fontSize: isMobile ? 10.sp : 11.sp)),
      ],
    );
  }
}

class _ExportAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  _ExportAction(this.label, this.icon, this.onTap, this.color);
}
