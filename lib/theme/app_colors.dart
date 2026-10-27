import 'package:flutter/material.dart';

import '../utils/expiry_status.dart';

/// สีทั้งหมดของแอปอยู่ที่นี่ที่เดียว (ค่าอ้างอิงจาก design/html)
class AppColors {
  AppColors._();

  static const background = Color(0xFFF5F2EC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0EEE8); // พื้นช่องกรอก / chip
  static const primary = Color(0xFF234235);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primarySoft = Color(0xFFC7EBD8);

  static const textPrimary = Color(0xFF1C1C18);
  static const textSecondary = Color(0xFF414844);
  static const textMuted = Color(0xFF727974);

  static const divider = Color(0xFFE5E2DC);
  static const shadow = Color(0x14000000);

  static const scrim = Color(0x99000000);

  static const error = Color(0xFFBA1A1A);
  static const errorSoft = Color(0xFFFFDAD6);

  // สถานะความสด: สีเข้ม (จุด / แถบ / ตัวอักษร) และสีอ่อน (พื้นหลัง)
  static const fresh = Color(0xFF6E9A84);
  static const freshText = Color(0xFF2E4D3F);
  static const freshSoft = Color(0xFFDCEFE4);

  static const soon = Color(0xFFCF9E52);
  static const soonText = Color(0xFF624000);
  static const soonSoft = Color(0xFFFFE8C7);

  static const urgent = Color(0xFFB5604F);
  static const urgentText = Color(0xFF9E4336);
  static const urgentSoft = Color(0xFFF8E9E6);

  static Color statusColor(ExpiryLevel level) => switch (level) {
    ExpiryLevel.fresh => fresh,
    ExpiryLevel.soon => soon,
    ExpiryLevel.urgent => urgent,
  };

  static Color statusTextColor(ExpiryLevel level) => switch (level) {
    ExpiryLevel.fresh => freshText,
    ExpiryLevel.soon => soonText,
    ExpiryLevel.urgent => urgentText,
  };

  static Color statusSoftColor(ExpiryLevel level) => switch (level) {
    ExpiryLevel.fresh => freshSoft,
    ExpiryLevel.soon => soonSoft,
    ExpiryLevel.urgent => urgentSoft,
  };
}
