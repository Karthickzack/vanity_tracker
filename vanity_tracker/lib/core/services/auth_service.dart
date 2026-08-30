import 'dart:async';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth? _firebaseAuth;
  UserModel? _currentUser;
  final _authStateController = StreamController<UserModel?>.broadcast();

  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth {
    _initAuthState();
  }

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  void _initAuthState() {
    if (_firebaseAuth != null) {
      _firebaseAuth!.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = UserModel(
            userId: user.uid,
            name: user.displayName ?? user.email?.split('@').first ?? 'Beauty Lover',
            email: user.email ?? '',
          );
        } else {
          _currentUser = null;
        }
        _authStateController.add(_currentUser);
      });
    } else {
      // Default to guest/demo user for instant access
      _currentUser = const UserModel(
        userId: 'demo_user_1',
        name: 'Glow Explorer',
        email: 'user@vanitytracker.app',
      );
      _authStateController.add(_currentUser);
    }
  }

  /// Sign up with email & password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      if (_firebaseAuth != null) {
        final credential = await _firebaseAuth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await credential.user?.updateDisplayName(name.trim());
        final user = UserModel(
          userId: credential.user!.uid,
          name: name.trim(),
          email: email.trim(),
        );
        _currentUser = user;
        _authStateController.add(_currentUser);
        return user;
      } else {
        // Local fallback
        final user = UserModel(
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          email: email.trim(),
        );
        _currentUser = user;
        _authStateController.add(_currentUser);
        return user;
      }
    } catch (e) {
      dev.log('Sign up error: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Sign in with email & password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (_firebaseAuth != null) {
        final credential = await _firebaseAuth!.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final user = UserModel(
          userId: credential.user!.uid,
          name: credential.user!.displayName ?? email.split('@').first,
          email: email.trim(),
        );
        _currentUser = user;
        _authStateController.add(_currentUser);
        return user;
      } else {
        final user = UserModel(
          userId: 'demo_user_1',
          name: email.split('@').first,
          email: email.trim(),
        );
        _currentUser = user;
        _authStateController.add(_currentUser);
        return user;
      }
    } catch (e) {
      dev.log('Sign in error: $e', name: 'AuthService');
      rethrow;
    }
  }

  /// Sign in as Demo / Guest user for instant evaluation
  Future<UserModel> signInDemo([String name = 'Skincare Connoisseur']) async {
    final user = UserModel(
      userId: 'demo_user_1',
      name: name,
      email: 'demo@vanitytracker.app',
    );
    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    if (_firebaseAuth != null) {
      await _firebaseAuth!.signOut();
    }
    _currentUser = null;
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
