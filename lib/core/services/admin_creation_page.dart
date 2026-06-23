import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import 'admin_setup_service.dart';

class AdminCreationPage extends StatefulWidget {
  const AdminCreationPage({super.key});

  @override
  State<AdminCreationPage> createState() => _AdminCreationPageState();
}

class _AdminCreationPageState extends State<AdminCreationPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController(text: 'admin@school.edu.pk');
  final _passwordController = TextEditingController(text: 'Admin@123456');
  final _firstNameController = TextEditingController(text: 'Muhammad');
  final _lastNameController = TextEditingController(text: 'Ali');
  final _schoolNameController = TextEditingController(text: 'Pakistan Public School');
  final _principalNameController = TextEditingController(text: 'Dr. Ahmad Hassan');
  final _contactController = TextEditingController(text: '+92-300-1234567');
  final _addressController = TextEditingController(text: 'Main Road, Lahore, Pakistan');
  final _sessionController = TextEditingController(text: '2024-2025');

  bool _isLoading = false;
  String? _result;

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = AdminSetupService();
      await service.createManualAdmin(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        schoolName: _schoolNameController.text.trim(),
        principalName: _principalNameController.text.trim(),
        contact: _contactController.text.trim(),
        address: _addressController.text.trim(),
        session: _sessionController.text.trim(),
      );

      setState(() {
        _result = '✅ Admin created successfully!\n\n'
            'Email: ${_emailController.text}\n'
            'Password: ${_passwordController.text}\n\n'
            'You can logIn.';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin (One Time Setup)'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Warning Card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Yeh sirf ek dafa use hoga! Admin create karne ke baad is page ko hata dein.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Form Fields
              _buildTextField(_emailController, 'Email', Icons.email),
              SizedBox(height: 12.h),
              _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
              SizedBox(height: 12.h),
              _buildTextField(_firstNameController, 'First Name', Icons.person),
              SizedBox(height: 12.h),
              _buildTextField(_lastNameController, 'Last Name', Icons.person),
              SizedBox(height: 12.h),
              _buildTextField(_schoolNameController, 'School Name', Icons.school),
              SizedBox(height: 12.h),
              _buildTextField(_principalNameController, 'Principal Name', Icons.person_outline),
              SizedBox(height: 12.h),
              _buildTextField(_contactController, 'Contact', Icons.phone),
              SizedBox(height: 12.h),
              _buildTextField(_addressController, 'Address', Icons.location_on, maxLines: 2),
              SizedBox(height: 12.h),
              _buildTextField(_sessionController, 'Session (e.g., 2024-2025)', Icons.calendar_today),

              SizedBox(height: 24.h),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CREATE ADMIN'),
                ),
              ),

              if (_result != null) ...[
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: _result!.startsWith('✅')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _result!,
                    style: TextStyle(
                      color: _result!.startsWith('✅')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isPassword = false,
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label required';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}