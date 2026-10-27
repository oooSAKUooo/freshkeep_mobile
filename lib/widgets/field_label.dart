import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ป้ายชื่อเหนือช่องกรอก (ดีไซน์วาง label ไว้นอกช่อง)
class FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing, // ใส่ใน Row เฉพาะเมื่อไม่เป็น null
        ],
      ),
    );
  }
}
