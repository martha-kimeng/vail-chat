import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
class VailColors {
  VailColors._();

  // Brand
  static const Color rose = Color(0xFFE8516A);
  static const Color roseDark = Color(0xFFC43150);
  static const Color roseSoft = Color(0xFFFDE8EC);

  // Neutrals
  static const Color ink = Color(0xFF1A1A2E);
  static const Color inkLight = Color(0xFF3D3D5C);
  static const Color mist = Color(0xFFF4F4F8);
  static const Color cloud = Color(0xFFFFFFFF);

  // Chat bubbles
  static const Color bubbleSelf = Color(0xFFE8516A);
  static const Color bubbleOther = Color(0xFFF0F0F5);

  // Status
  static const Color online = Color(0xFF4CAF82);
  static const Color away = Color(0xFFFFC15E);

  // Gradient stops
  static const List<Color> heroGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF2D1B3D),
    Color(0xFF4A1942),
  ];
}

// ─── Typography ─────────────────────────────────────────────────────────────
class VailTextStyles {
  VailTextStyles._();

  static TextStyle display(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: VailColors.cloud,
        height: 1.1,
      );

  static TextStyle heading1(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: VailColors.ink,
        height: 1.2,
      );

  static TextStyle heading2(BuildContext context) =>
      GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: VailColors.ink,
      );

  static TextStyle body(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: VailColors.inkLight,
        height: 1.5,
      );

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: VailColors.inkLight,
      );

  static TextStyle label(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: VailColors.inkLight,
        letterSpacing: 1.0,
      );

  static TextStyle button(BuildContext context) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );
}

// ─── Theme ───────────────────────────────────────────────────────────────────
ThemeData vailTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: VailColors.rose,
      primary: VailColors.rose,
      onPrimary: Colors.white,
      secondary: VailColors.roseDark,
      surface: VailColors.cloud,
      onSurface: VailColors.ink,
    ),
    scaffoldBackgroundColor: VailColors.mist,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: VailColors.ink,
      ),
      iconTheme: const IconThemeData(color: VailColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: VailColors.ink.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: VailColors.ink.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: VailColors.rose, width: 1.5),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: VailColors.inkLight.withOpacity(0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VailColors.rose,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VailColors.rose,
      ),
    ),
  );
  return base;
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

/// Full-screen dark gradient background used on branded screens.
class VailGradientBackground extends StatelessWidget {
  const VailGradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: VailColors.heroGradient,
        ),
      ),
      child: child,
    );
  }
}

/// Pill-shaped primary CTA button.
class VailButton extends StatelessWidget {
  const VailButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.isLight = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? Colors.white : VailColors.rose,
          side: BorderSide(
            color: isLight ? Colors.white : VailColors.rose,
            width: 1.5,
          ),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label, style: VailTextStyles.button(context)),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label, style: VailTextStyles.button(context)),
    );
  }
}
