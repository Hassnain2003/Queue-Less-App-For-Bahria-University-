import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';
import '../public/queue_display_screen.dart';

class HandlerDashboardScreen extends StatefulWidget {
  const HandlerDashboardScreen({super.key});

  @override
  State<HandlerDashboardScreen> createState() => _HandlerDashboardScreenState();
}

class _HandlerDashboardScreenState extends State<HandlerDashboardScreen> {
  String? _serviceId;
  bool _isLoading = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final deps = QueueLessDependencies.of(context);
    final authService = deps.authService;
    
    // Listen for auth state changes to get complete user data
    StreamSubscription? subscription;
    subscription = authService.authStateChanges().listen((user) {
      if (!mounted) return;
      
      print('Auth state changed: user=${user?.email}, role=${user?.role}, handlerRole=${user?.handlerRole}');
      
      if (user != null) {
        setState(() {
          _user = user;
        });
        
        // Check if user has handler role info loaded
        if (user.role == UserRole.handler) {
          print('Handler user loaded with role: ${user.handlerRole}');
          _loadServiceId();
        } else if (user.role == UserRole.student) {
          print('User is student, redirecting to login');
          setState(() {
            _isLoading = false;
          });
          // Redirect to login if student somehow lands on handler dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else {
          print('Invalid user role, setting loading to false');
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    // Add timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (subscription != null && !subscription.isPaused && mounted && _isLoading) {
        print('Timeout reached, setting loading to false');
        subscription.cancel();
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadServiceId() async {
    if (_user == null) {
      print('Error: User is null');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    // Handle missing handler role gracefully
    final handlerRole = _user!.handlerRole ?? 'Student Advisor'; // Default fallback
    final canteen = _user!.canteen;
    final serviceName = _getServiceNameForHandlerRole(handlerRole, canteen);
    
    print('Loading service ID for handler role: $handlerRole, canteen: $canteen');
    print('Looking for service name: $serviceName');
    
    try {
      // Find service by name instead of using hardcoded ID
      final services = await queueService.getServices().first;
      print('Available services: ${services.map((s) => s.name).toList()}');
      
      if (services.isEmpty) {
        print('No services available');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final service = services.firstWhere(
        (s) => s.name.toLowerCase() == serviceName.toLowerCase(),
        orElse: () {
          print('Service not found: $serviceName. Using first available service.');
          return services.first; // Fallback to first service
        },
      );
      
      print('Found service: ${service.name} with ID: ${service.id}');
      
      if (mounted) {
        setState(() {
          _serviceId = service.id;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading service ID: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getServiceNameForHandlerRole(String handlerRole, String? canteen) {
    // Map handler roles to service names
    switch (handlerRole) {
      case 'Student Advisor':
        return 'Advisor Office';
      case 'HOD Coordinator':
        return 'HOD Meeting';
      case 'Accounts Office':
        return 'Accounts Office';
      case 'Canteen Staff':
        // Use canteen-specific mapping
        switch (canteen) {
          case 'Crispino':
            return 'Crispino';
          case 'Deans':
            return 'Deans Canteen';
          case 'Student Café':
            return 'Bites and Beans'; // Assuming this maps to Bites and Beans
          case 'Nescafe':
            return 'Quetta'; // Assuming this maps to Quetta
          default:
            return 'Crispino'; // Default fallback
        }
      default:
        return 'Advisor Office'; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Handler Dashboard'),
        ),
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading dashboard...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (_serviceId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Handler Dashboard'),
        ),
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Unable to load service',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Handler Role: ${_user?.handlerRole ?? "Not specified"}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadServiceId();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final authService = deps.authService;
                  await authService.logout();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Handler Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tv),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QueueDisplayScreen(serviceId: _serviceId!),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = deps.authService;
              await authService.logout();
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: StreamBuilder<List<Appointment>>(
          stream: queueService.watchServiceQueue(_serviceId!),
          builder: (context, snapshot) {
            final queue = snapshot.data ?? [];
            final current = queue
                .where((a) => a.status == AppointmentStatus.inProgress)
                .toList();
            final pending = queue
                .where((a) => a.status == AppointmentStatus.pending)
                .toList()
              ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Now Serving', style: AppTextStyles.heading2),
                      Text(
                        'Accepting',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (current.isEmpty)
                          Text(
                            'No one in progress',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textLight),
                          )
                        else
                          Text(
                            'Token #${current.first.tokenNumber} - ${current.first.userName}',
                            style: AppTextStyles.heading1,
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await queueService
                                    .markNextAsInProgress(_serviceId!);
                              },
                              child: const Text('Next'),
                            ),
                            const SizedBox(width: 8),
                            if (current.isNotEmpty) ...[
                              ElevatedButton(
                                onPressed: () async {
                                  await queueService
                                      .markCompleted(current.first.id);
                                },
                                child: const Text('Complete'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await queueService
                                      .markCancelled(current.first.id);
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Waiting Queue', style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final a = pending[index];
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          title: Text('Token #${a.tokenNumber}'),
                          subtitle: Text(a.userName),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
