import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum SyncStatus { idle, syncing, success, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authStateSubscription;
  
  bool _isAuthenticated = false;
  String? _email;
  String? _displayName;
  SyncStatus _syncStatus = SyncStatus.idle;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  String? get displayName => _displayName;
  SyncStatus get syncStatus => _syncStatus;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      _isAuthenticated = user != null;
      _email = user?.email;
      _displayName = user?.displayName ?? user?.email?.split('@').first;
      
      if (user != null) {
        // Trigger sync when user signs in
        unawaited(triggerSync());
      } else {
        // Clear sync status when user signs out
        _syncStatus = SyncStatus.idle;
      }
      
      notifyListeners();
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setError(null);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<bool> signUp({required String name, required String email, required String password}) async {
    _setError(null);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update display name
      await credential.user?.updateDisplayName(name.trim());
      await credential.user?.reload();
      
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _setError(null);
    } catch (e) {
      _setError('Error signing out. Please try again.');
    }
  }

  Future<void> triggerSync() async {
    if (!_isAuthenticated) return;
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 1));
      // Simulate occasional sync error in debug to validate error toasts
      if (kDebugMode && DateTime.now().millisecondsSinceEpoch % 7 == 0) {
        throw Exception('Network error while syncing');
      }
      _syncStatus = SyncStatus.success;
      _setError(null);
      notifyListeners();
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _setError(e.toString());
      notifyListeners();
    }
  }

  void clearError() {
    _setError(null);
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}