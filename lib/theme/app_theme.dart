import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- 🎨 REFINED HERITAGE PALETTE ---

  // Primary: Vibrant Heritage Red (Modern & Friendly)
  static const Color primaryColor = Color(0xFF9E2A2B);
  static const Color primaryDarkColor = Color(0xFF6A1B1B);

  // Secondary: Warm Amber/Gold (Cheerful & Accessible)
  static const Color secondaryColor = Color(0xFFE09F3E);

  // Accent: Muar Maroon (Deep & Stable)
  static const Color accentColor = Color(0xFF540B0E);

  // Neutrals (Clean & Airy)
  static const Color backgroundColor = Color(0xFFFFFDF9);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  static const Color textLight = Color(0xFF333333);
  static const Color subTextLight = Color(0xFF757575);
  static const Color textDark = Colors.white;
  static const Color subTextDark = Color(0xFFE0E0E0);

  static const Color textColor = textLight;
  static const Color subTextColor = subTextLight;

  static Color getAdaptiveTextColor(BuildContext context) => textLight;
  static Color getAdaptiveSubTextColor(BuildContext context) => subTextLight;

  static const Color buttonTextColor = Colors.white;
  static const Color lightPrimary = Color(0x1A9E2A2B); // 10% Opacity

  // --- ✨ DESIGN TOKENS ---

  static const double borderRadius = 20.0;
  static const double cardPadding = 16.0;

  // --- 🌈 GRADIENTS ---

  // Modern Vibrant Gradient (Primary)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Warm Heritage Gradient (Secondary)
  static const LinearGradient heritageGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFFFFF3B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- 🧊 GLASSMORPHISM HELPERS ---

  static BoxDecoration glassStyle({double blur = 10, double opacity = 0.7}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // --- 🧊 FORM HELPERS ---

  static InputDecoration inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: subTextColor),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: primaryColor) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  // --- 🏛️ THEME DATA ---

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        brightness: Brightness.light,
      ),
      // --- 🖋️ FONT MODERNIZATION ---
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        bodyLarge: GoogleFonts.outfit(color: textLight),
        bodyMedium: GoogleFonts.outfit(color: textLight),
        titleLarge: GoogleFonts.outfit(
            color: textLight, fontWeight: FontWeight.bold, fontSize: 20),
        displayLarge: GoogleFonts.outfit(
            color: textLight, fontWeight: FontWeight.w800, fontSize: 32),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0, // Softer, modern look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: GoogleFonts.outfit(
          color: textLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: buttonTextColor,
          minimumSize: const Size(double.infinity, 56),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0, // Modern flat design or very subtle
        ),
      ),
    );
  }
}
