import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'animated_number.dart';
import 'app_logo.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // โลโก้ → การ์ดฟอร์ม → ลิงก์ด้านล่าง เลื่อนเข้ามาไล่กัน (index ห่างกัน 2 ให้จังหวะกว้างขึ้น)
                FadeSlideIn(
                  index: 0,
                  child: Column(
                    children: [
                      const AppLogo.large(),
                      const SizedBox(height: 8),
                      Text(
                        'ของสดในตู้เย็น ไม่ถูกลืมอีกต่อไป',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FadeSlideIn(
                  index: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),
                          form,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(index: 4, child: footer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
