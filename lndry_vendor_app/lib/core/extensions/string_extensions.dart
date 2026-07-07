/// String extensions for common operations used across the app.
extension StringExt on String {
  // ── Capitalisation ────────────────────────────────────────────────────────

  /// "hello world" → "Hello World"
  String get toTitleCase => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  /// "hello world" → "Hello world"
  String get toSentenceCase =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// "helloWorld" → "Hello World"
  String get camelToWords => replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => ' ${m.group(0)}',
      ).trim().toSentenceCase;

  // ── Validation helpers ────────────────────────────────────────────────────
  bool get isValidEmail =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$').hasMatch(trim());

  bool get isValidPhone =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(replaceAll(RegExp(r'[\s\-\(\)]'), ''));

  bool get isValidPincode => RegExp(r'^\d{6}$').hasMatch(trim());

  bool get isNumeric => RegExp(r'^\d+$').hasMatch(trim());

  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => trim().isNotEmpty;

  // ── Masking ───────────────────────────────────────────────────────────────

  /// "9876543210" → "98765 43210"
  String get formatPhone {
    final d = replaceAll(RegExp(r'\D'), '');
    if (d.length != 10) return this;
    return '${d.substring(0, 5)} ${d.substring(5)}';
  }

  /// "9876543210" → "98••••••10"
  String get maskedPhone {
    final d = replaceAll(RegExp(r'\D'), '');
    if (d.length < 4) return this;
    return '${d.substring(0, 2)}${'•' * (d.length - 4)}${d.substring(d.length - 2)}';
  }

  /// "john@example.com" → "jo••@example.com"
  String get maskedEmail {
    final idx = indexOf('@');
    if (idx < 2) return this;
    return '${substring(0, 2)}${'•' * (idx - 2)}${substring(idx)}';
  }

  // ── Parsing ───────────────────────────────────────────────────────────────
  int    get toIntOrZero    => int.tryParse(trim()) ?? 0;
  double get toDoubleOrZero => double.tryParse(trim()) ?? 0.0;

  // ── Truncation ────────────────────────────────────────────────────────────

  /// Truncates to [maxLength] chars and appends [ellipsis].
  String truncate(int maxLength, {String ellipsis = '…'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$ellipsis';

  // ── Slug ──────────────────────────────────────────────────────────────────

  /// "Dry Clean & Iron" → "dry-clean-iron"
  String get toSlug => toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .trim();

  // ── Initials ──────────────────────────────────────────────────────────────

  /// "Aditya Kumar" → "AK"
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Nullable String extensions
extension NullableStringExt on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  bool get isNotNullOrBlank => !isNullOrBlank;
  String get orEmpty => this ?? '';
  String orDefault(String def) => (this == null || this!.trim().isEmpty) ? def : this!;
}
