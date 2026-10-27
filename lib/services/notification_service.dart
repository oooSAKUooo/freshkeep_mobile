import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/food_item.dart';
import 'settings_service.dart';

/// แจ้งเตือนก่อนของหมดอายุ (local notification ตั้งเวลาล่วงหน้า ไม่ต้องใช้เซิร์ฟเวอร์)
/// ผูกกับ CRUD ใน ItemService และการตั้งค่าใน Profile
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _notifyHour = 9;
  static const _channelId = 'expiry_reminder';

  final _plugin = FlutterLocalNotificationsPlugin();
  final _settings = SettingsService();
  bool _initialized = false;

  /// เรียกครั้งเดียวใน main() ก่อน runApp
  Future<void> init() async {
    // timezone: ต้องรู้เขตเวลาของเครื่อง เพื่อให้ "09:00" เป็นเวลาท้องถิ่นของผู้ใช้
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // ไม่ขอ permission ตอน initialize เพราะจะขอเองใน requestPermission()
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// iOS: ขอตอนเริ่มใช้ / Android 13+: POST_NOTIFICATIONS
  Future<void> requestPermission() async {
    if (!_initialized) return;
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  /// notification ID = hashCode ของ itemId (บังคับให้เป็นบวก 31 บิต ตามที่ plugin ต้องการ)
  int _idFor(String itemId) => itemId.hashCode & 0x7FFFFFFF;

  /// ตั้งเตือน 09:00 ของวัน (expiryDate − N วัน)
  /// ถ้าปิดการแจ้งเตือนอยู่ หรือเวลานั้นผ่านไปแล้ว จะไม่ตั้ง
  Future<void> scheduleForItem(FoodItem item) async {
    if (!_initialized || item.id == null) return;
    if (!await _settings.isNotificationsEnabled()) return;

    final daysBefore = await _settings.getDaysBefore();
    final expiry = item.expiryDate;
    final scheduled = tz.TZDateTime(
      tz.local,
      expiry.year,
      expiry.month,
      expiry.day - daysBefore,
      _notifyHour,
    );
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id: _idFor(item.id!),
        title: 'ใกล้หมดอายุ',
        body: '${item.name} จะหมดอายุในอีก $daysBefore วัน',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'เตือนก่อนหมดอายุ',
            channelDescription: 'แจ้งเตือนเมื่อของในตู้เย็นใกล้หมดอายุ',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        // inexact ไม่ต้องขอสิทธิ์ exact alarm (ตรงเวลาโดยประมาณ พอสำหรับเตือนรายวัน)
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      // ตั้งเตือนไม่สำเร็จไม่ควรทำให้การบันทึกของล้มเหลว
      debugPrint('schedule notification failed: $e');
    }
  }

  Future<void> cancelForItem(String itemId) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _idFor(itemId));
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  /// เปลี่ยนค่า N / เปิด-ปิดแจ้งเตือน → ยกเลิกทั้งหมดแล้วตั้งใหม่จากรายการ active
  Future<void> rescheduleAll(List<FoodItem> activeItems) async {
    await cancelAll();
    for (final item in activeItems) {
      await scheduleForItem(item);
    }
  }
}
