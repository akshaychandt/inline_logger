/// A powerful inline logger for Flutter that lets you log anywhere
/// in your widget tree without breakpoints.
/// Chain logging calls directly on any expression.
///
/// **Key Features:**
/// - 🔗 **Chainable logging** - Log any value inline without breaking
///   your code flow
/// - 🎯 **Multiple log levels** - Debug, Verbose, Info, Success,
///   Warning, Error, Critical
/// - 🎨 **Emoji support** - Visual log levels with optional emoji
///   indicators
/// - ⚡ **Zero performance impact** - Automatically disabled in
///   release mode
/// - 📊 **Log history** - Store important logs for crash reporting
/// - 🔍 **Stack trace support** - Capture stack traces for errors
///
/// ## Quick Start
///
/// ```dart
/// import 'package:inline_logger/inline_logger.dart';
///
/// // Log anywhere in your widget tree
/// Text(userData.log('User data').name)
///
/// // Chain multiple logs
/// final result = apiCall()
///   .log('API Response')
///   .data
///   .logSuccess('Data extracted');
///
/// // Use direct logging methods
/// Logger.error('Something went wrong', 'Error context');
/// Logger.apiRequest(endpoint: '/users', method: 'GET');
/// ```
library;

export 'src/inline_logger.dart';
