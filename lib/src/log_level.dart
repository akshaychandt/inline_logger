/// ANSI color codes for terminal output.
class AnsiColors {
  AnsiColors._();

  static const String reset = '\x1B[0m';
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
  debug(0, '🔍', 'DEBUG', AnsiColors.gray),
  verbose(1, '📝', 'VERBOSE', AnsiColors.cyan),
  info(2, 'ℹ️', 'INFO', AnsiColors.blue),
  success(3, '✅', 'SUCCESS', AnsiColors.green),
  warning(4, '⚠️', 'WARNING', AnsiColors.yellow),
  error(5, '❌', 'ERROR', AnsiColors.red),
  critical(6, '🚨', 'CRITICAL', AnsiColors.brightRed);

  const LogLevel(this.priority, this.emoji, this.label, this.color);

  final int priority;
  final String emoji;
  final String label;
  final String color;
}
