import 'package:flutter_test/flutter_test.dart';
import 'package:inline_logger/inline_logger.dart';

void main() {
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
      expect(LoggerConfig.showFilePath, isTrue);
      expect(LoggerConfig.showLineNumber, isTrue);
      expect(LoggerConfig.showColumnNumber, isFalse);
      expect(LoggerConfig.showMemberName, isFalse);
      expect(LoggerConfig.useClickableLinks, isTrue);
      expect(
        LoggerConfig.clickableLinkFormat,
        LinkFormat.auto,
      );
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
      expect(output, isNot(contains('(')));
      expect(output, isNot(contains(')')));
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

    test('location segment has no ANSI codes even with colors enabled', () {
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
      // The trailing parenthesised segment must not be inside the
      // colored body — it must come after the reset escape.
      final reset = '\x1B[0m';
      final resetIdx = output.indexOf(reset);
      expect(resetIdx, greaterThan(0));
      final tail = output.substring(resetIdx + reset.length);
      expect(tail, isNot(contains('\x1B[')));
      expect(tail, contains('(file:///abs/lib/main.dart:1:1)'));
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
}
