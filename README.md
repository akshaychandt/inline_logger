# inline_logger

**A powerful inline logger for Flutter that lets you log anywhere in your widget tree without breakpoints.**

[![pub package](https://img.shields.io/pub/v/inline_logger.svg)](https://pub.dev/packages/inline_logger)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Maintained by Akshay Chand T ([akshaychandt](https://github.com/akshaychandt))

## ✨ Why inline_logger?

Traditional logging requires you to break your code flow, add print statements, and often rebuild your UI. With `inline_logger`, you can **log any value inline** - directly in your widget tree, method chains, or anywhere else - without disrupting your code!

```dart
// ❌ Traditional way
final userName = user.name;
print('User name: $userName');
return Text(userName);

// ✅ With inline_logger
return Text(user.name.log('User name'));
```

## 🚀 Features

- 🔗 **Chainable inline logging** - Log any value without breaking code flow
- 🎯 **Multiple log levels** - Debug, Verbose, Info, Success, Warning, Error, Critical
- 📍 **Clickable source locations** - IDE-clickable links to the exact call site
- 🧹 **Low-noise by default** - ~24 columns of chrome, not ~74, so your message stops wrapping
- 🏷️ **Tag in the IDE's own gutter** - your subsystem name *replaces* the log prefix instead of following it
- 🎨 **Color-coded output** - Different colors for each log level in console
- 🎨 **Emoji indicators** - Visual log levels (opt-in)
- ↺ **Repeat collapsing** - fold a retry loop's identical lines into `↺ xN` (opt-in, lossless)
- ⚡ **Zero performance impact** - Automatically disabled in release mode
- 📊 **Log history** - Store important logs for crash reporting
- 🔍 **Stack trace support** - Capture stack traces for errors
- 🌳 **Widget tree logging** - Log anywhere in your build methods
- 🔌 **Extensibility hooks** - Custom formatters and record sinks
- ⚙️ **Highly configurable** - Customize timestamps, emojis, colors, log levels

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  inline_logger: ^0.3.0
```

Then run:

```bash
flutter pub get
```

## 🎯 Quick Start

### Import the package

```dart
import 'package:inline_logger/inline_logger.dart';
```

### Basic Usage

#### 1. Inline Widget Tree Logging

The most powerful feature - log directly in your widget tree:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // Log user data inline without breaking the widget tree
      Text(userData.log('User data').name),

      // Log calculations inline
      Text('Total: ${(price * quantity).logInfo('Calculated total')}'),

      // Chain multiple logs
      Text(user.log('Full user').email.logDebug('Email address')),
    ],
  );
}
```

#### 2. Method Chaining

```dart
// Chain logs on any expression
final result = apiCall()
  .log('API Response')
  .data
  .logSuccess('Data extracted')
  .firstWhere((item) => item.id == 5)
  .logDebug('Found item');
```

#### 3. Direct Logging Methods

```dart
Logger.debug('Debugging info');
Logger.info('General information');
Logger.success('Operation completed successfully!');
Logger.warning('Warning message');
Logger.error('Error occurred', 'Context', stackTrace);
Logger.critical('Critical failure!');
```

## 📚 Log Levels

inline_logger supports 7 log levels with color-coded output:

| Level | Color | Emoji | Method | Use Case |
|-------|-------|-------|--------|----------|
| Debug | Gray | 🔍 | `.logDebug()` | Debugging information |
| Verbose | Cyan | 📝 | `.logVerbose()` | Detailed logs |
| Info | Blue | ℹ️ | `.logInfo()` | General information |
| Success | Green | ✅ | `.logSuccess()` | Successful operations |
| Warning | Yellow | ⚠️ | `.logWarning()` | Warnings |
| Error | Red | ❌ | `.logError()` | Errors |
| Critical | Bright Red | 🚨 | `.logCritical()` | Critical failures |

## 🎨 Advanced Features

### Configuration

```dart
// Set minimum log level (only warnings and above)
LoggerConfig.minLevel = LogLevel.warning;

// Timestamps — off by default, because DevTools and both IDE consoles
// render their own time column. Turn them on for a plain terminal.
LoggerConfig.showTimestamp = true;
LoggerConfig.timestampStyle = TimestampStyle.clock;  // 14:23:28.751
LoggerConfig.timestampStyle = TimestampStyle.iso;    // the 0.2.x form

// Level token — a fixed-width 3-char abbreviation by default, so the
// message always starts at the same column.
LoggerConfig.levelStyle = LevelStyle.short;  // ERR
LoggerConfig.levelStyle = LevelStyle.full;   // [ERROR]
LoggerConfig.levelStyle = LevelStyle.none;

// Emojis — off by default. Severity is already carried by the colour
// and the level token, and emoji cell widths differ between levels,
// which is what stops columns from lining up.
LoggerConfig.showEmoji = true;

// Enable/disable color-coded output.
LoggerConfig.useColors = true; // Default is true

// How much of the line the level's colour covers.
LoggerConfig.colorScope = ColorScope.body;   // default: whole line
                                             // except the location
LoggerConfig.colorScope = ColorScope.line;   // include the location
LoggerConfig.colorScope = ColorScope.level;  // only the ERR/WRN token

// The trailing location is dimmed so it recedes. Without this it renders
// in the console's default foreground — a bright amber in the VS Code
// Debug Console, which makes the least important part of the line the
// loudest. Set to '' to leave it un-styled.
LoggerConfig.locationStyle = AnsiColors.gray;  // default

// Disable logging completely
LoggerConfig.enabled = false;

// Reset every field to its shipped default (also clears history).
LoggerConfig.reset();
```

### Where the tag comes from

`dart:developer` renders a `[name] ` gutter on every log line, and the prefix cannot be removed — an empty name is substituted with the literal `log` by the SDK debug adapter, Dart-Code, flutter-intellij and DevTools alike. So inline_logger puts it to work: by default your log's **key becomes the gutter**, replacing the constant prefix rather than following it.

```dart
Logger.error('syncPending failed', 'VideoProgressRepo');
// [VideoProgressRepo] ERR syncPending failed (package:my_app/repo.dart:176:7)
//  ^^^^^^^^^^^^^^^^^ drawn by the console host — costs zero columns of
//                    the line's own width, and gives DevTools per-
//                    subsystem filtering via `k:VideoProgressRepo`
```

Records with no key fall back to `LoggerConfig.developerLogName` (`'IL'`). To get the 0.2.x `@key` form back:

```dart
LoggerConfig.keyPlacement = KeyPlacement.inline;
LoggerConfig.developerLogName = 'IL';
// [IL] ERR @VideoProgressRepo syncPending failed (package:…:176:7)
```

### Collapsing repeated logs

A retry loop or polling timer that logs the same failure every few minutes fills the console with identical lines. Opt in to collapse them:

```dart
LoggerConfig.collapseRepeats = true;
LoggerConfig.repeatWindow = const Duration(minutes: 10);

// [VideoProgressRepo] ERR syncPending failed (package:…/repo.dart:176:7)
// [VideoProgressRepo] ERR ↺ x3 syncPending failed
```

Suppression is **console-only and lossless**:

- `onRecord` and `logHistory` run *above* the collapser and always see 100% of records, so Crashlytics/Sentry forwarding is unaffected.
- A pending count is never discarded — it is surfaced as a `↺ xN` summary when the window elapses, when a different message interrupts the run, when the entry is evicted past `repeatMemory`, or on an explicit `Logger.flushRepeats()`.
- The window is measured from a run's **first** occurrence, so a message repeating every 5 minutes reports in every 10 rather than staying hidden forever.
- It is skipped entirely whenever `LoggerConfig.formatter` is set.

### Console recipes

```dart
// ── Android Studio / IntelliJ ────────────────────────────────────────
// The IntelliJ Run console does not decode ANSI for dart:developer.log,
// so colours arrive as literal escape codes. Trade them for emoji.
LoggerConfig.useColors = false;
LoggerConfig.showEmoji = true;

// ── Plain `flutter run` terminal ─────────────────────────────────────
// No timestamp column of its own, so add one.
LoggerConfig.showTimestamp = true;

// ── Bullet-proof click-to-source ─────────────────────────────────────
LoggerConfig.locationPlacement = LocationPlacement.ownLine;

// ── Noisy retry loops ────────────────────────────────────────────────
LoggerConfig.collapseRepeats = true;

// ── Quiet: keep logs, drop the paths ─────────────────────────────────
LoggerConfig.useClickableLinks = false;

// ── Restore the 0.2.x look ───────────────────────────────────────────
LoggerConfig.developerLogName = 'InlineLogger';
LoggerConfig.keyPlacement = KeyPlacement.inline;
LoggerConfig.showTimestamp = true;
LoggerConfig.timestampStyle = TimestampStyle.iso;
LoggerConfig.levelStyle = LevelStyle.full;
LoggerConfig.showEmoji = true;
LoggerConfig.showColumnNumber = false;
// Note: the emoji now renders *after* the level token rather than
// before it, so that it cannot shift the fixed-width gutter.
```

### 📍 Clickable Source Locations

Every log line automatically includes the **exact call site** (file path + line + column) appended at end-of-line in parentheses. Click it in your IDE's Run/Debug console to jump straight to that line.

```
[MyRepo] INF Counter updated → 5 (package:my_app/main.dart:42:23)
```

The leading `[MyRepo] ` gutter is drawn by the console host, not by this package — see [Where the tag comes from](#where-the-tag-comes-from).

**No extra arguments needed** — source location is captured automatically via `StackTrace.current`, and the package intelligently skips its own internal frames to find your code.

#### What the IDE link scanners actually require

The trailing `(...)` segment is un-styled (no ANSI) and is always the last thing on its physical line, because that is what the two scanners need:

- **VS Code (Dart-Code)** requires both `:line:column` — a bare `main.dart:42` is not linkified. It matches the **first** `.dart` occurrence on a line, so a `.dart` substring earlier in your message wins instead. Set `LoggerConfig.locationPlacement = LocationPlacement.ownLine` to make the match unambiguous.
- **IntelliJ / Android Studio** treats the column as optional, but requires a non-alphanumeric character immediately before the `package:` / `file:` scheme — which is what the opening parenthesis provides.

Both resolve `package:` URIs through your package config, so eliding directories inside one breaks resolution and kills the link. The location is therefore never abbreviated.

#### Where the location goes

```dart
// Default — appended to the message line.
LoggerConfig.locationPlacement = LocationPlacement.inline;
// INF Counter updated → 5 (package:my_app/main.dart:42:23)

// On its own row. Costs a line, but makes the link bullet-proof: no
// `.dart` in your message can steal it, and the row can never exceed
// Dart-Code's 1000-character parse limit (which `Logger.json` does hit).
LoggerConfig.locationPlacement = LocationPlacement.ownLine;
// INF Counter updated → 5
// ↳ (package:my_app/main.dart:42:23)

// Omit it entirely (same as useClickableLinks = false).
LoggerConfig.locationPlacement = LocationPlacement.none;
```

#### Link Formats

For frames under `lib/` — which is nearly all of them — `auto`, `packageUri`, `fileUri` and `projectRelative` all emit the **same** `package:` string. Only `bareAbsolute` differs, and only for non-`package:` URIs such as files under `test/`.

```dart
// Recommended default — package: URIs are clickable in both VS Code and
// Android Studio. Falls back to fileUri for files outside lib/.
LoggerConfig.clickableLinkFormat = LinkFormat.auto;

// Explicit package URI (same fallback behaviour as `auto`).
LoggerConfig.clickableLinkFormat = LinkFormat.packageUri;
// Output: (package:my_app/main.dart:42:23)

// Absolute file URI — clickable in both VS Code and Android Studio.
LoggerConfig.clickableLinkFormat = LinkFormat.fileUri;
// Output: (file:///Users/akshay/app/lib/main.dart:42:23)

// Bare absolute path — kept for older IntelliJ plugin versions.
// Not clickable in VS Code, which requires a URI scheme.
LoggerConfig.clickableLinkFormat = LinkFormat.bareAbsolute;
// Output: (/Users/akshay/app/lib/main.dart:42:23)

// Deprecated: project-relative paths are NOT clickable in any IDE.
// Silently falls back to packageUri/fileUri.
// LoggerConfig.clickableLinkFormat = LinkFormat.projectRelative;
```

#### Source Location Configuration

```dart
// Master switch (default: true in debug, false in release)
LoggerConfig.showSourceLocation = true;

// These two have no *individual* effect — a clickable link needs both a
// path and a line, so only the both-false case suppresses the segment.
// To hide it, use useClickableLinks or LocationPlacement.none.
LoggerConfig.showFilePath = true;
LoggerConfig.showLineNumber = true;

// The rendered string ALWAYS includes `:column` (VS Code requires it).
// This flag controls only whether that column is the real one from the
// stack frame (`true`, the default since 0.3.0) or a forced `:1`.
LoggerConfig.showColumnNumber = true;

LoggerConfig.showMemberName = false;    // Off by default

// Omit the location segment from the rendered string entirely.
// The location is still attached to `LogRecord.source` for
// `onRecord` / `logHistory` consumers.
LoggerConfig.useClickableLinks = false;
```

#### Zero-Cost in Production

Source location capture is **completely free in release builds**. `StackTrace.current` is never called unless both `LoggerConfig.enabled` and `LoggerConfig.showSourceLocation` are true, and the message passes the `minLevel` filter. Filter first, capture second.

### Color-Coded Console Output

inline_logger automatically adds ANSI color codes to your console output, making it easy to distinguish between different log levels at a glance:

- **Debug** logs appear in gray
- **Verbose** logs appear in cyan
- **Info** logs appear in blue
- **Success** logs appear in green
- **Warning** logs appear in yellow
- **Error** logs appear in red
- **Critical** logs appear in bright red

By default the colour covers the whole line up to the clickable location, which stays un-styled so IDE link scanners can match it:

```
\x1B[31mERR boom\x1B[0m (package:app/main.dart:9:4)
```

The location carries its own dim style (`LoggerConfig.locationStyle`, gray by default) so it recedes rather than competing with the message. Both spans sit strictly outside the parentheses, so the segment's text reaches the IDE link scanners as one unbroken run.

`ColorScope.line` extends the level's span over the location too; `ColorScope.level` narrows it to just the `ERR` token. Note that an ANSI reset returns the foreground to the terminal default, which is *not* necessarily the colour a console uses for un-styled text — that is why an un-styled location shows up amber in the VS Code Debug Console, and why `ColorScope.level` renders the text before and after the token in two different colours.

Colors work in most modern IDEs and terminals that support ANSI escape codes. You can disable colors if needed:

```dart
LoggerConfig.useColors = false;
```

### 🔌 Extensibility Hooks

#### Custom Record Sink

Forward every log record to external services:

```dart
LoggerConfig.onRecord = (record) {
  // Forward to Crashlytics
  FirebaseCrashlytics.instance.log(record.message);

  // Forward to Sentry
  Sentry.addBreadcrumb(Breadcrumb(message: record.message));

  // Access full metadata
  print('Level: ${record.level}');
  print('Source: ${record.source}');
  print('Time: ${record.time}');
};
```

#### Custom Formatter

Replace the built-in console formatter:

```dart
LoggerConfig.formatter = (record) {
  // Use renderLocation so the segment stays IDE-clickable — it applies
  // the mandatory `:line:column` and the URI rules for you. Building
  // the string by hand is how you end up with a dead link.
  final source = record.source != null
      ? ' ${ConsoleFormatter.renderLocation(record.source!)}'
      : '';
  return '${record.level.label}: ${record.message}$source';
};
```

Note that setting a custom formatter also disables repeat collapsing, so your formatter always receives every record.

### API Logging

```dart
// Log API requests
Logger.apiRequest(
  endpoint: '/api/users',
  method: 'POST',
  headers: {'Authorization': 'Bearer token'},
  body: {'name': 'John'},
);

// Log API responses with duration
Logger.apiResponse(
  endpoint: '/api/users',
  statusCode: 200,
  data: responseData,
  duration: Duration(milliseconds: 234),
);
```

### Navigation Logging

```dart
Logger.navigation('HomeView', 'ProfileView');
```

### State Logging

```dart
Logger.state('isLoading', true);
Logger.state('userData', userObject);
```

### Lifecycle Logging

```dart
Logger.lifecycle('initState', 'ViewModel initialized');
Logger.lifecycle('dispose', 'Cleaning up resources');
```

### Log History

Log history now stores full `LogRecord` objects with source locations:

```dart
// Access stored logs (warnings, errors, critical)
final history = LoggerConfig.logHistory;

// Each record includes source location
for (final record in history) {
  print('${record.level}: ${record.message}');
  print('Source: ${record.source}');
}

// Clear history
LoggerConfig.clearHistory();

// Configure history size
LoggerConfig.maxHistorySize = 50;
```

### Structured Logging

```dart
Logger.header('USER AUTHENTICATION');
Logger.info('Starting process...');
Logger.success('Completed!');
Logger.divider();
```

## 💡 Real-World Examples

### ViewModel with inline logging

```dart
class HomeViewModel extends ChangeNotifier {
  List<User> _users = [];

  Future<void> loadUsers() async {
    Logger.header('LOAD USERS');

    _isLoading = true.logState('isLoading');
    notifyListeners();

    try {
      final stopwatch = Stopwatch()..start();

      Logger.apiRequest(endpoint: '/api/users', method: 'GET');

      final response = await _api.getUsers();

      stopwatch.stop();
      Logger.apiResponse(
        endpoint: '/api/users',
        statusCode: 200,
        data: response,
        duration: stopwatch.elapsed,
      );

      _users = response.logSuccess('Users loaded');

    } catch (e, stackTrace) {
      Logger.error('Failed to load users: $e', 'Error', stackTrace);
    } finally {
      _isLoading = false.logState('isLoading');
      notifyListeners();
      Logger.divider();
    }
  }
}
```

### Widget with inline logging

```dart
@override
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: items.length.log('Item count'),
    itemBuilder: (context, index) {
      final item = items[index].logDebug('Current item');

      return ListTile(
        title: Text(item.name.log('Item name')),
        subtitle: Text(item.price.toString().logInfo('Price')),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailView(
              id: item.id.log('Selected item ID'),
            ),
          ),
        ).then((_) => Logger.navigation('DetailView', 'HomeView')),
      );
    },
  );
}
```

## 🔧 Configuration Guide

### Production Setup

```dart
void main() {
  // Disable in production
  if (kReleaseMode) {
    LoggerConfig.enabled = false;
  }

  // Or set minimum level to only show errors
  LoggerConfig.minLevel = LogLevel.error;

  runApp(MyApp());
}
```

### Development Setup

```dart
void main() {
  // Show everything in debug
  LoggerConfig.minLevel = LogLevel.debug;
  LoggerConfig.useColors = true;
  LoggerConfig.maxHistorySize = 100;

  // Add a timestamp if your console has no time column of its own.
  LoggerConfig.showTimestamp = true;

  // Source locations are enabled by default in debug mode
  // Customize format for your IDE:
  LoggerConfig.clickableLinkFormat = LinkFormat.auto;

  runApp(MyApp());
}
```

## 📖 API Reference

### Extension Methods (Chainable)

All these methods can be chained on any object:

- `.log([String key, LogLevel level])` - Log with custom level
- `.logDebug([String key])` - Log as debug
- `.logVerbose([String key])` - Log as verbose
- `.logInfo([String key])` - Log as info
- `.logSuccess([String key])` - Log as success
- `.logWarning([String key])` - Log as warning
- `.logError([String key])` - Log as error
- `.logCritical([String key])` - Log as critical

### Static Methods

- `Logger.debug(value, [name])` - Log debug
- `Logger.verbose(value, [name])` - Log verbose
- `Logger.info(value, [name])` - Log info
- `Logger.success(value, [name])` - Log success
- `Logger.warning(value, [name])` - Log warning
- `Logger.error(value, [name, stackTrace])` - Log error
- `Logger.critical(value, [name, stackTrace])` - Log critical
- `Logger.apiRequest({...})` - Log API request
- `Logger.apiResponse({...})` - Log API response
- `Logger.navigation(from, to)` - Log navigation
- `Logger.state(name, value)` - Log state change
- `Logger.lifecycle(event, [details])` - Log lifecycle event
- `Logger.divider([title])` - Log divider
- `Logger.header(title)` - Log header
- `Logger.flushRepeats()` - Emit any pending `↺ xN` repeat summaries immediately

### New Types

- `SourceLocation` - Represents a source code location. Stores the original `Uri` (so `package:` URIs are preserved verbatim) plus line, optional column, and optional enclosing member. The legacy `filePath` getter and string constructor remain for back-compat.
- `SourceLocationResolver` - Resolves call sites from stack traces
- `LinkFormat` - Enum for IDE-clickable link formats
- `LogRecord` - Structured log event record
- `ConsoleFormatter` - Formats LogRecords for console output. `renderLocation` builds a clickable segment; `formatPlain` renders an ANSI-free single line.
- `TimestampStyle` / `LevelStyle` / `LocationPlacement` / `KeyPlacement` - Console layout styles (0.3.0)

### Configuration

- `LoggerConfig.enabled` - Master switch (default: `kDebugMode`)
- `LoggerConfig.minLevel` - Minimum log level
- `LoggerConfig.showTimestamp` - Show timestamps (default: `false`)
- `LoggerConfig.timestampStyle` - `clock` (default) or `iso`
- `LoggerConfig.levelStyle` - `short` (default), `full`, or `none`
- `LoggerConfig.showEmoji` - Show emoji indicators (default: `false`)
- `LoggerConfig.useColors` - ANSI color output
- `LoggerConfig.colorScope` - `body` (default), `line`, or `level`
- `LoggerConfig.locationStyle` - ANSI style for the location segment (default: `AnsiColors.gray`; `''` to disable)
- `LoggerConfig.keyPlacement` - `developerLogName` (default) or `inline`
- `LoggerConfig.developerLogName` - The `[name] ` gutter, and the fallback for keyless records (default: `'IL'`)
- `LoggerConfig.dividerWidth` - Width of `Logger.divider` rules (default: `60`)
- `LoggerConfig.consoleStackTraceFrames` - Frames forwarded to the console (default: `8`; `null` for all)
- `LoggerConfig.showSourceLocation` - Source location capture (default: `kDebugMode`)
- `LoggerConfig.locationPlacement` - `inline` (default), `ownLine`, or `none`
- `LoggerConfig.locationPrefix` - Prefix for the `ownLine` row (default: `'↳ '`)
- `LoggerConfig.showFilePath` / `showLineNumber` - No individual effect; only the both-false case suppresses the location
- `LoggerConfig.showColumnNumber` - Real captured column (default: `true`) vs a forced `:1`
- `LoggerConfig.showMemberName` - Show enclosing member name
- `LoggerConfig.useClickableLinks` - When `false`, omits the location segment entirely
- `LoggerConfig.clickableLinkFormat` - Link format (default: `LinkFormat.auto`)
- ~~`LoggerConfig.linkAnsiStyle`~~ - **Deprecated.** The clickable segment must be un-styled for IDE recognition; this value is no longer applied.
- `LoggerConfig.collapseRepeats` - Collapse identical console lines (default: `false`)
- `LoggerConfig.repeatWindow` / `repeatMemory` / `repeatSummaryExcerpt` - Collapser tuning
- `LoggerConfig.onRecord` - Custom record sink
- `LoggerConfig.formatter` - Custom formatter override
- `LoggerConfig.maxHistorySize` - Max history entries
- `LoggerConfig.reset()` - Restore every field to its shipped default

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits

Created with ❤️ for the Flutter community.

Special thanks to [aswinbbc](https://github.com/aswinbbc) for contributing ideas to this project.

## 📞 Support

- 🐛 [Report bugs](https://github.com/akshaychandt/inline_logger/issues)
- 💡 [Request features](https://github.com/akshaychandt/inline_logger/issues)
- ⭐ [Star on GitHub](https://github.com/akshaychandt/inline_logger)
