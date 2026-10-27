import 'date_format.dart';

enum ExpiryLevel { fresh, soon, urgent }

/// คำนวณจำนวนวันที่เหลือก่อนหมดอายุ (เทียบระดับวัน ไม่สนชั่วโมง)
/// แล้วแปลงเป็นระดับสี + ข้อความที่ใช้แสดงใน pill
class ExpiryStatus {
  final int daysLeft;

  ExpiryStatus._(this.daysLeft);

  factory ExpiryStatus.fromDate(DateTime expiryDate) {
    // ใช้ DateTime.utc เพื่อไม่ให้ช่วง daylight saving ทำให้นับวันเพี้ยน
    final now = today();
    final expiry = dateOnly(expiryDate);
    final days = DateTime.utc(
      expiry.year,
      expiry.month,
      expiry.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    return ExpiryStatus._(days);
  }

  bool get isExpired => daysLeft < 0;

  ExpiryLevel get level {
    if (daysLeft <= 1) return ExpiryLevel.urgent;
    if (daysLeft <= 3) return ExpiryLevel.soon;
    return ExpiryLevel.fresh;
  }

  /// ข้อความสั้นสำหรับ pill ในรายการ
  String get label {
    if (daysLeft < 0) return 'หมดอายุแล้ว';
    if (daysLeft == 0) return 'วันนี้';
    if (daysLeft == 1) return 'พรุ่งนี้';
    return 'อีก $daysLeft วัน';
  }

  /// ข้อความยาวสำหรับแบนเนอร์หน้า Detail
  String get bannerText {
    if (daysLeft < 0) return 'หมดอายุแล้ว ${-daysLeft} วัน';
    if (daysLeft == 0) return 'หมดอายุวันนี้';
    if (daysLeft == 1) return 'หมดอายุพรุ่งนี้';
    return 'หมดอายุในอีก $daysLeft วัน';
  }
}
