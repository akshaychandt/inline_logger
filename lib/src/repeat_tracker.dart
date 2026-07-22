import 'dart:collection';

import 'log_record.dart';
import 'logger_config.dart';

/// Callback used to print a pending repeat summary.
///
/// Receives the first record of the collapsed run and the number of
/// *further* identical occurrences that were suppressed after it.
typedef RepeatSummarySink = void Function(LogRecord sample, int suppressed);

/// Internal, opt-in collapser for identical consecutive log lines.
///
/// Disabled by default ([LoggerConfig.collapseRepeats] is `false`), in
/// which case [observe] returns immediately and output is byte-identical
/// to having no tracker at all.
///
/// **Losslessness.** A suppressed occurrence is never silently dropped:
///
/// * The collapser sits *below* [LoggerConfig.addToHistory] and
///   [LoggerConfig.onRecord] in [Logger.log], so history sinks and
///   crash reporters always observe 100% of records. Only the console
///   line is suppressed.
/// * A pending count is always surfaced as a `↺ xN` summary — when the
///   run's window elapses, when a different message interrupts it, when
///   the entry is evicted from the bounded LRU, or on an explicit
///   [Logger.flushRepeats].
///
/// There is no [Timer] anywhere in this class: everything happens
/// synchronously inside the logging call. That keeps it web-compatible
/// and means it can never fail a `testWidgets` with a pending-timer
/// error.
class RepeatTracker {
  RepeatTracker._();

  /// Insertion-ordered so the first key is the least-recently-used.
  static final LinkedHashMap<String, _Entry> _entries =
      LinkedHashMap<String, _Entry>();

  /// Observes [record] and reports whether its console line should be
  /// suppressed as a repeat.
  ///
  /// [emitSummary] is invoked synchronously, before this call returns,
  /// for every pending count that becomes due.
  static bool observe(LogRecord record, RepeatSummarySink emitSummary) {
    if (!LoggerConfig.collapseRepeats) return false;

    final now = record.time;
    final id = _identity(record);

    _expireStale(now, emitSummary);

    final existing = _entries[id];
    if (existing != null) {
      existing.suppressed += 1;
      _touch(id, existing);
      return true;
    }

    // A message we have not seen this window interrupts every open run,
    // so each summary prints immediately before the line that broke the
    // run rather than drifting to the end of the session.
    _flushPending(emitSummary);

    _touch(id, _Entry(firstSeen: now, sample: record));
    _evictIfNeeded(emitSummary);
    return false;
  }

  /// Emits every pending summary and clears all tracking state.
  static void flushAll(RepeatSummarySink emitSummary) {
    _flushPending(emitSummary);
    _entries.clear();
  }

  /// Drops all tracking state **without** emitting pending summaries.
  ///
  /// Intended for test teardown. In normal operation prefer
  /// [Logger.flushRepeats], which emits first.
  static void reset() => _entries.clear();

  /// The number of occurrences currently suppressed for [record]'s
  /// identity. Exposed for tests.
  static int pendingFor(LogRecord record) =>
      _entries[_identity(record)]?.suppressed ?? 0;

  // ────────────────────────────────────────────────────────────────

  /// A collision-free identity: a real string rather than a hash, so
  /// two unrelated records can never be folded into one counter.
  ///
  /// Each component is length-prefixed rather than joined by a
  /// separator. Any separator can be forged from the components
  /// themselves — with a plain space, `key: 'A B', message: 'C'` and
  /// `key: 'A', message: 'B C'` produce the identical string — whereas a
  /// length-prefixed encoding has exactly one parse.
  static String _identity(LogRecord record) {
    final source = record.source;
    final buffer = StringBuffer();
    for (final part in <String>[
      '${record.level.index}',
      record.key ?? '',
      record.message,
      source?.uri.toString() ?? '',
      '${source?.line ?? -1}',
    ]) {
      buffer
        ..write(part.length)
        ..write(':')
        ..write(part);
    }
    return buffer.toString();
  }

  static bool _withinWindow(DateTime firstSeen, DateTime now) {
    final window = LoggerConfig.repeatWindow;
    if (window <= Duration.zero) return false;
    // `now` can precede `firstSeen` if the host clock steps backwards;
    // treat that as out-of-window so the run restarts cleanly rather
    // than staying open indefinitely.
    final elapsed = now.difference(firstSeen);
    return !elapsed.isNegative && elapsed < window;
  }

  /// Re-insert so [_entries] stays ordered least-recently-used first.
  static void _touch(String id, _Entry entry) {
    _entries.remove(id);
    _entries[id] = entry;
  }

  static void _flush(String id, _Entry entry, RepeatSummarySink emitSummary) {
    _entries.remove(id);
    if (entry.suppressed > 0) {
      emitSummary(entry.sample, entry.suppressed);
    }
  }

  /// Emit the pending count of every tracked identity, then zero the
  /// counters.
  ///
  /// The entries themselves survive, so an identity that alternates with
  /// another message keeps collapsing instead of printing in full every
  /// time the other message interleaves.
  static void _flushPending(RepeatSummarySink emitSummary) {
    if (_entries.isEmpty) return;
    // Snapshot first: `emitSummary` re-enters the logger, which must not
    // be able to mutate the map we are iterating.
    final pending = <MapEntry<LogRecord, int>>[];
    for (final entry in _entries.values) {
      if (entry.suppressed == 0) continue;
      pending.add(MapEntry(entry.sample, entry.suppressed));
      entry.suppressed = 0;
    }
    for (final entry in pending) {
      emitSummary(entry.key, entry.value);
    }
  }

  static void _expireStale(DateTime now, RepeatSummarySink emitSummary) {
    if (_entries.isEmpty) return;
    final stale = <String>[];
    for (final entry in _entries.entries) {
      if (!_withinWindow(entry.value.firstSeen, now)) stale.add(entry.key);
    }
    for (final id in stale) {
      final entry = _entries[id];
      if (entry != null) _flush(id, entry, emitSummary);
    }
  }

  static void _evictIfNeeded(RepeatSummarySink emitSummary) {
    final limit = LoggerConfig.repeatMemory;
    if (limit <= 0) {
      flushAll(emitSummary);
      return;
    }
    while (_entries.length > limit) {
      final oldest = _entries.keys.first;
      final entry = _entries[oldest]!;
      // In the current call order `_flushPending` always runs immediately
      // before this, so an evicted entry cannot still be carrying a
      // count. The flush stays anyway: it is the invariant that matters,
      // not the call order that happens to satisfy it today.
      _flush(oldest, entry, emitSummary);
    }
  }
}

class _Entry {
  _Entry({required this.firstSeen, required this.sample});

  /// When this run started. The window is measured from here.
  final DateTime firstSeen;

  /// The first record of the run, reused to render the summary.
  final LogRecord sample;

  /// Occurrences suppressed *after* [sample] was printed.
  int suppressed = 0;
}
