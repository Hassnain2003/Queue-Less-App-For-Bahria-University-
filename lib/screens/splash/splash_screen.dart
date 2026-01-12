import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../student/student_dashboard_screen.dart';
import '../handler/handler_dashboard_screen.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final deps = QueueLessDependencies.of(context);
    final AuthService authService = deps.authService;
    
    // Listen to auth state changes properly
    StreamSubscription? subscription;
    subscription = authService.authStateChanges().listen((user) {
      if (!mounted) return;
      
      // Cancel subscription after first event
      subscription?.cancel();
      
      if (user == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        if (user.role == UserRole.student) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HandlerDashboardScreen(initialUser: user)),
          );
        }
      }
    });
    
    // Add timeout as fallback
    Future.delayed(const Duration(seconds: 15), () {
      if (subscription != null && !subscription.isPaused) {
        subscription.cancel();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QueueLess',
              style: AppTextStyles.heading1.copyWith(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Appointment Manager',
              style: AppTextStyles.body.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
