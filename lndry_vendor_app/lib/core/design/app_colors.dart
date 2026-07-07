import 'package:flutter/material.dart';

/// LNDRY Design Token: Colors
/// Matches the Brand System & Mobile UI Kit (with support for full M3 ColorScheme)
/// Typography and surface colors are dynamic getters driven by the static isDarkMode state.
abstract final class AppColors {
  AppColors._();

  /// Global reactive flag set by LndryApp on build/theme update
  static bool isDarkMode = false;

  // ── Brand System Colors (Always Const) ─────────────────────────────────────
  /// Main Brand Accent Violet
  static const Color primary = Color(0xFF6C63E8);
  static const Color primaryDark = Color(0xFF3D46C8);
  static const Color primaryLight = Color(0xFFEA8EFF); // Soft Lavender
  static const Color electricLavender = Color(0xFF887CF6);
  static const Color primaryContainer =
      Color(0xFFF1F2FF); // Soft violet background tint
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001254);

  /// Secondary Teal Accent for operational/success indicators
  static const Color secondary = Color(0xFF0FB5A6);
  static const Color secondaryLight = Color(0xFFDDF7F3); // Teal Tint
  static const Color secondaryDark = Color(0xFF086A61);
  static const Color secondaryContainer = Color(0xFFDDF7F3);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00201D);

  /// Tertiary definitions
  static const Color tertiary = Color(0xFF8B470A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFDBC6);
  static const Color onTertiaryContainer = Color(0xFF321400);

  /// Semantic colors
  static const Color success = Color(0xFF0FB5A6);
  static const Color successContainer = Color(0xFFDDF7F3);
  static const Color warning = Color(0xFFF4A329);
  static const Color rating = Color(0xFFF4A329);
  static const Color error = Color(0xFFE04A57);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD9);
  static const Color onErrorContainer = Color(0xFF410006);
  static const Color errorLight = Color(0xFFFFB4AB);

  // ── Theme-Specific Typography Colors (Constants) ──────────────────────────
  static const Color lightTextPrimary = Color(0xFF090F14); // Near Black
  static const Color lightTextBody = Color(0xFF495467);
  static const Color lightTextSecondary = Color(0xFF7E8B9B);
  static const Color lightTextHint = Color(0xFF9AA5B5);
  static const Color lightTextDisabled = Color(0xFFB6C0CC);

  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White
  static const Color darkTextBody = Color(0xFFE6EAF2);
  static const Color darkTextSecondary = Color(0xFFC2CAD6);
  static const Color darkTextHint = Color(0xFF98A3B4);
  static const Color darkTextDisabled = Color(0xFF6E7785);

  // ── Neutrals Constants ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF090F14);
  static const Color darkSurface = Color(0xFF141A22);
  static const Color darkSurfaceContainer = Color(0xFF1E2631);
  static const Color darkSurfaceContainerHigh = Color(0xFF283241);
  static const Color darkOnSurface = Color(0xFFECEEEF);
  static const Color darkOnSurfaceVariant = Color(0xFFC3C6CF);
  static const Color darkOutline = Color(0xFF8D9199);
  static const Color darkOutlineVariant = Color(0xFF43474E);

  // ── Dynamic Theme-Aware Getters (Fallback bindings for legacy components) ──
  /// Typography Colors
  static Color get textBlack =>
      isDarkMode ? darkTextPrimary : lightTextPrimary; // Near Black / White
  static Color get textSecondary =>
      isDarkMode ? darkTextSecondary : lightTextSecondary; // Secondary Grey
  static Color get textMuted =>
      isDarkMode ? darkTextHint : lightTextSecondary; // Subtle Muted

  /// Surfaces & Backgrounds
  static Color get background =>
      isDarkMode ? darkBackground : const Color(0xFFF8F9FD); // App Background
  static Color get surface =>
      isDarkMode ? darkSurface : const Color(0xFFFFFFFF); // Card Surface
  static Color get surfaceContainer =>
      isDarkMode ? darkSurfaceContainer : const Color(0xFFF0F2FF);
  static Color get surfaceContainerHigh =>
      isDarkMode ? darkSurfaceContainerHigh : const Color(0xFFECEEF4);
  static Color get surfaceContainerHighest =>
      isDarkMode ? darkSurfaceContainerHigh : const Color(0xFFE2E8F0);
  static Color get surfaceVariant =>
      isDarkMode ? darkSurfaceContainer : const Color(0xFFE2E8F0);
  static Color get onSurface =>
      isDarkMode ? darkOnSurface : const Color(0xFF090F14);
  static Color get onSurfaceVariant =>
      isDarkMode ? darkOnSurfaceVariant : const Color(0xFF495467);
  static Color get inverseSurface =>
      isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF2E3135);
  static Color get inverseOnSurface =>
      isDarkMode ? const Color(0xFF090F14) : const Color(0xFFF0F0F3);
  static Color get inversePrimary =>
      isDarkMode ? primary : const Color(0xFFEA8EFF);

  static Color get divider =>
      isDarkMode ? darkOutlineVariant : const Color(0xFFEEEFF8);
  static Color get outline =>
      isDarkMode ? darkOutline : const Color(0xFFEEEFF8);
  static Color get outlineVariant =>
      isDarkMode ? darkOutlineVariant : const Color(0xFFE2E8F0);

  // ── Glassmorphism Support ─────────────────────────────────────────────────
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassDark = Color(0x33000000);
  static const Color glassStroke = Color(0x1F2A245F);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0x142A245F); // 0.08 alpha shadow color
  static const Color shadowColor = Color(0x142A245F);
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color offerLavender = Color(0xFFEAE8FF);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, electricLavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient offerGradient = LinearGradient(
    colors: [Color(0xFFEAE8FF), Color(0xFFCFC8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [primaryDark, primary, Color(0xFFEA8EFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
