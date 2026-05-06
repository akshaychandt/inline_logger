import 'package:flutter/foundation.dart';

import 'link_format.dart';
import 'log_level.dart';
import 'log_record.dart';

/// Global configuration for the inline logger.
///
/// All fields are static and can be modified at runtime to control
/// logging behaviour without restarting the application.
class LoggerConfig {
  LoggerConfig._();

  // ──────────────────────────────────────────────────────────────────
  // Existing flags (unchanged)
  // ──────────────────────────────────────────────────────────────────

  /// Minimum log level to display (logs below this level are ignored).
  static LogLevel minLevel = LogLevel.debug;

  /// Whether to show timestamps in logs.
  static bool showTimestamp = true;

  /// Whether to show emojis in logs.
  static bool showEmoji = true;

  /// Whether to use ANSI colors in console output.
  static bool useColors = true;

  /// Whether to enable logging (can be toggled at runtime).
  static bool enabled = kDebugMode;

  /// Custom log storage (e.g., for crash reporting).
  static final List<LogRecord> _logHistory = [];
  static int maxHistorySize = 100;

  /// Get log history as [LogRecord] objects with full metadata
  /// including source locations.
  static List<LogRecord> get logHistory => List.unmodifiable(_logHistory);

  /// Legacy plain-text log history for backward compatibility.
  static List<String> get logHistoryStrings =>
      List.unmodifiable(_logHistory.map((r) => r.toString()));

  /// Add a [LogRecord] to the history.
  static void addToHistory(LogRecord record) {
    _logHistory.add(record);
    if (_logHistory.length > maxHistorySize) {
      _logHistory.removeAt(0);
    }
  }

  /// Clear log history.
  static void clearHistory() {
    _logHistory.clear();
  }

  // ──────────────────────────────────────────────────────────────────
  // Source location flags (NEW)
  // ──────────────────────────────────────────────────────────────────

  /// Master switch for source-location capture.
  ///
  /// Default: `true` in debug mode, `false` in release mode.
  /// Already gated by the existing [enabled] flag, but this lets users
  /// keep logs while dropping the stack-trace cost.
  static bool showSourceLocation = kDebugMode;

  /// Show file path (or relative path, depending on [clickableLinkFormat]).
  /// Default: `true`.
  static bool showFilePath = true;

  /// Show `:line` number. Default: `true`.
  static bool showLineNumber = true;

  /// Whether the rendered column comes from the captured stack frame.
  ///
  /// Note: the rendered console string **always** includes a column —
  /// IDEs require `:line:column` to recognise the link. This flag only
  /// controls whether that column is the real column from the stack
  /// frame (`true`) or a fixed `:1` (`false`). Default: `false`.
  static bool showColumnNumber = false;

  /// Show enclosing method/class name when available. Default: `false`.
  static bool showMemberName = false;

  /// When `true`, append a clickable `(<uri>:<line>:<col>)` segment to
  /// every log line (the only format VS Code / IntelliJ recognise).
  ///
  /// When `false`, the segment is **omitted entirely** — the bracketed
  /// `[file.dart:42]` form is not clickable in any IDE, so shipping it
  /// would be misleading. The location remains attached to
  /// [LogRecord.source] for [onRecord] / [logHistory] consumers.
  /// Default: `true`.
  static bool useClickableLinks = true;

  /// Link format for source location output.
  /// Default: [LinkFormat.auto].
  static LinkFormat clickableLinkFormat = LinkFormat.auto;

  /// Reserved for backwards compatibility. The clickable location segment
  /// is intentionally un-styled so the IDE's stack-frame scanner can match
  /// it; this value is no longer applied.
  @Deprecated(
    'linkAnsiStyle is no longer applied. The trailing (<uri>:<line>:<col>) '
    'segment must be un-styled for IDE click recognition.',
  )
  static String linkAnsiStyle = '';

  // ──────────────────────────────────────────────────────────────────
  // Extensibility hooks (NEW)
  // ──────────────────────────────────────────────────────────────────

  /// Optional sink. When set, every record is forwarded here in addition
  /// to the console.
  ///
  /// Use this for DevTools panels, Crashlytics, Sentry, file logging, etc.
  ///
  /// ```dart
  /// LoggerConfig.onRecord = (record) {
  ///   // Send to Crashlytics, Sentry, etc.
  ///   crashlytics.log(record.message);
  /// };
  /// ```
  static void Function(LogRecord record)? onRecord;

  /// Optional formatter override. When set, replaces the built-in
  /// console formatter.
  ///
  /// Receives the assembled [LogRecord] and returns the final string
  /// written to stdout.
  ///
  /// ```dart
  /// LoggerConfig.formatter = (record) {
  ///   return '${record.level.label}: ${record.message}';
  /// };
  /// ```
  static String Function(LogRecord record)? formatter;
}
