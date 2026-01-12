import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';

class SimpleHandlerDashboardScreen extends StatefulWidget {
  const SimpleHandlerDashboardScreen({super.key});

  @override
  State<SimpleHandlerDashboardScreen> createState() => _SimpleHandlerDashboardScreenState();
}

class _SimpleHandlerDashboardScreenState extends State<SimpleHandlerDashboardScreen> {
  List<Appointment> _appointments = [];
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
    
    // Get current user immediately
    _user = authService.currentUser;
    
    if (_user == null) {
      // If no current user, wait for auth state
      authService.authStateChanges().listen((user) {
        if (!mounted) return;
        if (user != null && user.role == UserRole.handler) {
          setState(() {
            _user = user;
          });
          _loadAppointments();
        } else {
          setState(() {
            _isLoading = false;
          });
          // Redirect to login if not a handler
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    } else if (_user!.role == UserRole.handler) {
      _loadAppointments();
    } else {
      setState(() {
        _isLoading = false;
      });
      // Redirect to login if not a handler
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _loadAppointments() async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      print('Loading all appointments for handler dashboard...');
      
      // Load all appointments and filter by handler role
      final allAppointments = await queueService.getStudentAppointments('').first;
      
      // Filter appointments based on handler role
      final filteredAppointments = _filterAppointmentsByHandlerRole(allAppointments);
      
      if (mounted) {
        setState(() {
          _appointments = filteredAppointments;
          _isLoading = false;
        });
      }
      
      print('Loaded ${filteredAppointments.length} appointments for handler');
    } catch (e) {
      print('Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Appointment> _filterAppointmentsByHandlerRole(List<Appointment> appointments) {
    if (_user == null) return appointments;
    
    // If no specific handler role, show all appointments
    if (_user!.handlerRole == null) {
      print('No specific handler role, showing all appointments');
      return appointments;
    }
    
    // Filter based on handler role
    final handlerRole = _user!.handlerRole!;
    print('Filtering appointments for handler role: $handlerRole');
    
    return appointments.where((appointment) {
      switch (handlerRole) {
        case 'Student Advisor':
          return appointment.serviceName == 'Advisor Office';
        case 'HOD Coordinator':
          return appointment.serviceName == 'HOD Meeting';
        case 'Accounts Office':
          return appointment.serviceName == 'Accounts Office';
        case 'Canteen Staff':
          // Show appointments for the specific canteen
          final canteen = _user!.canteen;
          switch (canteen) {
            case 'Crispino':
              return appointment.serviceName == 'Crispino';
            case 'Deans':
              return appointment.serviceName == 'Deans Canteen';
            case 'Student Café':
              return appointment.serviceName == 'Bites and Beans';
            case 'Nescafe':
              return appointment.serviceName == 'Quetta theirs';
            default:
              return appointment.serviceName == 'Crispino';
          }
        default:
          return true; // Show all for unknown roles
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Handler Dashboard'),
        ),
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Handler Dashboard${_user?.handlerRole != null ? ' - ${_user!.handlerRole}' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final deps = QueueLessDependencies.of(context);
              await deps.authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _appointments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No appointments found',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
Text(
                      _user?.handlerRole != null 
                        ? 'No appointments for ${_user!.handlerRole}'
                        : 'No appointments available',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(appointment.userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.userEmail),
                          if (appointment.userEnrollment != null)
                            Text('Enrollment: ${appointment.userEnrollment}'),
                          Text('Service: ${appointment.serviceName}'),
                          Text('Token: #${appointment.tokenNumber}'),
                          Text('Time: ${appointment.scheduledTime.toString().substring(0, 16)}'),
                        ],
                      ),
                      trailing: _buildActionButtons(appointment),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (appointment.status == AppointmentStatus.pending)
          ElevatedButton(
            onPressed: () => _markInProgress(appointment),
            child: const Text('Start'),
          ),
        if (appointment.status == AppointmentStatus.inProgress)
          ElevatedButton(
            onPressed: () => _markCompleted(appointment),
            child: const Text('Complete'),
          ),
        const SizedBox(height: 4),
        if (appointment.status != AppointmentStatus.completed)
          OutlinedButton(
            onPressed: () => _cancelAppointment(appointment),
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  Future<void> _markInProgress(Appointment appointment) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      await queueService.markNextAsInProgress(appointment.serviceId);
      _loadAppointments(); // Refresh the list
    } catch (e) {
      print('Error marking appointment as in progress: $e');
    }
  }

  Future<void> _markCompleted(Appointment appointment) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      await queueService.markCompleted(appointment.id);
      _loadAppointments(); // Refresh the list
    } catch (e) {
      print('Error marking appointment as completed: $e');
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      await queueService.markCancelled(appointment.id);
      _loadAppointments(); // Refresh the list
    } catch (e) {
      print('Error cancelling appointment: $e');
    }
  }
}
