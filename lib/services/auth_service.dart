import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// รวมงาน Firebase Authentication ทั้งหมด
/// ทุกเมธอดเป็น async (คืน Future) เพราะต้องรอเซิร์ฟเวอร์ตอบกลับ
/// ถ้าล้มเหลวจะ throw [AuthException] ที่มีข้อความภาษาไทยพร้อมแสดง
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_thaiMessage(e.code));
    }
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(displayName.trim());

      // เก็บโปรไฟล์ไว้ที่ users/{uid} ด้วย (รายการของจะอยู่ใน subcollection ใต้ document นี้)
      await _db.collection('users').doc(user.uid).set({
        'displayName': displayName.trim(),
        'email': user.email,
        'createdAt': Timestamp.now(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_thaiMessage(e.code));
    }
  }

  /// เปลี่ยนชื่อที่แสดง: อัปเดตทั้ง Firebase Auth (displayName) และ users/{uid} ใน Firestore
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser!;
    final name = displayName.trim();
    try {
      await user.updateDisplayName(name);
      await user.reload();
      // set + merge: ถ้า document โปรไฟล์ยังไม่มีจะสร้างให้ ถ้ามีอยู่แล้วแก้เฉพาะชื่อ
      await _db.collection('users').doc(user.uid).set({
        'displayName': name,
      }, SetOptions(merge: true));
    } on FirebaseException {
      throw AuthException('บันทึกชื่อไม่สำเร็จ กรุณาลองใหม่');
    }
  }

  Future<void> logout() => _auth.signOut();

  String _thaiMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้สมัครแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      // Firebase รุ่นใหม่รวม "ไม่พบผู้ใช้" กับ "รหัสผิด" เป็นรหัสนี้ เพื่อไม่ให้เดาได้ว่ามีอีเมลนี้หรือไม่
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'ลองเข้าสู่ระบบบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ กรุณาลองใหม่';
      default:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
