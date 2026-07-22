import 'package:flutter_test/flutter_test.dart';
import 'package:inline_logger/inline_logger.dart';
// Internal — not exported from the barrel. Imported directly so the
// collapser's suppression decisions can be asserted without adding a
// public test seam.
import 'package:inline_logger/src/repeat_tracker.dart';

void main() {
  // LoggerConfig is entirely static, so without this a flag set by one
  // test leaks into every test that follows it.
  tearDown(LoggerConfig.reset);

  group('SourceLocation', () {
    test('creates with required fields', () {
      final loc = SourceLocation(filePath: '/app/lib/main.dart', line: 42);
      expect(loc.filePath, '/app/lib/main.dart');
      expect(loc.line, 42);
      expect(loc.column, isNull);
      expect(loc.member, isNull);
    });

    test('creates with all fields', () {
      final loc = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 42,
        column: 10,
        member: 'HomeViewModel.loadUsers',
      );
      expect(loc.filePath, '/app/lib/main.dart');
      expect(loc.line, 42);
      expect(loc.column, 10);
      expect(loc.member, 'HomeViewModel.loadUsers');
    });

    test('toString includes all fields', () {
      final loc = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 42,
        column: 10,
        member: 'main',
      );
      expect(
        loc.toString(),
        'SourceLocation(/app/lib/main.dart:42:10 in main)',
      );
    });

    test('toString without optional fields', () {
      final loc = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 42,
      );
      expect(
        loc.toString(),
        'SourceLocation(/app/lib/main.dart:42)',
      );
    });

    test('equality works', () {
      final loc1 = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 42,
        column: 10,
      );
      final loc2 = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 42,
        column: 10,
      );
      final loc3 = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 43,
      );
      expect(loc1, equals(loc2));
      expect(loc1, isNot(equals(loc3)));
      expect(loc1.hashCode, equals(loc2.hashCode));
    });
  });

  group('SourceLocationResolver', () {
    setUp(() {
      SourceLocationResolver.clearCache();
    });

    test('parses VM-style stack frames', () {
      final trace = StackTrace.fromString('''
#0      main (file:///Users/akshay/app/lib/main.dart:42:10)
#1      _runMain (dart:isolate-patch/isolate_patch.dart:297:19)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNotNull);
      expect(loc!.filePath, contains('main.dart'));
      expect(loc.line, 42);
      expect(loc.column, 10);
      expect(loc.member, 'main');
    });

    test('skips inline_logger package frames', () {
      final trace = StackTrace.fromString('''
#0      Logger.log (package:inline_logger/src/logger.dart:30:5)
#1      Logger.info (package:inline_logger/src/logger.dart:80:5)
#2      MyWidget.build (file:///Users/akshay/app/lib/home.dart:55:20)
#3      StatelessElement.build (package:flutter/src/widgets/framework.dart:4000:28)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNotNull);
      expect(loc!.filePath, contains('home.dart'));
      expect(loc.line, 55);
      expect(loc.column, 20);
      expect(loc.member, 'MyWidget.build');
    });

    test('skips dart: internal frames', () {
      final trace = StackTrace.fromString('''
#0      someFunction (dart:core/runtime/libcore_patch.dart:10:5)
#1      MyClass.method (file:///Users/akshay/app/lib/service.dart:30:12)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNotNull);
      expect(loc!.filePath, contains('service.dart'));
      expect(loc.line, 30);
    });

    test('returns null for empty trace', () {
      final trace = StackTrace.fromString('');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNull);
    });

    test('returns null when only package frames exist', () {
      final trace = StackTrace.fromString('''
#0      Logger.log (package:inline_logger/src/logger.dart:30:5)
#1      Logger.info (package:inline_logger/src/logger.dart:80:5)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNull);
    });

    test('handles frames without column number', () {
      final trace = StackTrace.fromString('''
#0      main (file:///Users/akshay/app/lib/main.dart:42)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNotNull);
      expect(loc!.line, 42);
      expect(loc.column, isNull);
    });

    test('handles package: URI frames', () {
      final trace = StackTrace.fromString('''
#0      MyApp.run (package:my_app/src/app.dart:15:8)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNotNull);
      expect(loc!.filePath, 'package:my_app/src/app.dart');
      expect(loc.line, 15);
    });

    test('skips extension frames from inline_logger', () {
      final trace = StackTrace.fromString('''
#0      InlineLogger.log (package:inline_logger/src/extensions.dart:20:5)
#1      Logger.log (package:inline_logger/src/logger.dart:30:5)
#2      _ExampleHomePageState._incrementCounter (file:///Users/akshay/app/lib/main.dart:55:30)
''');
      final loc = SourceLocationResolver.resolve(trace);
      expect(loc, isNotNull);
      expect(loc!.filePath, contains('main.dart'));
      expect(loc.line, 55);
    });
  });

  group('LinkFormat', () {
    test('has expected values', () {
      expect(LinkFormat.values, hasLength(5));
      expect(LinkFormat.values, contains(LinkFormat.packageUri));
      expect(LinkFormat.values, contains(LinkFormat.fileUri));
      expect(LinkFormat.values, contains(LinkFormat.bareAbsolute));
      // ignore: deprecated_member_use
      expect(LinkFormat.values, contains(LinkFormat.projectRelative));
      expect(LinkFormat.values, contains(LinkFormat.auto));
    });
  });

  group('LogRecord', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final record = LogRecord(
        time: now,
        level: LogLevel.info,
        message: 'Hello',
      );
      expect(record.time, now);
      expect(record.level, LogLevel.info);
      expect(record.message, 'Hello');
      expect(record.key, isNull);
      expect(record.source, isNull);
      expect(record.error, isNull);
      expect(record.stackTrace, isNull);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final source = SourceLocation(
        filePath: '/app/lib/main.dart',
        line: 42,
      );
      final error = Exception('test error');
      final trace = StackTrace.current;

      final record = LogRecord(
        time: now,
        level: LogLevel.error,
        message: 'Something failed',
        key: 'TestKey',
        source: source,
        error: error,
        stackTrace: trace,
      );

      expect(record.time, now);
      expect(record.level, LogLevel.error);
      expect(record.message, 'Something failed');
      expect(record.key, 'TestKey');
      expect(record.source, source);
      expect(record.error, error);
      expect(record.stackTrace, trace);
    });
  });

  group('LoggerConfig', () {
    setUp(() {
      LoggerConfig.reset();
      // Reset to defaults before each test
      LoggerConfig.enabled = true;
      LoggerConfig.showSourceLocation = true;
      LoggerConfig.showFilePath = true;
      LoggerConfig.showLineNumber = true;
      LoggerConfig.showColumnNumber = false;
      LoggerConfig.showMemberName = false;
      LoggerConfig.useClickableLinks = true;
      LoggerConfig.clickableLinkFormat = LinkFormat.auto;
      // ignore: deprecated_member_use
      LoggerConfig.linkAnsiStyle = '';
      LoggerConfig.onRecord = null;
      LoggerConfig.formatter = null;
      LoggerConfig.minLevel = LogLevel.debug;
      LoggerConfig.showTimestamp = true;
      LoggerConfig.showEmoji = true;
      LoggerConfig.useColors = true;
      LoggerConfig.clearHistory();
    });

    test('default source location flags', () {
      LoggerConfig.reset();
      expect(LoggerConfig.showFilePath, isTrue);
      expect(LoggerConfig.showLineNumber, isTrue);
      expect(LoggerConfig.showColumnNumber, isTrue);
      expect(LoggerConfig.showMemberName, isFalse);
      expect(LoggerConfig.useClickableLinks, isTrue);
      expect(
        LoggerConfig.clickableLinkFormat,
        LinkFormat.auto,
      );
    });

    test('default console layout flags', () {
      LoggerConfig.reset();
      expect(LoggerConfig.showEmoji, isFalse);
      expect(LoggerConfig.showTimestamp, isFalse);
      expect(LoggerConfig.timestampStyle, TimestampStyle.clock);
      expect(LoggerConfig.levelStyle, LevelStyle.short);
      expect(LoggerConfig.locationPlacement, LocationPlacement.inline);
      expect(LoggerConfig.keyPlacement, KeyPlacement.developerLogName);
      expect(LoggerConfig.developerLogName, 'IL');
      expect(LoggerConfig.dividerWidth, 60);
      expect(LoggerConfig.consoleStackTraceFrames, 8);
    });

    test('repeat collapsing is opt-in', () {
      LoggerConfig.reset();
      expect(LoggerConfig.collapseRepeats, isFalse);
      expect(LoggerConfig.repeatWindow, const Duration(minutes: 10));
      expect(LoggerConfig.repeatMemory, 8);
    });

    test('reset() restores every mutated field', () {
      LoggerConfig.showEmoji = true;
      LoggerConfig.levelStyle = LevelStyle.full;
      LoggerConfig.developerLogName = 'Custom';
      LoggerConfig.collapseRepeats = true;
      LoggerConfig.minLevel = LogLevel.critical;
      LoggerConfig.formatter = (r) => 'x';
      Logger.warning('leaves a history entry');

      LoggerConfig.reset();

      expect(LoggerConfig.showEmoji, isFalse);
      expect(LoggerConfig.levelStyle, LevelStyle.short);
      expect(LoggerConfig.developerLogName, 'IL');
      expect(LoggerConfig.collapseRepeats, isFalse);
      expect(LoggerConfig.minLevel, LogLevel.debug);
      expect(LoggerConfig.formatter, isNull);
      expect(LoggerConfig.logHistory, isEmpty);
    });

    test('logHistoryStrings renders through formatPlain', () {
      LoggerConfig.showTimestamp = false;
      Logger.warning('Disk full', 'Storage');

      final lines = LoggerConfig.logHistoryStrings;
      expect(lines, hasLength(1));
      // Plain text: the key is always inline, no ANSI, no newlines.
      expect(lines.single, contains('@Storage'));
      expect(lines.single, contains('Disk full'));
      expect(lines.single, isNot(contains('\x1B[')));
      expect(lines.single, isNot(contains('\n')));
      expect(lines.single, isNot(contains('LogRecord(')));
    });

    test('onRecord hook receives log records', () {
      LogRecord? capturedRecord;
      LoggerConfig.onRecord = (record) {
        capturedRecord = record;
      };

      Logger.info('Test message', 'TestKey');

      expect(capturedRecord, isNotNull);
      expect(capturedRecord!.level, LogLevel.info);
      expect(capturedRecord!.message, 'Test message');
      expect(capturedRecord!.key, 'TestKey');
      expect(capturedRecord!.source, isNotNull);
    });

    test('custom formatter is used when set', () {
      String? formattedOutput;
      LoggerConfig.formatter = (record) {
        formattedOutput = 'CUSTOM: ${record.level.label} - ${record.message}';
        return formattedOutput!;
      };

      Logger.info('Test message');

      expect(formattedOutput, isNotNull);
      expect(formattedOutput, 'CUSTOM: INFO - Test message');
    });

    test('logHistory stores LogRecord objects', () {
      Logger.warning('Warning message');

      expect(LoggerConfig.logHistory, hasLength(1));
      expect(
        LoggerConfig.logHistory.first.message,
        'Warning message',
      );
      expect(
        LoggerConfig.logHistory.first.level,
        LogLevel.warning,
      );
      expect(
        LoggerConfig.logHistory.first.source,
        isNotNull,
      );
    });

    test('logHistory includes source location', () {
      Logger.error('Error message');

      expect(LoggerConfig.logHistory, hasLength(1));
      final record = LoggerConfig.logHistory.first;
      expect(record.source, isNotNull);
      expect(record.source!.line, isPositive);
    });

    test('no StackTrace.current when showSourceLocation is false', () {
      LoggerConfig.showSourceLocation = false;

      LogRecord? capturedRecord;
      LoggerConfig.onRecord = (record) {
        capturedRecord = record;
      };

      Logger.info('Test message');

      expect(capturedRecord, isNotNull);
      expect(capturedRecord!.source, isNull);
    });

    test('no logging when enabled is false', () {
      LoggerConfig.enabled = false;

      LogRecord? capturedRecord;
      LoggerConfig.onRecord = (record) {
        capturedRecord = record;
      };

      Logger.info('Test message');

      expect(capturedRecord, isNull);
    });

    test('no logging when below minLevel', () {
      LoggerConfig.minLevel = LogLevel.warning;

      LogRecord? capturedRecord;
      LoggerConfig.onRecord = (record) {
        capturedRecord = record;
      };

      Logger.debug('Test message');
      expect(capturedRecord, isNull);

      Logger.warning('Warning message');
      expect(capturedRecord, isNotNull);
    });

    test('clearHistory works', () {
      Logger.warning('Warning 1');
      Logger.error('Error 1');
      expect(LoggerConfig.logHistory, hasLength(2));

      LoggerConfig.clearHistory();
      expect(LoggerConfig.logHistory, isEmpty);
    });
  });

  group('ConsoleFormatter', () {
    setUp(() {
      LoggerConfig.reset();
      LoggerConfig.enabled = true;
      LoggerConfig.showSourceLocation = true;
      LoggerConfig.showFilePath = true;
      LoggerConfig.showLineNumber = true;
      LoggerConfig.showColumnNumber = false;
      LoggerConfig.showMemberName = false;
      LoggerConfig.useClickableLinks = true;
      LoggerConfig.clickableLinkFormat = LinkFormat.fileUri;
      LoggerConfig.useColors = false;
      LoggerConfig.showTimestamp = false;
      LoggerConfig.showEmoji = false;
      // Pinned explicitly so these tests cannot silently change meaning
      // if a shipped default is ever flipped again.
      LoggerConfig.keyPlacement = KeyPlacement.inline;
      LoggerConfig.levelStyle = LevelStyle.full;
      LoggerConfig.locationPlacement = LocationPlacement.inline;
      LoggerConfig.collapseRepeats = false;
    });

    test('formats with source location (fileUri)', () {
      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello world',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
          column: 10,
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(output, contains('[INFO]'));
      expect(output, contains('Hello world'));
      expect(
        output,
        contains(
          'file:///Users/akshay/app/lib/main.dart:42',
        ),
      );
    });

    test('formats with bareAbsolute format', () {
      LoggerConfig.clickableLinkFormat = LinkFormat.bareAbsolute;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(
        output,
        contains('/Users/akshay/app/lib/main.dart:42'),
      );
      expect(output, isNot(contains('file://')));
    });

    test('projectRelative is deprecated and falls back to fileUri', () {
      // ignore: deprecated_member_use
      LoggerConfig.clickableLinkFormat = LinkFormat.projectRelative;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
        ),
      );

      final output = ConsoleFormatter.format(record);
      // Falls back to fileUri form, wrapped in parens at end of line.
      expect(
        output,
        endsWith('(file:///Users/akshay/app/lib/main.dart:42:1)'),
      );
    });

    test('formats with column number when enabled', () {
      LoggerConfig.showColumnNumber = true;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
          column: 10,
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(output, contains(':42:10'));
    });

    test('formats with member name when enabled', () {
      LoggerConfig.showMemberName = true;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
          member: 'MyWidget.build',
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(output, contains('MyWidget.build'));
    });

    test('useClickableLinks=false omits the location segment', () {
      LoggerConfig.useClickableLinks = false;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(output, isNot(contains('main.dart')));
      // No parenthesised source-location segment anywhere. Narrower than
      // banning every paren, which would break the moment a message or a
      // repeat summary legitimately contains one.
      expect(
        output,
        isNot(matches(RegExp(r'\([^)]*\.dart[^)]*\)'))),
      );
      expect(output, contains('Hello'));
    });

    test('formats without source location', () {
      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
      );

      final output = ConsoleFormatter.format(record);
      expect(output, contains('[INFO]'));
      expect(output, contains('Hello'));
      expect(output, isNot(contains('file://')));
    });

    test('formats with key', () {
      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hello',
        key: 'TestKey',
      );

      final output = ConsoleFormatter.format(record);
      expect(output, contains('@TestKey'));
    });

    test('formatPlain produces no ANSI codes', () {
      LoggerConfig.useColors = true;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.error,
        message: 'Error occurred',
        source: SourceLocation(
          filePath: '/Users/akshay/app/lib/main.dart',
          line: 42,
        ),
      );

      final output = ConsoleFormatter.formatPlain(record);
      expect(output, isNot(contains('\x1B[')));
    });

    test('packageUri renders package: URIs verbatim', () {
      LoggerConfig.clickableLinkFormat = LinkFormat.packageUri;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'App starting',
        source: SourceLocation(
          filePath: 'package:my_app/main.dart',
          line: 25,
          column: 5,
        ),
      );

      LoggerConfig.showColumnNumber = true;
      final output = ConsoleFormatter.format(record);
      expect(
        output,
        endsWith('(package:my_app/main.dart:25:5)'),
      );
    });

    test('packageUri falls back to fileUri for file: URIs', () {
      LoggerConfig.clickableLinkFormat = LinkFormat.packageUri;

      final record = LogRecord(
        time: DateTime(2024, 1, 1, 12, 34, 56),
        level: LogLevel.info,
        message: 'Hi',
        source: SourceLocation(
          filePath: '/abs/test/widget_test.dart',
          line: 10,
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(
        output,
        endsWith('(file:///abs/test/widget_test.dart:10:1)'),
      );
    });

    test('column falls back to 1 when not present and not shown', () {
      // showColumnNumber = false (the setUp default).
      final record = LogRecord(
        time: DateTime(2024, 1, 1),
        level: LogLevel.info,
        message: 'm',
        source: SourceLocation(
          filePath: '/x/lib/y.dart',
          line: 7,
          column: 99,
        ),
      );
      final output = ConsoleFormatter.format(record);
      // Real column is suppressed; renderer emits :1.
      expect(output, endsWith(':7:1)'));
    });

    test('location segment text is contiguous even with colors enabled', () {
      LoggerConfig.useColors = true;
      final record = LogRecord(
        time: DateTime(2024, 1, 1),
        level: LogLevel.error,
        message: 'boom',
        source: SourceLocation(
          filePath: '/abs/lib/main.dart',
          line: 1,
        ),
      );
      final output = ConsoleFormatter.format(record);

      // What the IDE link scanners need is that the segment's TEXT is
      // one unbroken run — no escape sequence between the parentheses.
      // Styling around the outside is fine; the console strips it before
      // scanning. This is the assertion that must never regress.
      expect(
        output,
        contains(
          '${LoggerConfig.locationStyle}'
          '(file:///abs/lib/main.dart:1:1)'
          '\x1B[0m',
        ),
      );
      // Nothing follows the closing parenthesis but the reset.
      expect(output, endsWith('(file:///abs/lib/main.dart:1:1)\x1B[0m'));
    });

    test('parenthesised segment is at end-of-line', () {
      final record = LogRecord(
        time: DateTime(2024, 1, 1),
        level: LogLevel.info,
        message: 'msg',
        source: SourceLocation(
          filePath: 'package:my_app/main.dart',
          line: 3,
        ),
      );
      final output = ConsoleFormatter.format(record);
      expect(output.endsWith(')'), isTrue);
      // No characters after the closing paren.
      expect(RegExp(r'\)[^)]+$').hasMatch(output), isFalse);
    });
  });

  group('Logger integration', () {
    setUp(() {
      LoggerConfig.reset();
      LoggerConfig.enabled = true;
      LoggerConfig.showSourceLocation = true;
      LoggerConfig.showFilePath = true;
      LoggerConfig.showLineNumber = true;
      LoggerConfig.showColumnNumber = false;
      LoggerConfig.showMemberName = false;
      LoggerConfig.useClickableLinks = true;
      LoggerConfig.clickableLinkFormat = LinkFormat.auto;
      LoggerConfig.useColors = false;
      LoggerConfig.showTimestamp = false;
      LoggerConfig.showEmoji = false;
      LoggerConfig.onRecord = null;
      LoggerConfig.formatter = null;
      LoggerConfig.minLevel = LogLevel.debug;
      LoggerConfig.clearHistory();
    });

    test('Logger.info captures source location', () {
      LogRecord? captured;
      LoggerConfig.onRecord = (r) => captured = r;

      Logger.info('hello');

      expect(captured, isNotNull);
      expect(captured!.source, isNotNull);
      // The source should point to this test file, not logger.dart
      expect(
        captured!.source!.filePath,
        isNot(contains('inline_logger/src')),
      );
    });

    test('extension .logDebug captures source location', () {
      LogRecord? captured;
      LoggerConfig.onRecord = (r) => captured = r;

      'test value'.logDebug('x');

      expect(captured, isNotNull);
      expect(captured!.source, isNotNull);
      expect(
        captured!.source!.filePath,
        isNot(contains('inline_logger/src')),
      );
    });

    test('extension .logInfo captures source location', () {
      LogRecord? captured;
      LoggerConfig.onRecord = (r) => captured = r;

      42.logInfo('count');

      expect(captured, isNotNull);
      expect(captured!.source, isNotNull);
    });

    test('extension methods return original value', () {
      LoggerConfig.onRecord = (_) {};

      expect('hello'.log('key'), 'hello');
      expect(42.logDebug('num'), 42);
      expect(true.logInfo('bool'), true);
      expect([1, 2, 3].logSuccess('list'), [1, 2, 3]);
      expect('warn'.logWarning('w'), 'warn');
      expect('err'.logError('e'), 'err');
      expect('crit'.logCritical('c'), 'crit');
      expect('verb'.logVerbose('v'), 'verb');
    });

    test('warning/error/critical save to history', () {
      Logger.warning('warn msg');
      Logger.error('err msg');
      Logger.critical('crit msg');

      expect(LoggerConfig.logHistory, hasLength(3));
      expect(
        LoggerConfig.logHistory[0].level,
        LogLevel.warning,
      );
      expect(
        LoggerConfig.logHistory[1].level,
        LogLevel.error,
      );
      expect(
        LoggerConfig.logHistory[2].level,
        LogLevel.critical,
      );

      // All should have source locations
      for (final record in LoggerConfig.logHistory) {
        expect(record.source, isNotNull);
      }
    });

    test('existing API still works', () {
      // These should all work without errors
      Logger.debug('debug msg');
      Logger.verbose('verbose msg');
      Logger.info('info msg');
      Logger.success('success msg');
      Logger.warning('warning msg');
      Logger.error('error msg');
      Logger.critical('critical msg');
      Logger.divider();
      Logger.divider('Title');
      Logger.header('Header');
      Logger.json({'key': 'value'});
      Logger.navigation('Home', 'Profile');
      Logger.lifecycle('init');
      Logger.lifecycle('init', 'details');
      Logger.state('loading', true);
    });
  });

  group('Windows path handling', () {
    setUp(LoggerConfig.reset);

    test('ConsoleFormatter handles Windows paths in fileUri', () {
      LoggerConfig.clickableLinkFormat = LinkFormat.fileUri;
      LoggerConfig.useColors = false;
      LoggerConfig.showTimestamp = false;
      LoggerConfig.showEmoji = false;

      final record = LogRecord(
        time: DateTime(2024, 1, 1),
        level: LogLevel.info,
        message: 'Hello',
        source: SourceLocation(
          filePath: r'C:\src\app\lib\main.dart',
          line: 42,
        ),
      );

      final output = ConsoleFormatter.format(record);
      expect(
        output,
        contains('file:///C:/src/app/lib/main.dart:42'),
      );
    });
  });

  group('Console layout (0.3.0)', () {
    late LogRecord record;

    setUp(() {
      LoggerConfig.reset();
      LoggerConfig.enabled = true;
      LoggerConfig.useColors = false;
      record = LogRecord(
        time: DateTime(2026, 7, 21, 14, 23, 28, 751),
        level: LogLevel.info,
        message: 'Hello world',
        key: 'TestKey',
        source: SourceLocation(
          filePath: 'package:my_app/main.dart',
          line: 42,
          column: 23,
        ),
      );
    });

    test('every shortLabel is exactly 3 columns wide', () {
      for (final level in LogLevel.values) {
        expect(level.shortLabel.length, 3, reason: level.name);
      }
      // The long labels are untouched, so custom formatters and the
      // LevelStyle.full path keep working.
      expect(LogLevel.info.label, 'INFO');
    });

    test('shipped default: no timestamp, short level, key in the gutter', () {
      final output = ConsoleFormatter.format(record);
      expect(output, 'INF Hello world (package:my_app/main.dart:42:23)');
      // The key is carried by dev.log(name:), not by the line itself.
      expect(output, isNot(contains('@TestKey')));
      // Real captured column, not a hardcoded :1.
      expect(output, endsWith(':42:23)'));
    });

    test('timestampStyle.clock renders HH:mm:ss.SSS', () {
      LoggerConfig.showTimestamp = true;
      final output = ConsoleFormatter.format(record);
      expect(output, startsWith('14:23:28.751 '));
      expect(output, matches(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3} ')));
    });

    test('timestampStyle.iso restores the 0.2.x string', () {
      LoggerConfig.showTimestamp = true;
      LoggerConfig.timestampStyle = TimestampStyle.iso;
      final output = ConsoleFormatter.format(record);
      expect(output, startsWith('[${record.time.toIso8601String()}] '));
    });

    test('timestampStyle.none wins over showTimestamp', () {
      LoggerConfig.showTimestamp = true;
      LoggerConfig.timestampStyle = TimestampStyle.none;
      expect(ConsoleFormatter.format(record), startsWith('INF '));
    });

    test('levelStyle.full restores [INFO]; none omits the token', () {
      LoggerConfig.levelStyle = LevelStyle.full;
      expect(ConsoleFormatter.format(record), startsWith('[INFO] '));

      LoggerConfig.levelStyle = LevelStyle.none;
      expect(ConsoleFormatter.format(record), startsWith('Hello world '));
    });

    test('default scope colours the whole line but not the location', () {
      LoggerConfig.useColors = true;
      final output = ConsoleFormatter.format(record);

      expect(
        output,
        '${LogLevel.info.color}INF Hello world\x1B[0m'
        ' \x1B[90m(package:my_app/main.dart:42:23)\x1B[0m',
      );
    });

    test('locationStyle dims the segment without breaking its text', () {
      LoggerConfig.useColors = true;

      // The segment's text is one unbroken run between the escapes.
      expect(
        ConsoleFormatter.format(record),
        endsWith('\x1B[90m(package:my_app/main.dart:42:23)\x1B[0m'),
      );

      LoggerConfig.locationStyle = '';
      expect(
        ConsoleFormatter.format(record),
        endsWith(' (package:my_app/main.dart:42:23)'),
      );

      LoggerConfig.locationStyle = AnsiColors.dim;
      expect(
        ConsoleFormatter.format(record),
        endsWith('\x1B[2m(package:my_app/main.dart:42:23)\x1B[0m'),
      );
    });

    test('locationStyle is ignored when colours are off', () {
      LoggerConfig.useColors = false;
      expect(
        ConsoleFormatter.format(record),
        'INF Hello world (package:my_app/main.dart:42:23)',
      );
    });

    test('ColorScope.line does not double-style the location', () {
      LoggerConfig.useColors = true;
      LoggerConfig.colorScope = ColorScope.line;
      final output = ConsoleFormatter.format(record);
      // Exactly two escapes: one opening the span, one closing it.
      expect('\x1B['.allMatches(output), hasLength(2));
      expect(output, isNot(contains(AnsiColors.gray)));
    });

    test('ColorScope.level colours only the token', () {
      LoggerConfig.useColors = true;
      LoggerConfig.colorScope = ColorScope.level;
      final output = ConsoleFormatter.format(record);
      expect(output, startsWith('${LogLevel.info.color}INF\x1B[0m '));
      final afterLevel = output.substring(output.lastIndexOf('\x1B[0m') + 4);
      expect(afterLevel, isNot(contains('\x1B[')));
    });

    test('ColorScope.line includes the location in the span', () {
      LoggerConfig.useColors = true;
      LoggerConfig.colorScope = ColorScope.line;
      final output = ConsoleFormatter.format(record);
      expect(
        output,
        '${LogLevel.info.color}INF Hello world'
        ' (package:my_app/main.dart:42:23)\x1B[0m',
      );
    });

    test('every scope is a no-op when useColors is false', () {
      for (final scope in ColorScope.values) {
        LoggerConfig.colorScope = scope;
        LoggerConfig.useColors = false;
        expect(
          ConsoleFormatter.format(record),
          'INF Hello world (package:my_app/main.dart:42:23)',
          reason: scope.name,
        );
      }
    });

    test('colour spans close correctly with no location segment', () {
      LoggerConfig.useColors = true;
      LoggerConfig.useClickableLinks = false;
      const color = '\x1B[34m'; // info
      const reset = '\x1B[0m';

      LoggerConfig.colorScope = ColorScope.body;
      expect(ConsoleFormatter.format(record), '${color}INF Hello world$reset');

      LoggerConfig.colorScope = ColorScope.line;
      expect(ConsoleFormatter.format(record), '${color}INF Hello world$reset');

      // Scope `level` closes its span after the token, so the line ends
      // with the message rather than a reset.
      LoggerConfig.colorScope = ColorScope.level;
      expect(ConsoleFormatter.format(record), '${color}INF$reset Hello world');
    });

    test('ownLine keeps the location out of the body span', () {
      LoggerConfig.useColors = true;
      LoggerConfig.locationPlacement = LocationPlacement.ownLine;
      final output = ConsoleFormatter.format(record);

      final lines = output.split('\n');
      expect(lines.first, '${LogLevel.info.color}INF Hello world\x1B[0m');
      expect(lines.last, '↳ \x1B[90m(package:my_app/main.dart:42:23)\x1B[0m');
      // The prefix stays outside the styled span, and the segment's text
      // is unbroken.
      expect(lines.last, startsWith('↳ '));
    });

    test('emoji renders after the level so the gutter cannot shift', () {
      LoggerConfig.showEmoji = true;
      expect(
        ConsoleFormatter.format(record),
        startsWith('INF ${LogLevel.info.emoji} '),
      );
    });

    test('keyPlacement.inline restores @key', () {
      LoggerConfig.keyPlacement = KeyPlacement.inline;
      expect(ConsoleFormatter.format(record), contains('@TestKey'));
    });

    test('formatPlain always carries the key and is single-line', () {
      LoggerConfig.useColors = true;
      LoggerConfig.locationPlacement = LocationPlacement.ownLine;

      final plain = ConsoleFormatter.formatPlain(record);
      // The key is inline even though keyPlacement sends it to the
      // gutter: a plain-text sink has no gutter to render into.
      expect(plain, contains('@TestKey'));
      expect(plain, isNot(contains('\n')));
      expect(plain, isNot(contains('\x1B[')));
      expect(plain, endsWith('(package:my_app/main.dart:42:23)'));
    });

    test('locationPlacement.ownLine isolates the link on its own row', () {
      LoggerConfig.locationPlacement = LocationPlacement.ownLine;
      final output = ConsoleFormatter.format(record);

      expect('\n'.allMatches(output), hasLength(1));
      final lines = output.split('\n');
      expect(lines.first, 'INF Hello world');
      expect(lines.last, '↳ (package:my_app/main.dart:42:23)');
      // The location is the only .dart token on its line, so nothing in
      // the message can steal VS Code's first-match link.
      expect('.dart'.allMatches(lines.last), hasLength(1));
    });

    test('locationPlacement.none suppresses the segment', () {
      LoggerConfig.locationPlacement = LocationPlacement.none;
      final output = ConsoleFormatter.format(record);
      expect(output, 'INF Hello world');
    });

    test('locationPrefix carries no .dart and ends non-alphanumeric', () {
      // Both rules are enforced by the IDE link scanners, not by us, so
      // pin the shipped default against regression.
      expect(LoggerConfig.locationPrefix, isNot(contains('.dart')));
      expect(
        RegExp(r'[A-Za-z0-9]$').hasMatch(LoggerConfig.locationPrefix),
        isFalse,
      );
    });

    test('renderLocation matches the segment format() appends', () {
      final segment = ConsoleFormatter.renderLocation(record.source!);
      expect(segment, '(package:my_app/main.dart:42:23)');
      expect(ConsoleFormatter.format(record), endsWith(segment!));

      LoggerConfig.useClickableLinks = false;
      expect(ConsoleFormatter.renderLocation(record.source!), isNull);
    });

    test('showColumnNumber=false restores the 0.2.x :1 column', () {
      LoggerConfig.showColumnNumber = false;
      expect(ConsoleFormatter.format(record), endsWith(':42:1)'));
    });

    test('a repeat summary carries no location and no parentheses', () {
      final summary = ConsoleFormatter.formatRepeatSummary(record, 3);
      expect(summary, 'INF ↺ x3 Hello world');
      expect(summary, isNot(contains('main.dart')));
    });

    test('a repeat summary excerpts long messages to one line', () {
      LoggerConfig.repeatSummaryExcerpt = 20;
      final long = LogRecord(
        time: record.time,
        level: LogLevel.error,
        message: 'line one\nline two which runs on and on and on',
      );

      final summary = ConsoleFormatter.formatRepeatSummary(long, 5);
      expect(summary, 'ERR ↺ x5 line one line two wh…');
      expect(summary, isNot(contains('\n')));
    });
  });

  group('Console gutter name', () {
    setUp(LoggerConfig.reset);

    test('the key becomes the gutter under the shipped default', () {
      // The whole point of the tagged-gutter layout: the subsystem name
      // REPLACES the constant prefix rather than following it.
      expect(Logger.resolveLogName('VideoProgressRepo'), 'VideoProgressRepo');
    });

    test('a keyless record falls back to developerLogName', () {
      expect(Logger.resolveLogName(null), 'IL');
      expect(Logger.resolveLogName(''), 'IL');
    });

    test('keyPlacement.inline keeps the gutter constant', () {
      LoggerConfig.keyPlacement = KeyPlacement.inline;
      expect(Logger.resolveLogName('VideoProgressRepo'), 'IL');
    });

    test('a .dart in the key cannot steal the click target', () {
      // The host prepends `[$name] ` BEFORE VS Code scans the line, and
      // Dart-Code linkifies the first `.dart` match — so an unsanitised
      // key would take the click from the real trailing location.
      expect(Logger.resolveLogName('widget_test.dart'), 'widget_test');
      expect(
        Logger.resolveLogName('widget_test.dart'),
        isNot(contains('.dart')),
      );
    });

    test('newlines cannot split the gutter across rows', () {
      expect(Logger.resolveLogName('Repo\nInjected'), 'Repo Injected');
      expect(Logger.resolveLogName('  padded  '), 'padded');
    });

    test('a key that sanitizes to nothing falls back, never to empty', () {
      // dart:developer substitutes the literal `log` for an empty name,
      // which is worse than any fallback we can pick.
      expect(Logger.resolveLogName('.dart'), 'IL');
      expect(Logger.resolveLogName('   '), 'IL');

      LoggerConfig.developerLogName = '.dart';
      expect(Logger.resolveLogName('.dart'), 'IL');
      expect(Logger.resolveLogName(null), 'IL');
    });

    test('a custom developerLogName is honoured', () {
      LoggerConfig.developerLogName = 'InlineLogger';
      expect(Logger.resolveLogName(null), 'InlineLogger');
      LoggerConfig.keyPlacement = KeyPlacement.inline;
      expect(Logger.resolveLogName('Repo'), 'InlineLogger');
    });
  });

  group('Repeat collapsing', () {
    late List<MapEntry<LogRecord, int>> summaries;

    /// Records emitted by the tracker instead of a full console line.
    void sink(LogRecord sample, int suppressed) =>
        summaries.add(MapEntry(sample, suppressed));

    LogRecord at(
      DateTime time, {
      String message = 'sync failed',
      String key = 'Repo',
      LogLevel level = LogLevel.error,
      int line = 176,
    }) =>
        LogRecord(
          time: time,
          level: level,
          message: message,
          key: key,
          source: SourceLocation(
            filePath: 'package:my_app/repo.dart',
            line: line,
          ),
        );

    final t0 = DateTime(2026, 7, 21, 14, 23, 28);

    setUp(() {
      LoggerConfig.reset();
      LoggerConfig.enabled = true;
      LoggerConfig.collapseRepeats = true;
      summaries = [];
    });

    test('disabled by default, and then a pure no-op', () {
      LoggerConfig.reset();
      expect(LoggerConfig.collapseRepeats, isFalse);
      for (var i = 0; i < 5; i++) {
        expect(RepeatTracker.observe(at(t0), sink), isFalse);
      }
      expect(summaries, isEmpty);
    });

    test('identical records after the first are suppressed', () {
      expect(RepeatTracker.observe(at(t0), sink), isFalse);
      expect(
        RepeatTracker.observe(at(t0.add(const Duration(minutes: 1))), sink),
        isTrue,
      );
      expect(
        RepeatTracker.observe(at(t0.add(const Duration(minutes: 2))), sink),
        isTrue,
      );
      expect(RepeatTracker.pendingFor(at(t0)), 2);
      expect(summaries, isEmpty, reason: 'nothing due yet');
    });

    test('records differing in any identity field are distinct', () {
      expect(RepeatTracker.observe(at(t0), sink), isFalse);
      expect(RepeatTracker.observe(at(t0, message: 'other'), sink), isFalse);
      expect(RepeatTracker.observe(at(t0, key: 'Other'), sink), isFalse);
      expect(RepeatTracker.observe(at(t0, line: 177), sink), isFalse);
      expect(
        RepeatTracker.observe(at(t0, level: LogLevel.warning), sink),
        isFalse,
      );
    });

    test('components cannot be forged into a colliding identity', () {
      // A separator-joined identity is forgeable: joined by a space,
      // (key 'A B', message 'C') and (key 'A', message 'B C') produce
      // the same string, so two unrelated logs would share one counter
      // and one of them would be silently swallowed.
      expect(
        RepeatTracker.observe(at(t0, key: 'A B', message: 'C'), sink),
        isFalse,
      );
      expect(
        RepeatTracker.observe(at(t0, key: 'A', message: 'B C'), sink),
        isFalse,
        reason: 'must be a distinct identity, not a suppressed repeat',
      );

      // Same trap one component over.
      expect(
        RepeatTracker.observe(at(t0, key: '', message: 'x y'), sink),
        isFalse,
      );
      expect(
        RepeatTracker.observe(at(t0, key: 'x', message: 'y'), sink),
        isFalse,
      );
    });

    test('a different message flushes the pending count first', () {
      RepeatTracker.observe(at(t0), sink);
      RepeatTracker.observe(at(t0), sink);
      RepeatTracker.observe(at(t0), sink);
      expect(summaries, isEmpty);

      final printed = RepeatTracker.observe(at(t0, message: 'other'), sink);

      expect(printed, isFalse);
      expect(summaries, hasLength(1));
      expect(summaries.single.value, 2);
      expect(summaries.single.key.message, 'sync failed');
      expect(RepeatTracker.pendingFor(at(t0)), 0, reason: 'counter zeroed');
    });

    test('two alternating messages each keep collapsing', () {
      // The interleaved case: a flush must not evict the identities, or
      // neither message would ever collapse.
      RepeatTracker.observe(at(t0, message: 'A'), sink);
      RepeatTracker.observe(at(t0, message: 'B'), sink);

      for (var i = 1; i <= 3; i++) {
        final t = t0.add(Duration(minutes: i));
        expect(RepeatTracker.observe(at(t, message: 'A'), sink), isTrue);
        expect(RepeatTracker.observe(at(t, message: 'B'), sink), isTrue);
      }

      expect(RepeatTracker.pendingFor(at(t0, message: 'A')), 3);
      expect(RepeatTracker.pendingFor(at(t0, message: 'B')), 3);
    });

    test('the window is measured from the first occurrence', () {
      // A 5-minute retry loop must not hold a 10-minute window open
      // forever by refreshing it on every hit.
      expect(RepeatTracker.observe(at(t0), sink), isFalse);
      expect(
        RepeatTracker.observe(at(t0.add(const Duration(minutes: 5))), sink),
        isTrue,
      );

      final reprinted =
          RepeatTracker.observe(at(t0.add(const Duration(minutes: 10))), sink);

      expect(reprinted, isFalse, reason: 'window elapsed, print in full');
      expect(summaries, hasLength(1));
      expect(summaries.single.value, 1);
    });

    test('eviction past repeatMemory emits rather than drops', () {
      LoggerConfig.repeatMemory = 2;

      RepeatTracker.observe(at(t0, message: 'A'), sink);
      RepeatTracker.observe(at(t0, message: 'A'), sink); // pending 1
      RepeatTracker.observe(at(t0, message: 'B'), sink); // flushes A
      expect(summaries.map((e) => e.value), [1]);
      summaries.clear();

      RepeatTracker.observe(at(t0, message: 'B'), sink); // pending 1
      RepeatTracker.observe(at(t0, message: 'C'), sink); // flush + evict A

      expect(summaries.map((e) => e.value), [1]);
      expect(summaries.single.key.message, 'B');
    });

    test('flushRepeats surfaces everything still pending', () {
      RepeatTracker.observe(at(t0), sink);
      RepeatTracker.observe(at(t0), sink);
      RepeatTracker.observe(at(t0), sink);

      RepeatTracker.flushAll(sink);

      expect(summaries, hasLength(1));
      expect(summaries.single.value, 2);
      expect(RepeatTracker.pendingFor(at(t0)), 0);
    });

    test('hooks and history observe 100% of records', () {
      final seen = <LogRecord>[];
      LoggerConfig.onRecord = seen.add;

      for (var i = 0; i < 4; i++) {
        Logger.error('identical failure', 'Repo');
      }

      // Console output may collapse; onRecord and logHistory never do.
      expect(seen, hasLength(4));
      expect(LoggerConfig.logHistory, hasLength(4));
      expect(seen.every((r) => r.repeatCount == 1), isTrue);
    });

    test('a custom formatter disables collapsing entirely', () {
      final formatted = <String>[];
      LoggerConfig.formatter = (r) {
        formatted.add(r.message);
        return r.message;
      };

      for (var i = 0; i < 4; i++) {
        Logger.error('identical failure', 'Repo');
      }

      expect(formatted, hasLength(4));
    });
  });
}
