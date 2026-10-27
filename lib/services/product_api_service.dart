import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// ข้อมูลสินค้าที่ดึงจาก Open Food Facts
class ProductInfo {
  final String name;
  final String? imageUrl;

  const ProductInfo({required this.name, this.imageUrl});
}

/// ดึงชื่อ/รูปสินค้าจากบาร์โค้ดผ่าน REST API ของ Open Food Facts
/// หมายเหตุ: API ไม่มีวันหมดอายุให้ ผู้ใช้ต้องกรอกเอง
class ProductApiService {
  static const _timeout = Duration(seconds: 8);

  // รับ client จากภายนอกได้ เพื่อให้ test ส่ง MockClient แทนการยิงเน็ตจริง
  final http.Client _client;

  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  /// คืน null ทุกกรณีที่ไม่ได้ข้อมูล (ไม่เจอสินค้า / ไม่มีเน็ต / timeout / ข้อมูลผิดรูป)
  /// เพื่อให้ผู้เรียกเปิดฟอร์มกรอกเองต่อได้ ไม่ crash
  Future<ProductInfo?> fetchProduct(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {'fields': 'product_name,product_name_th,image_front_url,image_url'},
    );
    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': 'FreshKeep/1.0 (student project)'})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null; // 1 = เจอสินค้า

      final product = body['product'] as Map<String, dynamic>;
      final name = _firstNotEmpty([
        product['product_name_th'],
        product['product_name'],
      ]);
      if (name == null) return null;

      return ProductInfo(
        name: name,
        imageUrl: _firstNotEmpty([
          product['image_front_url'],
          product['image_url'],
        ]),
      );
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on FormatException {
      return null;
    } catch (_) {
      // SocketException (ไม่มีเน็ต) หรือ type ผิดจาก JSON
      return null;
    }
  }

  String? _firstNotEmpty(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
