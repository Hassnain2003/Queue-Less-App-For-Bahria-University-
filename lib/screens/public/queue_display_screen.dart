import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/queue_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class QueueDisplayScreen extends StatelessWidget {
  final String serviceId;

  const QueueDisplayScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    final deps = QueueLessDependencies.of(context);
    final queueService = deps.queueService;

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: StreamBuilder<QueueSnapshot>(
          stream: queueService.watchPublicQueue(serviceId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }
            final data = snapshot.data!;
            final current = data.current;
            final nextUp = data.nextUp;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.service.name,
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Now Serving',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current == null
                        ? '--'
                        : 'Token #${current.tokenNumber}',
                    style: AppTextStyles.heading1.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Up Next',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (nextUp.isEmpty)
                    Text(
                      'No one waiting',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white60,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: nextUp
                          .map(
                            (a) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Token #${a.tokenNumber} - ${a.userName}',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
