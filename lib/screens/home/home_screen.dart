import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/food_item.dart';
import '../../services/item_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/expiry_status.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // สร้าง stream ครั้งเดียวใน initState ไม่ใช่ใน build
  // ไม่งั้นทุกครั้งที่ rebuild จะเปิด listener กับ Firestore ใหม่
  late final Stream<List<FoodItem>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _itemsStream = ItemService().watchActiveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: false, title: const AppLogo.horizontal()),
      // StreamBuilder สร้าง UI ใหม่ทุกครั้งที่ Firestore ส่งข้อมูลชุดใหม่มา
      body: StreamBuilder<List<FoodItem>>(
        stream: _itemsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageView(
              icon: LucideIcons.circleAlert,
              message: 'โหลดรายการไม่สำเร็จ\n${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _HomeContent(items: snapshot.data!);
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<FoodItem> items;

  const _HomeContent({required this.items});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'สวัสดีตอนเช้า';
    if (hour < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      // เว้นที่ด้านล่างให้ปุ่มสแกนที่ยื่นขึ้นมา
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
      children: [
        Text(
          _greeting(),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        Text(
          formatFullDayDate(DateTime.now()),
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        _SummaryCard(items: items),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'จัดเรียงตามวันหมดอายุ',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${items.length}',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: _MessageView(
              icon: LucideIcons.refrigerator,
              message:
                  'ยังไม่มีของในตู้เย็น\nกดปุ่มตรงกลางด้านล่างเพื่อเพิ่มของชิ้นแรก',
            ),
          )
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ItemCard(
                item: item,
                onTap: () => context.push('/item/${item.id}'),
              ),
            ),
      ],
    );
  }
}

/// การ์ดสรุป: จำนวนของ, จำนวนที่ใกล้หมดอายุ และแถบสัดส่วน สด / ใกล้หมด / ด่วน
class _SummaryCard extends StatelessWidget {
  final List<FoodItem> items;

  const _SummaryCard({required this.items});

  int _countLevel(ExpiryLevel level) =>
      items.where((item) => item.expiryStatus.level == level).length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final freshCount = _countLevel(ExpiryLevel.fresh);
    final soonCount = _countLevel(ExpiryLevel.soon);
    final urgentCount = _countLevel(ExpiryLevel.urgent);
    final nearExpiryCount = soonCount + urgentCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.refrigerator,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'สถานะความสด',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${items.length}', style: AppTheme.serif(fontSize: 40)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('ชิ้นในตู้เย็น', style: textTheme.bodyMedium),
                ),
                const SizedBox(width: 20),
                Text(
                  '$nearExpiryCount',
                  style: AppTheme.serif(
                    fontSize: 40,
                    color: AppColors.urgentText,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('ใกล้หมดอายุ', style: textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      for (final (level, count) in [
                        (ExpiryLevel.fresh, freshCount),
                        (ExpiryLevel.soon, soonCount),
                        (ExpiryLevel.urgent, urgentCount),
                      ])
                        if (count > 0)
                          Expanded(
                            flex: count,
                            child: Container(
                              color: AppColors.statusColor(level),
                            ),
                          ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Legend(
                  level: ExpiryLevel.fresh,
                  label: 'สดใหม่ ($freshCount)',
                ),
                _Legend(
                  level: ExpiryLevel.soon,
                  label: 'ใน 3 วัน ($soonCount)',
                ),
                _Legend(
                  level: ExpiryLevel.urgent,
                  label: 'ด่วน ($urgentCount)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final ExpiryLevel level;
  final String label;

  const _Legend({required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.statusColor(level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MessageView({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
