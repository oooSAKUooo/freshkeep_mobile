import 'package:shared_preferences/shared_preferences.dart';

/// ค่าตั้งค่าการแจ้งเตือนที่เก็บในเครื่อง (SharedPreferences)
/// ไม่เก็บใน Firestore เพราะเป็นค่าของเครื่องนี้ และไม่ต้องใช้ข้ามอุปกรณ์
class SettingsService {
  static const _daysBeforeKey = 'notify_days_before';
  static const _enabledKey = 'notifications_enabled';

  static const _hourKey = 'notify_hour';
  static const _minuteKey = 'notify_minute';

  static const defaultDaysBefore = 2;
  static const defaultHour = 9;
  static const defaultMinute = 0;

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

  /// เวลาที่ให้แจ้งเตือนในแต่ละวัน (ค่าเริ่มต้น 09:00)
  Future<(int hour, int minute)> getNotifyTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getInt(_hourKey) ?? defaultHour,
      prefs.getInt(_minuteKey) ?? defaultMinute,
    );
  }

  Future<void> setNotifyTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);
  }

  /// ชื่อไฟล์รูปโปรไฟล์ในเครื่อง แยกตาม uid (รูปอยู่เฉพาะเครื่องนี้ เหมือนรูปสินค้า)
  Future<String?> getProfilePhoto(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_photo_$uid');
  }

  Future<void> setProfilePhoto(String uid, String? fileName) async {
    final prefs = await SharedPreferences.getInstance();
    if (fileName == null) {
      await prefs.remove('profile_photo_$uid');
    } else {
      await prefs.setString('profile_photo_$uid', fileName);
    }
  }
}
