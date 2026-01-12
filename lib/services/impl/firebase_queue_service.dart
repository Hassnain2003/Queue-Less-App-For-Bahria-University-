import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/appointment.dart';
import '../../models/service.dart';
import '../queue_service.dart';

class FirebaseQueueService implements QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Service>> getServices() {
    return _firestore
        .collection('services')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Service(
                  id: doc.id,
                  name: doc['name'] as String,
                  description: doc['description'] as String,
                  location: doc['location'] as String,
                  minutesPerPerson: doc['minutesPerPerson'] as int,
                ))
            .toList());
  }

  @override
  Future<void> markInProgress(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.inProgress.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Appointment>> getStudentAppointments(String userId) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _documentToAppointment(doc))
            .toList());
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
    print('=== BOOKING APPOINTMENT DEBUG ===');
    print('User ID: $userId');
    print('User Name: $userName');
    print('User Email: $userEmail');
    print('User Enrollment: $userEnrollment');
    print('Service ID: ${service.id}');
    print('Service Name: ${service.name}');
    print('Scheduled Time: $scheduledTime');
    
    // Bookings are always allowed - no need to check service open status
    
    // Get next token number for this service on the same day
    final today = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);
    final tomorrow = today.add(const Duration(days: 1));

    print('Querying for existing appointments...');
    print('Today: $today');
    print('Tomorrow: $tomorrow');

    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('serviceId', isEqualTo: service.id)
          .where('scheduledTime', isGreaterThanOrEqualTo: today)
          .where('scheduledTime', isLessThan: tomorrow)
          .orderBy('tokenNumber', descending: true)
          .limit(1)
          .get();

      print('Query completed. Found ${snapshot.docs.length} existing appointments');
      
      final nextToken = snapshot.docs.isEmpty ? 1 : (snapshot.docs.first['tokenNumber'] as int) + 1;
      print('Next token number: $nextToken');

    final appointment = Appointment(
      id: 'temp_id', // Will be replaced with Firestore document ID
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
    );

    print('Creating appointment document in Firestore...');
    final docRef = await _firestore.collection('appointments').add({
      'serviceId': appointment.serviceId,
      'serviceName': appointment.serviceName,
      'userId': appointment.userId,
      'userName': appointment.userName,
      'userEmail': appointment.userEmail,
      'userEnrollment': appointment.userEnrollment,
      'createdAt': Timestamp.fromDate(appointment.createdAt),
      'scheduledTime': Timestamp.fromDate(appointment.scheduledTime),
      'tokenNumber': appointment.tokenNumber,
      'status': appointment.status.name,
      if (seatNumbers != null) 'seatNumbers': seatNumbers,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
    });

    print('Appointment created with ID: ${docRef.id}');

    return Appointment(
      id: docRef.id,
      serviceId: appointment.serviceId,
      serviceName: appointment.serviceName,
      userId: appointment.userId,
      userName: appointment.userName,
      userEmail: appointment.userEmail,
      userEnrollment: appointment.userEnrollment,
      createdAt: appointment.createdAt,
      scheduledTime: appointment.scheduledTime,
      tokenNumber: appointment.tokenNumber,
      status: appointment.status,
      seatNumbers: seatNumbers,
      durationMinutes: durationMinutes,
    );
    } catch (e) {
      print('ERROR during booking: $e');
      rethrow;
    }
  }

  @override
  Stream<Appointment?> watchAppointment(String appointmentId) {
    return _firestore
        .collection('appointments')
        .doc(appointmentId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? _documentToAppointment(snapshot) : null);
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<Appointment>> watchServiceQueue(String serviceId) {
    return _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .orderBy('tokenNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _documentToAppointment(doc))
            .toList());
  }

  @override
  Future<void> markNextAsInProgress(String serviceId) async {
    final batch = _firestore.batch();

    // Get all pending and in-progress appointments for this service
    final snapshot = await _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .orderBy('tokenNumber')
        .get();

    if (snapshot.docs.isEmpty) return;

    // Mark current in-progress as completed
    for (final doc in snapshot.docs) {
      final status = doc['status'] as String;
      if (status == 'inProgress') {
        batch.update(doc.reference, {
          'status': AppointmentStatus.completed.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Mark first pending as in-progress
    final firstPending = snapshot.docs.firstWhere(
      (doc) => doc['status'] == 'pending',
      orElse: () => snapshot.docs.first,
    );

    batch.update(firstPending.reference, {
      'status': AppointmentStatus.inProgress.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> markCompleted(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markCancelled(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.cancelled.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<QueueSnapshot> watchPublicQueue(String serviceId) {
    return _firestore.collection('appointments')
        .where('serviceId', isEqualTo: serviceId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .orderBy('tokenNumber')
        .snapshots()
        .asyncMap((snapshot) async {
          // Get service details
          final serviceDoc = await _firestore.collection('services').doc(serviceId).get();
          if (!serviceDoc.exists) {
            throw Exception('Service not found');
          }

          final service = Service(
            id: serviceDoc.id,
            name: serviceDoc['name'] as String,
            description: serviceDoc['description'] as String,
            location: serviceDoc['location'] as String,
            minutesPerPerson: serviceDoc['minutesPerPerson'] as int,
          );

          final appointments = snapshot.docs
              .map((doc) => _documentToAppointment(doc))
              .toList();

          Appointment? current;
          if (appointments.isNotEmpty) {
            current = appointments.firstWhere(
              (a) => a.status == AppointmentStatus.inProgress,
              orElse: () => appointments.first,
            );
          }

          final nextUp = current == null
              ? appointments.take(3).toList()
              : appointments
                  .where((a) => a.id != current!.id)
                  .take(3)
                  .toList();

          return QueueSnapshot(service: service, current: current, nextUp: nextUp);
        });
  }

  @override
  Future<int> getPositionInQueue(String appointmentId) async {
    final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
    if (!appointmentDoc.exists) {
      throw ArgumentError('Appointment not found');
    }

    final appointment = _documentToAppointment(appointmentDoc);

    final snapshot = await _firestore
        .collection('appointments')
        .where('serviceId', isEqualTo: appointment.serviceId)
        .where('status', whereIn: ['pending', 'inProgress'])
        .orderBy('tokenNumber')
        .get();

    final index = snapshot.docs.indexWhere((doc) => doc.id == appointmentId);
    return index == -1 ? 0 : index + 1;
  }

  @override
  Future<int> getEstimatedWaitMinutes(
    String appointmentId, {
    int minutesPerPerson = 5,
  }) async {
    final position = await getPositionInQueue(appointmentId);
    if (position <= 1) return 0;

    // Get actual minutes per person from service
    final appointmentDoc = await _firestore.collection('appointments').doc(appointmentId).get();
    final appointment = _documentToAppointment(appointmentDoc);

    final serviceDoc = await _firestore.collection('services').doc(appointment.serviceId).get();
    final actualMinutesPerPerson = serviceDoc.data()?['minutesPerPerson'] as int? ?? minutesPerPerson;

    return (position - 1) * actualMinutesPerPerson;
  }

  @override
  Stream<bool> watchServiceOpen(String serviceId) {
    // Always return true - bookings are always allowed
    return Stream.value(true);
  }

  @override
  Future<void> setServiceOpen(String serviceId, bool isOpen) async {
    try {
      print('Setting service open status for $serviceId to $isOpen');
      
      // Check if service document exists
      final serviceDoc = await _firestore.collection('services').doc(serviceId).get();
      if (!serviceDoc.exists) {
        print('Service document does not exist: $serviceId');
        throw Exception('Service not found');
      }
      
      print('Service document exists, updating...');
      await _firestore.collection('services').doc(serviceId).update({
        'isOpen': isOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Service open status updated successfully');
    } catch (e) {
      print('Error setting service open status: $e');
      rethrow;
    }
  }

  Appointment _documentToAppointment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Appointment(
      id: doc.id,
      serviceId: data['serviceId'] as String,
      serviceName: data['serviceName'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userEmail: data['userEmail'] as String? ?? '',
      userEnrollment: data['userEnrollment'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      tokenNumber: data['tokenNumber'] as int,
      status: AppointmentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      seatNumbers: (data['seatNumbers'] as List?)?.map((e) => (e as num).toInt()).toList(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
    );
  }
}
