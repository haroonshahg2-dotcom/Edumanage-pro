import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import 'login_page.dart';
import 'register_school_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
              const Color(0xFFA855F7),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40.h),

                  // App Logo
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.school,
                        size: 70.w,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ).animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .then()
                      .shake(duration: 200.ms),

                  SizedBox(height: 30.h),

                  // App Name
                  Text(
                    'EduManage Pro',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ).animate(delay: 200.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  SizedBox(height: 8.h),

                  // Tagline
                  Text(
                    'School Management System',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 2,
                    ),
                  ).animate(delay: 400.ms).fadeIn(),

                  SizedBox(height: 60.h),

                  // Admin Login
                  _buildRoleButton(
                    context: context,
                    title: 'Admin Login',
                    subtitle: 'School Administrator',
                    icon: Icons.admin_panel_settings,
                    color: Colors.redAccent,
                    delay: 500.ms,
                    onTap: () => _navigateToLogin(context, 'admin'),
                  ),

                  SizedBox(height: 16.h),

                  // Teacher Login
                  _buildRoleButton(
                    context: context,
                    title: 'Teacher Login',
                    subtitle: 'Faculty Member',
                    icon: Icons.person_outline,
                    color: AppTheme.successColor,
                    delay: 600.ms,
                    onTap: () => _navigateToLogin(context, 'teacher'),
                  ),

                  SizedBox(height: 16.h),

                  // Student Login
                  _buildRoleButton(
                    context: context,
                    title: 'Student Login',
                    subtitle: 'Student Portal',
                    icon: Icons.school_outlined,
                    color: AppTheme.infoColor,
                    delay: 700.ms,
                    onTap: () => _navigateToLogin(context, 'student'),
                  ),

                  SizedBox(height: 20.h),

                  // Register New School
                  _buildRegisterButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Role Button Widget
  Widget _buildRoleButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Duration delay,
    required VoidCallback onTap,
  }) {
    return Animate(
      delay: delay,
      effects: [
        FadeEffect(duration: 500.ms),
        SlideEffect(
          begin: const Offset(-50, 0),
          end: Offset.zero,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28.w,
                  ),
                ),
                SizedBox(width: 16.w),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Register Button
  Widget _buildRegisterButton(BuildContext context) {
    return Animate(
      delay: 800.ms,
      effects: [
        FadeEffect(duration: 600.ms),
        ScaleEffect(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToRegister(context),
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade600,
                  Colors.orange.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_business,
                  color: Colors.white,
                  size: 28.w,
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register New School',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Setup your school account',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation
  void _navigateToLogin(BuildContext context, String role) {
    print('🎯 Navigating to login with role: $role'); // Debug print
    Navigator.push(
      context,
      MaterialPageRoute(
        // FIX: userType bhi pass karo, empty string nahi
        builder: (context) => LoginPage(
          preselectedRole: role,
          userType: role,  // 👈 YEH FIX HAI
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterSchoolPage(),
      ),
    );
  }
}