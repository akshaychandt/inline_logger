import 'log_level.dart';
import 'logger.dart';

/// Extension on any type to enable inline logging.
///
/// Every extension method captures the call-site source location
/// automatically through [Logger.log], so log output includes
/// IDE-clickable links to the line where the extension was called.
extension InlineLogger<E> on E {
  /// Log with default debug level.
  ///
  /// Example:
  /// ```dart
  /// final result = apiCall().log('API Response');
  /// ```
  E log([String key = '', LogLevel level = LogLevel.debug]) {
    Logger.log(this, key, level: level);
    return this;
  }

  /// Log as debug.
  E logDebug([String key = '']) {
    Logger.debug(this, key);
    return this;
  }

  /// Log as verbose.
  E logVerbose([String key = '']) {
    Logger.verbose(this, key);
    return this;
  }

  /// Log as info.
  E logInfo([String key = '']) {
    Logger.info(this, key);
    return this;
  }

  /// Log as success.
  E logSuccess([String key = '']) {
    Logger.success(this, key);
    return this;
  }

  /// Log as warning.
  E logWarning([String key = '']) {
    Logger.warning(this, key);
    return this;
  }

  /// Log as error.
  E logError([String key = '']) {
    Logger.error(this, key);
    return this;
  }

  /// Log as critical.
  E logCritical([String key = '']) {
    Logger.critical(this, key);
    return this;
  }
}
