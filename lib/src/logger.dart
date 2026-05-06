import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import 'formatters/console_formatter.dart';
import 'log_level.dart';
import 'log_record.dart';
import 'logger_config.dart';
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
      stackTrace: stackTrace,
    );

    // Store in history if requested
    if (saveToHistory) {
      LoggerConfig.addToHistory(record);
    }

    // Fire the onRecord hook
    LoggerConfig.onRecord?.call(record);

    // Format and output
    if (kDebugMode) {
      final formatted = LoggerConfig.formatter != null
          ? LoggerConfig.formatter!(record)
          : ConsoleFormatter.format(record);

      dev.log(
        formatted,
        name: 'InlineLogger',
        level: _getLogLevel(level),
        stackTrace: stackTrace,
      );
    }
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

  /// Log a divider/separator.
  static void divider([String title = '']) {
    if (!LoggerConfig.enabled) return;
    final separator = '=' * 60;
    if (title.isEmpty) {
      dev.log(separator, name: 'InlineLogger');
    } else {
      dev.log('$separator $title $separator', name: 'InlineLogger');
    }
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
    divider();
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
    divider();
  }

  /// Log navigation events.
  static void navigation(String from, String to) {
    info('$from → $to', '🧭 Navigation');
  }

  /// Log lifecycle events.
  static void lifecycle(String event, [String? details]) {
    verbose(details ?? event, '🔄 Lifecycle');
  }

  /// Log state changes.
  static void state(String stateName, dynamic value) {
    debug(value, '📊 State: $stateName');
  }

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
