import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/category.dart';
import '../../models/food_item.dart';
import '../../models/item_prefill.dart';
import '../../models/storage_location.dart';
import '../../services/item_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_format.dart';
import '../../utils/validators.dart';
import '../../widgets/field_label.dart';

/// ใช้ทั้งเพิ่มของ ([itemId] = null) และแก้ไข ([itemId] = id ของ document)
class ItemFormScreen extends StatefulWidget {
  final String? itemId;
  final ItemPrefill? prefill; // เฉพาะโหมดเพิ่มที่มาจากหน้า Scan

  const ItemFormScreen({super.key, this.itemId, this.prefill});

  bool get isEditing => itemId != null;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  // โหมดแก้ไข: ดึงข้อมูลเดิมครั้งเดียวด้วย .get() มาเป็นค่าเริ่มต้นของฟอร์ม
  Future<FoodItem?>? _loadItem;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadItem = ItemService().getItem(widget.itemId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) {
      return _ItemForm(initialItem: null, prefill: widget.prefill);
    }

    return FutureBuilder<FoodItem?>(
      future: _loadItem,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('แก้ไขของ')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final item = snapshot.data;
        if (snapshot.hasError || item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('แก้ไขของ')),
            body: const Center(child: Text('ไม่พบรายการนี้')),
          );
        }
        return _ItemForm(initialItem: item);
      },
    );
  }
}

class _ItemForm extends StatefulWidget {
  final FoodItem? initialItem;
  final ItemPrefill? prefill;

  const _ItemForm({required this.initialItem, this.prefill});

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemService = ItemService();
  late final TextEditingController _nameController;

  // ค่าที่ได้จาก FormField แต่ละช่องตอน save()
  late FoodCategory _category;
  late StorageLocation _storage;
  late int _quantity;
  DateTime? _expiryDate;

  bool _isSaving = false;

