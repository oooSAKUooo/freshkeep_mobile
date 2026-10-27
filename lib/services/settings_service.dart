import 'package:shared_preferences/shared_preferences.dart';

/// ค่าตั้งค่าการแจ้งเตือนที่เก็บในเครื่อง (SharedPreferences)
/// ไม่เก็บใน Firestore เพราะเป็นค่าของเครื่องนี้ และไม่ต้องใช้ข้ามอุปกรณ์
class SettingsService {
  static const _daysBeforeKey = 'notify_days_before';
  static const _enabledKey = 'notifications_enabled';

  static const defaultDaysBefore = 2;

  /// SharedPreferences.getInstance() เป็น async เพราะต้องอ่านไฟล์ในเครื่อง
  Future<int> getDaysBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_daysBeforeKey) ?? defaultDaysBefore;
  }

  Future<void> setDaysBefore(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_daysBeforeKey, days);
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
