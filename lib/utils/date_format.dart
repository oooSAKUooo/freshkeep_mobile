import 'package:intl/intl.dart';

/// ตัดเวลาออก เหลือเที่ยงคืนของวันนั้น (เวลาท้องถิ่น)
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime today() => dateOnly(DateTime.now());

/// วันที่อีก [days] วันนับจากวันนี้ (บวกที่ช่องวัน ไม่ใช่บวกชั่วโมง)
DateTime daysFromToday(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

/// เช่น "20 ต.ค. 2026"
String formatShortDate(DateTime date) =>
    DateFormat('d MMM y', 'th').format(date);

/// เช่น "วันพฤหัสบดีที่ 24 ตุลาคม"
String formatFullDayDate(DateTime date) =>
    DateFormat("EEEE'ที่' d MMMM", 'th').format(date);
