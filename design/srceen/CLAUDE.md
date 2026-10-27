# FreshKeep — CLAUDE.md

ไฟล์นี้คือบริบทของโปรเจกต์สำหรับ Claude Code อ่านให้ครบก่อนเริ่มงานทุกครั้ง

## กติกาการทำงาน (สำคัญที่สุด)

- **ตอบเป็นภาษาไทย** ศัพท์เทคนิคและชื่อ class/package ใช้ภาษาอังกฤษได้
- **ทำทีละ phase** ตามหัวข้อ "แผนการพัฒนา" ด้านล่าง ห้ามทำข้ามไป phase ถัดไปจนกว่าจะสั่ง
- **จบทุกงานด้วยสรุป**: แก้/สร้างไฟล์ไหน ทำไม และส่วนไหนที่เป็น async หรือคุยกับ Firestore ให้อธิบายสั้น ๆ ว่าทำงานอย่างไร (เจ้าของโปรเจกต์ต้องตอบคำถามอาจารย์เรื่อง code ได้)
- หลังจบแต่ละ phase ให้รัน `flutter analyze` ให้ผ่าน แล้วเสนอ commit message (commit เมื่อได้รับคำสั่ง)
- **ห้ามเพิ่มฟีเจอร์นอกขอบเขต** (ดูหัวข้อ "นอกขอบเขต") ถ้าคิดว่าควรเพิ่ม ให้ถามก่อน
- เขียน code ให้อ่านง่าย ตั้งชื่อชัดเจน ไม่ซับซ้อนเกินจำเป็น ใส่ comment เฉพาะจุดที่ไม่ชัดเจนเอง
- ทดสอบบนมือถือจริง (iPhone ผ่าน Xcode / Android) เพราะใช้กล้องและการแจ้งเตือน เครื่องมือ: MacBook + IntelliJ (Flutter/Dart plugin)

## เกี่ยวกับแอป

**FreshKeep** แอปบันทึกของในตู้เย็นพร้อมวันหมดอายุ และแจ้งเตือนก่อนของเสีย
- **ปัญหา:** ซื้อของมาแช่แล้วลืมจนหมดอายุต้องทิ้ง
- **ผู้ใช้:** นักศึกษาอยู่หอ / คนอยู่คนเดียว
- **งาน:** โปรเจกต์รายบุคคล วิชา Mobile Application Development นำเสนอ **3 พ.ย. 2569 (2026)**

### Main Workflow
Login → สแกนบาร์โค้ด → ดึงชื่อ/รูปสินค้าจาก Open Food Facts → กรอกวันหมดอายุ/จำนวน (มี validation) → บันทึก (ตั้งแจ้งเตือนอัตโนมัติ) → ดูรายการเรียงตามวันใกล้หมด → แก้ไข / "กินหมดแล้ว" / "ทิ้ง" → ดูสถิติในหน้าโปรไฟล์

### ข้อกำหนดจากอาจารย์ (ต้องมีครบ)
- อย่างน้อย 4 หน้าจอ + Navigation
- อย่างน้อย 1 Form ที่มี Validation
- Firebase Authentication (Register / Login / Logout)
- Firestore CRUD กับข้อมูลที่มีความหมาย
- Asynchronous operations
- Mobile/External features ≥ 2 อย่าง ที่มีบทบาทจริงในแอป
- Main Workflow ทำงานได้ครบตั้งแต่ต้นจนจบ

## หน้าจอ

| หน้า | Route | หมายเหตุ |
|---|---|---|
| Login | `/login` | หน้าแรกเมื่อยังไม่ login ไม่มี header icon ใด ๆ |
| Register | `/register` | **ยังไม่มีดีไซน์** ใช้หน้าตาแบบ Login เพิ่มช่องชื่อ + ยืนยันรหัสผ่าน |
| Home | `/` | แท็บ "หน้าหลัก" |
| Scan Barcode | `/scan` | ปุ่มกลมตรงกลาง bottom nav |
| Add / Edit Item | `/item/new`, `/item/:id/edit` | ฟอร์มหลักที่มี validation |
| Item Detail | `/item/:id` | |
| Profile | `/profile` | แท็บ "โปรไฟล์" |

