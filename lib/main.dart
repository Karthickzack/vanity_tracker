import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'core/constants/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/open_beauty_facts_service.dart';
import 'repositories/vanity_repository.dart';
import 'repositories/firestore_repository.dart';
import 'repositories/local_demo_repository.dart';
import 'providers/vanity_provider.dart';
import 'screens/auth/login_signup_screen.dart';
import 'screens/dashboard/vanity_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize Open Beauty Facts API service
  final beautyFactsService = OpenBeautyFactsService();

  // Initialize Firebase (or fallback to Local Demo Mode)
  VanityRepository repository;
  AuthService authService;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    dev.log('Firebase initialized in Test Mode successfully', name: 'VanityTracker');
    repository = FirestoreRepository(firestore: FirebaseFirestore.instance);
    authService = AuthService(firebaseAuth: FirebaseAuth.instance);
  } catch (e) {
    dev.log('Firebase initialization error / running in offline demo mode: $e', name: 'VanityTracker');
    repository = LocalDemoRepository();
    authService = AuthService(); // Local in-memory authentication
  }

  runApp(
    VanityTrackerApp(
      repository: repository,
      authService: authService,
      notificationService: notificationService,
      beautyFactsService: beautyFactsService,
    ),
  );
}

class VanityTrackerApp extends StatefulWidget {
  final VanityRepository repository;
  final AuthService authService;
  final NotificationService notificationService;
  final OpenBeautyFactsService beautyFactsService;

  const VanityTrackerApp({
    super.key,
    required this.repository,
    required this.authService,
    required this.notificationService,
    required this.beautyFactsService,
  });

  @override
  State<VanityTrackerApp> createState() => _VanityTrackerAppState();
}

class _VanityTrackerAppState extends State<VanityTrackerApp> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
    setState(() {
      _isAuthenticated = widget.authService.currentUser != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VanityProvider(
        repository: widget.repository,
        beautyFactsService: widget.beautyFactsService,
        notificationService: widget.notificationService,
        userId: widget.authService.currentUser?.userId ?? 'demo_user_1',
      ),
      child: MaterialApp(
        title: 'Vanity Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _isAuthenticated
            ? VanityDashboardScreen(
                authService: widget.authService,
                onSignOut: () {
                  setState(() => _isAuthenticated = false);
                },
              )
            : LoginSignupScreen(
                authService: widget.authService,
                onAuthenticated: () {
                  setState(() => _isAuthenticated = true);
                },
              ),
      ),
    );
  }
}
