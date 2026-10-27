import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // ต้องเรียกก่อนใช้ plugin ใด ๆ ที่คุยกับ native (เช่น Firebase) ก่อน runApp
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('th');

  runApp(const FreshKeepApp());
}
