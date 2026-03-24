import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Palette: bright teal core, deep navy anchor, amber highlight
const Color primaryColor = Color(0xFF0FB9B1);
const Color primaryDark = Color(0xFF0A7C73);
const Color accentColor = Color(0xFFF6A800);
const Color navy = Color(0xFF0F1B4C);
const Color mist = Color(0xFFF3F5FB);
const Color surfaceColor = Colors.white;

// Motion & layout helpers
class AppMotion {
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration long = Duration(milliseconds: 550);
}

class AppRadius {
  static const BorderRadius small = BorderRadius.all(Radius.circular(10));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(16));
  static const BorderRadius large = BorderRadius.all(Radius.circular(24));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(50));
}

class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x22000000), blurRadius: 26, offset: Offset(0, 18)),
  ];
}

// Surfaces & gradients
BoxDecoration glassSurface({BorderRadius borderRadius = AppRadius.medium}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.72),
    borderRadius: borderRadius,
    boxShadow: AppShadows.soft,
    border: Border.all(color: Colors.white.withOpacity(0.5)),
  );
}

BoxDecoration gradientCard({BorderRadius borderRadius = AppRadius.large}) {
  return BoxDecoration(
    borderRadius: borderRadius,
    gradient: const LinearGradient(
      colors: [Color(0xFF12D8C6), Color(0xFF0F9CD5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    boxShadow: AppShadows.elevated,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: navy,
      surface: surfaceColor,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: mist,

    // Typography
    textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.spaceGrotesk(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w400, height: 1.35),
      bodyMedium: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w400, height: 1.35),
      labelLarge: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600),
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w700),
      surfaceTintColor: Colors.transparent,
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        elevation: 0,
        shadowColor: Colors.transparent,
      ).merge(
        ButtonStyle(
          overlayColor: WidgetStateProperty.all(primaryDark.withOpacity(0.12)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: const BorderSide(color: Color(0x330F1B4C)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),

    // Cards
    cardColor: surfaceColor,
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
      shadowColor: Colors.transparent,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEAF3FF),
      selectedColor: primaryColor.withOpacity(0.12),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: const BorderSide(color: primaryColor, width: 1.1)),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),

    // ListTile
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      iconColor: Colors.black87,
    ),

    // Bottom navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFF9E9E9E),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),

    // Visual density
    visualDensity: VisualDensity.adaptivePlatformDensity,
    dividerColor: Colors.grey.shade200,
    splashColor: primaryColor.withOpacity(0.08),
    highlightColor: primaryColor.withOpacity(0.04),
  );
}

// Theme extensions
extension ThemeExtras on ThemeData {
  LinearGradient get primaryGradient => const LinearGradient(colors: [primaryColor, primaryDark]);
  LinearGradient get accentGradient => const LinearGradient(colors: [Color(0xFFFEE440), Color(0xFFF6A800)]);
  BoxDecoration get heroBackdrop => BoxDecoration(
    gradient: LinearGradient(
      colors: [primaryColor.withOpacity(0.12), Colors.white],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}