- **Header:** หน้าแท็บ (Home, Profile) = โลโก้ FreshKeep + ปุ่มค้นหา / หน้าที่กดเข้าไป (Add, Edit, Detail) = ลูกศรย้อนกลับ + ชื่อหน้าภาษาไทย
- **Bottom nav:** 3 ช่อง: หน้าหลัก · ปุ่มสแกน (วงกลมยกขึ้น สีเขียวเข้ม) · โปรไฟล์ แท็บที่เลือกเป็น pill สีเขียวเข้มมีไอคอน + label เหมือนกันทั้งสองแท็บ
- ข้อความใน UI ทั้งหมดเป็นภาษาไทย

### รายละเอียดแต่ละหน้า
- **Home:** คำทักทายตามช่วงเวลา + วันที่, การ์ดสรุป (จำนวนของในตู้เย็น, ใกล้หมดอายุ, แถบสัดส่วน สด/ใกล้หมด/ด่วน), chips กรองหมวด, รายการเรียงตามวันหมดอายุ (ไอคอนหมวดบนพื้นสีอ่อน, ชื่อ, หมวด · จำนวน, pill สถานะ "พรุ่งนี้" / "อีก N วัน" / "หมดอายุแล้ว"), การ์ด "ลดขยะอาหารได้ X%" (ตัวเลขเดียวกับหน้า Profile)
- **Scan:** กล้องเต็มจอ กรอบสแกนมุมโค้ง ปุ่มปิด (X) และไฟฉาย, bottom sheet "วางบาร์โค้ดให้อยู่ในกรอบ" / "สแกนบาร์โค้ดเพื่อดึงชื่อและรูปสินค้า", ปุ่ม "กรอกข้อมูลเอง", หมายเหตุ "รองรับบาร์โค้ด EAN-13 และ UPC"
- **Add/Edit:** chip แสดงเลขบาร์โค้ด + "ดึงข้อมูลจาก Open Food Facts" (ถ้ามาจากการสแกน), ชื่อสินค้า, หมวดหมู่ (dropdown), สถานที่เก็บ, จำนวน (stepper −/+), วันหมดอายุ (date picker) + ปุ่มลัด +3 / +7 / +14 วัน, ปุ่ม "บันทึก" ติดด้านล่าง
- **Detail:** รูปสินค้า (ถ้าไม่มีรูป ใช้ไอคอนหมวดบนพื้นสีอ่อน), ชื่อ, หมวด, แบนเนอร์สถานะ "หมดอายุในอีก N วัน" + แถบความสด (คำนวณจาก `createdAt` → `expiryDate`), แถวข้อมูล: จำนวน, วันหมดอายุ, เพิ่มเมื่อ, บาร์โค้ด, การแจ้งเตือน, ปุ่ม "ทิ้ง" (outline สีดินเผา) และ "กินหมดแล้ว" (primary), ไอคอนดินสอที่ header ไปหน้า Edit
- **Profile:** avatar ตัวอักษรย่อ, ชื่อ, อีเมล, การ์ดสถิติเดือนนี้ "กินหมด N" / "ทิ้ง N" + "ลดขยะอาหารได้ X%", ตั้งค่า: แจ้งเตือนล่วงหน้า (segmented 1 / 2 / 3 วัน), สวิตช์เปิด/ปิดการแจ้งเตือน, "ออกจากระบบ"

## Design system

ดีไซน์ต้นแบบจาก Google Stitch อยู่ใน `design/screens/` (PNG) และ `design/html/` (HTML) ใช้รูปดูหน้าตา และใช้ HTML ดึงค่าสี ระยะ ฟอนต์ที่แน่นอน ถ้าขัดกับไฟล์นี้ ให้ยึด **ไฟล์นี้** เป็นหลัก (ดีไซน์บางส่วนมีของเกินขอบเขต)

- ใช้ **Material 3** (`useMaterial3: true`) แล้วปรับ `ThemeData` ให้ตรงดีไซน์ อย่าสร้าง widget เองถ้า Material มีให้
- โทน: โมเดิร์น เรียบหรู สบายตา พื้นที่ว่างเยอะ

