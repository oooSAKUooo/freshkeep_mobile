import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import 'widgets/splash_overlay.dart';

class FreshKeepApp extends StatelessWidget {
  const FreshKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FreshKeep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
      builder: (context, child) =>
          SplashOverlay(child: child ?? const SizedBox.shrink()),
      // ให้ date picker และข้อความของ Material เป็นภาษาไทย
      locale: const Locale('th'),
      supportedLocales: const [Locale('th')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
