import '../models/appointment.dart';
import '../models/service.dart';

class QueueSnapshot {
  final Service service;
  final Appointment? current;
  final List<Appointment> nextUp;

  const QueueSnapshot({
    required this.service,
    required this.current,
    required this.nextUp,
  });
}

abstract class QueueService {
  Stream<List<Service>> getServices();

  Stream<List<Appointment>> getStudentAppointments(String userId);

  Future<Appointment> bookAppointment({
    required String userId,
    required String userName,
    required String userEmail,
    String? userEnrollment,
    required Service service,
    required DateTime scheduledTime,
    List<int>? seatNumbers,
    int? durationMinutes,
  });

  Stream<Appointment?> watchAppointment(String appointmentId);

  Future<void> cancelAppointment(String appointmentId);

  Stream<List<Appointment>> watchServiceQueue(String serviceId);

  Future<void> markInProgress(String appointmentId);

  Future<void> markNextAsInProgress(String serviceId);

  Future<void> markCompleted(String appointmentId);

  Future<void> markCancelled(String appointmentId);

  Stream<QueueSnapshot> watchPublicQueue(String serviceId);

  Future<int> getPositionInQueue(String appointmentId);

  Future<int> getEstimatedWaitMinutes(
    String appointmentId, {
    int minutesPerPerson = 5,
  });

  // Whether a given service is currently accepting new appointments.
  Stream<bool> watchServiceOpen(String serviceId);

  // Update whether a service is accepting new appointments.
  Future<void> setServiceOpen(String serviceId, bool isOpen);
}
