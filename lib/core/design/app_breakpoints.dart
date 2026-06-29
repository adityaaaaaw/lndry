/// LNDRY Design Token: Breakpoints
/// Thresholds for responsive designs
abstract final class AppBreakpoints {
  AppBreakpoints._();

  static const double mobileSmall  = 360;
  static const double mobile       = 390;  // design baseline width
  static const double mobileLarge  = 430;
  static const double tablet       = 600;
  static const double tabletLarge  = 840;
  static const double desktop      = 1024;

  static const int mobileColumns  = 4;
  static const int tabletColumns  = 8;
  static const int desktopColumns = 12;

  static const double mobileGutter  = 16;
  static const double tabletGutter  = 24;
  static const double desktopGutter = 32;

  // ScreenUtil baseline design dimension constants
  static const double designWidth  = 390;
  static const double designHeight = 844;
}
