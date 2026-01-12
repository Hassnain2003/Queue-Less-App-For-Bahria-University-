import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';

class NewHandlerDashboardScreen extends StatefulWidget {
  const NewHandlerDashboardScreen({super.key});

  @override
  State<NewHandlerDashboardScreen> createState() => _NewHandlerDashboardScreenState();
}

class _NewHandlerDashboardScreenState extends State<NewHandlerDashboardScreen> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  AppUser? _user;
  String? _handlerRole;

  @override
  void initState() {
    super.initState();
    _initializeHandler();
  }

  Future<void> _initializeHandler() async {
    final deps = QueueLessDependencies.of(context);
    final authService = deps.authService;
    
    // Get current user immediately
    _user = authService.currentUser;
    
    if (_user == null) {
      // Wait for auth state
      authService.authStateChanges().listen((user) {
        if (!mounted) return;
        if (user != null && user.role == UserRole.handler) {
          _loadHandlerData(user);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    } else if (_user!.role == UserRole.handler) {
      _loadHandlerData(_user!);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _loadHandlerData(AppUser user) async {
    setState(() {
      _user = user;
      _handlerRole = user.handlerRole;
    });
    
    print('Handler loaded: ${user.name}, Role: ${user.handlerRole}, Canteen: ${user.canteen}');
    
    await _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Loading appointments for handler role: $_handlerRole');
      
      // Get all appointments
      final allAppointments = await queueService.getStudentAppointments('').first;
      print('Total appointments found: ${allAppointments.length}');
      
      // Filter by handler role
      final filteredAppointments = _filterAppointmentsByRole(allAppointments);
      print('Filtered appointments for handler: ${filteredAppointments.length}');
      
      if (mounted) {
        setState(() {
          _appointments = filteredAppointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Appointment> _filterAppointmentsByRole(List<Appointment> appointments) {
    if (_handlerRole == null) {
      print('No handler role, showing all appointments');
      return appointments;
    }
    
    print('Filtering appointments for role: $_handlerRole');
    
    return appointments.where((appointment) {
      switch (_handlerRole) {
        case 'Student Advisor':
          return appointment.serviceName.toLowerCase().contains('advisor');
        case 'HOD Coordinator':
          return appointment.serviceName.toLowerCase().contains('hod');
        case 'Accounts Office':
          return appointment.serviceName.toLowerCase().contains('account');
        case 'Canteen Staff':
          // Filter by canteen
          final canteen = _user?.canteen?.toLowerCase() ?? '';
          print('Filtering canteen: $canteen');
          
          switch (canteen) {
            case 'crispino':
              return appointment.serviceName.toLowerCase().contains('crispino');
            case 'deans':
              return appointment.serviceName.toLowerCase().contains('dean');
            case 'student café':
              return appointment.serviceName.toLowerCase().contains('bite') || 
                     appointment.serviceName.toLowerCase().contains('bean');
            case 'nescafe':
              return appointment.serviceName.toLowerCase().contains('quetta');
            default:
              return appointment.serviceName.toLowerCase().contains('crispino');
          }
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Handler Dashboard'),
            if (_handlerRole != null)
              Text(
                _handlerRole!,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAppointmentsList(),
    );
  }

  Widget _buildAppointmentsList() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Appointments',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No bookings found for ${_handlerRole ?? 'your department'}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.userName,
                        style: AppTextStyles.heading2,
                      ),
                      Text(
                        appointment.userEmail,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                      if (appointment.userEnrollment != null)
                        Text(
                          'Enrollment: ${appointment.userEnrollment}',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.name.toUpperCase(),
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  appointment.serviceName,
                  style: AppTextStyles.body,
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Token #${appointment.tokenNumber}',
                  style: AppTextStyles.body,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${appointment.scheduledTime.toString().substring(0, 16)}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(appointment),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callNext(appointment),
                icon: const Icon(Icons.play_arrow),
                label: const Text('CALL NEXT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelAppointment(appointment),
                icon: const Icon(Icons.cancel),
                label: const Text('CANCEL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
              ),
            ),
          ],
        );
      case AppointmentStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _completeAppointment(appointment),
                icon: const Icon(Icons.check),
                label: const Text('COMPLETE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelAppointment(appointment),
                icon: const Icon(Icons.cancel),
                label: const Text('CANCEL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
              ),
            ),
          ],
        );
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.inProgress:
        return AppColors.primaryBlue;
      case AppointmentStatus.completed:
        return AppColors.accentGreen;
      case AppointmentStatus.cancelled:
        return AppColors.errorRed;
    }
  }

  Future<void> _callNext(Appointment appointment) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      print('Calling next appointment: ${appointment.id}');
      await queueService.markNextAsInProgress(appointment.serviceId);
      await _loadAppointments(); // Refresh
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment called!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      print('Error calling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _completeAppointment(Appointment appointment) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      print('Completing appointment: ${appointment.id}');
      await queueService.markCompleted(appointment.id);
      await _loadAppointments(); // Refresh
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment completed!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } catch (e) {
      print('Error completing appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel the appointment for ${appointment.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('YES'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      print('Cancelling appointment: ${appointment.id}');
      await queueService.markCancelled(appointment.id);
      await _loadAppointments(); // Refresh
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } catch (e) {
      print('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final deps = QueueLessDependencies.of(context);
    await deps.authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
