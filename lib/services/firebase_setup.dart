import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firebase_config.dart';

class FirebaseSetup {
  static Future<void> initializeServices() async {
    await FirebaseConfig.initializeFirebase();
  }

  static Future<void> seedInitialData() async {
    final firestore = FirebaseFirestore.instance;
    
    try {
      // Check if services already exist
      final servicesSnapshot = await firestore.collection('services').limit(1).get();
      if (servicesSnapshot.docs.isNotEmpty) {
        return; // Services already seeded
      }

      // Seed services
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
          'description': 'Fast food and snacks',
          'location': 'Food Court',
          'minutesPerPerson': 4,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Muncheez',
          'description': 'Fast food and snacks',
          'location': 'Food Court',
          'minutesPerPerson': 4,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Quetta',
          'description': 'Tea and snacks',
          'location': 'Food Court',
          'minutesPerPerson': 2,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Bites and Beans',
          'description': 'Coffee and snacks',
          'location': 'Food Court',
          'minutesPerPerson': 5,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Accounts Office',
          'description': 'Fee and accounts related queries',
          'location': 'Admin Block',
          'minutesPerPerson': 10,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'HOD Meeting',
          'description': 'Meetings with Head of Department',
          'location': 'Department Office',
          'minutesPerPerson': 20,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Rector Meeting',
          'description': 'Meetings with Rector',
          'location': 'Rector Office',
          'minutesPerPerson': 25,
          'isOpen': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add services one by one to avoid batch issues
      for (final service in services) {
        await firestore.collection('services').add(service);
      }
      
      print('Services seeded successfully');
    } catch (e) {
      print('Error seeding services: $e');
      // Don't rethrow - allow app to continue even if seeding fails
    }
  }
}
