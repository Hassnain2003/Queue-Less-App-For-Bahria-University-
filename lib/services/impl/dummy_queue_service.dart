import 'dart:async';

import '../../models/appointment.dart';
import '../../models/service.dart';
import '../queue_service.dart';

class DummyQueueService implements QueueService {
  final List<Service> _services = [
    const Service(
      id: 'advisor_office',
      name: 'Advisor Office',
      description: 'Course advising and academic guidance',
      location: 'Main Block',
      minutesPerPerson: 15,
    ),
    const Service(
      id: 'canteen_deans',
      name: 'Deans Canteen',
      description: 'Food and beverages',
      location: 'Central Courtyard',
      minutesPerPerson: 3,
    ),
    const Service(
      id: 'canteen_crispino',
      name: 'Crispino',
      description: 'Fast food and snacks',
      location: 'Food Court',
      minutesPerPerson: 4,
    ),
    const Service(
      id: 'canteen_muncheez',
      name: 'Muncheez',
      description: 'Fast food and snacks',
      location: 'Food Court',
      minutesPerPerson: 4,
    ),
    const Service(
      id: 'canteen_quetta',
      name: 'Quetta',
      description: 'Tea and snacks',
      location: 'Food Court',
      minutesPerPerson: 2,
    ),
    const Service(
      id: 'canteen_bites_beans',
      name: 'Bites and Beans',
      description: 'Coffee and snacks',
      location: 'Food Court',
      minutesPerPerson: 5,
    ),
    const Service(
      id: 'accounts_office',
      name: 'Accounts Office',
      description: 'Fee and accounts related queries',
      location: 'Admin Block',
      minutesPerPerson: 10,
    ),
    const Service(
      id: 'hod_meeting',
      name: 'HOD Meeting',
      description: 'Meetings with Head of Department',
      location: 'Department Office',
      minutesPerPerson: 20,
    ),
    const Service(
      id: 'rector_meeting',
      name: 'Rector Meeting',
      description: 'Meetings with Rector',
      location: 'Rector Office',
      minutesPerPerson: 25,
    ),
  ];

  final List<Appointment> _appointments = [];

  final _servicesController = StreamController<List<Service>>.broadcast();
  final _studentAppointmentsControllers =
      <String, StreamController<List<Appointment>>>{};
  final _serviceQueueControllers =
      <String, StreamController<List<Appointment>>>{};
  final _appointmentControllers =
      <String, StreamController<Appointment?>>{};
  final _publicQueueControllers =
      <String, StreamController<QueueSnapshot>>{};

  final Map<String, bool> _serviceOpenState = {};
  final Map<String, StreamController<bool>> _serviceOpenControllers = {};

  DummyQueueService() {
    _servicesController.add(List.unmodifiable(_services));
    for (final service in _services) {
      _serviceOpenState[service.id] = true;
      _getServiceOpenController(service.id).add(true);
    }
    _seedDummyAppointments();
  }

  @override
  Stream<List<Service>> getServices() => _servicesController.stream;

  @override
  Stream<List<Appointment>> getStudentAppointments(String userId) {
    return _getStudentController(userId).stream;
  }

  @override
  Future<Appointment> bookAppointment({
    required String userId,
    required String userName,
    required String userEmail,
    String? userEnrollment,
    required Service service,
    required DateTime scheduledTime,
    List<int>? seatNumbers,
    int? durationMinutes,
  }) async {
    if (!(_serviceOpenState[service.id] ?? true)) {
      throw StateError('Service is not accepting new appointments');
    }
    final sameDay = _appointments.where((a) =>
        a.serviceId == service.id &&
        _isSameDay(a.scheduledTime, scheduledTime));
    final nextToken =
        (sameDay.map((a) => a.tokenNumber).fold<int>(0, (p, e) => e > p ? e : p)) +
            1;

    final appointment = Appointment(
      id: '${service.id}_${DateTime.now().millisecondsSinceEpoch}',
      serviceId: service.id,
      serviceName: service.name,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userEnrollment: userEnrollment,
      createdAt: DateTime.now(),
      scheduledTime: scheduledTime,
      tokenNumber: nextToken,
      status: AppointmentStatus.pending,
      seatNumbers: seatNumbers,
      durationMinutes: durationMinutes,
    );

    _appointments.add(appointment);
    _emitAllForService(service.id);
    _emitStudentAppointments(userId);
    _getAppointmentController(appointment.id).add(appointment);

    return appointment;
  }

  @override
  Stream<Appointment?> watchAppointment(String appointmentId) {
    return _getAppointmentController(appointmentId).stream;
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return;
    final updated = _appointments[index]
        .copyWith(status: AppointmentStatus.cancelled);
    _appointments[index] = updated;
    _emitAllForService(updated.serviceId);
    _emitStudentAppointments(updated.userId);
    _getAppointmentController(appointmentId).add(updated);
  }

