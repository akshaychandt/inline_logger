import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import 'console_style.dart';
import 'formatters/console_formatter.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'logger_config.dart';
import 'repeat_tracker.dart';
import 'source_location.dart';

/// Main logger class with static methods.
///
/// Provides structured logging with automatic source location capture,
/// IDE-clickable links, ANSI color output, and extensibility hooks.
class Logger {
  Logger._();

  /// Generic log method.
  ///
  /// Source location is captured automatically via [StackTrace.current]
  /// when both [LoggerConfig.enabled] and [LoggerConfig.showSourceLocation]
  /// are true, and the message passes the [LoggerConfig.minLevel] filter.
  ///
  /// **Performance:** The level filter is applied **before** capturing
  /// the stack trace, so disabled log levels have zero cost.
  static void log(
    dynamic value,
    String name, {
    LogLevel level = LogLevel.debug,
    StackTrace? stackTrace,
    Object? error,
    bool saveToHistory = false,
  }) {
    if (!LoggerConfig.enabled) return;
    if (level.priority < LoggerConfig.minLevel.priority) return;

    // Capture source location AFTER passing filters (zero-cost guarantee)
    SourceLocation? source;
    if (LoggerConfig.showSourceLocation) {
      source = SourceLocationResolver.resolve();
    }

    final record = LogRecord(
      time: DateTime.now(),
      level: level,
      message: '$value',
      key: name.isEmpty ? null : name,
      source: source,
      error: error,
      stackTrace: stackTrace,
    );

    // Store in history if requested
    if (saveToHistory) {
      LoggerConfig.addToHistory(record);
    }

    // Fire the onRecord hook
    LoggerConfig.onRecord?.call(record);

    // Format and output
    if (!kDebugMode) return;

    final custom = LoggerConfig.formatter;

    // Repeat collapsing is console-only, and never runs when a custom
    // formatter is installed — both `onRecord` above and `formatter`
    // below must observe 100% of records.
    if (custom == null && RepeatTracker.observe(record, _emitRepeatSummary)) {
      return;
    }

    final formatted =
        custom != null ? custom(record) : ConsoleFormatter.format(record);

    _emit(
      formatted,
      key: record.key,
      level: level,
      time: record.time,
      stackTrace: stackTrace,
    );
  }

