import 'package:flutter/foundation.dart';

/// Represents a source code location captured from a stack trace.
///
/// Holds the original [Uri] from the frame (so `package:` URIs are preserved
/// rather than being collapsed to filesystem paths), the line, optional
/// column, and optional enclosing member name.
class SourceLocation {
  /// The URI of the source location. Scheme is typically `package`, `file`,
  /// or `dart`.
  final Uri uri;

  /// The 1-based line number.
  final int line;

  /// The 1-based column number, if available.
  final int? column;

  /// The enclosing function/method name (e.g. `HomeViewModel.loadUsers`),
  /// when parseable from the stack trace.
  final String? member;

  /// Creates a [SourceLocation] from a [Uri].
  const SourceLocation.fromUri({
    required this.uri,
    required this.line,
    this.column,
    this.member,
  });

  /// Backwards-compatible constructor that accepts a [filePath] string.
  ///
  /// If the string parses as a URI with a scheme (e.g. `package:foo/bar.dart`,
  /// `file:///abs/path`) it is preserved; otherwise it is treated as a local
  /// filesystem path and converted to a `file:` URI.
  SourceLocation({
    required String filePath,
    required this.line,
    this.column,
    this.member,
  }) : uri = _parsePathOrUri(filePath);

  static Uri _parsePathOrUri(String input) {
    // Detect Windows-style absolute paths (e.g. `C:\src\app\main.dart`)
    // before URI parsing — `C:` would otherwise be misread as a scheme.
    if (input.length >= 3 &&
        _isAlpha(input.codeUnitAt(0)) &&
        input.codeUnitAt(1) == 0x3A /* : */ &&
        (input[2] == '\\' || input[2] == '/')) {
      final forward = input.replaceAll('\\', '/');
      return Uri.parse('file:///$forward');
    }
    final parsed = Uri.tryParse(input);
    if (parsed != null && parsed.hasScheme) return parsed;
    if (input.startsWith('/')) {
      return Uri.parse('file://$input');
    }
    return Uri(path: input);
  }

  static bool _isAlpha(int c) =>
      (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);

  /// Backwards-compatible accessor. Returns the local filesystem path for
  /// `file:` URIs, and the full URI string for `package:`/`dart:` URIs.
  String get filePath {
    if (uri.scheme == 'file') {
      // Manually format so we don't need dart:io. This produces
      // `/abs/path` on POSIX and `C:/abs/path` on Windows-shaped URIs.
      final path = uri.path;
      if (path.length >= 3 &&
          path.startsWith('/') &&
          path.codeUnitAt(2) == 0x3A) {
        return path.substring(1);
      }
      return path;
    }
    if (!uri.hasScheme) return uri.path;
    return uri.toString();
  }

  @override
  String toString() =>
      'SourceLocation($filePath:$line${column != null ? ':$column' : ''}'
      '${member != null ? ' in $member' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceLocation &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          line == other.line &&
          column == other.column &&
          member == other.member;

  @override
  int get hashCode => Object.hash(uri, line, column, member);
}

// VM-style frame regex, compiled once.
// Example: #0      main (file:///Users/akshay/app/lib/main.dart:42:10)
final _vmFrameRegex = RegExp(
  r'^#\d+\s+(?<member>.+?)\s+\((?<uri>.+\.dart):(?<line>\d+)(?::(?<col>\d+))?\)$',
);

// Web-style frame regex, compiled once.
// Example: packages/my_app/main.dart 42:10  main
final _webFrameRegex = RegExp(
  r'^(?<uri>[^\s]+\.dart)\s+(?<line>\d+)(?::(?<col>\d+))?\s+(?<member>.+)$',
);

/// Resolves source locations from stack traces by finding the first
/// frame outside `package:inline_logger/`.
class SourceLocationResolver {
  SourceLocationResolver._();

  /// Returns the first frame outside `package:inline_logger/`.
  /// Returns null on Web release builds or when parsing fails.
  ///
  /// [trace] can be provided for testing; defaults to [StackTrace.current].
  static SourceLocation? resolve([StackTrace? trace]) {
    trace ??= StackTrace.current;

    final frames = trace.toString().split('\n');
    for (final frame in frames) {
      final trimmed = frame.trim();
      if (trimmed.isEmpty) continue;

      final location =
          kIsWeb ? _parseWebFrame(trimmed) : _parseVmFrame(trimmed);
      if (location != null) return location;
    }

    return null;
  }

  /// Parse a VM-style stack frame.
  static SourceLocation? _parseVmFrame(String frame) {
    final match = _vmFrameRegex.firstMatch(frame);
    if (match == null) return null;

    final uriStr = match.namedGroup('uri')!;

    // Skip frames from within this package.
    if (uriStr.contains('package:inline_logger/')) return null;
    // Skip dart: internal frames.
    if (uriStr.startsWith('dart:')) return null;

    final parsed = Uri.tryParse(uriStr);
    final uri =
        (parsed != null && parsed.hasScheme) ? parsed : Uri(path: uriStr);

    return SourceLocation.fromUri(
      uri: uri,
      line: int.parse(match.namedGroup('line')!),
      column: match.namedGroup('col') != null
          ? int.parse(match.namedGroup('col')!)
          : null,
      member: match.namedGroup('member'),
    );
  }

  /// Parse a Web-style stack frame.
  static SourceLocation? _parseWebFrame(String frame) {
    final match = _webFrameRegex.firstMatch(frame);
    if (match == null) return null;

    final uriStr = match.namedGroup('uri')!;

    // Skip frames from within this package.
    if (uriStr.contains('inline_logger')) return null;

    return SourceLocation.fromUri(
      uri: Uri(path: uriStr),
      line: int.parse(match.namedGroup('line')!),
      column: match.namedGroup('col') != null
          ? int.parse(match.namedGroup('col')!)
          : null,
      member: match.namedGroup('member'),
    );
  }

  /// Clear caches. Useful for testing.
  @visibleForTesting
  static void clearCache() {}
}