  @override
  Stream<List<Appointment>> watchServiceQueue(String serviceId) {
    return _getServiceQueueController(serviceId).stream;
  }

  @override
  Future<void> markInProgress(String appointmentId) async {
    _updateAppointmentStatus(appointmentId, AppointmentStatus.inProgress);
  }

  @override
  Future<void> markNextAsInProgress(String serviceId) async {
    final serviceAppointments = _appointments
        .where((a) => a.serviceId == serviceId)
        .where((a) =>
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.inProgress)
        .toList()
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));

    if (serviceAppointments.isEmpty) return;

    final currentInProgress = serviceAppointments
        .where((a) => a.status == AppointmentStatus.inProgress)
        .toList();
    for (final appt in currentInProgress) {
      _updateAppointmentStatus(appt.id, AppointmentStatus.completed);
    }

    final nextPending = serviceAppointments
        .firstWhere((a) => a.status == AppointmentStatus.pending,
            orElse: () => serviceAppointments.first);
    _updateAppointmentStatus(nextPending.id, AppointmentStatus.inProgress);

    _emitAllForService(serviceId);
  }

  @override
  Future<void> markCompleted(String appointmentId) async {
    _updateAppointmentStatus(appointmentId, AppointmentStatus.completed);
  }

  @override
  Future<void> markCancelled(String appointmentId) async {
    _updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
  }

  @override
  Stream<QueueSnapshot> watchPublicQueue(String serviceId) {
    return _getPublicQueueController(serviceId).stream;
  }

  @override
  Future<int> getPositionInQueue(String appointmentId) async {
    final appt = _appointments.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () => throw ArgumentError('Appointment not found'),
    );

    final sameService = _appointments
        .where((a) => a.serviceId == appt.serviceId)
        .where((a) =>
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.inProgress)
        .toList()
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));

    final index = sameService.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return 0;
    return index + 1;
  }

  @override
  Future<int> getEstimatedWaitMinutes(
    String appointmentId, {
    int minutesPerPerson = 5,
  }) async {
    final appt = _appointments.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () => throw ArgumentError('Appointment not found'),
    );
    final service = _services.firstWhere((s) => s.id == appt.serviceId);
    final perPerson = service.minutesPerPerson;

    final position = await getPositionInQueue(appointmentId);
    if (position <= 1) return 0;
    return (position - 1) * perPerson;
  }

  @override
  Stream<bool> watchServiceOpen(String serviceId) {
    return _getServiceOpenController(serviceId).stream;
  }

  @override
  Future<void> setServiceOpen(String serviceId, bool isOpen) async {
    _serviceOpenState[serviceId] = isOpen;
    _getServiceOpenController(serviceId).add(isOpen);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _updateAppointmentStatus(String id, AppointmentStatus status) {
    final index = _appointments.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final updated = _appointments[index].copyWith(status: status);
    _appointments[index] = updated;
    _emitAllForService(updated.serviceId);
    _emitStudentAppointments(updated.userId);
    _getAppointmentController(updated.id).add(updated);
  }

  StreamController<List<Appointment>> _getStudentController(String userId) {
    return _studentAppointmentsControllers.putIfAbsent(
      userId,
      () {
        final controller = StreamController<List<Appointment>>.broadcast();
        _emitStudentAppointments(userId, controller: controller);
        return controller;
      },
    );
  }

  StreamController<bool> _getServiceOpenController(String serviceId) {
    return _serviceOpenControllers.putIfAbsent(
      serviceId,
      () => StreamController<bool>.broadcast(),
    );
  }

  StreamController<List<Appointment>> _getServiceQueueController(
      String serviceId) {
    return _serviceQueueControllers.putIfAbsent(
      serviceId,
      () {
        final controller = StreamController<List<Appointment>>.broadcast();
        _emitServiceQueue(serviceId, controller: controller);
        return controller;
      },
    );
  }

  StreamController<Appointment?> _getAppointmentController(
      String appointmentId) {
    return _appointmentControllers.putIfAbsent(
      appointmentId,
      () => StreamController<Appointment?>.broadcast(),
    );
  }

  StreamController<QueueSnapshot> _getPublicQueueController(
      String serviceId) {
    return _publicQueueControllers.putIfAbsent(
      serviceId,
      () {
        final controller = StreamController<QueueSnapshot>.broadcast();
        _emitPublicQueue(serviceId, controller: controller);
        return controller;
      },
    );
  }

  void _emitStudentAppointments(String userId,
      {StreamController<List<Appointment>>? controller}) {
    final c = controller ?? _studentAppointmentsControllers[userId];
    if (c == null) return;
    final list = _appointments
        .where((a) => a.userId == userId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    c.add(List.unmodifiable(list));
  }

  void _emitServiceQueue(String serviceId,
      {StreamController<List<Appointment>>? controller}) {
    final c = controller ?? _serviceQueueControllers[serviceId];
    if (c == null) return;
    final list = _appointments
        .where((a) => a.serviceId == serviceId)
        .where((a) =>
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.inProgress)
        .toList()
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
    c.add(List.unmodifiable(list));
  }

  void _emitPublicQueue(String serviceId,
      {StreamController<QueueSnapshot>? controller}) {
    final c = controller ?? _publicQueueControllers[serviceId];
    if (c == null) return;
    final service = _services.firstWhere((s) => s.id == serviceId);
    final list = _appointments
        .where((a) => a.serviceId == serviceId)
        .where((a) =>
            a.status == AppointmentStatus.pending ||
            a.status == AppointmentStatus.inProgress)
        .toList()
      ..sort((a, b) => a.tokenNumber.compareTo(b.tokenNumber));
    Appointment? current;
    if (list.isNotEmpty) {
      current = list.firstWhere(
        (a) => a.status == AppointmentStatus.inProgress,
        orElse: () => list.first,
      );
    }
    final nextUp = current == null
        ? list.take(3).toList(growable: false)
        : list
            .where((a) => a.id != current!.id)
            .take(3)
            .toList(growable: false);
    c.add(QueueSnapshot(service: service, current: current, nextUp: nextUp));
  }

  void _emitAllForService(String serviceId) {
    _emitServiceQueue(serviceId);
    _emitPublicQueue(serviceId);
  }

  void _seedDummyAppointments() {
    final now = DateTime.now();

    void seedForService(Service service, List<Appointment> appts) {
      if (_appointments.any((a) => a.serviceId == service.id)) {
        _emitAllForService(service.id);
        return;
      }
      _appointments.addAll(appts);
      _emitAllForService(service.id);
    }

    final advisor = _services.firstWhere((s) => s.id == 'advisor_office');
    seedForService(advisor, [
      Appointment(
        id: '${advisor.id}_seed1',
        serviceId: advisor.id,
        serviceName: advisor.name,
        userId: 'seed_student_1',
        userName: 'Ali',
        userEmail: '',
        createdAt: now.subtract(const Duration(minutes: 30)),
        scheduledTime: now.subtract(const Duration(minutes: 20)),
        tokenNumber: 1,
        status: AppointmentStatus.inProgress,
      ),
      Appointment(
        id: '${advisor.id}_seed2',
        serviceId: advisor.id,
        serviceName: advisor.name,
        userId: 'seed_student_2',
        userName: 'Sara',
        userEmail: '',
        createdAt: now.subtract(const Duration(minutes: 20)),
        scheduledTime: now.subtract(const Duration(minutes: 10)),
        tokenNumber: 2,
        status: AppointmentStatus.pending,
      ),
    ]);

    final accounts = _services.firstWhere((s) => s.id == 'accounts_office');
    seedForService(accounts, [
      Appointment(
        id: '${accounts.id}_seed1',
        serviceId: accounts.id,
        serviceName: accounts.name,
        userId: 'seed_student_3',
        userName: 'Bilal',
        userEmail: '',
        createdAt: now.subtract(const Duration(minutes: 25)),
        scheduledTime: now.subtract(const Duration(minutes: 15)),
        tokenNumber: 1,
        status: AppointmentStatus.inProgress,
      ),
      Appointment(
        id: '${accounts.id}_seed2',
        serviceId: accounts.id,
        serviceName: accounts.name,
        userId: 'seed_student_4',
        userName: 'Hira',
        userEmail: '',
        createdAt: now.subtract(const Duration(minutes: 15)),
        scheduledTime: now.subtract(const Duration(minutes: 5)),
        tokenNumber: 2,
        status: AppointmentStatus.pending,
      ),
    ]);

    final deans = _services.firstWhere((s) => s.id == 'canteen_deans');
    seedForService(deans, [
      Appointment(
        id: '${deans.id}_seed1',
        serviceId: deans.id,
        serviceName: deans.name,
        userId: 'seed_student_5',
        userName: 'Omar',
        userEmail: '',
        createdAt: now.subtract(const Duration(minutes: 10)),
        scheduledTime: now.subtract(const Duration(minutes: 5)),
        tokenNumber: 10,
        status: AppointmentStatus.inProgress,
      ),
      Appointment(
        id: '${deans.id}_seed2',
        serviceId: deans.id,
        serviceName: deans.name,
        userId: 'seed_student_6',
        userName: 'Ayesha',
        userEmail: '',
        createdAt: now.subtract(const Duration(minutes: 8)),
        scheduledTime: now.subtract(const Duration(minutes: 3)),
        tokenNumber: 11,
        status: AppointmentStatus.pending,
      ),
    ]);
  }
}
