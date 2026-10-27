import 'dart:io';

import 'package:flutter/material.dart';

import '../services/image_storage_service.dart';

/// แสดงรูปที่ผู้ใช้เลือกเองจากชื่อไฟล์ในเครื่อง
/// ระหว่างหาไฟล์ (async) แสดง loading, ถ้าไฟล์ไม่อยู่แล้วแสดง [fallback]
class LocalImage extends StatelessWidget {
  final String fileName;
  final BoxFit fit;
  final Widget fallback;

  const LocalImage({
    super.key,
    required this.fileName,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: ImageStorageService().fileFor(fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final file = snapshot.data;
        if (file == null) return fallback;
        return Image.file(file, fit: fit, errorBuilder: (_, _, _) => fallback);
      },
    );
  }
}
