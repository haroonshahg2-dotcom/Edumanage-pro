import 'package:edumanage/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';

class RegisterSchoolPage extends StatefulWidget {
  const RegisterSchoolPage({super.key});

  @override
  State<RegisterSchoolPage> createState() => _RegisterSchoolPageState();
}

class _RegisterSchoolPageState extends State<RegisterSchoolPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // School Info Controllers
  final _schoolNameController = TextEditingController();
  final _schoolAddressController = TextEditingController();
  final _schoolPhoneController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _schoolWebsiteController = TextEditingController();

  // Admin Info Controllers
  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminPhoneController = TextEditingController();

  bool _isLoading = false;
  String? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade600,
              Colors.orange.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Register New School',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Steps
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Row(
                  children: [
                    _buildStepIndicator(0, 'School'),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                    _buildStepIndicator(1, 'Admin'),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.5))),
                    _buildStepIndicator(2, 'Plan'),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildSchoolInfoStep(),
                    _buildAdminInfoStep(),
                    _buildPlanStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== STEP 1: SCHOOL INFO ====================
  Widget _buildSchoolInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.orange, size: 32.w),
                    SizedBox(width: 12.w),
                    Text(
                      'School Information',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Step 1 of 3',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.greyColor,
                  ),
                ),
                SizedBox(height: 24.h),

                _buildTextField(
                  controller: _schoolNameController,
                  label: 'School Name *',
                  icon: Icons.school,
                  hint: 'Pakistan Public School',
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _schoolAddressController,
                  label: 'School Address *',
                  icon: Icons.location_on,
                  hint: '123 Main Street, Lahore',
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _schoolPhoneController,
                  label: 'Contact Number *',
                  icon: Icons.phone,
                  hint: '+92 300 1234567',
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _schoolEmailController,
                  label: 'School Email *',
                  icon: Icons.email,
                  hint: 'info@school.edu.pk',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _schoolWebsiteController,
                  label: 'Website (Optional)',
                  icon: Icons.language,
                  hint: 'www.school.edu.pk',
                ),

                SizedBox(height: 30.h),

                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_validateSchoolInfo()) {
                        _pageController.nextPage(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'NEXT: CREATE ADMIN',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

  // ==================== STEP 2: ADMIN ACCOUNT ====================
  Widget _buildAdminInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.orange, size: 32.w),
                    SizedBox(width: 12.w),
                    Text(
                      'Create Admin Account',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'Step 2 of 3 - You will be the administrator',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.greyColor,
                  ),
                ),
                SizedBox(height: 24.h),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _adminFirstNameController,
                        label: 'First Name *',
                        icon: Icons.person,
                        hint: 'Ahmad',
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTextField(
                        controller: _adminLastNameController,
                        label: 'Last Name *',
                        icon: Icons.person,
                        hint: 'Hassan',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _adminEmailController,
                  label: 'Email Address *',
                  icon: Icons.email,
                  hint: 'admin@school.edu.pk',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _adminPasswordController,
                  label: 'Password *',
                  icon: Icons.lock,
                  hint: 'Min 6 characters',
                  isPassword: true,
                ),
                SizedBox(height: 16.h),

                _buildTextField(
                  controller: _adminPhoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  hint: '+92 300 1234567',
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 30.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pageController.previousPage(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('BACK'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_validateAdminInfo()) {
                            _pageController.nextPage(
                              duration: 300.ms,
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('NEXT: CHOOSE PLAN'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STEP 3: PLAN ====================
  Widget _buildPlanStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 24.h),

          _buildPlanCard(
            title: 'FREE TRIAL',
            price: 'FREE',
            period: '14 days',
            features: [
              '✓ Up to 100 students',
              '✓ Basic features only',
              '✓ Email support',
            ],
            color: Colors.green,
            planId: 'free',
          ),
          SizedBox(height: 16.h),

          _buildPlanCard(
            title: 'MONTHLY',
            price: '₨4,999',
            period: 'per month',
            features: [
              '✓ Unlimited students',
              '✓ All features included',
            ],
            color: Colors.blue,
            planId: 'monthly',
            isPopular: true,
          ),
          SizedBox(height: 16.h),

          _buildPlanCard(
            title: 'YEARLY',
            price: '₨49,999',
            period: 'per year',
            features: [
              '✓ Everything in Monthly',
              '✓ White-labeling option',
            ],
            color: Colors.purple,
            planId: 'yearly',
          ),
          SizedBox(height: 30.h),

          TextButton.icon(
            onPressed: () => _pageController.previousPage(
              duration: 300.ms,
              curve: Curves.easeInOut,
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('GO BACK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({required String title, required String price, required String period, required List<String> features, required Color color, required String planId, bool isPopular = false}) {
    final isSelected = _selectedPlan == planId;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: _isLoading ? null : () => setState(() => _selectedPlan = planId),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Radio<String>(
                    value: planId,
                    groupValue: _selectedPlan,
                    onChanged: _isLoading ? null : (v) => setState(() => _selectedPlan = v),
                    activeColor: color,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(price, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: color)),
                      Text(period, style: TextStyle(fontSize: 12.sp, color: AppTheme.greyColor)),
                    ],
                  ),
                ],
              ),
              if (isSelected) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _registerSchool(_selectedPlan!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SELECT & CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== REGISTER SCHOOL ====================
  Future<void> _registerSchool(String plan) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _adminEmailController.text.trim(),
        password: _adminPasswordController.text.trim(),
      );
      final adminUid = userCredential.user!.uid;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final schoolId = 'school_$timestamp';

      // 🔹 Schools Collection
      await FirebaseFirestore.instance.collection('schools').doc(schoolId).set({
        'name': _schoolNameController.text.trim(),
        'adminId': adminUid,
        'email': _schoolEmailController.text.trim(),
        'phone': _schoolPhoneController.text.trim(),
        'website': _schoolWebsiteController.text.trim(),
        'plan': plan,
        'planExpiry': _calculatePlanExpiry(plan),
        'isActive': true,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      // 🔹 Admin Subcollection
      await FirebaseFirestore.instance.collection('schools').doc(schoolId).collection('admins').doc(adminUid).set({
        'uid': adminUid,
        'fullName': '${_adminFirstNameController.text} ${_adminLastNameController.text}',
        'firstName': _adminFirstNameController.text.trim(),
        'lastName': _adminLastNameController.text.trim(),
        'email': _adminEmailController.text.trim(),
        'phone': _adminPhoneController.text.trim(),
        'role': 'admin',
        'isActive': true,
        'isOnline': true,
        'createdAt': timestamp,
        'lastActive': timestamp,
      });

      // 🔹 Global Users Collection
      await FirebaseFirestore.instance.collection('users').doc(adminUid).set({
        'uid': adminUid,
        'fullName': '${_adminFirstNameController.text} ${_adminLastNameController.text}',
        'firstName': _adminFirstNameController.text.trim(),
        'lastName': _adminLastNameController.text.trim(),
        'email': _adminEmailController.text.trim(),
        'role': 'admin',
        'schoolId': schoolId,
        'isActive': true,
        'isOnline': true,
        'createdAt': timestamp,
        'lastActive': timestamp,
      });

      if (mounted) _showSuccessDialog(schoolId);

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = 'Registration failed';
      if (e.code == 'email-already-in-use') errorMsg = 'This email already in-use';
      else if (e.code == 'weak-password') errorMsg = 'Password is week (min 6 characters)';
      else if (e.code == 'invalid-email') errorMsg = 'Incorrect email format';
      _showError(errorMsg);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Koi error aa gaya: $e');
    }
  }

  DateTime _calculatePlanExpiry(String plan) {
    final now = DateTime.now();
    switch (plan) {
      case 'free': return now.add(const Duration(days: 14));
      case 'monthly': return now.add(const Duration(days: 30));
      case 'yearly': return now.add(const Duration(days: 365));
      default: return now.add(const Duration(days: 14));
    }
  }

  // ==================== VALIDATION ====================
  bool _validateSchoolInfo() {
    if (_schoolNameController.text.isEmpty) { _showError('Enter School Name'); return false; }
    if (_schoolAddressController.text.isEmpty) { _showError('Enter Address'); return false; }
    if (_schoolPhoneController.text.isEmpty) { _showError('Enter Phone Number'); return false; }
    if (_schoolEmailController.text.isEmpty || !_schoolEmailController.text.contains('@')) { _showError('Use correct email'); return false; }
    return true;
  }

  bool _validateAdminInfo() {
    if (_adminFirstNameController.text.isEmpty) { _showError('Enter First Name'); return false; }
    if (_adminLastNameController.text.isEmpty) { _showError('Enter Last Name'); return false; }
    if (_adminEmailController.text.isEmpty || !_adminEmailController.text.contains('@')) { _showError('Use correct admin email'); return false; }
    if (_adminPasswordController.text.length < 6) { _showError('Password Must be at leat 6 character'); return false; }
    return true;
  }

  void _showSuccessDialog(String schoolId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64.w),
            SizedBox(height: 16.h),
            const Text('🎉 Registration Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_schoolNameController.text}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8.h),
            const Text('has been successfully registered'),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(
                    preselectedRole: 'admin',
                    prefilledEmail: _adminEmailController.text.trim(),
                    userType: '',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('GO TO LOGIN'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentPage >= step;
    return Column(
      children: [
        CircleAvatar(
          radius: 16.w,
          backgroundColor: isActive ? Colors.white : Colors.white.withOpacity(0.3),
          child: Text('${step + 1}', style: TextStyle(color: isActive ? Colors.orange : Colors.white, fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 4.h),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, int maxLines = 1, TextInputType? keyboardType, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _schoolNameController.dispose();
    _schoolAddressController.dispose();
    _schoolPhoneController.dispose();
    _schoolEmailController.dispose();
    _schoolWebsiteController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminPhoneController.dispose();
    super.dispose();
  }
}