## 0.3.0

A console-output release: same API, far less noise per line. The fixed
prefix in front of your message drops from ~74 columns to ~24, so real
messages stop wrapping to three rows.

Before:

```
[InlineLogger] [2026-07-21T14:23:28.751343] ❌ [ERROR] @VideoProgressRepo syncPending failed: … (package:my_app/repo.dart:176:1)
```

After:

```
[VideoProgressRepo] ERR syncPending failed: … (package:my_app/repo.dart:176:7)
```

### Output format changed (no API breaks)

Every existing call signature, field name and type is unchanged. What
changed is what the console prints. Most items below list the one line
that restores the old behaviour; where none is given, the change is not
revertable by configuration.

* **The subsystem tag moved into the console's own gutter.** A record's
  key is now passed to `dart:developer`'s `log(name:)`, so the IDE draws
  `[VideoProgressRepo] ` in the dimmed slot where `[InlineLogger] ` used
  to sit — replacing the prefix instead of following it. Records with no
  key fall back to `LoggerConfig.developerLogName`. This also gives
  DevTools per-subsystem filtering (`k:VideoProgressRepo`) in place of a
  single `k:InlineLogger`.
  Restore: `LoggerConfig.keyPlacement = KeyPlacement.inline;`
* **`developerLogName` is `'IL'`, was `'InlineLogger'`** — 13 columns
  back on every line. The prefix cannot be removed entirely: an empty
  name is substituted with the literal `log` by the SDK debug adapter,
  Dart-Code, flutter-intellij and DevTools alike.
  Restore: `LoggerConfig.developerLogName = 'InlineLogger';`
* **`showTimestamp` defaults to `false`.** DevTools and both IDE
  consoles render their own time column, so an in-line timestamp was
  duplicated information. A plain `flutter run` terminal has no such
  column — turn it back on there.
  Restore: `LoggerConfig.showTimestamp = true;`
* **Timestamps render as `14:23:28.751`, not
  `[2026-07-21T14:23:28.751343]`.** The date does not change within a
  session and microseconds are unreadable. `LogRecord.time` keeps full
  precision for `onRecord`, history and crash reporters.
  Restore: `LoggerConfig.timestampStyle = TimestampStyle.iso;`
* **The level renders as a fixed-width `ERR`, not `[ERROR]`.** The old
  labels ranged from 7 to 10 columns, so the message start column
  jittered by 4 between levels.
  Restore: `LoggerConfig.levelStyle = LevelStyle.full;`
* **`showEmoji` defaults to `false`.** Severity was encoded three times
  over. The emoji is also what prevented columns from aligning: `ℹ️` and
  `⚠️` are a base character plus U+FE0F while `🔍📝✅❌🚨` are single wide
  code points, so their cell widths differ. When re-enabled it now
  renders *after* the level token so it cannot shift the gutter.
  Restore: `LoggerConfig.showEmoji = true;`
* **`showColumnNumber` defaults to `true`.** This flag never controlled
  whether a column was rendered — the string always ends `:line:column`
  because VS Code will not linkify without one. It chose between the
  real captured column and a hardcoded `:1`, and defaulted to throwing
  the real one away. IDE jumps now land on the expression that logged.
  Restore: `LoggerConfig.showColumnNumber = false;`
* **Titled `divider` / `header` rules are 60 columns, were 122+.** A
  titled rule used to be a full 60-column rule on *each* side of the
  title; it is now a single `── title ` padded to 60, so it stops
  wrapping to two rows. Untitled rules were already 60 and are
  unchanged in width, but the glyph is now `─` rather than `=` and both
  forms are dimmed with `locationStyle`. They also now honour
  `kDebugMode` and `minLevel` (see *Fixed*), and `apiRequest` /
  `apiResponse` emit one rule instead of two.
  Adjust: `LoggerConfig.dividerWidth = 122;`
* **Built-in keys are no longer emoji-prefixed.** `@🧭 Navigation`,
  `@🔄 Lifecycle` and `@📊 State: name` become `Nav`, `Lifecycle` and
  `State`; `Logger.state` moves the state name into the message as
  `name = value`. No restore line: these are the literal `LogRecord.key`
  values, so an `onRecord` consumer matching on the old strings must be
  updated.
* **`ConsoleFormatter.format` no longer contains `@key`** under the
  default `keyPlacement`, because the console host draws it.
  `ConsoleFormatter.formatPlain` always includes it.
  Restore: `LoggerConfig.keyPlacement = KeyPlacement.inline;`
* **Stack traces forwarded to the console are capped at 8 frames.**
  0.2.x forwarded the whole trace, which becomes an entire extra
  prefixed block in both IDE consoles. `LogRecord.stackTrace` always
  keeps the full trace for `onRecord`.
  Restore: `LoggerConfig.consoleStackTraceFrames = null;`
* **`ConsoleFormatter.formatPlain` now always carries a full ISO
  timestamp** and flattens newlines in the message, so
  `logHistoryStrings` stays one self-describing line per record even
  though `showTimestamp` defaults to `false` for the console.
* **`logHistoryStrings` renders through `ConsoleFormatter.formatPlain`.**
  It previously returned `LogRecord(time: …, level: …)` debug dumps,
  matching neither the console output nor 0.1.x's format.

