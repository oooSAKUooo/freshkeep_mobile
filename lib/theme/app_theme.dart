import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radius = 16;
  static const double cardRadius = 20;

  /// ฟอนต์ชื่อแอป "FreshKeep" — Manrope ตัวหนามาก ตัวอักษรชิดกันเล็กน้อย
  static TextStyle brand({
    double fontSize = 24,
    Color color = AppColors.primary,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: color,
    );
  }

  /// ฟอนต์ตัวเลขใหญ่ (จำนวนของ, สถิติ, เปอร์เซ็นต์) — Manrope ตัวหนา
  /// tabularFigures ทำให้ตัวเลขกว้างเท่ากัน ตัวเลขไม่ขยับตอนค่าเปลี่ยน
  /// ถ้าอยากเปลี่ยนฟอนต์ตัวเลขทั้งแอป แก้ที่ GoogleFonts.manrope บรรทัดเดียวนี้
  static TextStyle number({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
      height: 1.1,
    );
  }

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primarySoft,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          surfaceContainerHighest: AppColors.surfaceMuted,
          outline: AppColors.textMuted,
          outlineVariant: AppColors.divider,
          error: AppColors.error,
          errorContainer: AppColors.errorSoft,
        );

    final textTheme = GoogleFonts.ibmPlexSansThaiTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: AppColors.shadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(AppColors.primary, 1.5),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: roundedShape,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: roundedShape,
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceMuted,
          selectedBackgroundColor: AppColors.primary,
          selectedForegroundColor: AppColors.onPrimary,
          side: BorderSide.none,
          shape: roundedShape,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        shape: roundedShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: AppColors.shadow,
      ),
    );
  }
}
