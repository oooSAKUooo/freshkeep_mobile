/// ข้อมูลที่ส่งจากหน้า Scan ไปเติมในฟอร์มเพิ่มของ (ผ่าน `extra` ของ go_router)
class ItemPrefill {
  final String barcode;
  final String? name; // null = ไม่พบข้อมูลสินค้า ให้ผู้ใช้กรอกเอง
  final String? imageUrl;

  const ItemPrefill({required this.barcode, this.name, this.imageUrl});

  bool get fromOpenFoodFacts => name != null;
}
