/// LNDRY Design Token: Spacing
/// All spacing scales are based on an 8-point spatial grid
abstract final class AppSpacing {
  AppSpacing._();

  // ── Grid units ────────────────────────────────────────────────────────────
  static const double x0 = 0;
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x14 = 56;
  static const double x16 = 64;
  static const double x20 = 80;
  static const double x24 = 96;

  // ── Semantic aliases ──────────────────────────────────────────────────────
  static const double xs   = x1;   //  4
  static const double sm   = x2;   //  8
  static const double md   = x4;   // 16
  static const double lg   = x6;   // 24
  static const double xl   = x8;   // 32
  static const double xxl  = x12;  // 48
  static const double xxxl = x16;  // 64

  // ── Layout gutters & spacing ──────────────────────────────────────────────
  static const double pagePaddingH = x5;   // 20px Horizontal Gutter
  static const double pagePaddingV = x4;   // 16px Vertical Gutter
  static const double cardPadding = x4;    // 16px Card padding
  static const double sectionGap = x6;     // 24px Section spacing
  static const double cardGap = x3;        // 12px Card gap spacing
  static const double inlineGap = x2;      //  8px Icon+text inline gap
}
