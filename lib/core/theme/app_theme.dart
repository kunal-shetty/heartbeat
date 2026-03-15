import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color brandPrimary = Color(0xFFF59E0B);
  static const Color brandPrimaryDark = Color(0xFFD97706);
  static const Color brandPrimaryDeep = Color(0xFF92400E);
  static const Color brandPrimaryLight = Color(0xFFFDE68A);
  static const Color brandPrimarySurface = Color(0xFFFEF3C7);
  static const Color brandAccent = Color(0xFFEA580C);
  static const Color brandAccentLight = Color(0xFFFED7AA);
  static const Color brandAccentSurface = Color(0xFFFFF7ED);

  // Neutral (Stone)
  static const Color neutral900 = Color(0xFF1C1917);
  static const Color neutral800 = Color(0xFF292524);
  static const Color neutral700 = Color(0xFF44403C);
  static const Color neutral600 = Color(0xFF57534E);
  static const Color neutral400 = Color(0xFFA8A29E);
  static const Color neutral100 = Color(0xFFF5F5F4);
  static const Color neutralWhite = Color(0xFFFFFFFF);

  // Semantic
  static const Color statusOnline = Color(0xFF22C55E);
  static const Color statusInfo = Color(0xFF3B82F6);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusOffline = Color(0xFF6B7280);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        secondary: brandAccent,
        brightness: Brightness.light,
      ).copyWith(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: neutralWhite,
        onPrimary: neutralWhite,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: neutral100,
      textTheme: _buildTextTheme(base.textTheme, neutral900),
      appBarTheme: AppBarTheme(
        backgroundColor: brandPrimary,
        foregroundColor: neutralWhite,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.12),
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: neutralWhite,
        ),
        iconTheme: const IconThemeData(color: neutralWhite, size: 24),
        actionsIconTheme: const IconThemeData(color: neutralWhite, size: 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: brandPrimary,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: neutralWhite,
        selectedItemColor: brandPrimary,
        unselectedItemColor: neutral400,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: neutralWhite,
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brandPrimarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: statusError, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: neutral400,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF3F4F6),
        thickness: 0.5,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brandPrimaryLight,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: brandPrimaryDeep,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandAccent,
        foregroundColor: neutralWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brandPrimary;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        secondary: brandAccent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: brandPrimary,
        secondary: brandAccent,
        surface: neutral800,
        onPrimary: neutralWhite,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: neutral900,
      textTheme: _buildTextTheme(base.textTheme, const Color(0xFFFAFAF9)),
      appBarTheme: AppBarTheme(
        backgroundColor: brandPrimaryDark,
        foregroundColor: neutralWhite,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: neutralWhite,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: brandPrimaryDark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: neutral800,
        selectedItemColor: brandPrimary,
        unselectedItemColor: neutral400,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w800, color: textColor),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w400, color: textColor),
    );
  }
}
