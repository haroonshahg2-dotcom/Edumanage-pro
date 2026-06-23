import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import 'login_page.dart';

class UserTypeSelectionPage extends StatelessWidget {
  const UserTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                // Logo
                Icon(
                  Icons.school,
                  size: 80.w,
                  color: Colors.white,
                ),
                SizedBox(height: 20.h),
                Text(
                  'EduManage Pro',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'School Management System',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 60.h),

                // Select User Type Text
                Text(
                  'Select User Type',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 30.h),

                // User Type Cards
                _buildUserTypeCard(
                  context,
                  title: 'Admin',
                  subtitle: 'School Administrator',
                  icon: Icons.admin_panel_settings,
                  color: Colors.orange,
                  onTap: () => _navigateToLogin(context, 'admin'),
                ),
                SizedBox(height: 16.h),
                _buildUserTypeCard(
                  context,
                  title: 'Teacher',
                  subtitle: 'Faculty Member',
                  icon: Icons.person,
                  color: AppTheme.successColor,
                  onTap: () => _navigateToLogin(context, 'teacher'),
                ),
                SizedBox(height: 16.h),
                _buildUserTypeCard(
                  context,
                  title: 'Student',
                  subtitle: 'Student Portal',
                  icon: Icons.school,
                  color: AppTheme.infoColor,
                  onTap: () => _navigateToLogin(context, 'student'),
                ),
                SizedBox(height: 16.h),
                _buildUserTypeCard(
                  context,
                  title: 'Guest',
                  subtitle: 'View Only Access',
                  icon: Icons.visibility,
                  color: Colors.purple,
                  onTap: () => _navigateAsGuest(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32.w,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20.w,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(userType: userType),
      ),
    );
  }

  void _navigateAsGuest(BuildContext context) {
    // Guest functionality - abhi sirf message show karein
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Guest access coming soon!'),
        backgroundColor: Colors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(20.w),
      ),
    );
  }
}