### Added

* `TimestampStyle`, `LevelStyle`, `LocationPlacement`, `KeyPlacement`,
  `ColorScope` — the console layout knobs behind the changes above.
* `LoggerConfig.colorScope` — how much of the line the level colour
  covers. The default, `ColorScope.body`, is unchanged from 0.2.x: the
  whole line is coloured except the trailing location, which must stay
  un-styled for the IDE link scanners. `ColorScope.line` extends the
  span over the location too; `ColorScope.level` narrows it to just the
  `ERR` token. Be aware that an ANSI reset returns the foreground to the
  terminal default, which is not necessarily the colour a console uses
  for un-styled text — under `ColorScope.level` the VS Code Debug
  Console renders the text before and after the token in two different
  colours.
* `LoggerConfig.locationStyle` (default `AnsiColors.gray`) — dims the
  trailing location segment so it recedes. Previously it was left
  un-styled, which means the console's default foreground — a bright
  amber in the VS Code Debug Console — making the least important part
  of the line the loudest thing on it. The escapes sit strictly outside
  the parentheses, so the segment's text stays contiguous for the IDE
  link scanners. Set to `''` for the old un-styled behaviour.
  `Logger.divider` / `header` rules are dimmed with the same style.
* `LocationPlacement.ownLine` — puts the clickable location on its own
  `↳ ` row, configurable via `LoggerConfig.locationPrefix`. Costs a row
  per log, and in exchange the link becomes deterministic (see *Fixed*).
* `LogLevel.shortLabel` — the fixed-width 3-character token. `label` is
  untouched and still returns `'INFO'`.
* `LoggerConfig.consoleStackTraceFrames` (default `8`) — caps the stack
  trace forwarded to the console, which otherwise becomes an entire
  extra prefixed block. `<asynchronous suspension>` markers are kept and
  do not count against the limit, so the budget is spent on real frames
  — but a trace whose application frame sits below more than 8 framework
  frames will still have it trimmed away; raise or disable the cap for
  those. `LogRecord.stackTrace` always keeps the full trace.
* **Opt-in repeat collapsing** (`LoggerConfig.collapseRepeats`, default
  `false`), with `repeatWindow`, `repeatMemory` and
  `repeatSummaryExcerpt`. Folds a retry loop's identical lines into a
  single line plus a `↺ xN` summary. Lossless by construction:
  `onRecord` and `logHistory` run above the collapser and always see
  100% of records; a pending count is always surfaced, never dropped
  (on the next log after the window elapses, or via
  `Logger.flushRepeats()` — there is no timer);
  and the collapser is skipped entirely when `formatter` is set. There
  is no `Timer` involved, so it is web-safe and cannot leave a
  `testWidgets` with a pending timer.
* `Logger.flushRepeats()` — emit pending `↺ xN` summaries immediately.
* `LogRecord.repeatCount` — how many occurrences a summary stands for.
* `Logger.log`'s named `error:` parameter, forwarded to
  `LogRecord.error`, which had no way to be populated before.
* `ConsoleFormatter.renderLocation(source)` — build a correctly-formed
  clickable segment from a custom `formatter`, and
  `ConsoleFormatter.formatRepeatSummary(record, count)`.
* `LoggerConfig.reset()` — restore every field to its shipped default;
  `LoggerConfig.resetRepeatTracking()` for the collapser alone.
* `Logger.resolveLogName(key)` (`@visibleForTesting`) — exposes the
  gutter-name resolution so it can be unit-tested; `dev.log` output is
  not otherwise observable from a test.

### Fixed

* **Click-to-source could be silently stolen.** VS Code's Dart-Code
  linkifies the *first* `.dart` match on a line, so a message mentioning
  a `.dart` file — or a key like `widget_test.dart` landing in the
  gutter — took the click instead of the real location. Keys are now
  sanitised before reaching `log(name:)`, and
  `LocationPlacement.ownLine` removes the ambiguity entirely.
* **Long lines lost their link.** Dart-Code will not parse a line beyond
  1000 characters, which `Logger.json` routinely exceeds.
  `LocationPlacement.ownLine` keeps the location well under the cap.
* **`divider` / `header` bypassed both gates.** They ignored `minLevel`,
  so `minLevel = error` still printed every rule, and they ignored
  `kDebugMode`, so a release build with `enabled` forced true printed
  rules while every real log was suppressed.
* **`Logger.lifecycle(event, details)` discarded `event`** whenever
  `details` was supplied. It now renders `event — details`.
* **DevTools' timestamp drifted from `LogRecord.time`.** `dev.log` now
  receives `time:` explicitly instead of stamping its own
  `DateTime.now()` microseconds later.

### Erratum for 0.2.0

0.2.0 claimed "no breaking changes to existing API". That was wrong:
`LoggerConfig.logHistory` changed from `List<String>` to
`List<LogRecord>`, which is a breaking type change. `logHistoryStrings`
was added as the string-typed replacement. The 0.2.0 example
`(package:my_app/main.dart:25:5)` also never rendered with a real column
under that release's defaults — it emitted `:25:1`. As of 0.3.0 it does.

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
