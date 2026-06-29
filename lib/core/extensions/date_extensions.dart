import 'package:intl/intl.dart';

/// DateTime extensions for the LNDRY app.
extension DateTimeExt on DateTime {
  // ── Formatters ────────────────────────────────────────────────────────────

  /// "27 Jun 2026"
  String get toDateString => DateFormat('dd MMM yyyy').format(this);

  /// "09:30 PM"
  String get toTimeString => DateFormat('hh:mm a').format(this);

  /// "27 Jun 2026, 09:30 PM"
  String get toDateTimeString => DateFormat('dd MMM yyyy, hh:mm a').format(this);

  /// "27 Jun"
  String get toDayMonth => DateFormat('dd MMM').format(this);

  /// "June 2026"
  String get toMonthYear => DateFormat('MMMM yyyy').format(this);

  /// "Sat, 27 Jun"
  String get toDayDate => DateFormat('EEE, dd MMM').format(this);

  /// "Saturday"
  String get toFullDay => DateFormat('EEEE').format(this);

  /// "Sat"
  String get toShortDay => DateFormat('EEE').format(this);

  /// ISO 8601 UTC string
  String get toIso => toUtc().toIso8601String();

  // ── Relative time ─────────────────────────────────────────────────────────

  /// "Just now", "5 min ago", "2 hr ago", "Yesterday", "27 Jun 2026"
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return toDateString;
  }

  // ── Comparison helpers ────────────────────────────────────────────────────
  bool get isToday {
    final n = DateTime.now();
    return year == n.year && month == n.month && day == n.day;
  }

  bool get isTomorrow {
    final t = DateTime.now().add(const Duration(days: 1));
    return year == t.year && month == t.month && day == t.day;
  }

  bool get isYesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return year == y.year && month == y.month && day == y.day;
  }

  bool get isFuture  => isAfter(DateTime.now());
  bool get isPast    => isBefore(DateTime.now());

  /// Whether two DateTimes fall on the same calendar day.
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  // ── Manipulation ──────────────────────────────────────────────────────────
  DateTime get startOfDay => DateTime(year, month, day, 0, 0, 0);
  DateTime get endOfDay   => DateTime(year, month, day, 23, 59, 59);
  DateTime get startOfMonth => DateTime(year, month, 1);
  DateTime get endOfMonth   => DateTime(year, month + 1, 0);
  DateTime get nextDay     => add(const Duration(days: 1));
  DateTime get prevDay     => subtract(const Duration(days: 1));
}

/// Nullable DateTime extensions
extension NullableDateTimeExt on DateTime? {
  String get orNa => this?.toDateString ?? 'N/A';
  bool   get isNullOrPast =>
      this == null || this!.isBefore(DateTime.now());
}
