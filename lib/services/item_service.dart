import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item.dart';
import 'notification_service.dart';

/// Firestore CRUD ของรายการในตู้เย็น
/// ข้อมูลอยู่ที่ users/{uid}/items เพื่อให้แต่ละคนเห็นเฉพาะของตัวเอง
/// (และ security rules ตรวจได้ง่ายว่า uid ใน path ตรงกับคนที่ login)
class ItemService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _db.collection('users').doc(uid).collection('items');
  }

  // ---------- Read ----------

  /// รายการที่ยังอยู่ในตู้เย็น เรียงจากใกล้หมดอายุที่สุด
  /// `.snapshots()` คืน Stream ที่ส่งข้อมูลใหม่มาทุกครั้งที่ document เปลี่ยน (realtime)
  /// ต่างจาก `.get()` ที่ดึงครั้งเดียวแล้วจบ
  /// หมายเหตุ: where + orderBy คนละ field ต้องมี composite index (status, expiryDate)
  Stream<List<FoodItem>> watchActiveItems() {
    return _items
        .where('status', isEqualTo: ItemStatus.active.name)
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FoodItem.fromFirestore).toList());
  }

  /// ดึงครั้งเดียว — ใช้ตั้งแจ้งเตือนใหม่ทั้งหมดตอนเปลี่ยนค่าใน Profile
  Future<List<FoodItem>> getActiveItems() async {
    final snapshot = await _items
        .where('status', isEqualTo: ItemStatus.active.name)
        .get();
    return snapshot.docs.map(FoodItem.fromFirestore).toList();
  }

  /// สถิติเดือนนี้: นับ consumed / discarded ที่ finishedAt อยู่ในเดือนนี้
  /// query ด้วย finishedAt อย่างเดียว (range บน field เดียว ไม่ต้องสร้าง index เพิ่ม)
  /// แล้วแยกสถานะฝั่งเครื่อง — ของ active มี finishedAt = null จึงไม่ถูกดึงมา
  Stream<MonthStats> watchMonthStats() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    return _items
        .where(
          'finishedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
        )
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(FoodItem.fromFirestore);
          return MonthStats(
            consumed: items
                .where((i) => i.status == ItemStatus.consumed)
                .length,
            discarded: items
                .where((i) => i.status == ItemStatus.discarded)
                .length,
          );
        });
  }

  /// ติดตาม document เดียวแบบ realtime (หน้า Detail) — คืน null ถ้าถูกลบไปแล้ว
  Stream<FoodItem?> watchItem(String id) {
    return _items
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? FoodItem.fromFirestore(doc) : null);
  }

  /// ดึงครั้งเดียว (หน้า Edit ใช้ค่าเริ่มต้นของฟอร์ม ไม่ต้อง realtime)
  Future<FoodItem?> getItem(String id) async {
    final doc = await _items.doc(id).get();
    return doc.exists ? FoodItem.fromFirestore(doc) : null;
  }

  // ---------- Create ----------

  /// คืน id ของ document ใหม่ แล้วตั้งแจ้งเตือนของชิ้นนี้ (ใช้ id ที่ Firestore เพิ่งสร้าง)
  Future<String> addItem(FoodItem item) async {
    final ref = await _items.add(item.toMap());
    await NotificationService.instance.scheduleForItem(
      item.copyWith(id: ref.id),
    );
    return ref.id;
  }

  // ---------- Update ----------

  Future<void> updateItem(FoodItem item) async {
    await _items.doc(item.id).update({
      'name': item.name,
      'imageFile': item.imageFile,
      'category': item.category.value,
      'storage': item.storage.value,
      'quantity': item.quantity,
      'expiryDate': Timestamp.fromDate(item.expiryDate),
      'updatedAt': Timestamp.now(),
    });
    // วันหมดอายุอาจเปลี่ยน → ยกเลิกของเดิมแล้วตั้งใหม่
    await NotificationService.instance.cancelForItem(item.id!);
    await NotificationService.instance.scheduleForItem(item);
  }

  /// "กินหมดแล้ว" / "ทิ้ง" — ไม่ลบ document แต่เปลี่ยนสถานะ เพื่อเก็บไว้ทำสถิติ
  Future<void> markFinished(String id, ItemStatus status) async {
    final now = Timestamp.now();
    await _items.doc(id).update({
      'status': status.name,
      'finishedAt': now,
      'updatedAt': now,
    });
    await NotificationService.instance.cancelForItem(id);
  }

  // ---------- Delete ----------

  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
    await NotificationService.instance.cancelForItem(id);
  }
}

/// สถิติของเดือนนี้ (ใช้ทั้งหน้า Home และ Profile เพื่อให้ตัวเลขตรงกัน)
class MonthStats {
  final int consumed;
  final int discarded;

  const MonthStats({required this.consumed, required this.discarded});

  /// ลดขยะได้ = consumed / (consumed + discarded) × 100 — ถ้าเป็น 0 ทั้งคู่ แสดง "–"
  String get wasteReducedLabel {
    final total = consumed + discarded;
    if (total == 0) return '–';
    return '${(consumed / total * 100).round()}%';
  }
}
