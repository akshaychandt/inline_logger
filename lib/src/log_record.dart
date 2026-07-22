import 'log_level.dart';
import 'source_location.dart';

/// A structured record of a log event.
///
/// Bundles together all information about a single log entry, including
/// timestamp, level, message, source location, and optional error/stack trace.
///
/// This class is used by [LoggerConfig.onRecord] and [LoggerConfig.formatter]
/// to provide extensibility hooks for custom log processing.
class LogRecord {
  /// The time at which the log event occurred.
  final DateTime time;

  /// The severity level of the log event.
  final LogLevel level;

  /// The log message content.
  final String message;

  /// An optional key/name associated with the log entry.
  final String? key;

  /// The source location where the log call was made, if captured.
  final SourceLocation? source;

  /// An optional error object associated with this log.
  final Object? error;

  /// An optional stack trace associated with this log.
  final StackTrace? stackTrace;

  /// How many occurrences this record stands for.
  ///
  /// `1` for the first occurrence of a given
  /// `(level, key, message, source)` identity. Greater than `1` only on
  /// the summary record synthesised by the opt-in repeat collapser
  /// (see [LoggerConfig.collapseRepeats]), which reports how many
  /// identical occurrences were folded into it.
  ///
  /// Records delivered to [LoggerConfig.onRecord] and
  /// [LoggerConfig.logHistory] always have `repeatCount == 1`: the
  /// collapser suppresses console output only, never the hooks.
  final int repeatCount;

  /// Creates a [LogRecord] with the given parameters.
  const LogRecord({
    required this.time,
    required this.level,
    required this.message,
    this.key,
    this.source,
    this.error,
    this.stackTrace,
    this.repeatCount = 1,
  });

  @override
  String toString() => 'LogRecord(time: $time, level: $level, message: $message'
      '${key != null ? ', key: $key' : ''}'
      '${source != null ? ', source: $source' : ''}'
      '${error != null ? ', error: $error' : ''}'
      '${repeatCount > 1 ? ', repeatCount: $repeatCount' : ''})';
}
