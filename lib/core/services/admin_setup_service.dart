import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSetupService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============= MANUAL ADMIN CREATION =============
  // Yeh method sirf developer use karega - App start pehle nahi chalta
  // Isko manually call karna hai ya Firebase Console se data add karna hai

  Future<void> createManualAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String schoolName,
    required String principalName,
    required String contact,
    required String address,
    required String session,
  }) async {
    try {
      // Step 1: Check if admin already exists
      final existingAdmin = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (existingAdmin.docs.isNotEmpty) {
        print('⚠️ Admin already exists!');
        print('Existing admin email: ${existingAdmin.docs.first['email']}');
        return;
      }

      // Step 2: Create Firebase Auth user
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Firebase Auth user created: ${userCredential.user!.uid}');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Agar email already exist karta hai, toh sign in karke UID lo
          final signInResult = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          userCredential = signInResult;
          print('✅ Using existing Firebase Auth user: ${userCredential.user!.uid}');
        } else {
          throw e;
        }
      }

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      // Step 3: Create users collection document
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'role': 'admin',
        'isActive': true,
        'isOnline': false,
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Users collection document created');

      // Step 4: Create admins collection document (school details)
      await _firestore.collection('admins').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': '$firstName $lastName',
        'schoolName': schoolName,
        'principalName': principalName,
        'contact': contact,
        'address': address,
        'session': session,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Admins collection document created');

      // Step 5: Create school settings document
      await _firestore.collection('settings').doc('school').set({
        'schoolName': schoolName,
        'principalName': principalName,
        'contact': contact,
        'address': address,
        'currentSession': session,
        'adminId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ School settings created');

      print('\n╔════════════════════════════════════════════════╗');
      print('║     ✅ ADMIN CREATED SUCCESSFULLY!              ║');
      print('╠════════════════════════════════════════════════╣');
      print('║  📧 Email: $email');
      print('║  🔑 Password: $password');
      print('║  🏫 School: $schoolName');
      print('║  👤 Principal: $principalName');
      print('╚════════════════════════════════════════════════╝');

      // Sign out after creation (taake login screen pe ja sake)
      await _auth.signOut();

    } catch (e) {
      print('❌ Error creating admin: $e');
      throw Exception('Failed to create admin: $e');
    }
  }

  // ============= CHECK ADMIN STATUS =============
  Future<bool> checkAdminExists() async {
    final adminQuery = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    return adminQuery.docs.isNotEmpty;
  }

  // ============= GET ADMIN DETAILS =============
  Future<Map<String, dynamic>?> getAdminDetails() async {
    final adminQuery = await _firestore
        .collection('admins')
        .limit(1)
        .get();

    if (adminQuery.docs.isNotEmpty) {
      return adminQuery.docs.first.data();
    }
    return null;
  }
}