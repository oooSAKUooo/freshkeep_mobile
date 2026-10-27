import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../services/item_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _itemService = ItemService();
  final _settings = SettingsService();

  // สร้าง stream ครั้งเดียว (ไม่สร้างใน build) เหมือนหน้า Home
  late final Stream<MonthStats> _statsStream = _itemService.watchMonthStats();

  // ค่าตั้งค่าโหลดจาก SharedPreferences แบบ async ครั้งเดียวตอนเปิดหน้า
  late final Future<(int, bool)> _loadSettings = _readSettings();

  Future<(int, bool)> _readSettings() async => (
    await _settings.getDaysBefore(),
    await _settings.isNotificationsEnabled(),
  );

  /// เปลี่ยนค่า N หรือเปิด/ปิด → บันทึกค่า แล้วตั้งแจ้งเตือนใหม่ทั้งหมดจากรายการ active
  Future<void> _applySettings({int? daysBefore, bool? enabled}) async {
    if (daysBefore != null) await _settings.setDaysBefore(daysBefore);
    if (enabled != null) await _settings.setNotificationsEnabled(enabled);
    try {
      final activeItems = await _itemService.getActiveItems();
      await NotificationService.instance.rescheduleAll(activeItems);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตั้งการแจ้งเตือนใหม่ไม่สำเร็จ กรุณาลองใหม่'),
        ),
      );
    }
  }

  String _initials(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
    // logout แล้ว router ได้ยิน authStateChanges และพาไปหน้า Login เอง
    if (confirmed == true) {
      await NotificationService.instance.cancelAll();
      await AuthService().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = AuthService().currentUser;
    final name = user?.displayName ?? '';
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const AppLogo.horizontal()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                _initials(name.isEmpty ? email : name),
                style: AppTheme.serif(fontSize: 32, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'ผู้ใช้ FreshKeep' : name,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            email,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          StreamBuilder<MonthStats>(
            stream: _statsStream,
            builder: (context, snapshot) =>
                _StatsCard(stats: snapshot.data, hasError: snapshot.hasError),
          ),
          const SizedBox(height: 16),
          FutureBuilder<(int, bool)>(
            future: _loadSettings,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return _SettingsCard(
                initialDaysBefore: snapshot.data!.$1,
                initialEnabled: snapshot.data!.$2,
                onChanged: _applySettings,
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(LucideIcons.logOut, color: AppColors.error),
              title: Text(
                'ออกจากระบบ',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.error),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดสถิติเดือนนี้: กินหมด / ทิ้ง / ลดขยะได้ X%
class _StatsCard extends StatelessWidget {
  final MonthStats? stats;
  final bool hasError;

  const _StatsCard({required this.stats, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget number(String label, String value, Color color) => Expanded(
      child: Column(
        children: [
          Text(value, style: AppTheme.serif(fontSize: 36, color: color)),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถิติเดือนนี้',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (hasError)
              Text(
                'โหลดสถิติไม่สำเร็จ',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
              )
            else if (stats == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  number('กินหมด', '${stats!.consumed}', AppColors.freshText),
                  number('ทิ้ง', '${stats!.discarded}', AppColors.urgentText),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.freshSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.leaf, color: AppColors.freshText),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ลดขยะอาหารได้',
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.freshText,
                        ),
                      ),
                    ),
                    Text(
                      stats!.wasteReducedLabel,
                      style: AppTheme.serif(
                        fontSize: 28,
                        color: AppColors.freshText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ตั้งค่าการแจ้งเตือน: เปิด/ปิด + แจ้งล่วงหน้า 1 / 2 / 3 วัน
class _SettingsCard extends StatefulWidget {
  final int initialDaysBefore;
  final bool initialEnabled;
  final Future<void> Function({int? daysBefore, bool? enabled}) onChanged;

  const _SettingsCard({
    required this.initialDaysBefore,
    required this.initialEnabled,
    required this.onChanged,
  });

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  late int _daysBefore = widget.initialDaysBefore;
  late bool _enabled = widget.initialEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตั้งค่า',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('การแจ้งเตือน'),
              subtitle: const Text('เตือนเวลา 09:00 ก่อนของหมดอายุ'),
              value: _enabled,
              onChanged: (value) {
                setState(() => _enabled = value);
                widget.onChanged(enabled: value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'แจ้งเตือนล่วงหน้า',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 วัน')),
                  ButtonSegment(value: 2, label: Text('2 วัน')),
                  ButtonSegment(value: 3, label: Text('3 วัน')),
                ],
                selected: {_daysBefore},
                // ปิดการแจ้งเตือนอยู่ → เลือกจำนวนวันไม่ได้
                onSelectionChanged: _enabled
                    ? (selection) {
                        setState(() => _daysBefore = selection.first);
                        widget.onChanged(daysBefore: selection.first);
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
