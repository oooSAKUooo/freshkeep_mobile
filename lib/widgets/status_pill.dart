import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/expiry_status.dart';

/// pill แสดง "พรุ่งนี้" / "อีก N วัน" / "หมดอายุแล้ว" สีตามระดับความสด
class StatusPill extends StatelessWidget {
  final ExpiryStatus status;

  const StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusSoftColor(status.level),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.statusTextColor(status.level),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
