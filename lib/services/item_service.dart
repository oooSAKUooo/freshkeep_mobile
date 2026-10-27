import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item.dart';

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

  /// คืน id ของ document ใหม่ (Phase 2 จะใช้ตั้ง notification)
  Future<String> addItem(FoodItem item) async {
    final ref = await _items.add(item.toMap());
    return ref.id;
  }

  // ---------- Update ----------

  Future<void> updateItem(FoodItem item) {
    return _items.doc(item.id).update({
      'name': item.name,
      'category': item.category.value,
      'storage': item.storage.value,
      'quantity': item.quantity,
      'expiryDate': Timestamp.fromDate(item.expiryDate),
      'updatedAt': Timestamp.now(),
    });
  }

  /// "กินหมดแล้ว" / "ทิ้ง" — ไม่ลบ document แต่เปลี่ยนสถานะ เพื่อเก็บไว้ทำสถิติ
  Future<void> markFinished(String id, ItemStatus status) {
    final now = Timestamp.now();
    return _items.doc(id).update({
      'status': status.name,
      'finishedAt': now,
      'updatedAt': now,
    });
  }

  // ---------- Delete ----------

  Future<void> deleteItem(String id) => _items.doc(id).delete();
}
