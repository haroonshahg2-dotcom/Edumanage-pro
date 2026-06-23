import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin credentials - CHANGE KAR SAKTE HO
  static const String adminEmail = 'admin@school.edu.pk';
  static const String adminPassword = 'Admin@123456'; // Strong password

  Future<void> createDefaultAdmin() async {
    try {
      // Check if admin already exists in Firestore
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        print('✅ Admin already exists in database');
        return;
      }

      String uid;

      // Try to create in Firebase Auth
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        uid = userCredential.user!.uid;
        print('✅ Admin created in Firebase Auth');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Admin already in Auth, get UID
          final methods = await _auth.fetchSignInMethodsForEmail(adminEmail);
          if (methods.isNotEmpty) {
            // Sign in to get UID
            final tempCredential = await _auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            uid = tempCredential.user!.uid;
            await _auth.signOut();
            print('✅ Admin already in Auth, using existing UID');
          } else {
            throw Exception('Email exists but cannot get UID');
          }
        } else {
          throw e;
        }
      }

      // Create admin document in users collection
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': adminEmail,
        'firstName': 'System',
        'lastName': 'Administrator',
        'fullName': 'System Administrator',
        'role': 'admin',
        'isActive': true,
        'isOnline': false,
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create in admins collection
      await _firestore.collection('admins').doc(uid).set({
        'uid': uid,
        'email': adminEmail,
        'firstName': 'System',
        'lastName': 'Administrator',
        'fullName': 'System Administrator',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('========================================');
      print('✅ DEFAULT ADMIN CREATED SUCCESSFULLY');
      print('========================================');
      print('📧 Email: $adminEmail');
      print('🔑 Password: $adminPassword');
      print('========================================');
      print('⚠️ IMPORTANT: Change password after first login!');
      print('========================================');

    } catch (e) {
      print('❌ Error creating admin: $e');
    }
  }
}