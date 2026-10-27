import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// หมวดหมู่ของในตู้เย็น — [value] คือค่าที่เก็บใน Firestore
enum FoodCategory {
  dairyEgg('dairy_egg', 'นมและไข่', LucideIcons.milk),
  produce('produce', 'ผักผลไม้', LucideIcons.carrot),
  meat('meat', 'เนื้อสัตว์', LucideIcons.beef),
  other('other', 'อื่นๆ', LucideIcons.package);

  const FoodCategory(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  /// แปลงค่าจาก Firestore กลับเป็น enum (ค่าไม่รู้จัก → อื่นๆ)
  static FoodCategory fromValue(String? value) {
    return FoodCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => FoodCategory.other,
    );
  }
}
