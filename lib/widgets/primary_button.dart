import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool isLoading;
  final bool enabled;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = (enabled && !isLoading) ? onPressed : null;
    final style = AppTextStyles.body.copyWith(
      color: filled ? Colors.white : AppColors.primaryBlue,
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          filled ? Colors.white : AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : Text(label, style: style),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          filled ? Colors.white : AppColors.primaryBlue,
                        ),
                      ),
                    )
                  : Text(label, style: style),
            ),
    );
  }
}
