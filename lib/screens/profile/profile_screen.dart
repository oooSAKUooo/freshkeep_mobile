import 'package:flutter/cupertino.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../services/image_storage_service.dart';
import '../../services/item_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/local_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _itemService = ItemService();
  final _settings = SettingsService();
  final _imageStorage = ImageStorageService();
  final _auth = AuthService();

  // ชื่อและรูปโปรไฟล์เก็บใน state เพื่อให้หน้าอัปเดตทันทีหลังแก้ไข
  late String _name = _auth.currentUser?.displayName ?? '';
  String? _photoFile;

  // สร้าง stream ครั้งเดียว (ไม่สร้างใน build) เหมือนหน้า Home
  late final Stream<MonthStats> _statsStream = _itemService.watchMonthStats();

  // ค่าตั้งค่าโหลดจาก SharedPreferences แบบ async ครั้งเดียวตอนเปิดหน้า
  late final Future<(int, bool, TimeOfDay)> _loadSettings = _readSettings();

  Future<(int, bool, TimeOfDay)> _readSettings() async {
    final (hour, minute) = await _settings.getNotifyTime();
    return (
      await _settings.getDaysBefore(),
      await _settings.isNotificationsEnabled(),
      TimeOfDay(hour: hour, minute: minute),
    );
  }

  /// เปลี่ยนค่า N หรือเปิด/ปิด → บันทึกค่า แล้วตั้งแจ้งเตือนใหม่ทั้งหมดจากรายการ active
  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final fileName = await _settings.getProfilePhoto(uid);
    if (mounted) setState(() => _photoFile = fileName);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final formKey = GlobalKey<FormState>();
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('แก้ไขชื่อ'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(hintText: 'ชื่อที่แสดง'),
            validator: Validators.displayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName == _name) return;

    try {
      await _auth.updateDisplayName(newName);
      if (!mounted) return;
      setState(() => _name = newName);
      _showMessage('บันทึกชื่อแล้ว');
    } on AuthException catch (e) {
      _showMessage(e.message);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (picked == null) return;
      final uid = _auth.currentUser!.uid;
      final oldFile = _photoFile;
      final newFile = await _imageStorage.save(picked.path);
      await _settings.setProfilePhoto(uid, newFile);
      await _imageStorage.delete(oldFile);
      if (mounted) setState(() => _photoFile = newFile);
    } on PlatformException {
      _showMessage(
        'เปิดกล้องหรือคลังรูปไม่ได้ ตรวจสอบสิทธิ์ในการตั้งค่าเครื่อง',
      );
    }
  }

  Future<void> _removePhoto() async {
    await _settings.setProfilePhoto(_auth.currentUser!.uid, null);
    await _imageStorage.delete(_photoFile);
    if (mounted) setState(() => _photoFile = null);
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoFile != null)
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: AppColors.error),
                title: const Text(
                  'ลบรูป',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _applySettings({
    int? daysBefore,
    bool? enabled,
    TimeOfDay? time,
  }) async {
    if (daysBefore != null) await _settings.setDaysBefore(daysBefore);
    if (enabled != null) await _settings.setNotificationsEnabled(enabled);
    if (time != null) await _settings.setNotifyTime(time.hour, time.minute);
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
    final name = _name;
    final email = _auth.currentUser?.email ?? '';
    final initials = Text(
      _initials(name.isEmpty ? email : name),
      style: AppTheme.number(fontSize: 32, color: AppColors.primary),
    );

    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const AppLogo.horizontal()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        children: [
          Center(
            child: GestureDetector(
              onTap: _showPhotoOptions,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primarySoft,
                    child: _photoFile == null
                        ? initials
                        : ClipOval(
                            child: SizedBox.square(
                              dimension: 88,
                              child: LocalImage(
                                fileName: _photoFile!,
                                fallback: Center(child: initials),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        LucideIcons.camera,
                        size: 14,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name.isEmpty ? 'ผู้ใช้ FreshKeep' : name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'แก้ไขชื่อ',
                icon: const Icon(LucideIcons.pencil, size: 18),
                onPressed: _editName,
              ),
            ],
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
          FutureBuilder<(int, bool, TimeOfDay)>(
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
                initialTime: snapshot.data!.$3,
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

class _StatsCard extends StatelessWidget {
  final MonthStats? stats;
  final bool hasError;

  const _StatsCard({required this.stats, required this.hasError});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget number(String label, String value, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          children: [
            Text(value, style: AppTheme.number(fontSize: 36, color: color)),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
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
                  number(
                    'กินหมดแล้ว',
                    '${stats!.consumed}',
                    AppColors.freshText,
                  ),
                  const SizedBox(width: 12),
                  number('ทิ้ง', '${stats!.discarded}', AppColors.urgentText),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.freshSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.leaf,
                          color: AppColors.freshText,
                        ),
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
                          style: AppTheme.number(
                            fontSize: 28,
                            color: AppColors.freshText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: stats!.wasteReducedFraction,
                        minHeight: 8,
                        backgroundColor: AppColors.surface,
                        color: AppColors.primary,
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

class _SettingsCard extends StatefulWidget {
  final int initialDaysBefore;
  final bool initialEnabled;
  final TimeOfDay initialTime;
  final Future<void> Function({int? daysBefore, bool? enabled, TimeOfDay? time})
  onChanged;

  const _SettingsCard({
    required this.initialDaysBefore,
    required this.initialEnabled,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  late int _daysBefore = widget.initialDaysBefore;
  late bool _enabled = widget.initialEnabled;
  late TimeOfDay _time = widget.initialTime;

  Future<void> _pickTime() async {
    var selected = _time;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('ยกเลิก'),
                  ),
                  Expanded(
                    child: Text(
                      'เวลาแจ้งเตือน',
                      textAlign: TextAlign.center,
                      style: Theme.of(sheetContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('ตกลง'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                // ค่าเริ่มต้นของล้อ = เวลาที่ตั้งไว้ตอนนี้ (วันที่ไม่มีผล ใช้แค่ชั่วโมง/นาที)
                initialDateTime: DateTime(2000, 1, 1, _time.hour, _time.minute),
                onDateTimeChanged: (value) => selected = TimeOfDay(
                  hour: value.hour,
                  minute: value.minute,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _time = selected);
    widget.onChanged(time: selected);
  }

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
              subtitle: const Text('เตือนล่วงหน้าก่อนของหมดอายุ'),
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
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: _enabled,
              leading: const Icon(LucideIcons.clock),
              title: const Text('เวลาแจ้งเตือน'),
              trailing: Text(
                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')} น.',
                style: textTheme.titleMedium?.copyWith(
                  color: _enabled ? AppColors.primary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _pickTime,
            ),
          ],
        ),
      ),
    );
  }
}