| Token | ค่า | ใช้กับ |
|---|---|---|
| background | `#F5F2EC` | พื้นหลังแอป (ครีมอุ่น) |
| surface | `#FFFFFF` | การ์ด เงาอ่อนมาก |
| primary | `#234235` | เขียวเข้ม ปุ่มหลัก, nav ที่เลือก |
| fresh | sage green | สถานะสด (> 3 วัน) |
| soon | muted amber | ใกล้หมด (≤ 3 วัน) |
| urgent | soft terracotta | ด่วน (≤ 1 วัน / หมดอายุแล้ว) |
| divider | warm gray บาง | เส้นแบ่ง |

- **ฟอนต์:** IBM Plex Sans Thai สำหรับ UI ทั้งหมด, Fraunces (serif) เฉพาะ wordmark "FreshKeep" และตัวเลขใหญ่ (ใช้ `google_fonts`)
- **มุมโค้ง:** 16–20 px
- **ไอคอน:** เส้นบาง สไตล์ Lucide เท่านั้น (`lucide_icons_flutter` หรือ `Icons.*_outlined`) **ห้ามใช้อิโมจิในแอปเด็ดขาด**
- เก็บสีและ theme ไว้ที่ `lib/theme/` ที่เดียว ห้าม hardcode สีในหน้าจอ

## Tech stack

| ส่วน | Package | เหตุผล |
|---|---|---|
| App | Flutter / Dart | ตามวิชา |
| Auth | `firebase_auth` | ข้อมูลแยกต่อผู้ใช้ |
| Database | `cloud_firestore` | CRUD รายการของ |
| Core | `firebase_core` (+ `flutterfire configure`) | |
| Camera | `mobile_scanner` | สแกนบาร์โค้ด ไม่ต้องพิมพ์เอง |
| REST API | `http` → Open Food Facts | ดึงชื่อ/รูปสินค้าอัตโนมัติ |
| Notification | `flutter_local_notifications` + `timezone` + `flutter_timezone` | เตือนก่อนหมดอายุ |
| Local storage | `shared_preferences` | ค่าตั้งค่าการเตือน |
| Navigation | `go_router` | redirect ตามสถานะ login |
| อื่น ๆ | `intl` (วันที่ภาษาไทย), `google_fonts`, `cached_network_image` | |

- State management: ใช้ `StreamBuilder` / `FutureBuilder` + service class ธรรมดา **ไม่ใช้** Riverpod/Bloc (อธิบายตอนนำเสนอง่ายกว่า) ถ้าจำเป็นใช้ `provider` ได้
- ถ้าเวอร์ชัน package ไหนขัดกัน ให้เลือกเวอร์ชันล่าสุดที่เข้ากันได้ และบอกในสรุป

## โครงโฟลเดอร์

```
lib/
  main.dart                 # init Firebase, notifications, timezone แล้ว runApp
  app.dart                  # MaterialApp.router + theme
  router.dart               # go_router + redirect ตาม authStateChanges
  theme/
    app_colors.dart
    app_theme.dart
  models/
    food_item.dart          # FoodItem + fromFirestore / toMap
    category.dart           # enum หมวดหมู่ + label ไทย + ไอคอน
    storage_location.dart   # enum สถานที่เก็บ
  services/
    auth_service.dart
    item_service.dart       # Firestore CRUD + stream
    product_api_service.dart# Open Food Facts
    notification_service.dart
    settings_service.dart   # SharedPreferences
  screens/
    auth/login_screen.dart
    auth/register_screen.dart
    home/home_screen.dart
    scan/scan_screen.dart
    item/item_form_screen.dart   # ใช้ทั้ง Add และ Edit
    item/item_detail_screen.dart
    profile/profile_screen.dart
  widgets/                  # item_card, status_pill, bottom_nav, ฯลฯ
  utils/
    validators.dart
    expiry_status.dart      # คำนวณจำนวนวันเหลือและสถานะสี
design/
  screens/                  # PNG จาก Stitch
  html/                     # HTML จาก Stitch
```

## Firestore

