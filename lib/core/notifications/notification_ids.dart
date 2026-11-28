/// A block of notification ids that belongs to one feature: [start]
/// inclusive, [end] exclusive.
class NotificationIdRange {
  const NotificationIdRange(this.start, this.end);

  final int start;
  final int end;

  bool contains(int id) => id >= start && id < end;

  /// The id for the [offset]-th notification of this range.
  int id(int offset) {
    assert(offset >= 0 && start + offset < end, 'offset $offset out of range');
    return start + offset;
  }
}

/// Every feature's notification ids, so a feature only ever cancels its own.
/// A new feature that schedules notifications takes the next free block.
class NotificationIds {
  NotificationIds._();

  /// The adhans: day offset × 10 + prayer row (see `AdhanPlan`).
  static const adhan = NotificationIdRange(1000, 2000);

  /// Where the adhans were before the ranges existed (ids 0–99). Cancelled
  /// with [adhan] so adhans scheduled by an older build don't play twice.
  static const legacyAdhan = NotificationIdRange(0, 100);

  /// The reminder a few minutes before each prayer (same offsets as
  /// [adhan], see `AdhanPlan.planEarly`).
  static const preAdhan = NotificationIdRange(3000, 4000);

  /// «بكرة صيام» the night before a recommended fast (one per day ahead,
  /// see `FastingReminders`).
  static const fasting = NotificationIdRange(4000, 5000);

  /// «نسخة جديدة» from the background update check. One at a time.
  static const update = NotificationIdRange(9000, 9001);

  // Next: azkar reminders 2000–2999, …
}
