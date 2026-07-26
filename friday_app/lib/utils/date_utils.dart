/// Shared date and time utility functions.
///
/// Used by Reminders, Calendar, Alarms, Chat, and Notes modules.
/// All time formatting and natural language parsing is centralised here.
class FridayDateUtils {
  FridayDateUtils._();

  /// Format a [DateTime] as a short human-readable string.
  ///
  /// Examples:
  ///   Today at 3:45 PM
  ///   Yesterday at 9:00 AM
  ///   26 Jul at 8:00 PM
  static String formatShort(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    final timeStr = _formatTime(dt);

    if (date == today) return 'Today at $timeStr';
    if (date == yesterday) return 'Yesterday at $timeStr';
    return '${dt.day} ${_monthName(dt.month)} at $timeStr';
  }

  /// Format a [DateTime] as 12-hour time string: "3:45 PM"
  static String _formatTime(DateTime dt) {
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }

  /// Parse a natural-language time phrase into an absolute [DateTime].
  ///
  /// Supported patterns (case-insensitive):
  ///   "in 10 minutes"
  ///   "in 2 hours"
  ///   "at 8 PM"
  ///   "at 20:00"
  ///   "tomorrow at 9 AM"
  ///   "tomorrow morning"   → 9:00 AM
  ///   "tomorrow evening"   → 7:00 PM
  ///   "tonight"            → 8:00 PM today
  ///   "next week"          → +7 days at 9:00 AM
  ///   "every monday"       → next Monday at 9:00 AM
  static DateTime? parseNaturalTime(String phrase) {
    final lower = phrase.toLowerCase().trim();
    final now = DateTime.now();

    // ── "in X minutes / hours" ─────────────────────────────────────────
    final relMatch =
        RegExp(r'in (\d+)\s*(minute|hour)s?').firstMatch(lower);
    if (relMatch != null) {
      final amount = int.parse(relMatch.group(1)!);
      final unit = relMatch.group(2)!;
      return unit.startsWith('h')
          ? now.add(Duration(hours: amount))
          : now.add(Duration(minutes: amount));
    }

    // ── "next week" ───────────────────────────────────────────────────
    if (lower.contains('next week')) {
      final nextWeek = now.add(const Duration(days: 7));
      return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9, 0);
    }

    // ── "every monday" / "next monday" ────────────────────────────────
    if (lower.contains('monday')) {
      int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
      if (daysUntilMonday <= 0) daysUntilMonday += 7;
      final target = now.add(Duration(days: daysUntilMonday));
      return DateTime(target.year, target.month, target.day, 9, 0);
    }

    // ── "tonight" ──────────────────────────────────────────────────────
    if (lower.contains('tonight')) {
      return DateTime(now.year, now.month, now.day, 20, 0);
    }

    // ── "tomorrow morning / evening / night / afternoon" ───────────────
    final tomorrow = now.add(const Duration(days: 1));
    if (lower.contains('tomorrow')) {
      if (lower.contains('morning')) {
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      }
      if (lower.contains('afternoon')) {
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 0);
      }
      if (lower.contains('evening') || lower.contains('night')) {
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19, 0);
      }
    }

    // ── "at HH:MM" / "at H PM" ────────────────────────────────────────
    final atMatch = RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?')
        .firstMatch(lower);
    if (atMatch != null) {
      int hour = int.parse(atMatch.group(1)!);
      final minute =
          atMatch.group(2) != null ? int.parse(atMatch.group(2)!) : 0;
      final period = atMatch.group(3);
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      final base = lower.contains('tomorrow') ? tomorrow : now;
      var scheduled =
          DateTime(base.year, base.month, base.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduled.isBefore(now) && !lower.contains('tomorrow')) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    return null;
  }
}
