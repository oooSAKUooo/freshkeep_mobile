import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/item_prefill.dart';
import '../../services/product_api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// สแกนบาร์โค้ดด้วยกล้อง → ดึงชื่อ/รูปจาก Open Food Facts → เปิดฟอร์มเพิ่มของพร้อมเติมข้อมูลให้
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _productApi = ProductApiService();

  // true ระหว่างรอ API — กันไม่ให้ onDetect ทำงานซ้ำจากบาร์โค้ดเดิมที่ยังอยู่ในกรอบ
  bool _isLookingUp = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isLookingUp) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isLookingUp = true);
    await _controller.stop();

    // ดึงข้อมูลสินค้า (async) — fetchProduct คืน null เมื่อไม่เจอ/เน็ตมีปัญหา/timeout โดยไม่ throw
    final product = await _productApi.fetchProduct(barcode);
    if (!mounted) return;

    if (product == null) {
      // ScaffoldMessenger อยู่เหนือ route จึงแสดงต่อบนหน้าฟอร์มที่เปิดถัดไปได้
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลสินค้า กรุณากรอกเอง')),
      );
    }
    context.pushReplacement(
      '/item/new',
      extra: ItemPrefill(
        barcode: barcode,
        name: product?.name,
        imageUrl: product?.imageUrl,
      ),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error: error),
          ),
          // พื้นมืดโปร่งทั้งจอ เว้นกรอบสแกนตรงกลาง
          const _ScanOverlay(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    tooltip: 'ปิด',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.scrim,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.x),
                  ),
                  IconButton.filled(
                    tooltip: 'ไฟฉาย',
                    style: IconButton.styleFrom(
                      backgroundColor: _torchOn
                          ? AppColors.onPrimary
                          : AppColors.scrim,
                      foregroundColor: _torchOn
                          ? AppColors.primary
                          : AppColors.onPrimary,
                    ),
                    onPressed: _toggleTorch,
                    icon: Icon(_torchOn ? LucideIcons.zap : LucideIcons.zapOff),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLookingUp
                          ? 'กำลังค้นหาสินค้า...'
                          : 'วางบาร์โค้ดให้อยู่ในกรอบ',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'สแกนบาร์โค้ดเพื่อดึงชื่อและรูปสินค้า',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLookingUp)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.pushReplacement('/item/new'),
                          icon: const Icon(LucideIcons.pencil, size: 20),
                          label: const Text('กรอกข้อมูลเอง'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'รองรับบาร์โค้ด EAN-13 และ UPC',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// พื้นมืดโปร่งพร้อมกรอบสแกนมุมโค้งตรงกลาง
class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _OverlayPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.38),
        width: size.width * 0.78,
        height: size.width * 0.5,
      ),
      const Radius.circular(AppTheme.radius),
    );
    // วาดพื้นมืดทั้งจอ แล้วเจาะรูตามกรอบด้วย Path.combine(difference)
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(frame),
    );
    canvas.drawPath(scrim, Paint()..color = AppColors.scrim);
    canvas.drawRRect(
      frame,
      Paint()
        ..color = AppColors.onPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// แสดงเมื่อเปิดกล้องไม่ได้ (เช่น ผู้ใช้ปฏิเสธ permission)
class _CameraError extends StatelessWidget {
  final MobileScannerException error;

  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.cameraOff,
              size: 48,
              color: AppColors.onPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'ไม่ได้รับอนุญาตให้ใช้กล้อง\nเปิดสิทธิ์กล้องในการตั้งค่าเครื่อง หรือกด "กรอกข้อมูลเอง"'
                  : 'เปิดกล้องไม่สำเร็จ\nลองใหม่ หรือกด "กรอกข้อมูลเอง"',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
