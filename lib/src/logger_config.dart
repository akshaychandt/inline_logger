import 'package:flutter/foundation.dart';

import 'console_style.dart';
import 'formatters/console_formatter.dart';
import 'link_format.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'repeat_tracker.dart';

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
  ///
  /// Defaults to `false` as of 0.3.0: under the default
  /// [KeyPlacement.developerLogName] layout, DevTools and both IDE
  /// consoles render their own timestamp column, so an in-line
  /// timestamp is duplicated information. Set to `true` when logging to
  /// a plain `flutter run` terminal, which has no such column.
  static bool showTimestamp = false;

  /// Whether to show emojis in logs.
  ///
  /// Defaults to `false` as of 0.3.0. Severity is already carried by
  /// the ANSI color and the level token; a third encoding is what
  /// prevents columns from aligning, because `ℹ️` and `⚠️` are a base
  /// character plus U+FE0F while `🔍📝✅❌🚨` are single wide code
  /// points, so their rendered cell widths differ.
  static bool showEmoji = false;

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

  /// Plain-text log history — one rendered line per record, with no
  /// ANSI codes and no embedded newlines, suitable for a file sink or
  /// a crash-report attachment.
  ///
  /// As of 0.3.0 this renders through [ConsoleFormatter.formatPlain].
  /// It previously returned `LogRecord.toString()` debug dumps, which
  /// matched neither the console output nor 0.1.x's format.
  static List<String> get logHistoryStrings =>
      List.unmodifiable(_logHistory.map(ConsoleFormatter.formatPlain));

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
  ///
  /// Note: this flag has no individual effect. A clickable link needs
  /// both a path and a line, so only the *both false* case suppresses
  /// the location segment. To hide it, set [useClickableLinks] to
  /// `false` or [locationPlacement] to [LocationPlacement.none].
  static bool showFilePath = true;

  /// Show `:line` number. Default: `true`.
  ///
  /// Note: this flag has no individual effect. See [showFilePath].
  static bool showLineNumber = true;

  /// Whether the rendered column comes from the captured stack frame.
  ///
  /// Note: the rendered console string **always** includes a column —
  /// IDEs require `:line:column` to recognise the link. This flag only
  /// controls whether that column is the real column from the stack
  /// frame (`true`) or a fixed `:1` (`false`).
  ///
  /// Default: `true` as of 0.3.0. It costs no extra width and makes an
  /// IDE jump land on the expression that logged rather than on column
  /// 1 of the line. Set to `false` to restore the 0.2.x `:1` behaviour.
  static bool showColumnNumber = true;

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

  // ──────────────────────────────────────────────────────────────────
  // Console layout (0.3.0)
  // ──────────────────────────────────────────────────────────────────

  /// How the timestamp is rendered when [showTimestamp] is `true`.
  /// Default: [TimestampStyle.clock].
  static TimestampStyle timestampStyle = TimestampStyle.clock;

  /// How much of the line the level's ANSI colour covers.
  /// Default: [ColorScope.body] — everything except the trailing
  /// location segment, which instead carries its own [locationStyle].
  static ColorScope colorScope = ColorScope.body;

  /// How the severity level is rendered. Default: [LevelStyle.short],
  /// a fixed-width 3-character token so the message start column does
  /// not jitter between levels.
  static LevelStyle levelStyle = LevelStyle.short;

  /// Where the clickable location segment is placed.
  /// Default: [LocationPlacement.inline].
  ///
  /// [useClickableLinks] always wins: when it is `false` the location
  /// is omitted regardless of this setting.
  static LocationPlacement locationPlacement = LocationPlacement.inline;

  /// ANSI style applied to the trailing location segment.
  ///
  /// Default: [AnsiColors.gray]. Without this the segment renders in the
  /// console's default foreground — which in the VS Code Debug Console
  /// is a bright amber, making the least important part of the line the
  /// loudest thing on it.
  ///
  /// Set to `''` to leave the segment un-styled. Ignored when
  /// [useColors] is `false`, and when [colorScope] is
  /// [ColorScope.line] (there the segment is already inside the level's
  /// colour span).
  ///
  /// The escape sequences sit strictly outside the parentheses, so the
  /// segment's text reaches the IDE link scanners contiguous and intact.
  static String locationStyle = AnsiColors.gray;

  /// Prefix for the location line under [LocationPlacement.ownLine].
  ///
  /// Two hard rules, both enforced by IDE link scanners rather than by
  /// this package:
  /// * It must **not** contain `.dart` — VS Code's Dart-Code extension
  ///   linkifies the *first* match on a line, so a `.dart` in the
  ///   prefix would steal the click from the real location.
  /// * It must be empty or end in a non-alphanumeric character —
  ///   IntelliJ refuses to start a path match directly after a letter
  ///   or digit.
  static String locationPrefix = '↳ ';

  /// Where a record's key (its subsystem tag) is rendered.
  ///
  /// Default: [KeyPlacement.developerLogName], which passes the key to
  /// `dart:developer`'s `log(name:)` so the IDE draws it in its own
  /// dimmed gutter — `[VideoProgressRepo] ` replaces `[InlineLogger] `
  /// rather than following it, costing zero columns of the line's own
  /// width. Use [KeyPlacement.inline] for the 0.2.x `@key` form.
  static KeyPlacement keyPlacement = KeyPlacement.developerLogName;

  /// The name passed to `dart:developer`'s `log(name:)`, which every
  /// console host renders as a `[name] ` prefix.
  ///
  /// Under [KeyPlacement.developerLogName] this is the fallback used
  /// for records that carry no key; otherwise it prefixes every line.
  ///
  /// The prefix cannot be removed — an empty name is substituted with
  /// the literal `log` by the SDK debug adapter, Dart-Code,
  /// flutter-intellij and DevTools alike — but it can be shortened.
  /// `'IL'` reclaims 13 columns per line versus 0.2.x's
  /// `'InlineLogger'` while keeping DevTools' `k:IL` filter working.
  static String developerLogName = 'IL';

  /// Width in columns of the rule drawn by [Logger.divider] and
  /// [Logger.header]. Default: `60`.
  static int dividerWidth = 60;

  /// Maximum number of stack frames forwarded to the console.
  ///
  /// A forwarded trace becomes an entire extra prefixed block in both
  /// IDE consoles, and the SDK debug adapter attaches a source chip to
  /// every frame line. `null` means unlimited, `0` suppresses the trace
  /// entirely. Default: `8`.
  ///
  /// `<asynchronous suspension>` markers are preserved and do not count
  /// against the limit, so the budget is spent on real frames. Note that
  /// this is a simple head-truncation: an application frame sitting
  /// below more than [consoleStackTraceFrames] framework frames is still
  /// trimmed away — raise the cap or set it to `null` when debugging
  /// deep async chains. [LogRecord.stackTrace] always keeps the full
  /// trace for [onRecord] consumers.
  static int? consoleStackTraceFrames = 8;

  // ──────────────────────────────────────────────────────────────────
  // Repeat collapsing (0.3.0, opt-in)
  // ──────────────────────────────────────────────────────────────────

  /// Collapse consecutive identical console lines into a single line
  /// plus a `↺ xN` summary. Default: `false`.
  ///
  /// Useful for retry loops and polling timers that log the same
  /// failure indefinitely. Two identical `(level, key, message,
  /// source)` records within [repeatWindow] print once; the suppressed
  /// count is then reported as a summary line on the next log after the
  /// window elapses,
  /// when a different message interrupts the run, when the entry is
  /// evicted past [repeatMemory], or on [Logger.flushRepeats].
  ///
  /// Suppression is **console-only and lossless**: [addToHistory] and
  /// [onRecord] run before the collapser and always see every record,
  /// and no pending count is ever discarded. The collapser is also
  /// skipped entirely whenever [formatter] is set, so a custom
  /// formatter always receives every record.
  static bool collapseRepeats = false;

  /// How long a collapsed run stays open, measured from its **first**
  /// occurrence. Default: 10 minutes.
  ///
  /// Measuring from the first rather than the most recent occurrence
  /// bounds how long a count can stay hidden: a message repeating every
  /// 5 minutes surfaces a summary every 10, instead of holding the
  /// window open forever.
  static Duration repeatWindow = const Duration(minutes: 10);

  /// How many distinct message identities are tracked concurrently.
  /// Default: `8`. Evicting an entry always emits its pending summary
  /// first.
  static int repeatMemory = 8;

  /// Maximum number of characters of the original message reproduced in
  /// a `↺ xN` summary line. Default: `48`.
  static int repeatSummaryExcerpt = 48;

  /// Reserved for backwards compatibility; no longer applied.
  ///
  /// Use [locationStyle] instead. This field was withdrawn because it
  /// styled the segment's interior, which does break the IDE scanners;
  /// [locationStyle] wraps the segment from outside, which does not.
  @Deprecated(
    'Superseded by LoggerConfig.locationStyle, which applies its escapes '
    'strictly outside the parentheses so the segment stays clickable.',
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

  // ──────────────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────────────

  /// Restores every field to its shipped default and clears both the
  /// log history and any pending repeat counts.
  ///
  /// Primarily a test-suite affordance: this class is entirely static,
  /// so without an explicit reset a flag set by one test leaks into
  /// every test that follows it.
  ///
  /// Pending repeat counts are **discarded**, not emitted. Call
  /// [Logger.flushRepeats] first if you need them.
  static void reset() {
    minLevel = LogLevel.debug;
    showTimestamp = false;
    showEmoji = false;
    useColors = true;
    enabled = kDebugMode;
    maxHistorySize = 100;

    showSourceLocation = kDebugMode;
    showFilePath = true;
    showLineNumber = true;
    showColumnNumber = true;
    showMemberName = false;
    useClickableLinks = true;
    clickableLinkFormat = LinkFormat.auto;

    timestampStyle = TimestampStyle.clock;
    colorScope = ColorScope.body;
    levelStyle = LevelStyle.short;
    locationPlacement = LocationPlacement.inline;
    locationStyle = AnsiColors.gray;
    locationPrefix = '↳ ';
    keyPlacement = KeyPlacement.developerLogName;
    developerLogName = 'IL';
    dividerWidth = 60;
    consoleStackTraceFrames = 8;

    collapseRepeats = false;
    repeatWindow = const Duration(minutes: 10);
    repeatMemory = 8;
    repeatSummaryExcerpt = 48;

    onRecord = null;
    formatter = null;

    clearHistory();
    resetRepeatTracking();
  }

  /// Drops pending repeat counts without emitting their summaries.
  /// See [Logger.flushRepeats] for the lossless equivalent.
  static void resetRepeatTracking() => RepeatTracker.reset();
}
