import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'book_slot_screen.dart';

class SimpleBookingCategoriesScreen extends StatefulWidget {
  const SimpleBookingCategoriesScreen({super.key});

  @override
  State<SimpleBookingCategoriesScreen> createState() => _SimpleBookingCategoriesScreenState();
}

class _SimpleBookingCategoriesScreenState extends State<SimpleBookingCategoriesScreen> {
  List<Service> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServices();
    });
  }

  Future<void> _loadServices() async {
    print('=== LOADING SERVICES ===');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deps = QueueLessDependencies.of(context);
      final queueService = deps.queueService;

      final services = await queueService.getServices().first;
      print('Found ${services.length} services');
      for (final service in services) {
        print('Service: ${service.name} (ID: ${service.id})');
      }
      
      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading services: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load services. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Appointment'),
        ),
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Book Appointment'),
        ),
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: AppColors.errorRed),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Retry',
                  onPressed: _loadServices,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Service', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              if (_services.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'No services available. Please try again later.',
                        style: AppTextStyles.body.copyWith(color: AppColors.textLight),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Refresh',
                        onPressed: _loadServices,
                        filled: false,
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(service.description),
                          trailing: Text('${service.minutesPerPerson} min'),
                          onTap: () {
                            print('Tapped service: ${service.name}');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BookSlotScreen(service: service),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
