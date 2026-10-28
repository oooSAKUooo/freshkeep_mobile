import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final Axis direction;

  const AppLogo.horizontal({super.key})
    : iconSize = 32,
      fontSize = 22,
      direction = Axis.horizontal;

  const AppLogo.large({super.key})
    : iconSize = 64,
      fontSize = 32,
      direction = Axis.vertical;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(iconSize * 0.3),
      ),
      child: Icon(
        LucideIcons.sprout,
        size: iconSize * 0.55,
        color: AppColors.primary,
      ),
    );
    final wordmark = Text(
      'FreshKeep',
      style: AppTheme.brand(fontSize: fontSize),
    );

    return Flex(
      direction: direction,
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(
          width: direction == Axis.horizontal ? 10 : 0,
          height: direction == Axis.vertical ? 16 : 0,
        ),
        wordmark,
      ],
    );
  }
}
