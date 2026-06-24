import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileStatsWidget extends StatelessWidget {
  final List<ProfileStatItem> items;

  const ProfileStatsWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: _buildStatItemsWithDividers(),
      ),
    );
  }

  List<Widget> _buildStatItemsWithDividers() {
    final List<Widget> widgets = [];
    for (int i = 0; i < items.length; i++) {
      widgets.add(
        Expanded(
          child: _buildStatItem(items[i]),
        ),
      );
      if (i < items.length - 1) {
        widgets.add(
          Container(
            width: 1,
            height: 40,
            color: AppColors.inputBackground,
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildStatItem(ProfileStatItem item) {
    return Column(
      children: [
        Text(
          item.value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: item.valueColor ?? AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class ProfileStatItem {
  final String label;
  final String value;
  final Color? valueColor;

  ProfileStatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });
}
