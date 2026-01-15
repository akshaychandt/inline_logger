import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// ANSI color codes for terminal output
class _AnsiColors {
  static const String reset = '\x1B[0m';
  static const String gray = '\x1B[90m';
  static const String cyan = '\x1B[36m';
  static const String blue = '\x1B[34m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String red = '\x1B[31m';
  static const String brightRed = '\x1B[91m';
}

/// Log levels for categorizing log messages
enum LogLevel {
  debug(0, '🔍', 'DEBUG', _AnsiColors.gray),
  verbose(1, '📝', 'VERBOSE', _AnsiColors.cyan),
  info(2, 'ℹ️', 'INFO', _AnsiColors.blue),
  success(3, '✅', 'SUCCESS', _AnsiColors.green),
  warning(4, '⚠️', 'WARNING', _AnsiColors.yellow),
  error(5, '❌', 'ERROR', _AnsiColors.red),
  critical(6, '🚨', 'CRITICAL', _AnsiColors.brightRed);

  const LogLevel(this.priority, this.emoji, this.label, this.color);

  final int priority;
  final String emoji;
  final String label;
  final String color;
}

/// Global configuration for the logger
class LoggerConfig {
  /// Minimum log level to display (logs below this level are ignored)
  static LogLevel minLevel = LogLevel.debug;

  /// Whether to show timestamps in logs
  static bool showTimestamp = true;

  /// Whether to show emojis in logs
  static bool showEmoji = true;

  /// Whether to use ANSI colors in console output
  static bool useColors = true;

  /// Whether to enable logging (can be toggled at runtime)
  static bool enabled = kDebugMode;

  /// Custom log storage (e.g., for crash reporting)
  static final List<String> _logHistory = [];
  static int maxHistorySize = 100;

  /// Get log history
  static List<String> get logHistory => List.unmodifiable(_logHistory);

  /// Add to log history
  static void _addToHistory(String log) {
    _logHistory.add(log);
    if (_logHistory.length > maxHistorySize) {
      _logHistory.removeAt(0);
    }
  }

  /// Clear log history
  static void clearHistory() {
    _logHistory.clear();
  }
}

/// Extension on any type to enable inline logging
extension InlineLogger<E> on E {
  /// Log with default debug level
  ///
  /// Example:
  /// ```dart
  /// final result = apiCall().log('API Response');
  /// ```
  E log([String key = '', LogLevel level = LogLevel.debug]) {
    Logger.log(this, key, level: level);
    return this;
  }

  /// Log as debug
  E logDebug([String key = '']) {
    Logger.debug(this, key);
    return this;
  }

  /// Log as verbose
  E logVerbose([String key = '']) {
    Logger.verbose(this, key);
    return this;
  }

  /// Log as info
  E logInfo([String key = '']) {
    Logger.info(this, key);
    return this;
  }

  /// Log as success
  E logSuccess([String key = '']) {
    Logger.success(this, key);
    return this;
  }

  /// Log as warning
  E logWarning([String key = '']) {
    Logger.warning(this, key);
    return this;
  }

  /// Log as error
  E logError([String key = '']) {
    Logger.error(this, key);
    return this;
  }

  /// Log as critical
  E logCritical([String key = '']) {
    Logger.critical(this, key);
    return this;
  }
}

/// Main logger class with static methods
class Logger {
  Logger._();

  /// Generic log method
  static void log(
    dynamic value,
    String name, {
    LogLevel level = LogLevel.debug,
    StackTrace? stackTrace,
    bool saveToHistory = false,
  }) {
    if (!LoggerConfig.enabled) return;
    if (level.priority < LoggerConfig.minLevel.priority) return;

    final timestamp = LoggerConfig.showTimestamp
        ? '[${DateTime.now().toIso8601String()}]'
        : '';
    final emoji = LoggerConfig.showEmoji ? level.emoji : '';
    final label = level.label;
    final key = name.isEmpty ? '' : '@$name';

    // Build message without colors first (for history)
    final plainMessage = '$timestamp $emoji [$label] $key $value';

    if (saveToHistory) {
      LoggerConfig._addToHistory(plainMessage);
    }

    // Apply colors if enabled
    final coloredMessage = LoggerConfig.useColors
        ? '${level.color}$plainMessage${_AnsiColors.reset}'
        : plainMessage;

    if (kDebugMode) {
      dev.log(
        coloredMessage,
        name: 'InlineLogger',
        level: _getLogLevel(level),
        stackTrace: stackTrace,
      );
    }
  }

  /// Debug level - for debugging information
  static void debug(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.debug);
  }

  /// Verbose level - for detailed information
  static void verbose(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.verbose);
  }

  /// Info level - for general information
  static void info(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.info);
  }

  /// Success level - for successful operations
  static void success(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.success);
  }

  /// Warning level - for warnings
  static void warning(dynamic value, [String name = '']) {
    log(value, name, level: LogLevel.warning, saveToHistory: true);
  }

  /// Error level - for errors
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

  /// Critical level - for critical errors
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

  /// Log a divider/separator
  static void divider([String title = '']) {
    if (!LoggerConfig.enabled) return;
    final separator = '=' * 60;
    if (title.isEmpty) {
      dev.log(separator, name: 'InlineLogger');
    } else {
      dev.log('$separator $title $separator', name: 'InlineLogger');
    }
  }

  /// Log a section header
  static void header(String title) {
    if (!LoggerConfig.enabled) return;
    divider(title);
  }

  /// Log JSON-like structured data
  static void json(Map<String, dynamic> data, [String name = 'JSON']) {
    if (!LoggerConfig.enabled) return;
    info(data, name);
  }

  /// Log API request details
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

  /// Log API response details
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

  /// Log navigation events
  static void navigation(String from, String to) {
    info('$from → $to', '🧭 Navigation');
  }

  /// Log lifecycle events
  static void lifecycle(String event, [String? details]) {
    verbose(details ?? event, '🔄 Lifecycle');
  }

  /// Log state changes
  static void state(String stateName, dynamic value) {
    debug(value, '📊 State: $stateName');
  }

  /// Convert LogLevel to dart:developer log level
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
