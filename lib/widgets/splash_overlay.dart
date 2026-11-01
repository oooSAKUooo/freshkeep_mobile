import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// แอนิเมชันตอนเปิดแอป: โลโก้เด้งเข้า → ตัวอักษรชื่อแอปไล่ขึ้นทีละตัว → จางหายเผยหน้าจริง
/// ซ้อนทับบน router (ผ่าน MaterialApp.builder) จึงไม่กระทบการ redirect / auth
class SplashOverlay extends StatefulWidget {
  final Widget child;

  const SplashOverlay({super.key, required this.child});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  static const _word = 'FreshKeep';

  late final AnimationController _controller;
  bool _done = false;

  late final Animation<double> _markScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
  );
  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.1, 0.5, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _tagline = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 0.75, curve: Curves.easeOut),
  );
  late final Animation<double> _exit = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.8, 1.0, curve: Curves.easeInCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 3000),
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _done = true);
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final exit = _exit.value;
              return IgnorePointer(
                ignoring: exit > 0.5,
                child: Opacity(
                  opacity: 1 - exit,
                  child: Transform.scale(
                    scale: 1 + exit * 0.15,
                    child: _buildSplash(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSplash() {
    // อยู่เหนือ Navigator จึงไม่มี Material ครอบ ต้องใส่เองไม่งั้นตัวอักษรมีขีดเส้นใต้
    return Material(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // วงแหวนขยายออกแล้วจาง
                  Opacity(
                    opacity: (1 - _ring.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 96 + 64 * _ring.value,
                      height: 96 + 64 * _ring.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primarySoft,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: _markScale.value.clamp(0.0, 1.3),
                    child: Opacity(
                      opacity: (_markScale.value * 2).clamp(0.0, 1.0),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(29),
                        ),
                        child: Transform.rotate(
                          angle: (1 - _markScale.value.clamp(0.0, 1.0)) * -0.6,
                          child: const Icon(
                            LucideIcons.sprout,
                            size: 54,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < _word.length; i++) _letter(i)],
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: _tagline.value,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - _tagline.value)),
                child: Text(
                  'ของสดในตู้เย็น ไม่ลืมหมดอายุ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primarySoft,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ตัวอักษรแต่ละตัวเริ่มช้ากว่าตัวก่อนหน้านิดหน่อย ให้ดูเป็นคลื่น
  Widget _letter(int index) {
    final start = 0.25 + index * 0.035;
    final t = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + 0.18, curve: Curves.easeOutCubic),
    ).value;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - t)),
        child: Text(
          _word[index],
          style: AppTheme.brand(fontSize: 38, color: AppColors.onPrimary),
        ),
      ),
    );
  }
}
