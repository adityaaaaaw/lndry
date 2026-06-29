/// LNDRY Design Token: Corner Radii
/// Matches the corner radius system of LNDRY design kit
abstract final class AppRadius {
  AppRadius._();

  static const double none    = 0;
  static const double xs      = 4;
  static const double sm      = 8;  // Small elements
  static const double md      = 12; // Chips, small buttons
  static const double lg      = 16; // Compact cards
  static const double xl      = 20; // Standard cards
  static const double xxl     = 24; // Hero cards
  static const double xxxl    = 28; // Sheets, modals
  static const double full    = 999; // Search, inputs, pills

  // ── Semantic aliases ──────────────────────────────────────────────────────
  static const double button   = full;  // Full pill for buttons
  static const double card     = xl;    // 20 — standard cards
  static const double compactCard = lg; // 16 — compact cards
  static const double input    = full;  // Full pill for inputs
  static const double chip     = md;    // 12 — chips
  static const double tag      = sm;    // 8 — tag / indicators
  static const double dialog   = xxxl;  // 28 — sheets/modals
  static const double sheet    = xxxl;  // 28 — sheets/modals (top only)
  static const double avatar   = full;  // circle avatars
  static const double image    = lg;    // 16 — images
}
