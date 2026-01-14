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
- 🎨 **Emoji indicators** - Visual log levels (can be disabled)
- ⚡ **Zero performance impact** - Automatically disabled in release mode
- 📊 **Log history** - Store important logs for crash reporting
- 🔍 **Stack trace support** - Capture stack traces for errors
- 🌳 **Widget tree logging** - Log anywhere in your build methods
- ⚙️ **Highly configurable** - Customize timestamps, emojis, log levels

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  inline_logger: ^0.1.0
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

inline_logger supports 7 log levels:

| Level | Emoji | Method | Use Case |
|-------|-------|--------|----------|
| Debug | 🔍 | `.logDebug()` | Debugging information |
| Verbose | 📝 | `.logVerbose()` | Detailed logs |
| Info | ℹ️ | `.logInfo()` | General information |
| Success | ✅ | `.logSuccess()` | Successful operations |
| Warning | ⚠️ | `.logWarning()` | Warnings |
| Error | ❌ | `.logError()` | Errors |
| Critical | 🚨 | `.logCritical()` | Critical failures |

## 🎨 Advanced Features

### Configuration

```dart
// Set minimum log level (only warnings and above)
LoggerConfig.minLevel = LogLevel.warning;

// Disable timestamps
LoggerConfig.showTimestamp = false;

// Disable emojis
LoggerConfig.showEmoji = false;

// Disable logging completely
LoggerConfig.enabled = false;
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

```dart
// Access stored logs (warnings, errors, critical)
final history = LoggerConfig.logHistory;

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
  LoggerConfig.maxHistorySize = 100;

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
