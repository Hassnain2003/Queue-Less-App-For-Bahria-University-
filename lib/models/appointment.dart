enum AppointmentStatus { pending, inProgress, completed, cancelled }

class Appointment {
  final String id;
  final String serviceId;
  final String serviceName;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userEnrollment;
  final DateTime createdAt;
  final DateTime scheduledTime;
  final int tokenNumber;
  final AppointmentStatus status;
  final List<int>? seatNumbers;
  final int? durationMinutes;

  Appointment({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userEnrollment,
    required this.createdAt,
    required this.scheduledTime,
    required this.tokenNumber,
    required this.status,
    this.seatNumbers,
    this.durationMinutes,
  });

  Appointment copyWith({
    AppointmentStatus? status,
    List<int>? seatNumbers,
    int? durationMinutes,
  }) {
    return Appointment(
      id: id,
      serviceId: serviceId,
      serviceName: serviceName,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userEnrollment: userEnrollment,
      createdAt: createdAt,
      scheduledTime: scheduledTime,
      tokenNumber: tokenNumber,
      status: status ?? this.status,
      seatNumbers: seatNumbers ?? this.seatNumbers,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
