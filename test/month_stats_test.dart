import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/services/item_service.dart';

void main() {
  group('MonthStats.wasteReducedLabel', () {
    test('ไม่มีข้อมูลเลย → "–" (ไม่ใช่ 0%)', () {
      expect(
        const MonthStats(consumed: 0, discarded: 0).wasteReducedLabel,
        '–',
      );
    });

    test('กิน 2 ทิ้ง 1 → 67%', () {
      expect(
        const MonthStats(consumed: 2, discarded: 1).wasteReducedLabel,
        '67%',
      );
    });

    test('กินหมดทั้งหมด → 100%', () {
      expect(
        const MonthStats(consumed: 5, discarded: 0).wasteReducedLabel,
        '100%',
      );
    });

    test('ทิ้งทั้งหมด → 0%', () {
      expect(
        const MonthStats(consumed: 0, discarded: 3).wasteReducedLabel,
        '0%',
      );
    });
  });
}
