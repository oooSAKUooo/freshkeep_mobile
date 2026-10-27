import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/utils/date_format.dart';
import 'package:freshkeep/utils/expiry_status.dart';
import 'package:freshkeep/utils/validators.dart';

void main() {
  group('ExpiryStatus', () {
    test('แบ่งระดับตามจำนวนวันที่เหลือ', () {
      expect(ExpiryStatus.fromDate(daysFromToday(-1)).label, 'หมดอายุแล้ว');
      expect(ExpiryStatus.fromDate(daysFromToday(0)).label, 'วันนี้');
      expect(ExpiryStatus.fromDate(daysFromToday(1)).label, 'พรุ่งนี้');
      expect(ExpiryStatus.fromDate(daysFromToday(1)).level, ExpiryLevel.urgent);
      expect(ExpiryStatus.fromDate(daysFromToday(3)).level, ExpiryLevel.soon);
      expect(ExpiryStatus.fromDate(daysFromToday(4)).level, ExpiryLevel.fresh);
      expect(ExpiryStatus.fromDate(daysFromToday(4)).label, 'อีก 4 วัน');
    });
  });

  group('Validators', () {
    test('อีเมลและรหัสผ่าน', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b.com'), isNull);
      expect(
        Validators.password('12345'),
        'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
      );
      expect(Validators.confirmPassword('123456', '123457'), isNotNull);
    });

    test('ชื่อสินค้าไม่เกิน 60 ตัวอักษร', () {
      expect(Validators.itemName('  '), isNotNull);
      expect(Validators.itemName('a' * 61), isNotNull);
      expect(Validators.itemName('นมสด'), isNull);
    });

    test('วันหมดอายุห้ามเป็นอดีต ยกเว้นตอนแก้ไขแล้วไม่ได้เปลี่ยนวัน', () {
      final yesterday = daysFromToday(-1);
      expect(Validators.expiryDate(null), isNotNull);
      expect(Validators.expiryDate(today()), isNull);
      expect(
        Validators.expiryDate(yesterday),
        'วันหมดอายุต้องไม่เป็นวันที่ผ่านมาแล้ว',
      );
      expect(Validators.expiryDate(yesterday, originalDate: yesterday), isNull);
    });
  });
}
