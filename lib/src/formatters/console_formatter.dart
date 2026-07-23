import 'package:flutter/foundation.dart';

import '../console_style.dart';
import '../link_format.dart';
import '../log_level.dart';
import '../log_record.dart';
import '../logger_config.dart';
import '../source_location.dart';

/// Formats [LogRecord] instances into console-printable strings.
///
/// Default output shape (0.3.0):
/// ```
/// ERR syncPending failed: … (package:my_app/repo.dart:176:23)
/// ```
/// with the subsystem tag supplied by the console host's own dimmed
/// gutter — see [KeyPlacement.developerLogName].
///
/// ## What the IDE link scanners actually require
///
/// The trailing parenthesised location is the last **text** on its
/// physical line and its characters are contiguous — no ANSI escape ever
/// appears *between* the parentheses. Styling that wraps the segment
/// from the outside is safe, which is why [LoggerConfig.locationStyle]
/// can dim it. The rules being satisfied are:
///
/// * **VS Code (Dart-Code)** requires both `:line:column`; a bare
///   `file.dart:42` is not linkified. It matches the *first* `.dart`
///   occurrence on a line, so anything earlier in the line that looks
///   like a Dart path wins instead — use [LocationPlacement.ownLine] to
///   make the match unambiguous. Escapes do not interfere: the pattern's
///   character class excludes them, and the console strips ANSI into
///   styled spans before link detection runs.
/// * **IntelliJ / Android Studio** treats the column as optional, but
///   requires a non-alphanumeric character immediately before the
///   `package:` / `file:` scheme. The opening parenthesis supplies it,
///   and any style escape sits before that parenthesis rather than
///   between it and the scheme.
///
/// Both resolve `package:` URIs through the package config, so eliding
/// directories inside one breaks resolution and kills the link. The
/// location is therefore never abbreviated.
class ConsoleFormatter {
  ConsoleFormatter._();

  /// ANSI escape code: reset all attributes.
  static const String _reset = '\x1B[0m';

  /// Marker for a collapsed run of identical lines.
  static const String _repeatGlyph = '↺';

  /// One-shot deprecation warning for [LinkFormat.projectRelative].
  static bool _projectRelativeWarned = false;

  /// Formats a [LogRecord] into a console string.
  ///
  /// Under [LocationPlacement.ownLine] the result contains a single
  /// embedded newline; otherwise it is always one line.
  static String format(LogRecord record) {
    final config = _FormatterConfig.fromLoggerConfig();
    return _assemble(record, config);
  }

  /// Formats a [LogRecord] into a plain string — no ANSI codes, no
  /// embedded newlines — suitable for log history and file sinks.
  ///
  /// The key is always rendered inline here regardless of
  /// [LoggerConfig.keyPlacement], because a plain-text sink has no
  /// console gutter to carry it.
  static String formatPlain(LogRecord record) {
    final config = _FormatterConfig.fromLoggerConfig().asPlain();
    return _assemble(record, config);
  }

  /// Renders the IDE-clickable `(<uri>:<line>:<column>)` segment for
  /// [source], or `null` if the current configuration suppresses it.
  ///
  /// Exposed so that a custom [LoggerConfig.formatter] can append a
  /// correctly-formed link without having to reimplement the URI and
  /// column rules described on this class.
  static String? renderLocation(SourceLocation source) =>
      _renderLocationSegment(source, _FormatterConfig.fromLoggerConfig());

  /// Renders the summary line for a collapsed run of identical logs.
  ///
  /// [count] is the number of occurrences suppressed *after* the first
  /// one was printed. The message is excerpted to
  /// [LoggerConfig.repeatSummaryExcerpt] characters and the location is
  /// omitted, since it is identical to the line already printed.
  static String formatRepeatSummary(LogRecord record, int count) {
    final config = _FormatterConfig.fromLoggerConfig();
    final summary = LogRecord(
      time: record.time,
      level: record.level,
      message: _excerpt(record.message, LoggerConfig.repeatSummaryExcerpt),
      key: record.key,
      repeatCount: count < 1 ? 1 : count,
    );
    // isSummary, not repeatCount > 1, gates the glyph — so a run with a
    // single suppressed occurrence reports the honest `↺ x1` instead of
    // being rounded up to `↺ x2`.
    final body = _renderBody(summary, config, isSummary: true);
    return _wrapBody(body, record.level, config);
  }

