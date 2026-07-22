/// ANSI color codes for terminal output.
class AnsiColors {
  AnsiColors._();

  static const String reset = '\x1B[0m';

  /// Faint/dim attribute, used for de-emphasised chrome.
  static const String dim = '\x1B[2m';
  static const String gray = '\x1B[90m';
  static const String cyan = '\x1B[36m';
  static const String blue = '\x1B[34m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String red = '\x1B[31m';
  static const String brightRed = '\x1B[91m';
}

/// Log levels for categorizing log messages.
enum LogLevel {
  debug(0, '🔍', 'DEBUG', AnsiColors.gray, 'DBG'),
  verbose(1, '📝', 'VERBOSE', AnsiColors.cyan, 'VRB'),
  info(2, 'ℹ️', 'INFO', AnsiColors.blue, 'INF'),
  success(3, '✅', 'SUCCESS', AnsiColors.green, 'SUC'),
  warning(4, '⚠️', 'WARNING', AnsiColors.yellow, 'WRN'),
  error(5, '❌', 'ERROR', AnsiColors.red, 'ERR'),
  critical(6, '🚨', 'CRITICAL', AnsiColors.brightRed, 'CRT');

  const LogLevel(
    this.priority,
    this.emoji,
    this.label,
    this.color,
    this.shortLabel,
  );

  final int priority;
  final String emoji;
  final String label;
  final String color;

  /// A fixed-width 3-character abbreviation of [label], used by
  /// [LevelStyle.short] so that the message start column does not
  /// jitter between levels.
  final String shortLabel;
}
