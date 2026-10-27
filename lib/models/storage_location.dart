import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// สถานที่เก็บ — [value] คือค่าที่เก็บใน Firestore
enum StorageLocation {
  fridge('fridge', 'ช่องแช่เย็น', LucideIcons.refrigerator),
  freezer('freezer', 'ช่องฟรีซ', LucideIcons.snowflake),
  pantry('pantry', 'ตู้กับข้าว', LucideIcons.archive);

  const StorageLocation(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  static StorageLocation fromValue(String? value) {
    return StorageLocation.values.firstWhere(
      (location) => location.value == value,
      orElse: () => StorageLocation.fridge,
    );
  }
}
