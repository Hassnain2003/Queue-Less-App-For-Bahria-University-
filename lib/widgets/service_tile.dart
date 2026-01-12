import 'package:flutter/material.dart';

import '../models/service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class ServiceTile extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const ServiceTile({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                )),
            const SizedBox(height: 4),
            Text(
              service.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textLight,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  service.location,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textLight,
                    fontSize: 10,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
