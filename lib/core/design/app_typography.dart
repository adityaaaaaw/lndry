import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// LNDRY Design Token: Typography
/// Primary font: Sora (Display & Headings)
/// Secondary font: Inter (Body & UI text)
abstract final class AppTypography {
  AppTypography._();

  static String get _fontSora => GoogleFonts.sora().fontFamily!;
  static String get _fontInter => GoogleFonts.inter().fontFamily!;

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => TextStyle(
        fontFamily: _fontSora,
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        height: 1.18,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: _fontSora,
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get displaySmall => TextStyle(
        fontFamily: _fontSora,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  // ── Headline ──────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => TextStyle(
        fontFamily: _fontSora,
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        height: 1.25,
      );

  static TextStyle get headlineMedium => TextStyle(
        fontFamily: _fontSora,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get headlineSmall => TextStyle(
        fontFamily: _fontSora,
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        height: 1.33,
      );

  // ── Title ─────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => TextStyle(
        fontFamily: _fontSora,
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        height: 1.29,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: _fontSora,
        fontSize: 15.sp,
        fontWeight: FontWeight.w600,
        height: 1.33,
      );

  static TextStyle get titleSmall => TextStyle(
        fontFamily: _fontSora,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        height: 1.43,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontInter,
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        height: 1.47,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontInter,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.43,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontInter,
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        height: 1.33,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => TextStyle(
        fontFamily: _fontInter,
        fontSize: 13.sp,
        fontWeight: FontWeight.w500,
        height: 1.38,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: _fontInter,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        height: 1.33,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _fontInter,
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        height: 1.45,
      );

  // ── Custom App-Specific ───────────────────────────────────────────────────
  static TextStyle get priceTag => TextStyle(
        fontFamily: _fontSora,
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get badge => TextStyle(
        fontFamily: _fontInter,
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: _fontInter,
        fontSize: 11.sp,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get overline => TextStyle(
        fontFamily: _fontInter,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      );

  static TextStyle get buttonText => TextStyle(
        fontFamily: _fontInter,
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

  static TextStyle get inputText => TextStyle(
        fontFamily: _fontInter,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get inputHint => TextStyle(
        fontFamily: _fontInter,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
      );

  // ── TextTheme factory (Dynamic Color Mapping) ─────────────────────────────
  static TextTheme getTextTheme(bool isDark) {
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.lightTextBody;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      displayLarge: displayLarge.copyWith(color: primaryColor),
      displayMedium: displayMedium.copyWith(color: primaryColor),
      displaySmall: displaySmall.copyWith(color: primaryColor),
      headlineLarge: headlineLarge.copyWith(color: primaryColor),
      headlineMedium: headlineMedium.copyWith(color: primaryColor),
      headlineSmall: headlineSmall.copyWith(color: primaryColor),
      titleLarge: titleLarge.copyWith(color: primaryColor),
      titleMedium: titleMedium.copyWith(color: primaryColor),
      titleSmall: titleSmall.copyWith(color: primaryColor),
      bodyLarge: bodyLarge.copyWith(color: bodyColor),
      bodyMedium: bodyMedium.copyWith(color: bodyColor),
      bodySmall: bodySmall.copyWith(color: secondaryColor),
      labelLarge: labelLarge.copyWith(color: bodyColor),
      labelMedium: labelMedium.copyWith(color: bodyColor),
      labelSmall: labelSmall.copyWith(color: secondaryColor),
    );
  }
}