  FoodItem? get _initial => widget.initialItem;
  bool get _isEditing => _initial != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _initial?.name ?? widget.prefill?.name ?? '',
    );
    _category = _initial?.category ?? FoodCategory.other;
    _storage = _initial?.storage ?? StorageLocation.fridge;
    _quantity = _initial?.quantity ?? 1;
    _expiryDate = _initial?.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // validate() เรียก validator ทุกช่อง ถ้ามีช่องไหนไม่ผ่าน จะแสดง error ใต้ช่องนั้นและหยุด
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!
        .save(); // เรียก onSaved ทุกช่อง → ค่าเข้าตัวแปรด้านบน

    setState(() => _isSaving = true);
    final now = DateTime.now();
    try {
      if (_isEditing) {
        await _itemService.updateItem(
          _initial!.copyWith(
            name: _nameController.text.trim(),
            category: _category,
            storage: _storage,
            quantity: _quantity,
            expiryDate: dateOnly(_expiryDate!),
            updatedAt: now,
          ),
        );
      } else {
        await _itemService.addItem(
          FoodItem(
            name: _nameController.text.trim(),
            category: _category,
            storage: _storage,
            quantity: _quantity,
            expiryDate: dateOnly(_expiryDate!),
            barcode: widget.prefill?.barcode,
            imageUrl: widget.prefill?.imageUrl,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกแล้ว')));
      context.pop();
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายการนี้?'),
        content: Text('ลบ "${_initial!.name}" ออกถาวร และจะไม่ถูกนับในสถิติ'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await _itemService.deleteItem(_initial!.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));
      context.go('/'); // ข้ามหน้า Detail ของรายการที่ถูกลบไปแล้ว
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบไม่สำเร็จ กรุณาลองใหม่')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขของ' : 'เพิ่มของ'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'ลบรายการ',
              icon: const Icon(LucideIcons.trash2, color: AppColors.error),
              onPressed: _isSaving ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (widget.prefill != null) ...[
              _BarcodeChip(prefill: widget.prefill!),
              const SizedBox(height: 12),
            ],
            _Section(
              children: [
                const FieldLabel('ชื่อสินค้า'),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'เช่น นมสด 830 มล.',
                  ),
                  validator: Validators.itemName,
                ),
                const SizedBox(height: 20),
                const FieldLabel('หมวดหมู่'),
                DropdownButtonFormField<FoodCategory>(
                  initialValue: _category,
                  icon: const Icon(LucideIcons.chevronDown, size: 20),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  items: [
                    for (final category in FoodCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Row(
                          children: [
                            Icon(category.icon, size: 20),
                            const SizedBox(width: 12),
                            Text(category.label),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (_) {},
                  onSaved: (value) => _category = value!,
                ),
                const SizedBox(height: 20),
                const FieldLabel('จำนวน'),
                _QuantityField(
                  initialValue: _quantity,
                  onSaved: (value) => _quantity = value!,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              children: [
                const FieldLabel('วันหมดอายุ'),
                _ExpiryDateField(
                  initialValue: _expiryDate,
                  originalDate: _initial?.expiryDate,
                  onSaved: (value) => _expiryDate = value,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              children: [
                const FieldLabel('สถานที่เก็บ'),
                FormField<StorageLocation>(
                  initialValue: _storage,
                  onSaved: (value) => _storage = value!,
                  builder: (field) => SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<StorageLocation>(
                      showSelectedIcon: false,
                      segments: [
                        for (final location in StorageLocation.values)
                          ButtonSegment(
                            value: location,
                            icon: Icon(location.icon, size: 18),
                            label: Text(location.label),
                          ),
                      ],
                      selected: {field.value!},
                      onSelectionChanged: (selection) =>
                          field.didChange(selection.first),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // ปุ่มบันทึกติดด้านล่างเสมอ
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(LucideIcons.save, size: 20),
            label: const Text('บันทึก'),
          ),
        ),
      ),
    );
  }
}

/// chip แสดงเลขบาร์โค้ดที่สแกนมา (+ ข้อความบอกว่าดึงข้อมูลจาก Open Food Facts ถ้าเจอสินค้า)
class _BarcodeChip extends StatelessWidget {
  final ItemPrefill prefill;

  const _BarcodeChip({required this.prefill});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(LucideIcons.barcode, size: 18),
          label: Text(prefill.barcode),
        ),
        if (prefill.fromOpenFoodFacts)
          Chip(
            avatar: const Icon(
              LucideIcons.circleCheck,
              size: 18,
              color: AppColors.freshText,
            ),
            backgroundColor: AppColors.freshSoft,
            label: Text(
              'ดึงข้อมูลจาก Open Food Facts',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.freshText,
              ),
            ),
          ),
      ],
    );
  }
}

/// การ์ดสีขาวครอบกลุ่มช่องกรอก
class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// ช่องจำนวนแบบ stepper −/+ ทำเป็น FormField เพื่อให้ validate/save พร้อมช่องอื่นได้
class _QuantityField extends FormField<int> {
  _QuantityField({required int super.initialValue, super.onSaved})
    : super(
        validator: Validators.quantity,
        builder: (field) {
          final value = field.value ?? 1;
          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'ลดจำนวน',
                  onPressed: value > 1
                      ? () => field.didChange(value - 1)
                      : null,
                  icon: const Icon(LucideIcons.minus, size: 20),
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: AppTheme.serif(fontSize: 24),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'เพิ่มจำนวน',
                  onPressed: () => field.didChange(value + 1),
                  icon: const Icon(LucideIcons.plus, size: 20),
                ),
              ],
            ),
          );
        },
      );
}

/// ช่องวันหมดอายุ: กดเพื่อเปิด date picker + ปุ่มลัด +3 / +7 / +14 วัน
class _ExpiryDateField extends FormField<DateTime> {
  _ExpiryDateField({super.initialValue, DateTime? originalDate, super.onSaved})
    : super(
        validator: (value) =>
            Validators.expiryDate(value, originalDate: originalDate),
        builder: (field) {
          final context = field.context;
          final textTheme = Theme.of(context).textTheme;
          final value = field.value;
          final hasError = field.hasError;

          Future<void> pickDate() async {
            final now = today();
            // ตอนแก้ไขของที่หมดอายุไปแล้ว ให้ปฏิทินเริ่มได้ตั้งแต่วันเดิม
            final firstDate = originalDate != null && originalDate.isBefore(now)
                ? dateOnly(originalDate)
                : now;
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: firstDate,
              lastDate: DateTime(now.year + 5),
              helpText: 'เลือกวันหมดอายุ',
            );
            if (picked != null) field.didChange(picked);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: pickDate,
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.calendar, size: 20),
                    errorText: field.errorText,
                    errorMaxLines: 2,
                  ),
                  isEmpty: value == null,
                  child: Text(
                    value == null ? 'แตะเพื่อเลือกวัน' : formatShortDate(value),
                    style: textTheme.bodyLarge?.copyWith(
                      color: value == null
                          ? AppColors.textMuted
                          : hasError
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontWeight: value == null ? null : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in const [3, 7, 14])
                    ActionChip(
                      label: Text(
                        '+$days วัน (${DateFormat('d MMM', 'th').format(daysFromToday(days))})',
                      ),
                      onPressed: () => field.didChange(daysFromToday(days)),
                    ),
                ],
              ),
            ],
          );
        },
      );
}
