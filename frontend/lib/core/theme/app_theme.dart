import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Blue
  static const Color primaryBlue = Color(0xFF203F9A);
  static const Color primaryBlueMid = Color(0xFF4E7CB2);
  static const Color primaryBlueLight = Color(0xFFE8EEF8);
  static const Color primaryBluePastel = Color(0xFF94C2DA);

  // Pink Accent
  static const Color accentPink = Color(0xFFE84797);
  static const Color accentPinkPastel = Color(0xFFE7A0CC);
  static const Color accentPinkLight = Color(0xFFFFEAF4);

  // Neutrals
  static const Color backgroundWhite = Color(0xFFF8F9FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF12194D);
  static const Color textSecondary = Color(0xFF6A72A8);
  static const Color borderColor = Color(0xFFE4E8F5);

  // Status Colors
  static const Color statusGreen = Color(0xFF1DB87A);
  static const Color statusGreenLight = Color(0xFFE6FAF3);
  static const Color statusAmber = Color(0xFFFFA040);
  static const Color statusAmberLight = Color(0xFFFFF4E6);
  static const Color statusRed = Color(0xFFE83A59);
  static const Color statusRedLight = Color(0xFFFFEAED);

  // Purple Accent
  static const Color accentPurple = Color(0xFF6C5CE7);
  static const Color accentPurpleLight = Color(0xFFF0EEFF);

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF0D1226);
  static const Color darkSurface = Color(0xFF161D3A);
  static const Color darkSurfaceElevated = Color(0xFF1E2749);
  static const Color darkBorder = Color(0xFF2B3663);
  static const Color darkTextPrimary = Color(0xFFF2F5FF);
  static const Color darkTextSecondary = Color(0xFFA3AED0);
}

class AppTheme {
  // Backwards-compatible aliases
  static const Color primarySeed = AppColors.primaryBlue;
  static const Color secondarySeed = AppColors.accentPink;
  static const Color successColor = AppColors.statusGreen;
  static const Color warningColor = AppColors.statusAmber;
  static const Color errorColor = AppColors.statusRed;

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryBlueLight,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accentPink,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.accentPinkLight,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.accentPurple,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accentPurpleLight,
      onTertiaryContainer: AppColors.textPrimary,
      error: AppColors.statusRed,
      onError: Colors.white,
      errorContainer: AppColors.statusRedLight,
      onErrorContainer: AppColors.statusRed,
      surface: AppColors.surfaceWhite,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.primaryBlueLight,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderColor,
      outlineVariant: AppColors.borderColor,
    );

    final baseText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundWhite,
      textTheme: baseText.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceWhite,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        indicatorColor: AppColors.primaryBlueLight,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryBlue, size: 24);
          }
          return const IconThemeData(color: AppColors.textSecondary, size: 24);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.statusRed),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          side: const BorderSide(color: AppColors.borderColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryBlueLight,
        selectedColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryBluePastel,
      onPrimary: AppColors.darkBackground,
      primaryContainer: AppColors.primaryBlue,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accentPink,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF4A1936),
      onSecondaryContainer: AppColors.accentPinkPastel,
      tertiary: AppColors.accentPurple,
      onTertiary: Colors.white,
      error: AppColors.statusRed,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
    );

    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: baseText.apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.45),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            );
          }
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBluePastel, width: 1.6),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}