  /// Apply the level's colour span to an assembled body, if the current
  /// [ColorScope] calls for it.
  static String _wrapBody(
    String body,
    LogLevel level,
    _FormatterConfig config,
  ) {
    if (!config.useColors) return body;
    if (config.colorScope == ColorScope.level) return body;
    return '${level.color}$body$_reset';
  }

  // ────────────────────────────────────────────────────────────────

  static String _assemble(LogRecord record, _FormatterConfig config) {
    final body = _renderBody(record, config);
    final location = _renderLocationSegment(record.source, config);
    final color = config.useColors ? record.level.color : null;

    // [ColorScope.level] is applied inside _renderLevel, so the body is
    // already final in that case.
    final wrapsBody = color != null && config.colorScope != ColorScope.level;

    if (location == null) {
      return wrapsBody ? '$color$body$_reset' : body;
    }

    final joiner = config.locationPlacement == LocationPlacement.ownLine
        ? '\n${config.locationPrefix}'
        : ' ';

    // ColorScope.line runs the level's colour over the location too. The
    // span is closed and reopened around the joiner so that every
    // physical line is independently balanced — an SGR span left open
    // across a newline bleeds into unrelated console output.
    if (color != null && config.colorScope == ColorScope.line) {
      return '$color$body$_reset$joiner$color$location$_reset';
    }

    final styled = _styleLocation(location, config);
    if (!wrapsBody) return '$body$joiner$styled';

    // The body's span closes before the location, which then carries its
    // own dim style. Both spans sit strictly outside the parentheses, so
    // the segment's text stays contiguous for the IDE link scanners.
    return '$color$body$_reset$joiner$styled';
  }

  /// Apply [LoggerConfig.locationStyle] to an already-rendered segment.
  static String _styleLocation(String location, _FormatterConfig config) {
    if (!config.useColors) return location;
    final style = config.locationStyle;
    return style.isEmpty ? location : '$style$location$_reset';
  }

  /// Render everything up to (but excluding) the location segment.
  static String _renderBody(
    LogRecord record,
    _FormatterConfig config, {
    bool isSummary = false,
  }) {
    final parts = <String>[];

    final timestamp = _renderTimestamp(record.time, config);
    if (timestamp != null) parts.add(timestamp);

    final level = _renderLevel(record, config);
    if (level != null) parts.add(level);

    // Deliberately after the level token: emoji cell widths are
    // inconsistent across levels, so placing them before it would shift
    // the fixed-width gutter and defeat column alignment.
    //
    // Skipped under LevelStyle.emoji, where the level token already *is*
    // the glyph — appending it again would print the emoji twice.
    if (config.showEmoji && config.levelStyle != LevelStyle.emoji) {
      parts.add(record.level.emoji);
    }

    if (config.showMemberName && record.source?.member != null) {
      parts.add(record.source!.member!);
    }

    // Trimmed so a whitespace-only key is treated as absent here exactly
    // as it is by Logger.resolveLogName on the gutter path.
    final key = record.key?.trim();
    if (key != null &&
        key.isNotEmpty &&
        config.keyPlacement == KeyPlacement.inline) {
      parts.add('@$key');
    }

    if (isSummary || record.repeatCount > 1) {
      // No parentheses: the location segment owns the only parentheses
      // on the line, so an IDE scanner can never mistake this for one.
      parts.add('$_repeatGlyph x${record.repeatCount}');
    }

    final message = config.flattenMessage
        ? record.message.replaceAll(RegExp(r'\s+'), ' ').trim()
        : record.message;
    if (message.isNotEmpty) parts.add(message);

    return parts.join(' ');
  }

