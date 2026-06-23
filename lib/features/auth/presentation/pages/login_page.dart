import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  final String? preselectedRole;
  final String? prefilledEmail;

  const LoginPage({
    super.key,
    this.preselectedRole,
    this.prefilledEmail,
    required String userType,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.preselectedRole;
    if (widget.prefilledEmail != null) {
      _emailController.text = widget.prefilledEmail!;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Firebase Auth Login
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      debugPrint('✅ Login successful. UID: \$uid');

      // Fetch user from Firestore users collection
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      debugPrint('📄 users/\$uid exists: \${userDoc.exists}');

      if (!userDoc.exists) {
        throw Exception('User not found in users collection. Please register first.');
      }

      final userData = userDoc.data()!;
      final role = userData['role'] ?? '';
      final schoolId = userData['schoolId'] ?? '';

      debugPrint('📄 User role: \$role');
      debugPrint('📄 User schoolId: \$schoolId');

      if (_selectedRole != null && role != _selectedRole) {
        throw Exception('Aap is role se login nahi kar sakte');
      }

      if (schoolId.isEmpty) {
        throw Exception('School ID missing hai. Please contact support.');
      }

      // Fetch school data from schools collection (COMPLETE DATA)
      debugPrint('🔍 Fetching school: schools/\$schoolId');
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .get();

      debugPrint('📄 School doc exists: \${schoolDoc.exists}');

      // Check if school document exists
      if (!schoolDoc.exists) {
        // Try to find school by adminId as fallback
        debugPrint('⚠️ School not found by ID. Trying adminId fallback...');
        final schoolQuery = await FirebaseFirestore.instance
            .collection('schools')
            .where('adminId', isEqualTo: uid)
            .limit(1)
            .get();

        if (schoolQuery.docs.isNotEmpty) {
          final foundSchool = schoolQuery.docs.first;
          debugPrint('✅ Found school by adminId: \${foundSchool.id}');

          // Update user's schoolId
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'schoolId': foundSchool.id,
          });

          // Use found school
          final schoolData = foundSchool.data();
          final String schoolName = schoolData.containsKey('name')
              ? schoolData['name'] as String? ?? 'School'
              : 'School';

          _navigateToDashboard(schoolId: foundSchool.id, schoolName: schoolName, uid: uid, role: role);
          return;
        }

        throw Exception('School data not found. School ID: \$schoolId. Please contact support.');
      }

      final schoolData = schoolDoc.data()!;

      // Safely get school name with fallback
      final String schoolName = schoolData.containsKey('name')
          ? schoolData['name'] as String? ?? 'School'
          : 'School';

      debugPrint('📄 School name: \$schoolName');

      // Fetch admin data from schools/{schoolId}/admins/{uid}
      final adminDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('admins')
          .doc(uid)
          .get();

      // Safely get admin name with fallback
      final String adminName;
      if (adminDoc.exists && adminDoc.data() != null) {
        final adminData = adminDoc.data()!;
        adminName = adminData.containsKey('fullName')
            ? adminData['fullName'] as String? ?? 'Admin'
            : 'Admin';
      } else {
        adminName = 'Admin';
      }

      _navigateToDashboard(schoolId: schoolId, schoolName: schoolName, adminName: adminName, uid: uid, role: role);

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = 'Login failed';
      if (e.code == 'user-not-found') errorMsg = 'User exist nahi karta';
      else if (e.code == 'wrong-password') errorMsg = 'Password galat hai';
      else if (e.code == 'invalid-email') errorMsg = 'Email format galat hai';
      else if (e.code == 'invalid-credential') errorMsg = 'Email ya password galat hai';
      setState(() => _error = errorMsg);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Login error: \$e');
      setState(() => _error = e.toString());
    }
  }

  void _navigateToDashboard({
    required String schoolId,
    required String schoolName,
    String adminName = 'Admin',
    required String uid,
    required String role,
  }) {
    if (mounted) {
      setState(() => _isLoading = false);
      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardPage(
              schoolId: schoolId,
              schoolName: schoolName,
              adminName: adminName,
            ),
          ),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dashboard for \$role not implemented yet')),
        );
      }
    }
  }

  Color get _roleColor {
    switch (_selectedRole) {
      case 'admin': return Colors.redAccent;
      default: return Colors.blue;
    }
  }

  String get _roleTitle {
    switch (_selectedRole) {
      case 'admin': return 'Admin Login';
      default: return 'Login';
    }
  }

  IconData _getRoleIcon() {
    switch (_selectedRole) {
      case 'admin': return Icons.admin_panel_settings;
      default: return Icons.login;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _roleColor,
              _roleColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Icon(_getRoleIcon(), size: 80.w, color: Colors.white),
                  SizedBox(height: 20.h),
                  Text(
                    _roleTitle,
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 40.h),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            validator: (v) => v!.isEmpty ? 'Email chahiye' : null,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: const Icon(Icons.email),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: (v) => v!.isEmpty ? 'Password chahiye' : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          ),
                          if (_error != null) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _roleColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text('LOGIN AS \${_selectedRole?.toUpperCase() ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}