  /// Debug level — for debugging information.
  static void debug(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.debug);
  }

  /// Verbose level — for detailed information.
  static void verbose(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.verbose);
  }

  /// Info level — for general information.
  static void info(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.info);
  }

  /// Success level — for successful operations.
  static void success(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.success);
  }

  /// Warning level — for warnings.
  static void warning(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.warning, saveToHistory: true);
  }

  /// Error level — for errors.
  static void error(
    dynamic value, [
    String name = '',
    StackTrace? stackTrace,
  ]) {
    log(
      value,
      name,
      level: LogLevel.error,
      stackTrace: stackTrace,
      saveToHistory: true,
    );
  }

  /// Critical level — for critical errors.
  static void critical(
    dynamic value, [
    String name = '',
    StackTrace? stackTrace,
  ]) {
    log(
      value,
      name,
      level: LogLevel.critical,
      stackTrace: stackTrace,
      saveToHistory: true,
    );
  }

  /// Emits every pending repeat summary immediately.
  ///
  /// Call this before tearing down an isolate, or from a lifecycle hook
  /// when the app backgrounds, so that a collapsed run is never left
  /// unreported. No-op when [LoggerConfig.collapseRepeats] is `false`.
  static void flushRepeats() {
    if (!LoggerConfig.enabled) return;
    RepeatTracker.flushAll(_emitRepeatSummary);
  }

  /// Log a divider/separator.
  static void divider([String title = '']) {
    if (!_canEmitStructural()) return;
    final width = LoggerConfig.dividerWidth;
    if (width <= 0) return;

    final String rule;
    if (title.isEmpty) {
      rule = '─' * width;
    } else {
      final head = '── $title ';
      rule = head.length >= width ? head : head + '─' * (width - head.length);
    }

    // A rule is pure chrome, so it is dimmed rather than rendered at the
    // same weight as a real log line.
    _emit(
      LoggerConfig.useColors && LoggerConfig.locationStyle.isNotEmpty
          ? '${LoggerConfig.locationStyle}$rule${AnsiColors.reset}'
          : rule,
      level: LogLevel.info,
    );
  }

  /// Log a section header.
  static void header(String title) {
    if (!LoggerConfig.enabled) return;
    divider(title);
  }

  /// Log JSON-like structured data.
  static void json(Map<String, dynamic> data, [String name = 'JSON']) {
    if (!LoggerConfig.enabled) return;
    info(data, name);
  }

  /// Log API request details.
  static void apiRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!LoggerConfig.enabled) return;
    divider('API REQUEST');
    info('$method $endpoint', 'Endpoint');
    if (headers != null) verbose(headers, 'Headers');
    if (body != null) verbose(body, 'Body');
  }

  /// Log API response details.
  static void apiResponse({
    required String endpoint,
    required int statusCode,
    dynamic data,
    Duration? duration,
  }) {
    if (!LoggerConfig.enabled) return;
    divider('API RESPONSE');
    info(endpoint, 'Endpoint');
    if (statusCode >= 200 && statusCode < 300) {
      success(statusCode, 'Status');
    } else if (statusCode >= 400) {
      error(statusCode, 'Status');
    } else {
      info(statusCode, 'Status');
    }
    if (duration != null) verbose('${duration.inMilliseconds}ms', 'Duration');
    if (data != null) verbose(data, 'Data');
  }

  /// Log navigation events.
  static void navigation(String from, String to) {
    info('$from → $to', 'Nav');
  }

  /// Log lifecycle events.
  static void lifecycle(String event, [String? details]) {
    verbose(details == null ? event : '$event — $details', 'Lifecycle');
  }

  /// Log state changes.
  static void state(String stateName, dynamic value) {
    debug('$stateName = $value', 'State');
  }

  // ────────────────────────────────────────────────────────────────
  // Emission
  // ────────────────────────────────────────────────────────────────

  /// The single `dart:developer` call site.
  ///
  /// Resolves the `[name] ` gutter the console host will draw, trims
  /// the forwarded stack trace, and stamps the record's own time so
  /// DevTools' timestamp column matches [LogRecord.time] rather than
  /// being a few microseconds later.
  static void _emit(
    String formatted, {
    String? key,
    required LogLevel level,
    DateTime? time,
    StackTrace? stackTrace,
  }) {
    dev.log(
      formatted,
      name: resolveLogName(key),
      time: time,
      level: _getLogLevel(level),
      stackTrace: _trimStack(stackTrace),
    );
  }

  /// Resolves the `[name] ` gutter the console host draws for a record
  /// with the given [key].
  ///
  /// Under [KeyPlacement.developerLogName] a non-empty key becomes the
  /// gutter, so `[VideoProgressRepo] ` replaces `[IL] ` rather than
  /// following it. Otherwise the constant
  /// [LoggerConfig.developerLogName] is used.
  ///
  /// Visible for testing because `dev.log` output cannot be observed
  /// from a unit test, which previously left this logic uncovered.
  @visibleForTesting
  static String resolveLogName(String? key) {
    final useKey = LoggerConfig.keyPlacement == KeyPlacement.developerLogName &&
        key != null &&
        key.isNotEmpty;
    return _sanitizeLogName(useKey ? key : LoggerConfig.developerLogName);
  }

  static void _emitRepeatSummary(LogRecord sample, int suppressed) {
    _emit(
      ConsoleFormatter.formatRepeatSummary(sample, suppressed),
      key: sample.key,
      level: sample.level,
    );
  }

  /// Make a string safe to pass as `dev.log(name:)`.
  ///
  /// The host prepends `[$name] ` *before* the IDE scans the line for a
  /// source link, and VS Code linkifies the first `.dart` match it
  /// finds — so a key like `widget_test.dart` in the gutter would steal
  /// the click from the real trailing location. Newlines would split
  /// the gutter across rows.
  static String _sanitizeLogName(String candidate) {
    final cleaned = _stripUnsafe(candidate);
    if (cleaned.isNotEmpty) return cleaned;

    final fallback = _stripUnsafe(LoggerConfig.developerLogName);
    // `dart:developer` substitutes the literal `log` for an empty name,
    // which is worse than any fallback we can choose.
    return fallback.isEmpty ? 'IL' : fallback;
  }

  static String _stripUnsafe(String value) =>
      value.replaceAll('.dart', '').replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

  /// Keep only the first [LoggerConfig.consoleStackTraceFrames] real
  /// frames.
  ///
  /// `<asynchronous suspension>` markers are preserved without counting
  /// against the limit, so a Flutter async error never loses the
  /// application frame that sits below them.
  static StackTrace? _trimStack(StackTrace? trace) {
    if (trace == null) return null;
    final limit = LoggerConfig.consoleStackTraceFrames;
    if (limit == null) return trace;
    if (limit <= 0) return null;

    final lines =
        trace.toString().split('\n').where((l) => l.trim().isNotEmpty).toList();

    final kept = <String>[];
    var frames = 0;
    for (final line in lines) {
      final isMarker = line.trim() == '<asynchronous suspension>';
      if (!isMarker) {
        if (frames >= limit) break;
        frames++;
      }
      kept.add(line);
    }
    // A trailing marker with nothing under it is noise.
    while (kept.isNotEmpty && kept.last.trim() == '<asynchronous suspension>') {
      kept.removeLast();
    }

    if (kept.length == lines.length) return trace;
    if (kept.isEmpty) return null;
    return StackTrace.fromString(kept.join('\n'));
  }

  /// Whether structural output (dividers, headers) should be emitted.
  ///
  /// These previously bypassed both the release-mode gate and the level
  /// filter, so `minLevel = error` still printed every divider, and a
  /// release build with `enabled` forced true printed rules while every
  /// real log was suppressed.
  static bool _canEmitStructural() =>
      LoggerConfig.enabled &&
      kDebugMode &&
      LogLevel.info.priority >= LoggerConfig.minLevel.priority;

  /// Convert [LogLevel] to `dart:developer` log level.
  static int _getLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
      case LogLevel.verbose:
        return 500;
      case LogLevel.info:
      case LogLevel.success:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
}