  static String? _renderTimestamp(DateTime time, _FormatterConfig config) {
    if (!config.showTimestamp) return null;
    switch (config.timestampStyle) {
      case TimestampStyle.none:
        return null;
      case TimestampStyle.clock:
        final h = time.hour.toString().padLeft(2, '0');
        final m = time.minute.toString().padLeft(2, '0');
        final s = time.second.toString().padLeft(2, '0');
        final ms = time.millisecond.toString().padLeft(3, '0');
        return '$h:$m:$s.$ms';
      case TimestampStyle.iso:
        return '[${time.toIso8601String()}]';
    }
  }

  static String? _renderLevel(LogRecord record, _FormatterConfig config) {
    final String token;
    switch (config.levelStyle) {
      case LevelStyle.none:
        return null;
      case LevelStyle.short:
        token = record.level.shortLabel;
      case LevelStyle.full:
        token = '[${record.level.label}]';
      case LevelStyle.emoji:
        token = record.level.emoji;
    }
    final colorizeToken =
        config.useColors && config.colorScope == ColorScope.level;
    return colorizeToken ? '${record.level.color}$token$_reset' : token;
  }

  /// Take the first [limit] characters of [message] as a single line.
  static String _excerpt(String message, int limit) {
    if (limit <= 0) return '';
    final flat = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Count by runes so a truncation can never split a surrogate pair.
    final runes = flat.runes.toList(growable: false);
    if (runes.length <= limit) return flat;
    return '${String.fromCharCodes(runes.take(limit))}…';
  }

  /// Render the trailing `(<uri>:<line>:<col>)` segment, or null if it
  /// should be omitted.
  ///
  /// Returned bare. Any styling is layered on afterwards by
  /// [_styleLocation] or the [ColorScope] span, always from strictly
  /// outside the parentheses, so the segment's text stays contiguous for
  /// the IDE stack-frame scanners.
  static String? _renderLocationSegment(
    SourceLocation? source,
    _FormatterConfig config,
  ) {
    if (source == null) return null;
    if (!config.showSourceLocation) return null;
    if (!config.useClickableLinks) return null;
    if (config.locationPlacement == LocationPlacement.none) return null;
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
  final TimestampStyle timestampStyle;
  final ColorScope colorScope;
  final LevelStyle levelStyle;
  final LocationPlacement locationPlacement;
  final String locationStyle;
  final String locationPrefix;
  final KeyPlacement keyPlacement;
  final bool flattenMessage;

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
    required this.timestampStyle,
    required this.colorScope,
    required this.levelStyle,
    required this.locationPlacement,
    required this.locationStyle,
    required this.locationPrefix,
    required this.keyPlacement,
    required this.flattenMessage,
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
      timestampStyle: LoggerConfig.timestampStyle,
      colorScope: LoggerConfig.colorScope,
      levelStyle: LoggerConfig.levelStyle,
      locationPlacement: LoggerConfig.locationPlacement,
      locationStyle: LoggerConfig.locationStyle,
      locationPrefix: LoggerConfig.locationPrefix,
      keyPlacement: LoggerConfig.keyPlacement,
      flattenMessage: false,
    );
  }

  /// Variant used by [ConsoleFormatter.formatPlain]: never coloured,
  /// never multi-line, and the key is always carried inline because a
  /// plain-text sink has no console gutter to render it into.
  ///
  /// The timestamp is forced on at full precision for the same reason:
  /// a file sink or crash-report attachment has no time column of its
  /// own, and [LoggerConfig.showTimestamp] is a console-display flag
  /// that defaults to `false`.
  _FormatterConfig asPlain() => _FormatterConfig(
        showTimestamp: true,
        showEmoji: showEmoji,
        useColors: false,
        showSourceLocation: showSourceLocation,
        showFilePath: showFilePath,
        showLineNumber: showLineNumber,
        showColumnNumber: showColumnNumber,
        showMemberName: showMemberName,
        useClickableLinks: useClickableLinks,
        clickableLinkFormat: clickableLinkFormat,
        timestampStyle: TimestampStyle.iso,
        colorScope: colorScope,
        levelStyle: levelStyle,
        locationPlacement: locationPlacement == LocationPlacement.none
            ? LocationPlacement.none
            : LocationPlacement.inline,
        locationStyle: '',
        locationPrefix: locationPrefix,
        keyPlacement: KeyPlacement.inline,
        flattenMessage: true,
      );
}
