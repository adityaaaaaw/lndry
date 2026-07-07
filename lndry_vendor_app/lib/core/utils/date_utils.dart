import 'package:intl/intl.dart';

/// LNDRY Date & Time formatting utilities
abstract final class AppDateUtils {
  AppDateUtils._();

  // ── Formatters ────────────────────────────────────────────────────────────
  static final _dateFormatter = DateFormat('dd MMM yyyy');
  static final _timeFormatter = DateFormat('hh:mm a');
  static final _dateTimeFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  static final _dayMonthFormatter = DateFormat('dd MMM');
  static final _monthYearFormatter = DateFormat('MMMM yyyy');
  static final _isoFormatter = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final _dayFormatter = DateFormat('EEE, dd MMM');
  static final _shortDayFormatter = DateFormat('EEE');
  static final _fullDayFormatter = DateFormat('EEEE');

  // ── Format helpers ────────────────────────────────────────────────────────

  /// "27 Jun 2026"
  static String formatDate(DateTime dt) => _dateFormatter.format(dt);

  /// "09:30 PM"
  static String formatTime(DateTime dt) => _timeFormatter.format(dt);

  /// "27 Jun 2026, 09:30 PM"
  static String formatDateTime(DateTime dt) => _dateTimeFormatter.format(dt);

  /// "27 Jun"
  static String formatDayMonth(DateTime dt) => _dayMonthFormatter.format(dt);

  /// "June 2026"
  static String formatMonthYear(DateTime dt) => _monthYearFormatter.format(dt);

  /// "Sat, 27 Jun"
  static String formatDayDate(DateTime dt) => _dayFormatter.format(dt);

  /// "Sat"
  static String formatShortDay(DateTime dt) => _shortDayFormatter.format(dt);

  /// "Saturday"
  static String formatFullDay(DateTime dt) => _fullDayFormatter.format(dt);

  /// ISO 8601 string
  static String toIso(DateTime dt) => _isoFormatter.format(dt.toUtc());

  /// Parse ISO 8601 string to local DateTime
  static DateTime? fromIso(String? iso) {
    if (iso == null) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  // ── Relative time ─────────────────────────────────────────────────────────

  /// Returns human-readable relative time:
  /// "Just now", "5 min ago", "2 hours ago", "Yesterday", "27 Jun 2026"
  static String timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(dt);
  }

  // ── Slot / Scheduling ─────────────────────────────────────────────────────

  /// Returns list of time slot labels for the day (e.g. 8 AM – 10 AM)
  static List<String> generateTimeSlots({
    int startHour = 8,
    int endHour = 20,
    int intervalHours = 2,
  }) {
    final slots = <String>[];
    for (var h = startHour; h < endHour; h += intervalHours) {
      final start = _formatHour(h);
      final end = _formatHour(h + intervalHours);
      slots.add('$start – $end');
    }
    return slots;
  }

  static String _formatHour(int hour) {
    final dt = DateTime(2000, 1, 1, hour);
    return DateFormat('h a').format(dt);
  }

  /// Whether [dt] is today
  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Whether [dt] is tomorrow
  static bool isTomorrow(DateTime dt) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;
  }
}
