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
- 🎨 **Color-coded output** - Different colors for each log level in console
- 🎨 **Emoji indicators** - Visual log levels (can be disabled)
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
  inline_logger: ^0.2.0
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

// Disable timestamps
LoggerConfig.showTimestamp = false;

// Disable emojis
LoggerConfig.showEmoji = false;

// Enable/disable color-coded output
LoggerConfig.useColors = true; // Default is true

// Disable logging completely
LoggerConfig.enabled = false;
```

### 📍 Clickable Source Locations

Every log line automatically includes the **exact call site** (file path + line + column) appended at end-of-line in parentheses — the only format VS Code (Dart-Code) and Android Studio / IntelliJ recognise as clickable. Click the link in your IDE's Run/Debug console to jump directly to that line of source code.

```
[2024-01-01T12:34:56.789] ℹ️ [INFO] Counter updated → 5 (package:my_app/main.dart:42:5)
```

**No extra arguments needed** — source location is captured automatically via `StackTrace.current`, and the package intelligently skips its own internal frames to find your code.

The trailing `(...)` segment is intentionally un-styled (no ANSI), at end-of-line, with a mandatory `:line:column`. Anything else breaks the IDE's stack-frame scanner.

#### Link Formats

```dart
// Recommended default — package: URIs are clickable in both VS Code and
// Android Studio. Falls back to fileUri for files outside lib/.
LoggerConfig.clickableLinkFormat = LinkFormat.auto;

// Explicit package URI (same fallback behaviour as `auto`).
LoggerConfig.clickableLinkFormat = LinkFormat.packageUri;
// Output: (package:my_app/main.dart:42:5)

// Absolute file URI — clickable in both VS Code and Android Studio.
LoggerConfig.clickableLinkFormat = LinkFormat.fileUri;
// Output: (file:///Users/akshay/app/lib/main.dart:42:5)

// Bare absolute path — kept for older IntelliJ plugin versions.
LoggerConfig.clickableLinkFormat = LinkFormat.bareAbsolute;
// Output: (/Users/akshay/app/lib/main.dart:42:5)

// Deprecated: project-relative paths are NOT clickable in any IDE.
// Silently falls back to packageUri/fileUri.
// LoggerConfig.clickableLinkFormat = LinkFormat.projectRelative;
```

#### Source Location Configuration

```dart
// Master switch (default: true in debug, false in release)
LoggerConfig.showSourceLocation = true;

// Show/hide individual components
LoggerConfig.showFilePath = true;
LoggerConfig.showLineNumber = true;
// The rendered string always includes `:column` (IDEs require it). This
// flag controls only whether the column comes from the stack frame
// (`true`) or is forced to `:1` (`false`).
LoggerConfig.showColumnNumber = false;
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
  final source = record.source != null
      ? ' (${record.source!.filePath}:${record.source!.line})'
      : '';
  return '${record.level.label}$source: ${record.message}';
};
```

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
  LoggerConfig.showTimestamp = true;
  LoggerConfig.showEmoji = true;
  LoggerConfig.useColors = true;
  LoggerConfig.maxHistorySize = 100;

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

### New Types

- `SourceLocation` - Represents a source code location. Stores the original `Uri` (so `package:` URIs are preserved verbatim) plus line, optional column, and optional enclosing member. The legacy `filePath` getter and string constructor remain for back-compat.
- `SourceLocationResolver` - Resolves call sites from stack traces
- `LinkFormat` - Enum for IDE-clickable link formats
- `LogRecord` - Structured log event record
- `ConsoleFormatter` - Formats LogRecords for console output

### Configuration

- `LoggerConfig.enabled` - Master switch (default: `kDebugMode`)
- `LoggerConfig.minLevel` - Minimum log level
- `LoggerConfig.showTimestamp` - Show timestamps
- `LoggerConfig.showEmoji` - Show emoji indicators
- `LoggerConfig.useColors` - ANSI color output
- `LoggerConfig.showSourceLocation` - Source location capture (default: `kDebugMode`)
- `LoggerConfig.showFilePath` - Show file path
- `LoggerConfig.showLineNumber` - Show line number
- `LoggerConfig.showColumnNumber` - Show column number
- `LoggerConfig.showMemberName` - Show enclosing member name
- `LoggerConfig.useClickableLinks` - When `false`, omits the location segment entirely
- `LoggerConfig.clickableLinkFormat` - Link format (default: `LinkFormat.auto`)
- ~~`LoggerConfig.linkAnsiStyle`~~ - **Deprecated.** The clickable segment must be un-styled for IDE recognition; this value is no longer applied.
- `LoggerConfig.onRecord` - Custom record sink
- `LoggerConfig.formatter` - Custom formatter override
- `LoggerConfig.maxHistorySize` - Max history entries

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
