import 'package:flutter/material.dart';

/// LNDRY Design Token: Shadows / Depth
/// Centralizes all elevations and shadows
abstract final class AppElevation {
  AppElevation._();

  static const double none    = 0;
  static const double xs      = 1;
  static const double sm      = 2;
  static const double md      = 4;
  static const double lg      = 8;
  static const double xl      = 16;
  static const double xxl     = 24;

  // ── Shadow System presets (Light Mode) ────────────────────────────────────
  static const List<BoxShadow> none_ = [];

  /// Shadow 1 - Soft: 0 4px 16px rgba(42, 36, 95, 0.08)
  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x142A245F), // rgba(42, 36, 95, 0.08) approx
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Shadow 2 - Elevated: 0 12px 32px rgba(57, 55, 145, 0.10)
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x1A393791), // rgba(57, 55, 145, 0.10) approx
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  /// High shadow for modals & overlays
  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x26393791), // rgba(57, 55, 145, 0.15)
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> overlay = high;
  static const List<BoxShadow> cardShadow = low;
  static const List<BoxShadow> buttonShadow = low;
  static const List<BoxShadow> modalShadow = high;
  static const List<BoxShadow> fabShadow = medium;
}
