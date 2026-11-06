import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription<User?>? _sub;

  AppUser? _user;
  bool _initializing = true; // true until we know if someone is logged in
  bool _loading = false; // true while a login/register request is running
  bool _needsVerification = false; // true after a login blocked by verification
  String? _error;
  String? _info;

  AppUser? get user => _user;
  bool get initializing => _initializing;
  bool get loading => _loading;
  bool get needsVerification => _needsVerification;
  String? get error => _error;
  String? get info => _info;
  bool get isLoggedIn => _user != null;
  bool get isStaff => _user?.isStaff ?? false;

  AuthProvider() {
    // Runs every time someone logs in or out
    _sub = _service.authChanges.listen((firebaseUser) async {
      if (firebaseUser == null || !firebaseUser.emailVerified) {
        _user = null;
      } else {
        _user = await _service.getAppUser(firebaseUser.uid);
      }
      _initializing = false;
      notifyListeners();
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(() => _service.register(
          name: name,
          email: email,
          password: password,
        ));
  }

  Future<bool> login({required String email, required String password}) {
    return _run(() => _service.login(email: email, password: password));
  }

  Future<bool> resendVerification({
    required String email,
    required String password,
  }) async {
    final ok = await _run(() => _service.resendVerification(
          email: email,
          password: password,
        ));
    if (ok) {
      _info = 'Verification email sent. Check your inbox and spam folder.';
      notifyListeners();
    }
    return ok;
  }

  Future<void> logout() async {
    await _service.logout();
  }

  void clearError() {
    _error = null;
    _info = null;
    _needsVerification = false;
    notifyListeners();
  }

  // Runs an action, shows loading, and turns errors into friendly messages
  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    _info = null;
    _needsVerification = false;
    notifyListeners();
    try {
      await action();
      _loading = false;
      notifyListeners();
      return true;
    } on EmailNotVerifiedException catch (e) {
      _error = e.toString();
      _needsVerification = true;
    } on FirebaseAuthException catch (e) {
      _error = _friendlyMessage(e.code);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}