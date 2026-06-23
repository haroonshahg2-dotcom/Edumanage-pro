import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final Function(String, {bool isError}) showSnackBar;

  const SettingsModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<SettingsModule> createState() => _SettingsModuleState();
}

class _SettingsModuleState extends State<SettingsModule>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  bool isSaving = false;

  // School Data
  Map<String, dynamic> schoolData = {};

  // Controllers
  final _schoolNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Academic Year
  String currentAcademicYear = '2025-2026';
  DateTime sessionStart = DateTime(2025, 4, 1);
  DateTime sessionEnd = DateTime(2026, 3, 31);

  // Grading System
  String gradingType = 'percentage';
  List<Map<String, dynamic>> gradeScale = [
    {'grade': 'A+', 'min': 90, 'max': 100, 'points': 4.0},
    {'grade': 'A', 'min': 80, 'max': 89, 'points': 3.7},
    {'grade': 'B+', 'min': 70, 'max': 79, 'points': 3.3},
    {'grade': 'B', 'min': 60, 'max': 69, 'points': 3.0},
    {'grade': 'C', 'min': 50, 'max': 59, 'points': 2.7},
    {'grade': 'D', 'min': 40, 'max': 49, 'points': 2.0},
    {'grade': 'F', 'min': 0, 'max': 39, 'points': 0.0},
  ];

  // Terms
  List<Map<String, dynamic>> terms = [
    {'name': 'First Term', 'start': '2025-04-01', 'end': '2025-08-31'},
    {'name': 'Second Term', 'start': '2025-09-01', 'end': '2026-03-31'},
  ];

  // Fee Heads
  List<Map<String, dynamic>> feeHeads = [
    {'id': 'tuition', 'name': 'Tuition Fee', 'mandatory': true, 'defaultAmount': 10000},
    {'id': 'transport', 'name': 'Transport Fee', 'mandatory': false, 'defaultAmount': 3000},
    {'id': 'lab', 'name': 'Lab Charges', 'mandatory': true, 'defaultAmount': 2000},
    {'id': 'library', 'name': 'Library Fee', 'mandatory': true, 'defaultAmount': 500},
  ];

  // User Roles
  List<Map<String, dynamic>> customRoles = [
    {'name': 'Principal', 'permissions': ['all'], 'level': 1},
    {'name': 'Vice Principal', 'permissions': ['view_all', 'edit_teachers', 'edit_students'], 'level': 2},
    {'name': 'Accountant', 'permissions': ['fees', 'expenses', 'reports'], 'level': 3},
    {'name': 'Receptionist', 'permissions': ['admission', 'view_students', 'attendance_view'], 'level': 4},
  ];

  // System Settings
  bool attendanceAutoSms = true;
  int feeReminderDays = 3;
  String currency = 'PKR';
  String timezone = 'Asia/Karachi';
  String dateFormat = 'dd/MM/yyyy';

  // Colors
  static const Color _bgDark = Color(0xFF0B0F19);
  static const Color _bgCard = Color(0xFF151B2B);
  static const Color _bgElevated = Color(0xFF1E2538);
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryLight = Color(0xFF818CF8);
  static const Color _accentSuccess = Color(0xFF22C55E);
  static const Color _accentWarning = Color(0xFFF59E0B);
  static const Color _accentDanger = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFF2D3748);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadSchoolData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadSchoolData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      if (doc.exists) {
        setState(() {
          schoolData = doc.data() ?? {};

          _schoolNameController.text = schoolData['name'] ?? widget.schoolName;
          _addressController.text = schoolData['address'] ?? '';
          _phoneController.text = schoolData['phone'] ?? '';
          _emailController.text = schoolData['email'] ?? '';
          _websiteController.text = schoolData['website'] ?? '';

          if (schoolData['academicYear'] != null) {
            currentAcademicYear = schoolData['academicYear']['current'] ?? '2025-2026';
          }

          if (schoolData['gradingSystem'] != null) {
            gradingType = schoolData['gradingSystem']['type'] ?? 'percentage';
            if (schoolData['gradingSystem']['scale'] != null) {
              gradeScale = List<Map<String, dynamic>>.from(schoolData['gradingSystem']['scale']);
            }
          }

          if (schoolData['terms'] != null) {
            terms = List<Map<String, dynamic>>.from(schoolData['terms']);
          }

          if (schoolData['feeStructure'] != null && schoolData['feeStructure']['heads'] != null) {
            feeHeads = List<Map<String, dynamic>>.from(schoolData['feeStructure']['heads']);
          }

          if (schoolData['settings'] != null) {
            attendanceAutoSms = schoolData['settings']['attendanceAutoSms'] ?? true;
            feeReminderDays = schoolData['settings']['feeReminderDays'] ?? 3;
            currency = schoolData['settings']['currency'] ?? 'PKR';
            timezone = schoolData['settings']['timezone'] ?? 'Asia/Karachi';
            dateFormat = schoolData['settings']['dateFormat'] ?? 'dd/MM/yyyy';
          }

          isLoading = false;
        });
      }
    } catch (e) {
      widget.showSnackBar('Error loading settings: $e', isError: true);
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => isSaving = true);

    try {
      final settingsData = {
        'name': _schoolNameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'website': _websiteController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'academicYear': {
          'current': currentAcademicYear,
          'startDate': sessionStart.toIso8601String().split('T')[0],
          'endDate': sessionEnd.toIso8601String().split('T')[0],
        },
        'gradingSystem': {
          'type': gradingType,
          'scale': gradeScale,
        },
        'terms': terms,
        'feeStructure': {
          'heads': feeHeads,
        },
        'settings': {
          'attendanceAutoSms': attendanceAutoSms,
          'feeReminderDays': feeReminderDays,
          'currency': currency,
          'timezone': timezone,
          'dateFormat': dateFormat,
        },
        'customRoles': customRoles,
      };

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .update(settingsData);

      widget.showSnackBar('Settings saved successfully');
    } catch (e) {
      widget.showSnackBar('Error saving settings: $e', isError: true);
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: widget.isMobile ? 16.h : 24.h),
        _buildTabBar(),
        SizedBox(height: 16.h),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSchoolProfileTab(),
              _buildAcademicSettingsTab(),
              _buildGradingSystemTab(),
              _buildFeeStructureTab(),
              _buildUserRolesTab(),
              _buildSystemSettingsTab(),
            ],
          ),
        ),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primary),
          SizedBox(height: 16.h),
          Text(
            'Loading settings...',
            style: TextStyle(color: _textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return widget.isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Settings',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Configure your school preferences',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14.sp,
          ),
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Settings',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Configure your school preferences and academic structure',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _industrialButton(
              'Reset',
              onPressed: _loadSchoolData,
              isSecondary: true,
            ),
            SizedBox(width: 12.w),
            _industrialButton(
              isSaving ? 'Saving...' : 'Save All Changes',
              onPressed: isSaving ? null : _saveSettings,
              isLoading: isSaving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      ('Profile', Icons.school_outlined),
      ('Academic', Icons.calendar_today_outlined),
      ('Grading', Icons.grade_outlined),
      ('Fees', Icons.account_balance_wallet_outlined),
      ('Roles', Icons.admin_panel_settings_outlined),
      ('System', Icons.settings_outlined),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: widget.isMobile,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryLight]),
          borderRadius: BorderRadius.circular(10.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
        tabs: tabs.map((tab) {
          return Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.$2, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(tab.$1),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSchoolProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('School Information'),
          SizedBox(height: 20.h),
          _buildLogoUpload(),
          SizedBox(height: 24.h),
          _industrialTextField(
            'School Name *',
            _schoolNameController,
            icon: Icons.school,
          ),
          SizedBox(height: 16.h),
          _industrialTextField(
            'Complete Address *',
            _addressController,
            icon: Icons.location_on,
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _industrialTextField(
                  'Phone Number *',
                  _phoneController,
                  icon: Icons.phone,
                  type: TextInputType.phone,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _industrialTextField(
                  'Email Address *',
                  _emailController,
                  icon: Icons.email,
                  type: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _industrialTextField(
            'Website',
            _websiteController,
            icon: Icons.language,
            hint: 'www.yourschool.edu',
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle('Primary Contact'),
          SizedBox(height: 16.h),
          _buildInfoCard(
            'Principal/Head',
            schoolData['adminName'] ?? 'Not assigned',
            Icons.person,
            _primary,
          ),
          SizedBox(height: 12.h),
          _buildInfoCard(
            'School ID',
            widget.schoolId,
            Icons.fingerprint,
            _textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoUpload() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _border),
              image: schoolData['logo'] != null
                  ? DecorationImage(
                image: NetworkImage(schoolData['logo']),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: schoolData['logo'] == null
                ? Icon(Icons.school, color: _textMuted, size: 48.sp)
                : null,
          ),
          SizedBox(height: 12.h),
          _industrialButton(
            'Upload Logo',
            icon: Icons.camera_alt,
            onPressed: _uploadLogo,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      try {
        final file = File(picked.path);
        final ref = FirebaseStorage.instance
            .ref()
            .child('schools/${widget.schoolId}/logo.jpg');

        await ref.putFile(file);
        final url = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .update({'logo': url});

        setState(() => schoolData['logo'] = url);
        widget.showSnackBar('Logo uploaded successfully');
      } catch (e) {
        widget.showSnackBar('Error uploading logo: $e', isError: true);
      }
    }
  }

  Widget _buildAcademicSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Academic Year'),
          SizedBox(height: 16.h),
          _buildAcademicYearDropdown(),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'Session Start',
                  sessionStart,
                      (date) => setState(() => sessionStart = date),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDatePicker(
                  'Session End',
                  sessionEnd,
                      (date) => setState(() => sessionEnd = date),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle('Terms/Semesters'),
          SizedBox(height: 16.h),
          ...terms.asMap().entries.map((entry) {
            final index = entry.key;
            final term = entry.value;
            return _buildTermCard(index, term);
          }),
          SizedBox(height: 12.h),
          _industrialButton(
            'Add Term',
            icon: Icons.add,
            onPressed: _addTerm,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicYearDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Academic Year',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentAcademicYear,
              isExpanded: true,
              dropdownColor: _bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: _textMuted),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              items: const [
                DropdownMenuItem(value: '2024-2025', child: Text('2024-2025')),
                DropdownMenuItem(value: '2025-2026', child: Text('2025-2026')),
                DropdownMenuItem(value: '2026-2027', child: Text('2026-2027')),
              ],
              onChanged: (String? val) {
                if (val != null) setState(() => currentAcademicYear = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermCard(int index, Map<String, dynamic> term) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _industrialTextField(
                  'Term Name',
                  TextEditingController(text: term['name']),
                  onChanged: (val) => terms[index]['name'] = val,
                ),
              ),
              SizedBox(width: 8.w),
              _industrialIconButton(
                Icons.delete,
                color: _accentDanger,
                onPressed: () => setState(() => terms.removeAt(index)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'Start Date',
                  DateTime.parse(term['start']),
                      (date) => setState(() => terms[index]['start'] =
                  date.toIso8601String().split('T')[0]),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildDatePicker(
                  'End Date',
                  DateTime.parse(term['end']),
                      (date) => setState(() => terms[index]['end'] =
                  date.toIso8601String().split('T')[0]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addTerm() {
    setState(() {
      terms.add({
        'name': 'New Term',
        'start': DateTime.now().toIso8601String().split('T')[0],
        'end': DateTime.now().add(const Duration(days: 90))
            .toIso8601String().split('T')[0],
      });
    });
  }

  Widget _buildGradingSystemTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Grading Configuration'),
          SizedBox(height: 16.h),
          _buildGradingTypeSelector(),
          SizedBox(height: 24.h),
          _buildSectionTitle('Grade Scale'),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: _bgElevated,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text('Grade', style: _tableHeaderStyle())),
                      Expanded(flex: 2, child: Text('Min %', style: _tableHeaderStyle())),
                      Expanded(flex: 2, child: Text('Max %', style: _tableHeaderStyle())),
                      Expanded(flex: 2, child: Text('Points', style: _tableHeaderStyle())),
                      SizedBox(width: 40.w),
                    ],
                  ),
                ),
                ...gradeScale.asMap().entries.map((entry) {
                  final index = entry.key;
                  final grade = entry.value;
                  return _buildGradeRow(index, grade);
                }),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          _industrialButton(
            'Add Grade',
            icon: Icons.add,
            onPressed: () {
              setState(() {
                gradeScale.add({
                  'grade': 'New',
                  'min': 0,
                  'max': 0,
                  'points': 0.0,
                });
              });
            },
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGradingTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grading Type',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: gradingType,
              isExpanded: true,
              dropdownColor: _bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: _textMuted),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              hint: Text(
                'Select grading system',
                style: TextStyle(color: _textMuted, fontSize: 14.sp),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'percentage',
                  child: Text('Percentage (0-100%)'),
                ),
                DropdownMenuItem(
                  value: 'gpa',
                  child: Text('GPA (4.0 Scale)'),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom Grade Scale'),
                ),
              ],
              onChanged: (String? val) {
                if (val != null) setState(() => gradingType = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _tableHeaderStyle() {
    return TextStyle(
      color: _textSecondary,
      fontSize: 12.sp,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildGradeRow(int index, Map<String, dynamic> grade) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _industrialSmallField(
              grade['grade'],
                  (val) => gradeScale[index]['grade'] = val,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _industrialSmallField(
              grade['min'].toString(),
                  (val) => gradeScale[index]['min'] = int.tryParse(val) ?? 0,
              type: TextInputType.number,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _industrialSmallField(
              grade['max'].toString(),
                  (val) => gradeScale[index]['max'] = int.tryParse(val) ?? 0,
              type: TextInputType.number,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 2,
            child: _industrialSmallField(
              grade['points'].toString(),
                  (val) => gradeScale[index]['points'] = double.tryParse(val) ?? 0.0,
              type: TextInputType.number,
            ),
          ),
          SizedBox(width: 8.w),
          _industrialIconButton(
            Icons.delete,
            color: _accentDanger,
            onPressed: () => setState(() => gradeScale.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeStructureTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Fee Heads Configuration'),
          SizedBox(height: 16.h),
          Text(
            'Configure all types of fees. Mandatory fees apply to all students, optional can be assigned per student.',
            style: TextStyle(color: _textMuted, fontSize: 13.sp),
          ),
          SizedBox(height: 20.h),
          ...feeHeads.asMap().entries.map((entry) {
            final index = entry.key;
            final head = entry.value;
            return _buildFeeHeadCard(index, head);
          }),
          SizedBox(height: 16.h),
          _industrialButton(
            'Add Fee Head',
            icon: Icons.add,
            onPressed: () {
              setState(() {
                feeHeads.add({
                  'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
                  'name': 'New Fee',
                  'mandatory': false,
                  'defaultAmount': 0,
                });
              });
            },
            isSecondary: true,
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle('Default Due Date'),
          SizedBox(height: 16.h),
          _buildFeeReminderDropdown(),
        ],
      ),
    );
  }

  Widget _buildFeeReminderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Fee Due Date',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: feeReminderDays.toString(),
              isExpanded: true,
              dropdownColor: _bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: _textMuted),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              items: const [
                DropdownMenuItem(value: '1', child: Text('1')),
                DropdownMenuItem(value: '2', child: Text('2')),
                DropdownMenuItem(value: '3', child: Text('3')),
                DropdownMenuItem(value: '5', child: Text('5')),
                DropdownMenuItem(value: '7', child: Text('7')),
                DropdownMenuItem(value: '10', child: Text('10')),
              ],
              onChanged: (String? val) {
                if (val != null) setState(() => feeReminderDays = int.tryParse(val) ?? 3);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeHeadCard(int index, Map<String, dynamic> head) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _industrialTextField(
                  'Fee Name',
                  TextEditingController(text: head['name']),
                  onChanged: (val) => feeHeads[index]['name'] = val,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _industrialTextField(
                  'Default Amount',
                  TextEditingController(text: head['defaultAmount'].toString()),
                  onChanged: (val) => feeHeads[index]['defaultAmount'] = int.tryParse(val) ?? 0,
                  type: TextInputType.number,
                  prefix: currency,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _industrialSwitch(
                'Mandatory for all students',
                head['mandatory'] ?? false,
                    (val) => setState(() => feeHeads[index]['mandatory'] = val),
              ),
              const Spacer(),
              _industrialIconButton(
                Icons.delete,
                color: _accentDanger,
                onPressed: () => setState(() => feeHeads.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRolesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Custom User Roles'),
          SizedBox(height: 16.h),
          Text(
            'Create custom roles with specific permissions. Level 1 = Highest authority.',
            style: TextStyle(color: _textMuted, fontSize: 13.sp),
          ),
          SizedBox(height: 20.h),
          ...customRoles.asMap().entries.map((entry) {
            final index = entry.key;
            final role = entry.value;
            return _buildRoleCard(index, role);
          }),
          SizedBox(height: 16.h),
          _industrialButton(
            'Add Custom Role',
            icon: Icons.add,
            onPressed: () {
              setState(() {
                customRoles.add({
                  'name': 'New Role',
                  'permissions': ['view_students'],
                  'level': 5,
                });
              });
            },
            isSecondary: true,
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle('Default Permissions Reference'),
          SizedBox(height: 16.h),
          _buildInfoCard(
            'Admin',
            'Full access to all modules and settings',
            Icons.admin_panel_settings,
            _accentDanger,
          ),
          SizedBox(height: 8.h),
          _buildInfoCard(
            'Teacher',
            'Attendance marking, marks entry, view assigned classes',
            Icons.school,
            _primary,
          ),
          SizedBox(height: 8.h),
          _buildInfoCard(
            'Parent',
            'View child data, pay fees, communicate with teachers',
            Icons.people,
            _accentSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(int index, Map<String, dynamic> role) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _industrialTextField(
                  'Role Name',
                  TextEditingController(text: role['name']),
                  onChanged: (val) => customRoles[index]['name'] = val,
                ),
              ),
              SizedBox(width: 16.w),
              Container(
                width: 60.w,
                child: _industrialTextField(
                  'Level',
                  TextEditingController(text: role['level'].toString()),
                  onChanged: (val) => customRoles[index]['level'] = int.tryParse(val) ?? 5,
                  type: TextInputType.number,
                ),
              ),
              SizedBox(width: 8.w),
              _industrialIconButton(
                Icons.delete,
                color: _accentDanger,
                onPressed: () => setState(() => customRoles.removeAt(index)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Permissions:',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              'all', 'view_all', 'edit_teachers', 'edit_students',
              'fees', 'attendance_mark', 'marks_entry', 'reports',
              'announcements', 'settings'
            ].map((perm) {
              final isSelected = (role['permissions'] as List).contains(perm);
              return _industrialChip(
                label: perm,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      (customRoles[index]['permissions'] as List).remove(perm);
                    } else {
                      (customRoles[index]['permissions'] as List).add(perm);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Notification Settings'),
          SizedBox(height: 16.h),
          _industrialSwitch(
            'Auto-SMS to parents on absent',
            attendanceAutoSms,
                (val) => setState(() => attendanceAutoSms = val),
          ),
          SizedBox(height: 12.h),
          _buildFeeReminderDropdown(),
          SizedBox(height: 24.h),
          _buildSectionTitle('Regional Settings'),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildCurrencyDropdown(),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildTimezoneDropdown(),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDateFormatDropdown(),
          SizedBox(height: 24.h),
          _buildSectionTitle('Danger Zone'),
          SizedBox(height: 16.h),
          _buildDangerCard(
            'Reset All Data',
            'Delete all students, teachers, and records. School structure remains.',
            Icons.delete_forever,
            _accentDanger,
            _resetAllData,
          ),
          SizedBox(height: 12.h),
          _buildDangerCard(
            'Archive Academic Year',
            'Archive current year data and start fresh session.',
            Icons.archive,
            _accentWarning,
            _archiveYear,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currency,
              isExpanded: true,
              dropdownColor: _bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: _textMuted),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              items: const [
                DropdownMenuItem(value: 'PKR', child: Text('PKR')),
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                DropdownMenuItem(value: 'GBP', child: Text('GBP')),
                DropdownMenuItem(value: 'INR', child: Text('INR')),
                DropdownMenuItem(value: 'AED', child: Text('AED')),
                DropdownMenuItem(value: 'SAR', child: Text('SAR')),
              ],
              onChanged: (String? val) {
                if (val != null) setState(() => currency = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timezone',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: timezone,
              isExpanded: true,
              dropdownColor: _bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: _textMuted),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              items: const [
                DropdownMenuItem(value: 'Asia/Karachi', child: Text('Asia/Karachi')),
                DropdownMenuItem(value: 'Asia/Dubai', child: Text('Asia/Dubai')),
                DropdownMenuItem(value: 'Asia/Riyadh', child: Text('Asia/Riyadh')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata')),
              ],
              onChanged: (String? val) {
                if (val != null) setState(() => timezone = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFormatDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Format',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: dateFormat,
              isExpanded: true,
              dropdownColor: _bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: _textMuted),
              style: TextStyle(color: _textPrimary, fontSize: 14.sp),
              items: const [
                DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('dd/MM/yyyy')),
                DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/dd/yyyy')),
                DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('yyyy-MM-dd')),
                DropdownMenuItem(value: 'dd-MM-yyyy', child: Text('dd-MM-yyyy')),
              ],
              onChanged: (String? val) {
                if (val != null) setState(() => dateFormat = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerCard(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
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
                    color: color,
                    fontSize: 14.sp,
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
          _industrialButton(
            'Execute',
            onPressed: onTap,
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  void _resetAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgCard,
        title: Text('Confirm Reset', style: TextStyle(color: _textPrimary)),
        content: Text(
          'This will delete all students, teachers, attendance, and fee records. This action cannot be undone.',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          _industrialButton('Cancel', onPressed: () => Navigator.pop(context), isSecondary: true),
          _industrialButton('Reset All', onPressed: () {
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _archiveYear() {}

  Widget _buildSaveButton() {
    if (widget.isMobile) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _bgCard,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: SafeArea(
          child: _industrialButton(
            isSaving ? 'Saving...' : 'Save All Changes',
            onPressed: isSaving ? null : _saveSettings,
            isLoading: isSaving,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _textPrimary,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onChanged) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: _primary,
                surface: _bgCard,
                onSurface: _textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: _bgElevated,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: _textMuted,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.calendar_today, color: _primary, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _industrialTextField(
      String label,
      TextEditingController controller, {
        IconData? icon,
        TextInputType type = TextInputType.text,
        int maxLines = 1,
        String? hint,
        String? prefix,
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
            onChanged: onChanged,
            style: TextStyle(color: _textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp),
              prefixIcon: icon != null
                  ? Icon(icon, color: _textMuted, size: 20.sp)
                  : prefix != null
                  ? Padding(
                padding: EdgeInsets.only(left: 16.w, right: 8.w),
                child: Text(
                  prefix,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : null,
              prefixIconConstraints: prefix != null
                  ? BoxConstraints(minWidth: 0, minHeight: 0)
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: maxLines > 1 ? 16.h : 14.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _industrialSmallField(
      String value,
      Function(String) onChanged, {
        TextInputType type = TextInputType.text,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: TextEditingController(text: value),
        keyboardType: type,
        onChanged: onChanged,
        style: TextStyle(color: _textPrimary, fontSize: 13.sp),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        ),
      ),
    );
  }

  Widget _industrialSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _primary,
          activeTrackColor: _primary.withOpacity(0.3),
          inactiveThumbColor: _textMuted,
          inactiveTrackColor: _bgDark,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14.sp,
            ),
          ),
        ),
      ],
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
          color: isSelected ? null : _bgDark,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isSelected ? Colors.transparent : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
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
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
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
  }

  Widget _industrialIconButton(
      IconData icon, {
        Color? color,
        VoidCallback? onPressed,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgDark,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(icon, color: color ?? _textSecondary, size: 18.sp),
          ),
        ),
      ),
    );
  }
}