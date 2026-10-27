import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// เก็บรูปที่ผู้ใช้เลือกเองไว้ในเครื่อง (ไม่ใช้ Cloud Storage)
/// Firestore เก็บแค่ "ชื่อไฟล์" ไม่เก็บ path เต็ม เพราะโฟลเดอร์ของแอปบน iOS เปลี่ยนได้หลังอัปเดต/ติดตั้งใหม่
/// รูปจึงอยู่เฉพาะเครื่องนี้ ไม่ตามไปเครื่องอื่น
class ImageStorageService {
  static const _folderName = 'item_images';

  Future<Directory> _folder() async {
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory('${documents.path}/$_folderName');
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder;
  }

  /// คัดลอกรูปที่เพิ่งเลือก/ถ่าย (ไฟล์ชั่วคราว) มาเก็บถาวร แล้วคืนชื่อไฟล์
  Future<String> save(String sourcePath) async {
    final folder = await _folder();
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(sourcePath).copy('${folder.path}/$fileName');
    return fileName;
  }

  /// คืนไฟล์รูป หรือ null ถ้าไม่มีชื่อไฟล์ / ไฟล์หายไปแล้ว
  Future<File?> fileFor(String? fileName) async {
    if (fileName == null) return null;
    final folder = await _folder();
    final file = File('${folder.path}/$fileName');
    return await file.exists() ? file : null;
  }

  Future<void> delete(String? fileName) async {
    final file = await fileFor(fileName);
    await file?.delete();
  }
}
