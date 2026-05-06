import 'package:flutter/foundation.dart';

import '../link_format.dart';
import '../log_record.dart';
import '../logger_config.dart';
import '../source_location.dart';

/// Formats [LogRecord] instances into console-printable strings.
///
/// Output shape:
/// ```
/// [timestamp] emoji [LEVEL] @key message (<uri>:<line>:<col>)
/// ```
/// The trailing parenthesised location is the only format VS Code
/// (Dart-Code) and IntelliJ/Android Studio recognise as a clickable link.
/// It is always emitted at end-of-line with no styling, so the IDE's
/// stack-frame scanner can match it.
class ConsoleFormatter {
  ConsoleFormatter._();

  /// ANSI escape code: reset all attributes.
  static const String _reset = '\x1B[0m';

  /// One-shot deprecation warning for [LinkFormat.projectRelative].
  static bool _projectRelativeWarned = false;

  /// Formats a [LogRecord] into a console string.
  static String format(LogRecord record) {
    final config = _FormatterConfig.fromLoggerConfig();
    final body = _renderBody(record, config);
    final colored =
        config.useColors ? '${record.level.color}$body$_reset' : body;
    final location = _renderLocationSegment(record.source, config);
    return location == null ? colored : '$colored $location';
  }

  /// Formats a [LogRecord] into a plain string (no ANSI codes),
  /// suitable for log history storage.
  static String formatPlain(LogRecord record) {
    final config = _FormatterConfig.fromLoggerConfig();
    final body = _renderBody(record, config);
    final location = _renderLocationSegment(record.source, config);
    return location == null ? body : '$body $location';
  }

  /// Render the prefix + key + message portion (everything before the
  /// trailing parenthesised location).
  static String _renderBody(LogRecord record, _FormatterConfig config) {
    final parts = <String>[];

    if (config.showTimestamp) {
      parts.add('[${record.time.toIso8601String()}]');
    }
    if (config.showEmoji) {
      parts.add(record.level.emoji);
    }
    parts.add('[${record.level.label}]');

    if (config.showMemberName && record.source?.member != null) {
      parts.add(record.source!.member!);
    }
    if (record.key != null && record.key!.isNotEmpty) {
      parts.add('@${record.key}');
    }
    parts.add(record.message);

    return parts.join(' ');
  }

  /// Render the trailing `(<uri>:<line>:<col>)` segment, or null if it
  /// should be omitted.
  ///
  /// The segment is intentionally un-styled (no ANSI codes) so the IDE's
  /// stack-frame scanner can match it.
  static String? _renderLocationSegment(
    SourceLocation? source,
    _FormatterConfig config,
  ) {
    if (source == null) return null;
    if (!config.showSourceLocation) return null;
    if (!config.useClickableLinks) return null;
    if (!config.showFilePath && !config.showLineNumber) return null;

    final uriStr = _renderUri(source, config.clickableLinkFormat);
    if (uriStr == null || uriStr.isEmpty) return null;

    // Column is mandatory for IDE matching. Fall back to 1.
    final column = (config.showColumnNumber ? source.column : null) ?? 1;
    return '($uriStr:${source.line}:$column)';
  }

  /// Resolve the URI string for the location based on [format].
  static String? _renderUri(SourceLocation source, LinkFormat format) {
    final resolved = _resolveFormat(format, source.uri);

    switch (resolved) {
      case LinkFormat.packageUri:
        if (source.uri.scheme == 'package') return source.uri.toString();
        // Fallback: treat as fileUri.
        return _toFileUriString(source);
      case LinkFormat.fileUri:
        if (source.uri.scheme == 'package') return source.uri.toString();
        return _toFileUriString(source);
      case LinkFormat.bareAbsolute:
        if (source.uri.scheme == 'package') return source.uri.toString();
        return source.filePath;
      // ignore: deprecated_member_use_from_same_package
      case LinkFormat.projectRelative:
        // Deprecated — silently upgrade to packageUri/fileUri.
        if (!_projectRelativeWarned) {
          _projectRelativeWarned = true;
          if (kDebugMode) {
            // ignore: avoid_print
            print(
              '[inline_logger] LinkFormat.projectRelative is deprecated and '
              'is not clickable in any IDE. Falling back to packageUri.',
            );
          }
        }
        if (source.uri.scheme == 'package') return source.uri.toString();
        return _toFileUriString(source);
      case LinkFormat.auto:
        // Should not reach here after _resolveFormat.
        return source.uri.toString();
    }
  }

  /// Render a `file:///...` URI string for a source location whose URI is
  /// either already `file:` or is a bare path.
  static String? _toFileUriString(SourceLocation source) {
    if (source.uri.scheme == 'file') return source.uri.toString();
    final path = source.filePath;
    if (path.isEmpty) return null;
    if (path.startsWith('/')) return 'file://$path';
    // Windows-shaped path like `C:/...` or `C:\...`.
    if (path.length >= 3 && path.codeUnitAt(1) == 0x3A) {
      return 'file:///${path.replaceAll('\\', '/')}';
    }
    return path;
  }

  /// Resolve [LinkFormat.auto] to a concrete format based on the URI.
  static LinkFormat _resolveFormat(LinkFormat format, Uri uri) {
    if (format != LinkFormat.auto) return format;
    if (uri.scheme == 'package') return LinkFormat.packageUri;
    return LinkFormat.fileUri;
  }
}

/// Internal snapshot of relevant LoggerConfig values to avoid
/// repeated static field access during formatting.
class _FormatterConfig {
  final bool showTimestamp;
  final bool showEmoji;
  final bool useColors;
  final bool showSourceLocation;
  final bool showFilePath;
  final bool showLineNumber;
  final bool showColumnNumber;
  final bool showMemberName;
  final bool useClickableLinks;
  final LinkFormat clickableLinkFormat;

  const _FormatterConfig({
    required this.showTimestamp,
    required this.showEmoji,
    required this.useColors,
    required this.showSourceLocation,
    required this.showFilePath,
    required this.showLineNumber,
    required this.showColumnNumber,
    required this.showMemberName,
    required this.useClickableLinks,
    required this.clickableLinkFormat,
  });

  factory _FormatterConfig.fromLoggerConfig() {
    return _FormatterConfig(
      showTimestamp: LoggerConfig.showTimestamp,
      showEmoji: LoggerConfig.showEmoji,
      useColors: LoggerConfig.useColors,
      showSourceLocation: LoggerConfig.showSourceLocation,
      showFilePath: LoggerConfig.showFilePath,
      showLineNumber: LoggerConfig.showLineNumber,
      showColumnNumber: LoggerConfig.showColumnNumber,
      showMemberName: LoggerConfig.showMemberName,
      useClickableLinks: LoggerConfig.useClickableLinks,
      clickableLinkFormat: LoggerConfig.clickableLinkFormat,
    );
  }
}
