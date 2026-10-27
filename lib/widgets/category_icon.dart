import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../utils/expiry_status.dart';

class CategoryIcon extends StatelessWidget {
  final FoodCategory category;
  final ExpiryLevel level;
  final double size;

  const CategoryIcon({
    super.key,
    required this.category,
    required this.level,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.statusSoftColor(level),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        category.icon,
        size: size * 0.45,
        color: AppColors.statusTextColor(level),
      ),
    );
  }
}
