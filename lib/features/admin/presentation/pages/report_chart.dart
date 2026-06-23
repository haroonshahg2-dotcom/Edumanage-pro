import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

// ═══════════════════════════════════════════════════════════════════════════════
//  REPORT CHARTS — Enterprise-grade chart collection using fl_chart
//  Pass/Fail Pie, Grade Distribution Bar, Subject Performance Bar,
//  Performance Trend Line, and responsive chart cards.
// ═══════════════════════════════════════════════════════════════════════════════

class ReportCharts {
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

  // ── Pass/Fail Pie Chart ──
  static Widget buildPassFailChart(Map<String, dynamic> stats, bool isMobile) {
    final passed = (stats['passed'] ?? 0) as int;
    final failed = (stats['failed'] ?? 0) as int;
    final total = passed + failed;
    if (total == 0) return _chartCard("Pass / Fail", "No data available", _noDataWidget(), isMobile);

    return _chartCard(
      "Pass / Fail Distribution",
      "$passed passed  •  $failed failed  •  $total total",
      SizedBox(
        height: isMobile ? 200.h : 240.h,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: isMobile ? 30.w : 40.w,
                  startDegreeOffset: -90,
                  sections: [
                    PieChartSectionData(
                      value: passed.toDouble(),
                      color: _accentSuccess,
                      radius: isMobile ? 45.w : 55.w,
                      title: "${((passed / total) * 100).toStringAsFixed(0)}%",
                      titleStyle: TextStyle(color: Colors.white, fontSize: isMobile ? 11.sp : 13.sp, fontWeight: FontWeight.w800),
                      titlePositionPercentageOffset: 0.55,
                      badgeWidget: passed > 0 ? _badgeIcon(Icons.check_circle, _accentSuccess) : null,
                      badgePositionPercentageOffset: 1.1,
                    ),
                    PieChartSectionData(
                      value: failed.toDouble(),
                      color: _accentDanger,
                      radius: isMobile ? 40.w : 50.w,
                      title: "${((failed / total) * 100).toStringAsFixed(0)}%",
                      titleStyle: TextStyle(color: Colors.white, fontSize: isMobile ? 11.sp : 13.sp, fontWeight: FontWeight.w800),
                      titlePositionPercentageOffset: 0.55,
                      badgeWidget: failed > 0 ? _badgeIcon(Icons.cancel, _accentDanger) : null,
                      badgePositionPercentageOffset: 1.1,
                    ),
                  ],
                ),

              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem("Passed", passed.toString(), _accentSuccess, isMobile),
                  SizedBox(height: isMobile ? 10.h : 14.h),
                  _legendItem("Failed", failed.toString(), _accentDanger, isMobile),
                  SizedBox(height: isMobile ? 10.h : 14.h),
                  _legendItem("Total", total.toString(), _textMuted, isMobile),
                  SizedBox(height: isMobile ? 10.h : 14.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _accentSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: _accentSuccess.withOpacity(0.2)),
                    ),
                    child: Text(
                      "Pass Rate: ${(stats['passRate'] ?? 0).toStringAsFixed(1)}%",
                      style: TextStyle(color: _accentSuccess, fontSize: isMobile ? 10.sp : 11.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isMobile,
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ── Grade Distribution Bar Chart ──
  static Widget buildGradeChart(Map<String, int> gradeDist, bool isMobile) {
    final grades = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D', 'F'];
    final maxCount = gradeDist.values.isEmpty ? 0 : gradeDist.values.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return _chartCard("Grade Distribution", "No grades recorded", _noDataWidget(), isMobile);

    return _chartCard(
      "Grade Distribution",
      "Student count by grade band",
      SizedBox(
        height: isMobile ? 200.h : 240.h,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxCount + 2).toDouble(),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final idx = v.toInt();
                    if (idx >= 0 && idx < grades.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(grades[idx] ?? "", style: TextStyle(
                          color: _textMuted, fontSize: isMobile ? 9.sp : 10.sp, fontWeight: FontWeight.w700,
                        )),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: grades.asMap().entries.map((e) {
              final count = gradeDist[e.value] ?? 0;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: count.toDouble(),
                    color: _getGradeColor(e.value),
                    width: isMobile ? 14.w : 18.w,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (maxCount + 2).toDouble(),
                      color: Colors.white.withOpacity(0.02),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

        ),
      ),
      isMobile,
    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
  }

  // ── Subject Performance Bar Chart ──
  static Widget buildSubjectChart(Map<String, double> subjectPerf, bool isMobile) {
    if (subjectPerf.isEmpty) {
      return _chartCard("Subject Performance", "No subject data", _noDataWidget(), isMobile);
    }
    final subjects = subjectPerf.keys.toList();
    final values = subjectPerf.values.toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return _chartCard(
      "Subject Performance",
      "Average percentage by subject",
      SizedBox(
        height: isMobile ? 200.h : 240.h,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxVal + 10).clamp(0, 100).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (v) => FlLine(color: _border, strokeWidth: 0.5),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 30.w,
                  getTitlesWidget: (v, m) => Text("${v.toInt()}", style: TextStyle(
                    color: _textMuted, fontSize: isMobile ? 8.sp : 9.sp,
                  )),
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final idx = v.toInt();
                    if (idx >= 0 && idx < subjects.length) {
                      final subj = subjects[idx];
                      return Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          subj.length > 8 ? "${subj.substring(0, 6)}.." : subj,
                          style: TextStyle(color: _textMuted, fontSize: isMobile ? 8.sp : 9.sp, fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: values.asMap().entries.map((e) {
              final val = e.value;
              final color = val >= 80 ? _accentSuccess : val >= 60 ? _accentWarning : _accentDanger;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: val,
                    color: color,
                    width: isMobile ? 18.w : 24.w,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: 100,
                      color: Colors.white.withOpacity(0.02),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

        ),
      ),
      isMobile,
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  // ── Performance Trend Line Chart (Simulated from averages) ──
  static Widget buildTrendChart(Map<String, double> subjectPerf, bool isMobile) {
    if (subjectPerf.isEmpty) {
      return _chartCard("Performance Trend", "No trend data", _noDataWidget(), isMobile);
    }
    final values = subjectPerf.values.toList();
    final spots = values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);

    return _chartCard(
      "Performance Trend",
      "Subject-wise progression pattern",
      SizedBox(
        height: isMobile ? 180.h : 220.h,
        child: LineChart(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
          LineChartData(
            minY: (minVal - 10).clamp(0, 100).toDouble(),
            maxY: (maxVal + 10).clamp(0, 100).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (v) => FlLine(color: _border, strokeWidth: 0.5),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 30.w,
                  getTitlesWidget: (v, m) => Text("${v.toInt()}", style: TextStyle(
                    color: _textMuted, fontSize: isMobile ? 8.sp : 9.sp,
                  )),
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: _examPrimary,
                barWidth: 3.w,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 5.w,
                    color: _examPrimary,
                    strokeWidth: 2.w,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      _examPrimary.withOpacity(0.3),
                      _examPrimary.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),

        ),
      ),
      isMobile,
    ).animate().fadeIn(duration: 400.ms, delay: 350.ms);
  }

  // ── Subject Difficulty Analysis (Horizontal Bar) ──
  static Widget buildDifficultyChart(Map<String, double> subjectPerf, bool isMobile) {
    if (subjectPerf.isEmpty) return const SizedBox.shrink();
    final sorted = subjectPerf.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return _chartCard(
      "Subject Difficulty Analysis",
      "Subjects sorted by difficulty (lowest avg first)",
      SizedBox(
        height: (sorted.length * (isMobile ? 36 : 44).h).clamp(180.h, 320.h),
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, i) {
            final entry = sorted[i];
            final val = entry.value;
            final difficulty = val < 50 ? 'Hard' : val < 70 ? 'Moderate' : 'Easy';
            final color = val < 50 ? _accentDanger : val < 70 ? _accentWarning : _accentSuccess;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 70.w : 100.w,
                    child: Text(
                      entry.key,
                      style: TextStyle(color: _textSecondary, fontSize: isMobile ? 10.sp : 11.sp, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: isMobile ? 20.h : 24.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: val / 100),
                          duration: Duration(milliseconds: 800 + (i * 100)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Container(
                              height: isMobile ? 20.h : 24.h,
                              width: MediaQuery.of(context).size.width * value * 0.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text("${val.toStringAsFixed(1)}%", style: TextStyle(
                    color: color, fontSize: isMobile ? 10.sp : 11.sp, fontWeight: FontWeight.w700,
                  )),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(difficulty ?? "", style: TextStyle(
                      color: color, fontSize: 8.sp, fontWeight: FontWeight.w700,
                    )),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      isMobile,
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  // ── Reusable Chart Card ──
  static Widget _chartCard(String title, String subtitle, Widget child, bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14.w : 18.w),
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
              Row(
                children: [
                  Expanded(
                    child: Text(title ?? "", style: TextStyle(
                      color: _textPrimary, fontSize: isMobile ? 14.sp : 16.sp, fontWeight: FontWeight.w700,
                    )),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _examPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text("Chart", style: TextStyle(
                      color: _examPrimary, fontSize: 9.sp, fontWeight: FontWeight.w700,
                    )),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(subtitle ?? "", style: TextStyle(color: _textMuted, fontSize: isMobile ? 10.sp : 11.sp)),
              SizedBox(height: isMobile ? 10.h : 14.h),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ── No Data Widget ──
  static Widget _noDataWidget() {
    return SizedBox(
      height: 160.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, color: _textMuted.withOpacity(0.3), size: 40.sp),
            SizedBox(height: 8.h),
            Text("No data available", style: TextStyle(color: _textMuted, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  // ── Legend Item ──
  static Widget _legendItem(String label, String value, Color color, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.r)),
        ),
        SizedBox(width: 8.w),
        Text(label ?? "", style: TextStyle(color: _textSecondary, fontSize: isMobile ? 11.sp : 12.sp)),
        SizedBox(width: 4.w),
        Text(value ?? "", style: TextStyle(color: _textPrimary, fontSize: isMobile ? 11.sp : 12.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ── Badge Icon for Pie Chart ──
  static Widget _badgeIcon(IconData icon, Color color) {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 12.sp),
    );
  }

  // ── Grade Color Helper ──
  static Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+': case 'A': return _accentSuccess;
      case 'A-': case 'B+': case 'B': return const Color(0xFF22D3EE);
      case 'B-': case 'C+': case 'C': return _accentWarning;
      case 'C-': case 'D': return const Color(0xFFF97316);
      default: return _accentDanger;
    }
  }
}
