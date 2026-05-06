## 0.2.0

* **Clickable source locations** — Every log line now includes the exact
  call site appended at end-of-line in parentheses as
  `(<uri>:<line>:<column>)` — the only format VS Code (Dart-Code) and
  Android Studio / IntelliJ recognise as clickable. Clicking the link
  jumps directly to that line of source code.
  Example: `... App starting (package:my_app/main.dart:25:5)`.
* The trailing parenthesised segment is intentionally un-styled (no ANSI)
  so the IDE's stack-frame scanner matches it; level color still applies
  to the rest of the line.
* New `SourceLocation` class — stores the original `Uri` (so `package:`
  URIs are preserved verbatim) plus line, optional column, and optional
  enclosing member. Exposes a backwards-compatible `filePath` getter and
  string-based constructor.
* New `SourceLocationResolver` to automatically capture call sites via
  `StackTrace.current`, skipping internal package frames.
* New `LinkFormat` enum:
  - `packageUri` — emits `package:foo/bar.dart` URIs verbatim.
  - `fileUri` — emits `file:///abs/path` URIs.
  - `bareAbsolute` — emits `/abs/path` (kept for older IntelliJ versions).
  - `auto` (default) — picks `packageUri` for `package:` frames and
    `fileUri` otherwise.
  - `projectRelative` — **deprecated**. Project-relative paths are not
    clickable in any IDE; silently falls back to the file URI form.
* New `LogRecord` data class bundling all log event metadata.
* New `LoggerConfig` flags:
  - `showSourceLocation` — Master switch (default: `true` in debug).
  - `showFilePath`, `showLineNumber`, `showMemberName`.
  - `showColumnNumber` — the rendered string always includes a column
    (IDEs require it); this flag controls whether the column comes from
    the stack frame (`true`) or is forced to `:1` (`false`).
  - `useClickableLinks` — when `false`, omits the location segment
    entirely. The location is still attached to `LogRecord.source` for
    `onRecord` / `logHistory` consumers.
  - `clickableLinkFormat` — Choose link format (default: `auto`).
* New extensibility hooks:
  - `LoggerConfig.onRecord` — Sink for forwarding records to Crashlytics,
    Sentry, DevTools, etc.
  - `LoggerConfig.formatter` — Custom formatter override.
* `LoggerConfig.logHistory` now stores `LogRecord` objects with full
  metadata including source locations.
* Extracted `ConsoleFormatter` for testability and customization.
* Refactored source into separate files under `lib/src/`.
* **Zero-cost guarantee**: `StackTrace.current` is only invoked after
  passing both `enabled` and `minLevel` filters.
* No breaking changes to existing API. All existing call signatures,
  flags, and behavior remain identical.

## 0.1.0+2

* Added color-coded console output with ANSI color codes
* Different colors for each log level (gray, cyan, blue, green, yellow, red, bright red)
* New `LoggerConfig.useColors` configuration option
* Updated documentation with color feature information

## 0.1.0+1

* Updated README with maintainer information
* Added credits for contributors

## 0.1.0

* Initial release
* Inline chainable logging for Flutter
* 7 log levels (Debug, Verbose, Info, Success, Warning, Error, Critical)
* Extension methods for inline logging
* Static logging methods
* API request/response logging
* Navigation, state, and lifecycle logging
* Log history support
* Stack trace support for errors
* Configurable timestamps and emojis
* Auto-disabled in release mode