```
users/{uid}
  displayName: string
  email: string
  createdAt: timestamp

users/{uid}/items/{itemId}
  name: string
  barcode: string?          # null ถ้ากรอกเอง
  imageUrl: string?         # จาก Open Food Facts
  category: string          # dairy_egg | produce | meat | other
  storage: string           # fridge | freezer | pantry
  quantity: int             # > 0
  expiryDate: timestamp     # เก็บเป็นเที่ยงคืนของวันนั้น (local)
  status: string            # active | consumed | discarded
  createdAt: timestamp
  updatedAt: timestamp
  finishedAt: timestamp?    # ตอนกด "กินหมดแล้ว" หรือ "ทิ้ง"
```

- หมวดหมู่ (label ไทย): `dairy_egg` นมและไข่ · `produce` ผักผลไม้ · `meat` เนื้อสัตว์ · `other` อื่นๆ
- สถานที่เก็บ: `fridge` ช่องแช่เย็น · `freezer` ช่องฟรีซ · `pantry` ตู้กับข้าว
- **"กินหมดแล้ว" / "ทิ้ง" ไม่ลบ document** แต่เปลี่ยน `status` + ใส่ `finishedAt` เพื่อเก็บสถิติ ส่วน Delete จริง (ลบ document) อยู่ในหน้า Edit (ปุ่มลบ + dialog ยืนยัน) เพื่อให้มีครบ CRUD
- Home แสดงเฉพาะ `status == active` เรียง `expiryDate` จากน้อยไปมาก (ใช้ `.snapshots()` ให้ realtime) ถ้าต้องสร้าง composite index ให้บอก
- สถิติ Profile: นับ `consumed` และ `discarded` ที่ `finishedAt` อยู่ในเดือนนี้, ลดขยะได้ = consumed / (consumed + discarded) × 100 (ถ้าเป็น 0 ทั้งคู่ แสดง "–")

### Security rules (`firestore.rules`)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Open Food Facts API

- `GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json?fields=product_name,product_name_th,image_front_url,image_url`
- ไม่ต้องใช้ API key แต่ต้องใส่ header `User-Agent: FreshKeep/1.0 (student project)`
- `status == 1` = เจอสินค้า → ใช้ `product_name_th` ถ้ามี ไม่งั้น `product_name`, รูปใช้ `image_front_url` หรือ `image_url`
- ไม่เจอ / network error / timeout (ตั้ง 8 วินาที) → **ไม่ crash** เปิดฟอร์มกรอกเองโดยเติมบาร์โค้ดไว้ให้ และแสดง SnackBar "ไม่พบข้อมูลสินค้า กรุณากรอกเอง"
- แสดง loading ระหว่างรอ (นี่คือจุดโชว์ async + error handling)
- **บาร์โค้ดไม่มีวันหมดอายุ** ผู้ใช้ต้องกรอกเองเสมอ ห้ามทำ UI ที่สื่อว่าแอปรู้วันหมดอายุเอง

## การแจ้งเตือน

- เวลาแจ้งเตือน: **09:00** ของวัน (`expiryDate` − N วัน) โดย N มาจาก settings (1/2/3, ค่าเริ่มต้น 2)
- ถ้าเวลานั้นผ่านไปแล้ว ไม่ต้องตั้ง (หรือตั้งเป็นอีก 1 นาทีถ้ายังไม่หมดอายุ ให้เลือกแบบเรียบง่าย)
- **notification ID = `itemId.hashCode`** (ให้เป็นค่าบวก 31-bit)
- ผูกกับ CRUD:
  - Create → ตั้งเตือน
  - Update (วันหมดอายุเปลี่ยน) → ยกเลิกแล้วตั้งใหม่
  - Delete / กินหมด / ทิ้ง → ยกเลิก
  - เปลี่ยนค่า N หรือปิด/เปิดการแจ้งเตือนใน Profile → ยกเลิกทั้งหมดแล้วตั้งใหม่จากรายการ active
  - Logout → ยกเลิกทั้งหมด
- ขอ permission: iOS ตอนเริ่มใช้, Android 13+ `POST_NOTIFICATIONS` (และตั้งค่า exact alarm ถ้าจำเป็น)
- ข้อความ: หัวข้อ "ใกล้หมดอายุ" เนื้อหา "{name} จะหมดอายุในอีก {N} วัน"

