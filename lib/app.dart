import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edumanage/core/theme/app_theme.dart';
import 'package:edumanage/features/admin/presentation/pages/admin_dashboard_page.dart';

class EduManageApp extends StatelessWidget {
  const EduManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: 'EduManage Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AdminDashboardPage(schoolId: '', schoolName: '', adminName: '',),
        );
      },
    );
  }
}