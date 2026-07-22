/// Console layout styles that control how much chrome each log line
/// carries before the message itself begins.
///
/// These were introduced in 0.3.0 to cut the fixed prefix down from
/// ~74 columns to ~24, so that real messages stop wrapping.
library;

/// How the timestamp is rendered.
enum TimestampStyle {
  /// Omit the timestamp entirely. Equivalent to
  /// `LoggerConfig.showTimestamp = false`.
  none,

  /// `14:23:28.751` — wall-clock time to millisecond precision, 12
  /// columns, unbracketed. This is the shape used by essentially every
  /// mainstream console renderer.
  ///
  /// The date is dropped because it does not change within a session,
  /// and microseconds are dropped because they are unreadable.
  /// [LogRecord.time] retains full precision for `onRecord`, history
  /// and crash reporters.
  clock,

  /// `[2026-07-21T14:23:28.751343]` — the 0.2.x format, byte for byte.
  /// 29 columns.
  iso,
}

/// How much of the line the level's ANSI colour covers.
///
/// Only applies when [LoggerConfig.useColors] is `true`.
enum ColorScope {
  /// Colour the whole line up to (but not including) the clickable
  /// location segment. This is the default.
  ///
  /// The level's span ends before the location, exactly as in 0.2.x. The
  /// location is not left bare, though: it carries its own
  /// [LoggerConfig.locationStyle] span (dim gray by default). Set
  /// `locationStyle = ''` for the fully bare 0.2.x segment.
  body,

  /// Colour only the level token, leaving timestamp, key and message
  /// un-styled.
  ///
  /// Be aware that an ANSI reset returns the foreground to the
  /// terminal's default, which is not necessarily the colour a console
  /// uses for un-styled output — in the VS Code Debug Console this
  /// makes the text after the token render in a different colour than
  /// the text before it.
  level,

  /// Colour the entire line including the location segment, so the
  /// location takes the level's colour instead of
  /// [LoggerConfig.locationStyle]'s.
  ///
  /// The span is closed and reopened around the joiner, so each physical
  /// line stays independently balanced under
  /// [LocationPlacement.ownLine].
  line,
}

/// How the severity level is rendered.
enum LevelStyle {
  /// Omit the level token. Severity is still carried by ANSI color
  /// (when [LoggerConfig.useColors] is on) and by the emoji (when
  /// [LoggerConfig.showEmoji] is on).
  none,

  /// A fixed-width 3-character token: `DBG VRB INF SUC WRN ERR CRT`.
  ///
  /// Fixed width matters: the 0.2.x `[DEBUG]`…`[CRITICAL]` labels range
  /// from 7 to 10 columns, so the message start column jitters by 4
  /// between levels and the log cannot be scanned as a table.
  short,

  /// `[DEBUG]` … `[CRITICAL]` — the 0.2.x format, byte for byte.
  full,
}

/// Where the IDE-clickable `(<uri>:<line>:<column>)` segment is placed.
enum LocationPlacement {
  /// Appended to the end of the message line, separated by a space.
  /// This is the 0.2.x behaviour.
  inline,

  /// Emitted on its own continuation line, prefixed by
  /// [LoggerConfig.locationPrefix].
  ///
  /// Costs an extra row per log, but makes click-to-source
  /// deterministic: the location is then the only `.dart` token on its
  /// line, so a `.dart` substring inside a message can never steal
  /// VS Code's link (Dart-Code takes the *first* match on a line), and
  /// the line can never exceed Dart-Code's 1000-character parse limit.
  ownLine,

  /// Omit the location segment. A synonym for
  /// `LoggerConfig.useClickableLinks = false`.
  none,
}

/// Where the log's `key` (subsystem tag) is rendered.
enum KeyPlacement {
  /// Rendered in the message body as `@MyKey`. This is the 0.2.x
  /// behaviour.
  inline,

  /// Passed to `dart:developer`'s `log(name:)`, so the IDE renders it
  /// in its own dimmed `[…]` gutter — replacing the constant
  /// `[InlineLogger]` prefix instead of following it.
  ///
  /// This is the cheapest possible way to show the tag: the gutter is
  /// drawn by the console host, so it costs zero columns of the
  /// package's own budget. It also gives DevTools per-subsystem
  /// filtering (`k:VideoProgressRepo`).
  ///
  /// Records with no key fall back to [LoggerConfig.developerLogName].
  ///
  /// Note that under this placement `ConsoleFormatter.format` no longer
  /// contains the key — the host supplies it. `formatPlain` always
  /// includes it, since a plain-text sink has no gutter to render into.
  developerLogName,
}
