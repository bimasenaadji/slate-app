import 'package:flutter/material.dart';

/// Single source of truth for Mindful Time Anchors (Pagi, Siang, Malam)
enum TimeAnchor {
  morning(
    key: 'morning',
    label: 'Pagi',
    timeHint: '09:00',
    targetHour: 9,
    icon: Icons.wb_twilight_outlined,
  ),
  afternoon(
    key: 'afternoon',
    label: 'Siang',
    timeHint: '13:00',
    targetHour: 13,
    icon: Icons.wb_sunny_outlined,
  ),
  evening(
    key: 'evening',
    label: 'Malam',
    timeHint: '19:00',
    targetHour: 19,
    icon: Icons.nightlight_outlined,
  );

  final String key;
  final String label;
  final String timeHint;
  final int targetHour;
  final IconData icon;

  const TimeAnchor({
    required this.key,
    required this.label,
    required this.timeHint,
    required this.targetHour,
    required this.icon,
  });

  /// Resolves a TimeAnchor enum from a string key
  static TimeAnchor? fromKey(String? key) {
    if (key == null) return null;
    for (final anchor in TimeAnchor.values) {
      if (anchor.key == key) return anchor;
    }
    return null;
  }
}

/// Lightweight natural language keyword detector for time anchors and tomorrow queue
class TimeAnchorDetector {
  static final _morningRegex =
      RegExp(r'\b(pagi|subuh|morning)\b', caseSensitive: false);
  static final _afternoonRegex =
      RegExp(r'\b(siang|sore|afternoon|noon)\b', caseSensitive: false);
  static final _eveningRegex =
      RegExp(r'\b(malam|evening|night)\b', caseSensitive: false);
  static final _tomorrowRegex =
      RegExp(r'\b(besok|tomorrow)\b', caseSensitive: false);

  /// Detects whether the input text contains a time anchor keyword
  static TimeAnchor? detectAnchor(String text) {
    if (_morningRegex.hasMatch(text)) return TimeAnchor.morning;
    if (_afternoonRegex.hasMatch(text)) return TimeAnchor.afternoon;
    if (_eveningRegex.hasMatch(text)) return TimeAnchor.evening;
    return null;
  }

  /// Detects whether the input text contains the "besok" / "tomorrow" keyword
  static bool detectTomorrow(String text) {
    return _tomorrowRegex.hasMatch(text);
  }
}
