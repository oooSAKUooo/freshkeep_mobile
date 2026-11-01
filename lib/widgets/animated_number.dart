import 'package:flutter/material.dart';

import '../services/item_service.dart';

const _countDuration = Duration(milliseconds: 900);

/// ตัวเลขที่นับขึ้นจาก 0 ตอนแสดงครั้งแรก และนับต่อจากค่าเดิมเมื่อค่าเปลี่ยน
/// (TweenAnimationBuilder จำค่าปัจจุบันไว้ให้เอง จึงไม่ต้องมี AnimationController)
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String suffix;

  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: _countDuration,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) =>
          Text('${current.round()}$suffix', style: style),
    );
  }
}

/// "ลดขยะอาหารได้ X%" ใช้ร่วมกันระหว่าง Home และ Profile
/// ถ้ายังไม่มีข้อมูลทั้งกินและทิ้ง แสดง "–" โดยไม่นับ
class AnimatedWastePercent extends StatelessWidget {
  final MonthStats stats;
  final TextStyle style;

  const AnimatedWastePercent({
    super.key,
    required this.stats,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.consumed + stats.discarded == 0) {
      return Text(stats.wasteReducedLabel, style: style);
    }
    return AnimatedCount(
      value: (stats.wasteReducedFraction * 100).round(),
      suffix: '%',
      style: style,
    );
  }
}

/// ค่า 0.0–1.0 ที่วิ่งจากค่าเดิมไปค่าใหม่ ใช้กับแถบความคืบหน้า
class AnimatedFraction extends StatelessWidget {
  final double value;
  final Widget Function(BuildContext context, double value) builder;

  const AnimatedFraction({
    super.key,
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: _countDuration,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => builder(context, current),
    );
  }
}

/// เลื่อนขึ้นพร้อมจางเข้า เล่นครั้งเดียวตอน widget ถูกสร้าง
/// ใส่ key เป็น id ของรายการ เพื่อให้ตอน stream อัปเดต รายการเดิมไม่เล่นซ้ำ
class FadeSlideIn extends StatefulWidget {
  final int index;
  final Widget child;

  const FadeSlideIn({super.key, required this.index, required this.child});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _stagger = 70;
  static const _base = 450;

  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    // หน่วงตามลำดับ แต่จำกัดไว้ที่ 8 ใบแรก ไม่ให้รายการท้าย ๆ รอนาน
    final delay = widget.index.clamp(0, 8) * _stagger;
    final total = _base + delay;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    )..forward();
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
