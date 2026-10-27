import 'date_format.dart';

/// ฟังก์ชัน validator ใช้กับ TextFormField / FormField
/// คืนค่า null = ผ่าน, คืนข้อความ = ไม่ผ่าน (แสดงใต้ช่อง)
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'กรุณากรอกชื่อ';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'กรุณากรอกอีเมล';
    if (!_emailPattern.hasMatch(email)) return 'รูปแบบอีเมลไม่ถูกต้อง';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (value != password) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  }

  static const itemNameMaxLength = 60;

  static String? itemName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'กรุณากรอกชื่อสินค้า';
    if (name.length > itemNameMaxLength) {
      return 'ชื่อสินค้าต้องไม่เกิน $itemNameMaxLength ตัวอักษร';
    }
    return null;
  }

  static String? quantity(int? value) {
    if (value == null || value < 1) return 'จำนวนต้องอย่างน้อย 1';
    return null;
  }

  /// [originalDate] คือวันหมดอายุเดิมตอนแก้ไข: ถ้าผู้ใช้ไม่ได้เปลี่ยนวัน
  /// ให้ผ่านได้ แม้ของชิ้นนั้นจะหมดอายุไปแล้ว
  static String? expiryDate(DateTime? value, {DateTime? originalDate}) {
    if (value == null) return 'กรุณาเลือกวันหมดอายุ';
    final date = dateOnly(value);
    if (originalDate != null && date == dateOnly(originalDate)) return null;
    if (date.isBefore(today())) return 'วันหมดอายุต้องไม่เป็นวันที่ผ่านมาแล้ว';
    return null;
  }
}
