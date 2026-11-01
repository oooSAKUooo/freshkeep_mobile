import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/food_item.dart';
import '../../services/item_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/local_image.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _itemService = ItemService();
  // ติดตาม document แบบ realtime: กลับมาจากหน้า Edit แล้วข้อมูลอัปเดตเองโดยไม่ต้องโหลดใหม่
  late final Stream<FoodItem?> _itemStream;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _itemStream = _itemService.watchItem(widget.itemId);
  }

  Future<void> _finish(ItemStatus status) async {
    setState(() => _isUpdating = true);
    try {
      await _itemService.markFinished(widget.itemId, status);
      if (!mounted) return;
      final message = status == ItemStatus.consumed
          ? 'บันทึกว่ากินหมดแล้ว'
          : 'บันทึกว่าทิ้งแล้ว';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.pop();
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FoodItem?>(
      stream: _itemStream,
      builder: (context, snapshot) {
        final item = snapshot.data;
        final isActive = item?.status == ItemStatus.active;

        Widget body;
        if (snapshot.hasError) {
          body = const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (item == null) {
          body = const Center(child: Text('ไม่พบรายการนี้'));
        } else {
          body = _DetailBody(item: item);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('รายละเอียด'),
            actions: [
              if (isActive)
                IconButton(
                  tooltip: 'แก้ไข',
                  icon: const Icon(LucideIcons.pencil, size: 20),
                  onPressed: () => context.push('/item/${widget.itemId}/edit'),
                ),
            ],
          ),
          body: body,
          bottomNavigationBar: isActive
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: _isUpdating
                                ? null
                                : () => _finish(ItemStatus.discarded),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.urgentText,
                              side: const BorderSide(color: AppColors.urgent),
                            ),
                            icon: const Icon(LucideIcons.trash2, size: 20),
                            label: const Text('ทิ้ง'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: _isUpdating
                                ? null
                                : () => _finish(ItemStatus.consumed),
                            icon: const Icon(LucideIcons.circleCheck, size: 20),
                            label: const Text('กินหมดแล้ว'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final FoodItem item;

  const _DetailBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _ProductImage(item: item),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: Icon(item.category.icon, size: 16),
              label: Text(item.category.label),
            ),
            Chip(
              avatar: Icon(item.storage.icon, size: 16),
              label: Text(item.storage.label),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.name,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        if (item.status == ItemStatus.active)
          _FreshnessBanner(item: item)
        else
          _FinishedBanner(item: item),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                _InfoRow(
                  icon: LucideIcons.package,
                  label: 'จำนวน',
                  value: '${item.quantity} ชิ้น',
                ),
                const Divider(),
                _InfoRow(
                  icon: LucideIcons.calendar,
                  label: 'วันหมดอายุ',
                  value: formatShortDate(item.expiryDate),
                ),
                const Divider(),
                _InfoRow(
                  icon: LucideIcons.history,
                  label: 'เพิ่มเมื่อ',
                  value: formatShortDate(item.createdAt),
                ),
                const Divider(),
                _InfoRow(
                  icon: LucideIcons.barcode,
                  label: 'บาร์โค้ด',
                  value: item.barcode ?? 'กรอกเอง',
                ),
                // ของที่กินหมด/ทิ้งแล้วไม่มีการแจ้งเตือน จึงแสดงเฉพาะของที่ยังอยู่ในตู้เย็น
                if (item.status == ItemStatus.active) ...[
                  const Divider(),
                  const _NotificationRow(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  final FoodItem item;

  const _ProductImage({required this.item});

  Widget _networkOrPlaceholder(Widget placeholder) {
    if (item.imageUrl == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: item.imageUrl!,
      fit: BoxFit.contain,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => placeholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: CategoryIcon(
        category: item.category,
        level: item.expiryStatus.level,
        size: 96,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        height: 220,
        color: AppColors.surface,
        // รูปที่ผู้ใช้เลือกเองมาก่อน → รูปจาก Open Food Facts → ไอคอนหมวด
        child: item.imageFile != null
            ? LocalImage(
                fileName: item.imageFile!,
                fit: BoxFit.contain,
                fallback: _networkOrPlaceholder(placeholder),
              )
            : _networkOrPlaceholder(placeholder),
      ),
    );
  }
}

/// ความสด = วันที่เหลือ / จำนวนวันทั้งหมดตั้งแต่เพิ่มของ (createdAt → expiryDate)
class _FreshnessBanner extends StatelessWidget {
  final FoodItem item;

  const _FreshnessBanner({required this.item});

  double get _freshness {
    final daysLeft = item.expiryStatus.daysLeft;
    final totalDays = dateOnly(
      item.expiryDate,
    ).difference(dateOnly(item.createdAt)).inDays;
    if (totalDays <= 0) return daysLeft >= 0 ? 1 : 0;
    return (daysLeft / totalDays).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = item.expiryStatus;
    final strongColor = AppColors.statusTextColor(status.level);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.statusSoftColor(status.level),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, color: strongColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.bannerText,
                      style: textTheme.titleMedium?.copyWith(
                        color: strongColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'ควรบริโภคให้หมดภายใน ${formatShortDate(item.expiryDate)}',
                      style: textTheme.bodySmall?.copyWith(color: strongColor),
                    ),
                  ],
                ),
              ),
              AnimatedCount(
                value: (_freshness * 100).round(),
                suffix: '%',
                style: AppTheme.number(fontSize: 28, color: strongColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedFraction(
            value: _freshness,
            builder: (context, value) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: AppColors.statusColor(status.level),
              backgroundColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เพิ่มเมื่อ ${formatShortDate(item.createdAt)}',
                style: textTheme.labelSmall?.copyWith(color: strongColor),
              ),
              Text(
                'หมดอายุ ${formatShortDate(item.expiryDate)}',
                style: textTheme.labelSmall?.copyWith(color: strongColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinishedBanner extends StatelessWidget {
  final FoodItem item;

  const _FinishedBanner({required this.item});

  @override
  Widget build(BuildContext context) {
    final consumed = item.status == ItemStatus.consumed;
    final finishedAt = item.finishedAt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Row(
        children: [
          Icon(consumed ? LucideIcons.circleCheck : LucideIcons.trash2),
          const SizedBox(width: 12),
          Text(
            '${consumed ? 'กินหมดแล้ว' : 'ทิ้งแล้ว'}'
            '${finishedAt == null ? '' : ' เมื่อ ${formatShortDate(finishedAt)}'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// แถว "การแจ้งเตือน" อ่านค่าที่ตั้งไว้ใน Profile (SharedPreferences เป็น async จึงใช้ FutureBuilder)
class _NotificationRow extends StatelessWidget {
  const _NotificationRow();

  Future<String> _describe() async {
    final settings = SettingsService();
    if (!await settings.isNotificationsEnabled()) return 'ปิดอยู่';
    final days = await settings.getDaysBefore();
    final (hour, minute) = await settings.getNotifyTime();
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return 'ล่วงหน้า $days วัน ($time น.)';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _describe(),
      builder: (context, snapshot) => _InfoRow(
        icon: LucideIcons.bell,
        label: 'การแจ้งเตือน',
        value: snapshot.data ?? '...',
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
