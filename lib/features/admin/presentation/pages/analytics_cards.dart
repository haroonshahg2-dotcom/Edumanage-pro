import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

// ═══════════════════════════════════════════════════════════════════════════════
//  ANALYTICS CARDS — Enterprise stat cards with glassmorphism, animations,
//  trend indicators, and performance meters. Fully responsive.
// ═══════════════════════════════════════════════════════════════════════════════

class AnalyticsCards extends StatelessWidget {
  final bool isMobile;
  final Map<String, dynamic> stats;

  const AnalyticsCards({
    super.key,
    required this.isMobile,
    required this.stats,
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
    final items = [
      _StatData("Total Students", "${stats['totalStudents'] ?? 0}", Icons.people_alt_outlined,
          _examPrimary, "Enrolled", stats['totalStudents'] != null),
      _StatData("Passed", "${stats['passed'] ?? 0}", Icons.check_circle_outline,
          _accentSuccess, "${(stats['passRate'] ?? 0).toStringAsFixed(1)}% rate", true),
      _StatData("Failed", "${stats['failed'] ?? 0}", Icons.cancel_outlined,
          _accentDanger, "${(stats['failRate'] ?? 0).toStringAsFixed(1)}% rate", true),
      _StatData("Pass %", "${(stats['passRate'] ?? 0).toStringAsFixed(1)}%", Icons.trending_up,
          _accentInfo, "Class performance", true),
      _StatData("Average", "${(stats['average'] ?? 0).toStringAsFixed(1)}%", Icons.analytics_outlined,
          _accentWarning, "Class average", true),
      _StatData("Highest", "${(stats['highest'] ?? 0).toStringAsFixed(0)}", Icons.emoji_events_outlined,
          const Color(0xFFFFB800), "Top score", true),
      _StatData("Lowest", "${(stats['lowest'] ?? 0).toStringAsFixed(0)}", Icons.trending_down,
          _accentDanger, "Needs attention", true),
      _StatData("Subjects", "${stats['totalSubjects'] ?? 0}", Icons.menu_book_outlined,
          const Color(0xFFEC4899), "Active subjects", true),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : (items.length > 6 ? 4 : 3),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: isMobile ? 1.15 : 1.4,
      children: items.asMap().entries.map((e) {
        return _glassStatCard(e.value)
            .animate(delay: (e.key * 80).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 20, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
      }).toList(),
    );
  }

  Widget _glassStatCard(_StatData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14.w : 18.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.04),
                Colors.white.withOpacity(0.01),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: data.color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [data.color.withOpacity(0.2), data.color.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: data.color.withOpacity(0.15)),
                    ),
                    child: Icon(data.icon, color: data.color, size: isMobile ? 18.sp : 22.sp),
                  ),
                  if (data.hasTrend)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.color == _accentDanger ? Icons.arrow_downward : Icons.arrow_upward,
                            color: data.color, size: 10.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text("Live", style: TextStyle(color: data.color, fontSize: 9.sp, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
              // Value + Label
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: isMobile ? 22.sp : 26.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    data.title,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    data.subtitle,
                    style: TextStyle(
                      color: data.color,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
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
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CLASS PERFORMANCE METER — Circular gauge showing overall class health
// ═══════════════════════════════════════════════════════════════════════════════

class ClassPerformanceMeter extends StatelessWidget {
  final double passRate;
  final bool isMobile;

  const ClassPerformanceMeter({
    super.key,
    required this.passRate,
    required this.isMobile,
  });

  static const Color _textPrimary   = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _accentSuccess = Color(0xFF22C55E);
  static const Color _accentWarning = Color(0xFFF59E0B);
  static const Color _accentDanger  = Color(0xFFEF4444);
  static const Color _examPrimary   = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final color = passRate >= 75 ? _accentSuccess : passRate >= 50 ? _accentWarning : _accentDanger;
    final label = passRate >= 75 ? "Excellent" : passRate >= 50 ? "Average" : "Critical";
    final size = isMobile ? 140.w : 180.w;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 10.w,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation(Colors.transparent),
              ),
              // Animated progress
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: passRate / 100),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 10.w,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
              // Center text
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${passRate.toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: isMobile ? 24.sp : 28.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          "Class Performance Index",
          style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            passRate >= 75 ? "🎉 Outstanding Results" : passRate >= 50 ? "📊 Needs Improvement" : "⚠️ Intervention Required",
            style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AI SUMMARY CARD — Smart insights section with auto-generated observations
// ═══════════════════════════════════════════════════════════════════════════════

class AISummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Map<String, double> subjectPerf;
  final List<Map<String, dynamic>> weakStudents;
  final bool isMobile;

  const AISummaryCard({
    super.key,
    required this.stats,
    required this.subjectPerf,
    required this.weakStudents,
    required this.isMobile,
  });

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

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();
    final bestSubject = _getBestSubject();
    final worstSubject = _getWorstSubject();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16.w : 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_examPrimary.withOpacity(0.1), _bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _examPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _examPrimary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.auto_awesome, color: _examPrimary, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Text("Smart Insights", style: TextStyle(
                color: _textPrimary, fontSize: isMobile ? 15.sp : 17.sp, fontWeight: FontWeight.w800,
              )),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: _examPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: _examPrimary.withOpacity(0.3)),
                ),
                child: Text("AI-Powered", style: TextStyle(
                  color: _examPrimary, fontSize: 9.sp, fontWeight: FontWeight.w700,
                )),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          // Key Metrics Row
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _insightChip("Best Subject: ${bestSubject ?? 'N/A'}", Icons.star, _accentSuccess),
              _insightChip("Weakest: ${worstSubject ?? 'N/A'}", Icons.warning_amber, _accentWarning),
              _insightChip("At Risk: ${weakStudents.length} students", Icons.priority_high, _accentDanger),
            ],
          ),
          SizedBox(height: 12.h),
          // Insight List
          ...insights.map((insight) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 4.h),
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: _examPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(color: _textSecondary, fontSize: 12.sp, height: 1.5),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  List<String> _generateInsights() {
    final insights = <String>[];
    final passRate = (stats['passRate'] ?? 0) as double;
    final average = (stats['average'] ?? 0) as double;
    final total = stats['totalStudents'] ?? 0;
    final failed = stats['failed'] ?? 0;

    if (passRate >= 80) {
      insights.add("🎉 Exceptional performance! $passRate% of students passed. The class demonstrates strong academic excellence.");
    } else if (passRate >= 60) {
      insights.add("📊 Moderate performance with $passRate% pass rate. Focus on remedial programs for struggling students.");
    } else {
      insights.add("⚠️ Critical alert: Only $passRate% passed. Immediate academic intervention and counseling recommended.");
    }

    if (average >= 75) {
      insights.add("Class average of ${average.toStringAsFixed(1)}% indicates strong overall comprehension of subjects.");
    } else if (average >= 50) {
      insights.add("Class average of ${average.toStringAsFixed(1)}% suggests need for curriculum review and teaching methodology assessment.");
    } else {
      insights.add("Class average below 50% signals systemic issues requiring administrative attention and resource allocation.");
    }

    if (failed > 0) {
      final ratio = total > 0 ? (failed / total * 100).toStringAsFixed(1) : '0';
      insights.add("$failed students ($ratio%) require immediate attention. Consider personalized tutoring and parent-teacher meetings.");
    }

    if (subjectPerf.isNotEmpty) {
      final avgPerf = subjectPerf.values.reduce((a, b) => a + b) / subjectPerf.length;
      insights.add("Subject performance variance: ${avgPerf.toStringAsFixed(1)}% average across ${subjectPerf.length} subjects.");
    }

    return insights;
  }

  String? _getBestSubject() {
    if (subjectPerf.isEmpty) return null;
    final entry = subjectPerf.entries.reduce((a, b) => a.value > b.value ? a : b);
    return "${entry.key} (${entry.value.toStringAsFixed(1)}%)";
  }

  String? _getWorstSubject() {
    if (subjectPerf.isEmpty) return null;
    final entry = subjectPerf.entries.reduce((a, b) => a.value < b.value ? a : b);
    return "${entry.key} (${entry.value.toStringAsFixed(1)}%)";
  }

  Widget _insightChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(text ?? "", style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WEAK STUDENTS ANALYSIS — At-risk student cards with intervention flags
// ═══════════════════════════════════════════════════════════════════════════════

class WeakStudentsAnalysis extends StatelessWidget {
  final List<Map<String, dynamic>> weakStudents;
  final bool isMobile;

  const WeakStudentsAnalysis({
    super.key,
    required this.weakStudents,
    required this.isMobile,
  });

  static const Color _bgCard       = Color(0xFF151B2B);
  static const Color _bgElevated   = Color(0xFF1E2538);
  static const Color _accentDanger  = Color(0xFFEF4444);
  static const Color _accentWarning = Color(0xFFF59E0B);
  static const Color _textPrimary   = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted     = Color(0xFF64748B);
  static const Color _border        = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    if (weakStudents.isEmpty) {
      return _emptyState("No at-risk students", "All students are performing well!");
    }

    final displayList = weakStudents.take(isMobile ? 5 : 8).toList();

    return Column(
      children: [
        ...displayList.asMap().entries.map((e) {
          final s = e.value;
          final avg = (s['average'] ?? 0) as double;
          final severity = avg < 30 ? 'Critical' : avg < 40 ? 'High' : 'Medium';
          final severityColor = avg < 30 ? _accentDanger : avg < 40 ? const Color(0xFFF97316) : _accentWarning;

          return Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: severityColor.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: severityColor.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      (s['name'] ?? '?')[0].toUpperCase(),
                      style: TextStyle(color: severityColor, fontSize: 14.sp, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['name'] ?? 'Unknown',
                        style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Roll: ${s['rollNumber'] ?? '--'}  •  ${s['subjectsCount'] ?? 0} subjects",
                        style: TextStyle(color: _textMuted, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${avg.toStringAsFixed(1)}%",
                      style: TextStyle(color: severityColor, fontSize: 16.sp, fontWeight: FontWeight.w900),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(color: severityColor, fontSize: 9.sp, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        if (weakStudents.length > (isMobile ? 5 : 8))
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              "+${weakStudents.length - (isMobile ? 5 : 8)} more at-risk students",
              style: TextStyle(color: _textMuted, fontSize: 11.sp),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return SizedBox(
      height: 120.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: _accentDanger.withOpacity(0.3), size: 36.sp),
            SizedBox(height: 8.h),
            Text(title ?? "", style: TextStyle(color: _textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 2.h),
            Text(subtitle ?? "", style: TextStyle(color: _textMuted, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool hasTrend;
  _StatData(this.title, this.value, this.icon, this.color, this.subtitle, this.hasTrend);
}
