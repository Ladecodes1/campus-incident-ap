import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Only these email domains can use the app
  static const allowedDomains = ['alueducation.com', 'alustudent.com'];

  bool isAllowedEmail(String email) {
    final e = email.trim().toLowerCase();
    return allowedDomains.any((d) => e.endsWith('@$d'));
  }

  // Tells the app when someone logs in or out
  Stream<User?> get authChanges => _auth.authStateChanges();

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!isAllowedEmail(email)) {
      throw Exception('Please use your ALU email address.');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    await user.updateDisplayName(name.trim());

    // Save the profile in Firestore. Everyone starts as a student.
    final appUser = AppUser(
      uid: user.uid,
      email: email.trim().toLowerCase(),
      name: name.trim(),
      role: 'student',
    );
    await _db.collection('users').doc(user.uid).set(appUser.toMap());

    await user.sendEmailVerification();

    // Sign out so they must verify their email before logging in
    await _auth.signOut();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    if (!user.emailVerified) {
      await _auth.signOut();
      throw Exception('Please verify your email first. Check your inbox.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Loads the user's profile (including their role) from Firestore
  Future<AppUser?> getAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }
}