import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// 🎨 CORE COLORS (Refined SaaS System)
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo (professional)
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan accent

  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  static const Color darkColor = Color(0xFF111827);
  static const Color greyColor = Color(0xFF6B7280);
  static const Color lightGreyColor = Color(0xFF9CA3AF);

  static const Color bgColor = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE5E7EB);

  /// 🌞 LIGHT THEME
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgColor,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
        background: bgColor,
        error: dangerColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkColor,
        onBackground: darkColor,
      ),

      /// 🔤 TYPOGRAPHY
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: darkColor,
        displayColor: darkColor,
      ),

      /// 🔝 APPBAR
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: darkColor,
        ),
      ),

      /// 🧾 CARD
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
          side: const BorderSide(color: dividerColor),
        ),
      ),

      /// 🔘 BUTTON
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),

      /// 🧾 INPUT FIELD
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        hintStyle: TextStyle(color: lightGreyColor, fontSize: 14.sp),

        contentPadding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 14.h,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),

      /// ➖ DIVIDER
      dividerColor: dividerColor,
    );
  }

  /// 🌙 DARK THEME
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: const Color(0xFF0F172A),

      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF1E293B),
        background: Color(0xFF0F172A),
        error: dangerColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),

      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }
}
