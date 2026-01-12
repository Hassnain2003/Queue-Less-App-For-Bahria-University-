import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/appointment.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../auth/login_screen.dart';

class MinimalHandlerDashboard extends StatefulWidget {
  const MinimalHandlerDashboard({super.key});

  @override
  State<MinimalHandlerDashboard> createState() => _MinimalHandlerDashboardState();
}

class _MinimalHandlerDashboardState extends State<MinimalHandlerDashboard> {
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    print('=== MINIMAL HANDLER DASHBOARD INIT ===');
    _loadData();
  }

  Future<void> _loadData() async {
    print('Starting data load...');
    
    final deps = QueueLessDependencies.of(context);
    final authService = deps.authService;
    
    // Get current user - no waiting for streams
    _user = authService.currentUser;
    print('Current user: ${_user?.name}, role: ${_user?.role}, handlerRole: ${_user?.handlerRole}');
    
    // Force loading to stop after 3 seconds regardless
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        print('Forcing loading to stop after timeout');
        setState(() {
          _isLoading = false;
        });
      }
    });
    
    // Load appointments
    await _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    print('Loading appointments...');
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      // Get all appointments
      final allAppointments = await queueService.getStudentAppointments('').first;
      print('Found ${allAppointments.length} total appointments');
      
      // Simple filtering - if no handler role, show all
      List<Appointment> filtered = allAppointments;
      
      if (_user?.handlerRole != null) {
        print('Filtering for role: ${_user!.handlerRole}');
        filtered = allAppointments.where((apt) {
          final serviceName = apt.serviceName.toLowerCase();
          final role = _user!.handlerRole!.toLowerCase();
          
          return serviceName.contains(role) || 
                 (role.contains('canteen') && (serviceName.contains('crispino') || serviceName.contains('dean') || serviceName.contains('bite')));
        }).toList();
        print('Filtered to ${filtered.length} appointments');
      }
      
      if (mounted) {
        setState(() {
          _appointments = filtered;
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

  @override
  Widget build(BuildContext context) {
    print('Building widget, isLoading: $_isLoading, appointments: ${_appointments.length}');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Handler Dashboard${_user?.handlerRole != null ? ' - ${_user!.handlerRole}' : ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No Appointments', style: AppTextStyles.heading2),
            Text('Handler: ${_user?.name ?? "Unknown"}'),
            Text('Role: ${_user?.handlerRole ?? "No role"}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAppointments,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final apt = _appointments[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(apt.userName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(apt.userEmail),
                Text('Service: ${apt.serviceName}'),
                Text('Token: #${apt.tokenNumber}'),
                Text('Status: ${apt.status.name}'),
              ],
            ),
            trailing: apt.status == AppointmentStatus.pending
                ? ElevatedButton(
                    onPressed: () => _markInProgress(apt),
                    child: const Text('Start'),
                  )
                : apt.status == AppointmentStatus.inProgress
                    ? ElevatedButton(
                        onPressed: () => _markCompleted(apt),
                        child: const Text('Complete'),
                      )
                    : null,
          ),
        );
      },
    );
  }

  Future<void> _markInProgress(Appointment apt) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      await queueService.markNextAsInProgress(apt.serviceId);
      _loadAppointments();
    } catch (e) {
      print('Error marking in progress: $e');
    }
  }

  Future<void> _markCompleted(Appointment apt) async {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;
    
    try {
      await queueService.markCompleted(apt.id);
      _loadAppointments();
    } catch (e) {
      print('Error marking completed: $e');
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
