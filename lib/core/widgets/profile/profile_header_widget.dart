import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String name;
  final String email;
  final String? phone;
  final String roleEmoji;
  final Color avatarColor;
  final String? rating;
  final String? verifiedText;
  final bool isVerified;

  const ProfileHeaderWidget({
    super.key,
    required this.name,
    required this.email,
    this.phone,
    required this.roleEmoji,
    this.avatarColor = AppColors.primaryLight,
    this.rating,
    this.verifiedText,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(roleEmoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phone!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          if (rating != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  rating!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
          if (isVerified && verifiedText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Only show icon if we want it, usually yes for verification
                  const Icon(Icons.verified,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    verifiedText!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
