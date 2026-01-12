import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/auth_service.dart';
import 'services/queue_service.dart';
import 'services/impl/firebase_auth_service.dart';
import 'services/impl/firebase_queue_service_simple.dart';
import 'services/firebase_setup.dart';
import 'utils/add_services_to_firebase.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await FirebaseSetup.initializeServices();
  
  // Add services to Firebase (one-time operation)
  await AddServicesToFirebase.addServices();

  final authService = FirebaseAuthService();
  final queueService = SimpleFirebaseQueueService();

  // Force create services if they don't exist
  await _ensureServicesExist(queueService);

  runApp(QueueLessApp(
    authService: authService,
    queueService: queueService,
  ));
}

Future<void> _ensureServicesExist(SimpleFirebaseQueueService queueService) async {
  try {
    print('=== CHECKING SERVICES ===');
    final services = await queueService.getServices().first;
    print('Found ${services.length} services');
    for (final service in services) {
      print('Service: ${service.name} (ID: ${service.id})');
    }
    
    if (services.isEmpty) {
      print('No services found, creating them manually...');
      await _createServicesManually();
    } else {
      print('Services already exist, skipping creation');
    }
  } catch (e) {
    print('Error checking services: $e');
    print('Creating services manually as fallback...');
    await _createServicesManually();
  }
}

Future<void> _createServicesManually() async {
  print('=== CREATING SERVICES MANUALLY ===');
  final firestore = FirebaseFirestore.instance;

  final services = [
    {
      'name': 'Advisor Office',
      'description': 'Course advising and academic guidance',
      'location': 'Main Block',
      'minutesPerPerson': 15,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Deans Canteen',
      'description': 'Food and beverages',
      'location': 'Central Courtyard',
      'minutesPerPerson': 3,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Crispino',
      'description': 'Food and beverages',
      'location': 'Building A',
      'minutesPerPerson': 5,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Bites and Beans',
      'description': 'Coffee and snacks',
      'location': 'Student Center',
      'minutesPerPerson': 5,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Quetta',
      'description': 'Food and beverages',
      'location': 'Building B',
      'minutesPerPerson': 5,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'Accounts Office',
      'description': 'Fee payments and accounts queries',
      'location': 'Admin Block',
      'minutesPerPerson': 10,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    {
      'name': 'HOD Meeting',
      'description': 'Department head meetings',
      'location': 'Department Office',
      'minutesPerPerson': 20,
      'isOpen': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
  ];

  for (final service in services) {
    try {
      await firestore.collection('services').add(service);
      print('Added: ${service['name']}');
    } catch (e) {
      print('Error adding ${service['name']}: $e');
    }
  }
  
  print('Services creation completed!');
}

class QueueLessApp extends StatelessWidget {
  final AuthService authService;
  final QueueService queueService;

  const QueueLessApp({
    super.key,
    required this.authService,
    required this.queueService,
  });

  @override
  Widget build(BuildContext context) {
    return QueueLessDependencies(
      authService: authService,
      queueService: queueService,
      child: MaterialApp(
        title: 'QueueLess',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
          useMaterial3: true,
          textTheme: AppTextStyles.textTheme,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class QueueLessDependencies extends InheritedWidget {
  final AuthService authService;
  final QueueService queueService;

  const QueueLessDependencies({
    super.key,
    required this.authService,
    required this.queueService,
    required super.child,
  });

  static QueueLessDependencies of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<QueueLessDependencies>();
    assert(result != null, 'No QueueLessDependencies found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant QueueLessDependencies oldWidget) {
    return authService != oldWidget.authService ||
        queueService != oldWidget.queueService;
  }
}