## Validation (ฟอร์ม)

- อีเมล: ไม่ว่าง + รูปแบบถูกต้อง
- รหัสผ่าน: อย่างน้อย 6 ตัวอักษร → "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร"
- ยืนยันรหัสผ่าน: ต้องตรงกัน
- ชื่อสินค้า: ไม่ว่าง, ไม่เกิน 60 ตัวอักษร
- จำนวน: ≥ 1
- วันหมดอายุ: ต้องเลือก และ **ไม่เป็นวันที่ผ่านมาแล้ว** (วันนี้ได้) → "วันหมดอายุต้องไม่เป็นวันที่ผ่านมาแล้ว" (ตอน Edit ของที่หมดอายุไปแล้ว ให้คงวันเดิมได้ถ้าไม่ได้แก้ช่องนี้)
- error จาก Firebase Auth แปลงเป็นข้อความไทยที่เข้าใจง่าย (อีเมลซ้ำ, รหัสผิด, ไม่พบผู้ใช้)

## สถานะวันหมดอายุ (`utils/expiry_status.dart`)

นับจำนวนวันจากวันนี้ (เทียบระดับวัน ไม่ใช่ชั่วโมง)
- < 0 → "หมดอายุแล้ว" (urgent)
- 0 → "วันนี้" (urgent), 1 → "พรุ่งนี้" (urgent)
- 2–3 → "อีก N วัน" (soon)
- > 3 → "อีก N วัน" (fresh)

## นอกขอบเขต (ห้ามทำ เว้นแต่ได้รับคำสั่ง)

Google/Apple sign-in · dark mode · กระดิ่ง/หน้ารวมการแจ้งเตือน · แชร์ตู้เย็นกับครอบครัว · AI จำสินค้า / OCR วันหมดอายุ · QR code · คำแนะนำการเก็บรักษา · ติดตามปริมาณคงเหลือเป็น % · เทียบสถิติกับเดือนก่อน · หน้าจัดการสถานที่เก็บ · อัปโหลดรูปเอง / Cloud Storage

## แผนการพัฒนา

- [ ] **Phase 0 — ติดตั้ง** (เจ้าของโปรเจกต์ทำเอง): `flutter create freshkeep`, สร้าง Firebase project เปิด Auth (Email/Password) + Firestore, `flutterfire configure`, วางไฟล์ดีไซน์ใน `design/`
- [ ] **Phase 1 — Auth + CRUD**: theme, router + redirect, Login/Register/Logout, model + item_service, Home (stream), Add/Edit form + validation, Detail, กินหมด/ทิ้ง/ลบ → **เป้าหมาย: CRUD ใช้ได้ครบ แม้ยังไม่มีกล้อง**
- [ ] **Phase 2 — ฟีเจอร์เสริม**: Scan (`mobile_scanner` + permission กล้องใน Info.plist / AndroidManifest), Open Food Facts, notifications, Profile (สถิติ + settings ใน SharedPreferences), filter chips, ปุ่มค้นหา (กรองตามชื่อฝั่ง client) → **ปิดรับฟีเจอร์ใหม่ 30 ต.ค.**
- [ ] **Phase 3 — เก็บงาน**: ปรับ UI ให้ตรงดีไซน์, empty/loading/error states, แก้บั๊ก, `flutter analyze` สะอาด, deploy `firestore.rules`, ช่วยเตรียมคำอธิบาย code สำหรับนำเสนอ 3 พ.ย.

### คำถามที่อาจารย์น่าจะถาม (ให้ code ตอบได้ชัด)
- async ตรงไหนบ้าง (login, Firestore, API, ตั้ง notification) และจัดการ loading/error อย่างไร
- `StreamBuilder` กับ `.snapshots()` ต่างจาก `.get()` อย่างไร
- ทำไมเก็บ items เป็น subcollection ใต้ user
- notification ผูกกับ CRUD อย่างไร (ID จาก `hashCode`)
- ทำไมบาร์โค้ดให้วันหมดอายุไม่ได้
