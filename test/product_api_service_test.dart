import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshkeep/services/product_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ProductApiService serviceReturning(http.Response Function(http.Request) fn) =>
    ProductApiService(client: MockClient((request) async => fn(request)));

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('ProductApiService.fetchProduct', () {
    test('เจอสินค้า: ใช้ชื่อไทยก่อน และรูป image_front_url ก่อน', () async {
      final service = serviceReturning(
        (_) => json({
          'status': 1,
          'product': {
            'product_name': 'Milk',
            'product_name_th': 'นมสด',
            'image_front_url': 'https://img/front.jpg',
            'image_url': 'https://img/other.jpg',
          },
        }),
      );
      final product = await service.fetchProduct('8851234567890');
      expect(product?.name, 'นมสด');
      expect(product?.imageUrl, 'https://img/front.jpg');
    });

    test('ไม่มีชื่อไทย: ใช้ product_name และ fallback ไป image_url', () async {
      final service = serviceReturning(
        (_) => json({
          'status': 1,
          'product': {
            'product_name': 'Milk',
            'product_name_th': '',
            'image_url': 'https://img/other.jpg',
          },
        }),
      );
      final product = await service.fetchProduct('1');
      expect(product?.name, 'Milk');
      expect(product?.imageUrl, 'https://img/other.jpg');
    });

    test('ส่ง User-Agent และ fields ตามที่กำหนด', () async {
      late http.Request captured;
      final service = serviceReturning((request) {
        captured = request;
        return json({'status': 0});
      });
      await service.fetchProduct('123');
      expect(captured.headers['User-Agent'], 'FreshKeep/1.0 (student project)');
      expect(captured.url.path, '/api/v2/product/123.json');
      expect(
        captured.url.queryParameters['fields'],
        'product_name,product_name_th,image_front_url,image_url',
      );
    });

    test('status = 0 (ไม่พบสินค้า) → null', () async {
      final service = serviceReturning((_) => json({'status': 0}));
      expect(await service.fetchProduct('1'), isNull);
    });

    test('เจอสินค้าแต่ไม่มีชื่อเลย → null', () async {
      final service = serviceReturning(
        (_) => json({
          'status': 1,
          'product': {'product_name': '  '},
        }),
      );
      expect(await service.fetchProduct('1'), isNull);
    });

    test('HTTP 500 → null', () async {
      final service = serviceReturning((_) => json({}, 500));
      expect(await service.fetchProduct('1'), isNull);
    });

    test('JSON เสีย → null ไม่ throw', () async {
      final service = serviceReturning((_) => http.Response('<html>', 200));
      expect(await service.fetchProduct('1'), isNull);
    });

    test('ไม่มีอินเทอร์เน็ต (SocketException) → null ไม่ throw', () async {
      final service = ProductApiService(
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      expect(await service.fetchProduct('1'), isNull);
    });

    test('timeout → null ไม่ throw', () async {
      final service = ProductApiService(
        client: MockClient((_) async => throw TimeoutException('slow')),
      );
      expect(await service.fetchProduct('1'), isNull);
    });
  });
}
