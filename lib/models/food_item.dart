import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/expiry_status.dart';
import 'category.dart';
import 'storage_location.dart';

enum ItemStatus {
  active,
  consumed,
  discarded;

  static ItemStatus fromValue(String? value) {
    return ItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ItemStatus.active,
    );
  }
}

/// ของ 1 ชิ้นในตู้เย็น = 1 document ใน users/{uid}/items/{id}
class FoodItem {
  final String? id; // null = ยังไม่ได้บันทึกลง Firestore
  final String name;
  final String? barcode;
  final String? imageUrl;
  final String? imageFile; // ชื่อไฟล์รูปที่ผู้ใช้เลือกเอง (เก็บในเครื่อง)
  final FoodCategory category;
  final StorageLocation storage;
  final int quantity;
  final DateTime expiryDate;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;

  const FoodItem({
    this.id,
    required this.name,
    this.barcode,
    this.imageUrl,
    this.imageFile,
    required this.category,
    required this.storage,
    required this.quantity,
    required this.expiryDate,
    this.status = ItemStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.finishedAt,
  });

  ExpiryStatus get expiryStatus => ExpiryStatus.fromDate(expiryDate);

  /// แปลง document จาก Firestore → object (Timestamp → DateTime)
  factory FoodItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FoodItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      barcode: data['barcode'] as String?,
      imageUrl: data['imageUrl'] as String?,
      imageFile: data['imageFile'] as String?,
      category: FoodCategory.fromValue(data['category'] as String?),
      storage: StorageLocation.fromValue(data['storage'] as String?),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      status: ItemStatus.fromValue(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      finishedAt: (data['finishedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// แปลง object → Map สำหรับเขียนลง Firestore (ไม่รวม id เพราะ id คือชื่อ document)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'imageFile': imageFile,
      'category': category.value,
      'storage': storage.value,
      'quantity': quantity,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'finishedAt': finishedAt == null ? null : Timestamp.fromDate(finishedAt!),
    };
  }

  FoodItem copyWith({
    String? id,
    String? name,
    String? imageFile,
    bool removeImageFile = false,
    FoodCategory? category,
    StorageLocation? storage,
    int? quantity,
    DateTime? expiryDate,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode,
      imageUrl: imageUrl,
      imageFile: removeImageFile ? null : (imageFile ?? this.imageFile),
      category: category ?? this.category,
      storage: storage ?? this.storage,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      finishedAt: finishedAt,
    );
  }
}
