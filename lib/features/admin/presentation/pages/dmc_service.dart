import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///   HYBRID GRADING DMC SERVICE
///   Supports: Overall Exam Passing + Per-Subject Passing
/// ═══════════════════════════════════════════════════════════════════════════

class DmcService {

  static const PdfColor _primary      = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor _primaryDark  = PdfColor.fromInt(0xFF0F1F33);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFE8EEF4);
  static const PdfColor _accent       = PdfColor.fromInt(0xFFC9A227);
  static const PdfColor _accentLight  = PdfColor.fromInt(0xFFFDF8E8);
  static const PdfColor _success      = PdfColor.fromInt(0xFF059669);
  static const PdfColor _danger       = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor _warning      = PdfColor.fromInt(0xFFD97706);
  static const PdfColor _greyLight    = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _greyMid      = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _greyText     = PdfColor.fromInt(0xFF64748B);
  static const PdfColor _darkText     = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _white        = PdfColors.white;
  static const PdfColor _borderColor  = PdfColor.fromInt(0xFFCBD5E1);

  static PdfColor _alpha(PdfColor c, double opacity) =>
      PdfColor(c.red, c.green, c.blue, opacity);

  static Future<pw.Font> _loadFont({bool bold = false}) async {
    try {
      final fontPath = bold
          ? 'assets/fonts/Roboto-Bold.ttf'
          : 'assets/fonts/Roboto-Regular.ttf';
      final fontData = await rootBundle.load(fontPath);
      return pw.Font.ttf(fontData);
    } catch (e) {
      return pw.Font.helveticaBold(); // ✅ BOLD
    }
  }

  static Future<void> showAndPrint({
    required BuildContext context,
    required String schoolId,
    required DocumentSnapshot student,
    required List<QueryDocumentSnapshot> results,
    required List<QueryDocumentSnapshot> subjectCombos,
    required String examId,
    required String classId,
  }) async {
    try {
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools').doc(schoolId).get();
      final schoolData = schoolDoc.data() ?? {};

      final examDoc = await FirebaseFirestore.instance
          .collection('schools').doc(schoolId)
          .collection('exams').doc(examId).get();
      final examData = examDoc.data() ?? {};

      final studentData = student.data() as Map<String, dynamic>;
      final studentName = (studentData['name'] ?? 'Student')
          .toString().replaceAll(' ', '_');
      final examName = (examData['name'] ?? 'Exam')
          .toString().replaceAll(' ', '_');

      final boldFont = await _loadFont(bold: true);

      await Printing.layoutPdf(
        name: "DMC_${studentName}_$examName.pdf",
        format: PdfPageFormat.a4,
        onLayout: (_) => _buildDmcPdf(
          schoolData: schoolData,
          examData: examData,
          student: student,
          results: results,
          subjectCombos: subjectCombos,
          classId: classId,
          boldFont: boldFont,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating DMC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<Uint8List> _buildDmcPdf({
    required Map<String, dynamic> schoolData,
    required Map<String, dynamic> examData,
    required DocumentSnapshot student,
    required List<QueryDocumentSnapshot> results,
    required List<QueryDocumentSnapshot> subjectCombos,
    required String classId,
    required pw.Font boldFont,
  }) async {
    final pdf = pw.Document();
    final studentData = student.data() as Map<String, dynamic>;

    // ✅ HYBRID GRADING: Get both overall and per-subject passing
    final overallMaxMarks = (examData['maxMarks'] ?? 600) as int;
    final overallPassingMarks = (examData['passingMarks'] ?? 300) as int;
    final subjectMaxMarks = (examData['subjectMaxMarks'] ?? 100) as int;
    final subjectPassingMarks = (examData['subjectPassingMarks'] ?? 33) as int;
    final overallPassingPercentage = overallMaxMarks > 0
        ? (overallPassingMarks / overallMaxMarks) * 100
        : 50.0;

    // Result map
    final Map<String, Map<String, dynamic>> resultMap = {};
    for (var r in results) {
      final rd = r.data() as Map<String, dynamic>;
      resultMap[rd['subject'] ?? ''] = rd;
    }

    // ✅ Calculate both subject-wise AND overall
    double totalObtained = 0;
    int totalMax = 0;
    int subjectsPassed = 0;
    int subjectsFailed = 0;
    int totalSubjects = subjectCombos.length;

    final Map<String, bool> subjectPassStatus = {};
    final Map<String, double> subjectPercentage = {};

    for (var combo in subjectCombos) {
      final sd = combo.data() as Map<String, dynamic>;
      final subj = sd['subject'] ?? '';
      final maxM = (sd['maxMarks'] ?? subjectMaxMarks) as int;
      final rd = resultMap[subj];

      totalMax += maxM;

      if (rd != null) {
        final obt = (rd['marksObtained'] ?? 0).toDouble();
        totalObtained += obt;

        final perc = maxM > 0 ? (obt / maxM) * 100 : 0.0;
        subjectPercentage[subj] = perc;

        // ✅ Subject-wise pass check (using exam's subjectPassingMarks)
        final isSubjectPassed = obt >= subjectPassingMarks;
        subjectPassStatus[subj] = isSubjectPassed;

        if (isSubjectPassed) {
          subjectsPassed++;
        } else {
          subjectsFailed++;
        }
      }
    }

    // ✅ Overall calculation
    final overallPerc = overallMaxMarks > 0
        ? (totalObtained / overallMaxMarks) * 100
        : 0.0;
    final overallGrade = _gradeFromPerc(overallPerc);
    final isOverallPassed = totalObtained >= overallPassingMarks;

    // Data
    final schoolName    = schoolData['name']    ?? 'School Name';
    final schoolPhone   = schoolData['phone']   ?? '';
    final schoolAddress = (schoolData['settings'] is Map)
        ? ((schoolData['settings'] as Map)['address'] ?? '') : '';
    final examName      = examData['name']  ?? 'Examination';
    final examType      = examData['type']  ?? '';
    final examDateRaw   = examData['examDate'];
    String examDateStr  = 'N/A';
    if (examDateRaw is Timestamp) {
      examDateStr = DateFormat('dd MMMM yyyy').format(examDateRaw.toDate());
    }
    final studentName = studentData['name']       ?? 'Unknown';
    final rollNumber  = studentData['rollNumber'] ?? '--';
    final fatherName  = studentData['fatherName'] ?? studentData['parentName'] ?? '--';
    final studentId   = studentData['studentId']  ?? student.id;
    final displayClassId = classId.replaceAll('_', ' ').toUpperCase();

    // Pre-calculate strings
    final String totalObtainedStr = totalObtained.toInt().toString();
    final String overallMaxStr = overallMaxMarks.toString();
    final String overallPercStr = overallPerc.toStringAsFixed(1);
    final String subjectPassingStr = subjectPassingMarks.toString();
    final String overallPassingStr = overallPassingMarks.toString();
    final String passedStr = subjectsPassed.toString();
    final String failedStr = subjectsFailed.toString();
    final String overallResultStr = isOverallPassed ? 'PASSED' : 'FAILED';
    final String issueDateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final String generatedDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final String totalMarksDisplay = '$totalObtainedStr / $overallMaxStr';
    final String percentageDisplay = '$overallPercStr%';
    final String subjectsDisplay = '$passedStr Pass\n$failedStr Fail';
    final String overallCriteriaDisplay = '$overallPassingStr / $overallMaxStr marks (${overallPassingPercentage.toStringAsFixed(0)}%)';
    final String subjectCriteriaDisplay = '$subjectPassingStr / $subjectMaxMarks per subject';
    final String phoneDisplay = schoolPhone.toString();
    final String addressDisplay = schoolAddress.toString();
    final String schoolNameDisplay = schoolName.toString();
    final String rollNumberDisplay = rollNumber.toString();
    final String studentIdDisplay = studentId.toString();

    final gradeColor  = overallPerc >= 80 ? _success : overallPerc >= overallPassingPercentage ? _warning : _danger;
    final resultColor = isOverallPassed ? _success : _danger;

    // Font styles - ALL BOLD
    final headerStyle = pw.TextStyle(font: boldFont, color: _white, fontSize: 18, letterSpacing: 1.2);
    final subHeaderStyle = pw.TextStyle(font: boldFont, color: _alpha(_white, 0.85), fontSize: 9);
    final titleStyle = pw.TextStyle(font: boldFont, color: _primary, fontSize: 13, letterSpacing: 2);
    final labelStyle = pw.TextStyle(font: boldFont, color: _greyText, fontSize: 8);
    final valueStyle = pw.TextStyle(font: boldFont, color: _darkText, fontSize: 9);
    final tableHeaderStyle = pw.TextStyle(font: boldFont, color: _white, fontSize: 8);
    final footerStyle = pw.TextStyle(font: boldFont, color: _greyText, fontSize: 7);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _primary, width: 2.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _accent, width: 0.8),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          margin: const pw.EdgeInsets.all(3),
          child: pw.Stack(
            children: [
              // Watermark
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Opacity(
                    opacity: 0.03,
                    child: pw.Text('OFFICIAL',
                      style: pw.TextStyle(font: boldFont, fontSize: 90, color: _primary),
                    ),
                  ),
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [

                    // Header
                    pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                          colors: [_primaryDark, _primary, PdfColor.fromInt(0xFF2D5A87)],
                          begin: pw.Alignment.topLeft,
                          end: pw.Alignment.bottomRight,
                        ),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 60, height: 60,
                            decoration: pw.BoxDecoration(
                              color: _alpha(_white, 0.12),
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(color: _accent, width: 1.5),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                schoolName.isNotEmpty ? schoolName[0].toUpperCase() : 'S',
                                style: pw.TextStyle(font: boldFont, color: _accent, fontSize: 28),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Expanded(child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(schoolName.toUpperCase(), style: headerStyle),
                              pw.SizedBox(height: 3),
                              pw.Container(height: 1.5, width: 60, color: _accent),
                              pw.SizedBox(height: 3),
                              if (addressDisplay.isNotEmpty)
                                pw.Text(addressDisplay, style: subHeaderStyle),
                              if (phoneDisplay.isNotEmpty)
                                pw.Text('Phone: $phoneDisplay',
                                    style: pw.TextStyle(font: boldFont, color: _alpha(_white, 0.75), fontSize: 7.5)),
                            ],
                          )),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: _alpha(_accent, 0.15),
                              borderRadius: pw.BorderRadius.circular(3),
                              border: pw.Border.all(color: _accent, width: 0.8),
                            ),
                            child: pw.Column(children: [
                              pw.Text('DMC', style: pw.TextStyle(font: boldFont, color: _accent, fontSize: 9)),
                              pw.Text('NO. $studentIdDisplay',
                                  style: pw.TextStyle(font: boldFont, color: _alpha(_white, 0.9), fontSize: 6.5)),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 10),

                    // Title Bar
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: _accentLight,
                        borderRadius: pw.BorderRadius.circular(5),
                        border: pw.Border.all(color: _accent, width: 0.5),
                      ),
                      child: pw.Center(child: pw.Column(children: [
                        pw.Text('DETAIL MARKS CERTIFICATE', style: titleStyle),
                        pw.SizedBox(height: 2),
                        pw.Text("$examName  •  $examType",
                            style: pw.TextStyle(font: boldFont, color: _greyText, fontSize: 8)),
                      ])),
                    ),

                    pw.SizedBox(height: 12),

                    // ✅ HYBRID GRADING INFO BAR
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: _primaryLight,
                        borderRadius: pw.BorderRadius.circular(5),
                        border: pw.Border.all(color: _primary),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _infoBadge('OVERALL PASS', overallCriteriaDisplay, _primary, boldFont),
                          _infoBadge('PER SUBJECT', subjectCriteriaDisplay, _primary, boldFont),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 12),

                    // Student Info
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: _greyLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: _borderColor),
                      ),
                      child: pw.Row(children: [
                        pw.Expanded(child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _infoRow('Student Name', studentName, valueStyle, labelStyle),
                            pw.SizedBox(height: 5),
                            _infoRow("Father's Name", fatherName, valueStyle, labelStyle),
                            pw.SizedBox(height: 5),
                            _infoRow('Roll Number', rollNumberDisplay, valueStyle, labelStyle),
                          ],
                        )),
                        pw.Container(width: 1, height: 58, color: _borderColor),
                        pw.SizedBox(width: 14),
                        pw.Expanded(child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _infoRow('Class', displayClassId, valueStyle, labelStyle),
                            pw.SizedBox(height: 5),
                            _infoRow('Exam Date', examDateStr, valueStyle, labelStyle),
                            pw.SizedBox(height: 5),
                            _infoRow('Issue Date', issueDateStr, valueStyle, labelStyle),
                          ],
                        )),
                      ]),
                    ),

                    pw.SizedBox(height: 12),

                    // Subject Table
                    pw.Text('SUBJECT-WISE PERFORMANCE',
                        style: pw.TextStyle(font: boldFont, color: _primary, fontSize: 8.5, letterSpacing: 1)),
                    pw.SizedBox(height: 5),

                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _borderColor, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(children: [
                        // Table Header
                        pw.Container(
                          decoration: const pw.BoxDecoration(
                            color: _primary,
                            borderRadius: pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(5),
                              topRight: pw.Radius.circular(5),
                            ),
                          ),
                          child: pw.Row(children: [
                            _tableHeader('Subject', 3, tableHeaderStyle),
                            _tableHeader('Max', 1, tableHeaderStyle),
                            _tableHeader('Obtained', 1.2, tableHeaderStyle),
                            _tableHeader('Percentage', 1.2, tableHeaderStyle),
                            _tableHeader('Grade', 0.8, tableHeaderStyle),
                            _tableHeader('Status', 1, tableHeaderStyle),
                          ]),
                        ),
                        // Table Rows
                        ...subjectCombos.asMap().entries.map((entry) {
                          final i    = entry.key;
                          final sd   = entry.value.data() as Map<String, dynamic>;
                          final subj = sd['subject'] ?? '';
                          final maxM  = (sd['maxMarks'] ?? subjectMaxMarks) as int;
                          final rd   = resultMap[subj];
                          final obt  = rd != null ? (rd['marksObtained'] ?? 0).toDouble() : null;
                          final perc = obt != null ? subjectPercentage[subj] ?? 0.0 : 0.0;
                          final grade = rd != null ? (rd['grade'] ?? _gradeFromPerc(perc)) : '--';

                          // ✅ Subject-wise pass check
                          final passed = obt != null ? (subjectPassStatus[subj] ?? false) : false;

                          final rowBg  = i.isEven ? _white : _greyLight;
                          final gc = perc >= 80 ? _success : perc >= (subjectPassingMarks / subjectMaxMarks * 100) ? _warning : _danger;

                          final String maxStr = maxM.toString();
                          final String obtStr = obt != null ? obt.toInt().toString() : '—';
                          final String percStr = obt != null ? '${perc.toStringAsFixed(1)}%' : '—';
                          final String statusStr = obt != null ? (passed ? 'PASS' : 'FAIL') : '—';
                          final PdfColor statusColor = obt != null ? (passed ? _success : _danger) : _greyText;

                          return pw.Container(
                            decoration: pw.BoxDecoration(
                              color: rowBg,
                              border: i == subjectCombos.length - 1 ? null : pw.Border(bottom: pw.BorderSide(color: _borderColor, width: 0.5)),
                            ),
                            child: pw.Row(children: [
                              _tableCell(subj, _darkText, flex: 3, bold: true, align: pw.TextAlign.left, boldFont: boldFont),
                              _tableCell(maxStr, _greyText, flex: 1, boldFont: boldFont),
                              _tableCell(obtStr, obt != null ? _darkText : _greyText, flex: 1.2, bold: true, boldFont: boldFont),
                              _tableCell(percStr, gc, flex: 1.2, boldFont: boldFont),
                              _tableCell(grade, gc, flex: 0.8, bold: true, boldFont: boldFont),
                              _tableCell(statusStr, statusColor, flex: 1, bold: true, boldFont: boldFont),
                            ]),
                          );
                        }),
                        // Total Row
                        pw.Container(
                          decoration: pw.BoxDecoration(
                            color: _accentLight,
                            borderRadius: const pw.BorderRadius.only(
                              bottomLeft: pw.Radius.circular(5),
                              bottomRight: pw.Radius.circular(5),
                            ),
                          ),
                          child: pw.Row(children: [
                            _tableCell('TOTAL', _primary, flex: 3, bold: true, align: pw.TextAlign.left, boldFont: boldFont),
                            _tableCell(overallMaxStr, _primary, flex: 1, bold: true, boldFont: boldFont),
                            _tableCell(totalObtainedStr, _primary, flex: 1.2, bold: true, boldFont: boldFont),
                            _tableCell(percentageDisplay, _primary, flex: 1.2, bold: true, boldFont: boldFont),
                            _tableCell(overallGrade, _primary, flex: 0.8, bold: true, boldFont: boldFont),
                            _tableCell('', _white, flex: 1, boldFont: boldFont),
                          ]),
                        ),
                      ]),
                    ),

                    pw.SizedBox(height: 12),

                    // ✅ HYBRID SUMMARY CARDS
                    pw.Row(children: [
                      _summaryCard('OVERALL MARKS', totalMarksDisplay, _primary, _accent, boldFont),
                      pw.SizedBox(width: 6),
                      _summaryCard('OVERALL %', percentageDisplay, gradeColor, _accent, boldFont),
                      pw.SizedBox(width: 6),
                      _summaryCard('GRADE', overallGrade, gradeColor, _accent, boldFont),
                      pw.SizedBox(width: 6),
                      _summaryCard('RESULT', overallResultStr, resultColor, _accent, boldFont),
                      pw.SizedBox(width: 6),
                      _summaryCard('SUBJECTS', subjectsDisplay, _greyText, _accent, boldFont),
                    ]),

                    pw.SizedBox(height: 8),

                    // ✅ HYBRID PASSING CRITERIA & REMARKS
                    pw.Row(children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: isOverallPassed ? PdfColor.fromInt(0xFFF0FDF4) : PdfColor.fromInt(0xFFFEF2F2),
                            borderRadius: pw.BorderRadius.circular(5),
                            border: pw.Border.all(color: isOverallPassed ? _success : _danger, width: 1),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Passing Criteria:', style: pw.TextStyle(font: boldFont, color: _greyText, fontSize: 7.5)),
                              pw.SizedBox(height: 2),
                              pw.Text('• Overall: $overallCriteriaDisplay', style: pw.TextStyle(font: boldFont, color: _darkText, fontSize: 7.5)),
                              pw.Text('• Per Subject: $subjectCriteriaDisplay', style: pw.TextStyle(font: boldFont, color: _darkText, fontSize: 7.5)),
                              pw.SizedBox(height: 3),
                              pw.Text(_remarks(overallPerc, subjectsPassed, totalSubjects),
                                  style: pw.TextStyle(font: boldFont, color: _darkText, fontSize: 7.5, fontStyle: pw.FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                    ]),

                    pw.Spacer(),

                    // QR & Signatures
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          width: 60, height: 60,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _borderColor),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Center(
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text('QR', style: pw.TextStyle(font: boldFont, fontSize: 18, color: _greyText)),
                                pw.SizedBox(height: 2),
                                pw.Text('VERIFY', style: pw.TextStyle(font: boldFont, fontSize: 5.5, color: _greyText)),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 14),
                        pw.Expanded(
                          child: pw.Row(children: [
                            _signatureBox('Class Teacher', _primary, boldFont),
                            pw.SizedBox(width: 8),
                            _signatureBox('Exam Controller', _primary, boldFont),
                            pw.SizedBox(width: 8),
                            _signatureBox('Principal', _primary, boldFont),
                          ]),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 6),

                    // Footer
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: pw.BoxDecoration(
                        color: _primaryLight,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('This is a computer-generated certificate.', style: footerStyle),
                          pw.Text("Generated: $generatedDateStr", style: footerStyle),
                          pw.Text(schoolNameDisplay, style: pw.TextStyle(font: boldFont, color: _greyText, fontSize: 7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    return pdf.save();
  }

  // ── Widget Helpers ───────────────────────────────────────────

  static pw.Widget _infoBadge(String label, String value, PdfColor color, pw.Font boldFont) =>
      pw.Column(children: [
        pw.Text(label, style: pw.TextStyle(font: boldFont, color: color, fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: boldFont, color: _darkText, fontSize: 8)),
      ]);

  static pw.Widget _infoRow(String label, String value, pw.TextStyle valueStyle, pw.TextStyle labelStyle) =>
      pw.Row(children: [
        pw.SizedBox(width: 85, child: pw.Text(label, style: labelStyle)),
        pw.Text(': ', style: labelStyle),
        pw.Expanded(child: pw.Text(value, style: valueStyle)),
      ]);

  static pw.Widget _tableHeader(String text, double flex, pw.TextStyle style) => pw.Expanded(
    flex: (flex * 10).toInt(),
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(text, textAlign: pw.TextAlign.center, style: style),
    ),
  );

  static pw.Widget _tableCell(String text, PdfColor color,
      {required double flex, bool bold = false, pw.TextAlign align = pw.TextAlign.center,
        required pw.Font boldFont}) => pw.Expanded(
    flex: (flex * 10).toInt(),
    child: pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(font: boldFont, color: color, fontSize: 8)),
    ),
  );

  static pw.Widget _summaryCard(String label, String value, PdfColor color, PdfColor accentColor,
      pw.Font boldFont) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: accentColor, width: 0.5),
      ),
      child: pw.Column(children: [
        pw.Text(label, style: pw.TextStyle(font: boldFont, color: _greyText, fontSize: 7, letterSpacing: 0.5)),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: accentColor, margin: const pw.EdgeInsets.symmetric(horizontal: 6)),
        pw.SizedBox(height: 3),
        pw.Text(value, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: boldFont, color: color, fontSize: 11)),
      ]),
    ),
  );

  static pw.Widget _signatureBox(String label, PdfColor lineColor, pw.Font boldFont) => pw.Expanded(
    child: pw.Column(children: [
      pw.SizedBox(height: 28),
      pw.Container(height: 1, color: lineColor),
      pw.SizedBox(height: 3),
      pw.Text(label, textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: boldFont, color: _greyText, fontSize: 7)),
      pw.Text('Signature & Seal', textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: boldFont, color: PdfColor.fromInt(0xFF94A3B8), fontSize: 6, fontStyle: pw.FontStyle.italic)),
    ]),
  );

  // ── Calculations ──────────────────────────────────────────────

  static String _gradeFromPerc(double p) {
    if (p >= 90) return 'A+';
    if (p >= 85) return 'A';
    if (p >= 80) return 'A-';
    if (p >= 75) return 'B+';
    if (p >= 70) return 'B';
    if (p >= 65) return 'B-';
    if (p >= 60) return 'C+';
    if (p >= 55) return 'C';
    if (p >= 50) return 'C-';
    if (p >= 45) return 'D';
    return 'F';
  }

  static String _remarks(double overallPerc, int subjectsPassed, int totalSubjects) {
    if (overallPerc >= 90) return 'Excellent! Outstanding performance across all subjects.';
    if (overallPerc >= 80) return 'Very good performance. Keep maintaining this standard.';
    if (overallPerc >= 70) return 'Good performance. Continue working hard for better results.';
    if (overallPerc >= 60) return 'Satisfactory. Room for improvement in weak subjects.';
    if (overallPerc >= 50) return 'Passed overall. Focus on subjects with failing grades.';
    if (subjectsPassed < totalSubjects) return 'Failed overall. Need to pass all subjects individually.';
    return 'Failed. Significant improvement required in all areas.';
  }
}