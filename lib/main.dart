import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';
import 'features/admin/presentation/bloc/admin_event.dart';
import 'features/admin/data/datasources/admin_remote_datasource.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/teacher/presentation/pages/teacher_dashboard_page.dart';
import 'features/student/presentation/pages/student_dashboard_page.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';  // ✅ YEH ADD KARO

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 900; // ya kIsWeb use karo
    return ScreenUtilInit(
      designSize: isWeb ? const Size(1440, 900) : const Size(375, 812),  // ✅ YEH CHANGE KARO
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MaterialApp(
          title: 'EduManage Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomePage();
        }

        final user = snapshot.data!;
        return _buildDashboardRouter(user);
      },
    );
  }

  Widget _buildDashboardRouter(User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return FutureBuilder<void>(
            future: _createDefaultUser(user),
            builder: (context, createSnap) {
              if (createSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return _buildDashboardRouter(user);
            },
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'] as String? ?? 'student';

        // ✅ EXTRACT SCHOOL DATA FROM USER DOCUMENT
        final schoolId = data['schoolId'] as String? ?? '';
        final schoolName = data['schoolName'] as String? ?? 'School';
        final adminName = data['fullName'] as String? ?? 'Admin';

        // Update online status
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isOnline': true,
          'lastActive': FieldValue.serverTimestamp(),
        });

        switch (role) {
          case 'admin':
          // ✅ SAFETY CHECK - Agar schoolId empty hai
            if (schoolId.isEmpty) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'School Not Assigned',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Please contact administrator'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return BlocProvider(
              create: (_) => AdminBloc(
                AdminRemoteDataSource(
                  FirebaseAuth.instance,
                  FirebaseFirestore.instance,
                ),
              )..add(LoadDashboardStats()),
              child: AdminDashboardPage(
                schoolId: schoolId,      // ✅ User se aaya!
                schoolName: schoolName,   // ✅ User se aaya!
                adminName: adminName,     // ✅ User se aaya!
              ),
            );

          case 'teacher':
            return TeacherDashboardPage(teacherId: user.uid);

          case 'student':
          default:
            return StudentDashboardPage(studentId: user.uid);
        }
      },
    );
  }

  Future<void> _createDefaultUser(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'firstName': user.email?.split('@').first ?? 'User',
      'lastName': '',
      'fullName': user.email?.split('@').first ?? 'User',
      'role': 'admin',
      'schoolId': 'school_${user.uid}',  // ✅ AUTO-GENERATE SCHOOL ID
      'schoolName': 'My School',        // ✅ DEFAULT SCHOOL NAME
      'isActive': true,
      'isOnline': true,
      'lastActive': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}