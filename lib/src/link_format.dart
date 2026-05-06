/// Defines how source location links are formatted in console output.
///
/// The IDE-clickable format requires the location to appear at the end
/// of the log line wrapped in parentheses: `(<uri>:<line>:<column>)`.
///
/// Different IDEs recognise different URI schemes. VS Code (Dart-Code)
/// and Android Studio both recognise `package:` and `file:` URIs in the
/// Dart VM stack-trace format.
enum LinkFormat {
  /// Emits `(package:my_app/foo.dart:42:5)` when the source file lives
  /// under `lib/`. Falls back to [fileUri] for files outside `lib/`
  /// (e.g. `test/`, `bin/`).
  ///
  /// This is the recommended format — it is clickable in both VS Code
  /// and Android Studio / IntelliJ.
  packageUri,

  /// Emits `(file:///abs/path/to/foo.dart:42:5)`.
  /// Clickable in VS Code and Android Studio.
  fileUri,

  /// Emits `(/abs/path/to/foo.dart:42:5)` — a bare absolute path.
  /// Kept for IntelliJ users on older plugin versions.
  bareAbsolute,

  /// **Deprecated.** Project-relative paths like `lib/main.dart:42`
  /// are not recognised as clickable links by any IDE.
  ///
  /// When selected, silently upgrades to [packageUri] at runtime.
  @Deprecated(
    'projectRelative paths are not clickable in any IDE. '
    'Use LinkFormat.packageUri or LinkFormat.auto instead.',
  )
  projectRelative,

  /// Auto-detects the best clickable format:
  /// - Uses [packageUri] when the source file is under `lib/`.
  /// - Falls back to [fileUri] for other files.
  /// - On Web, uses whatever URI the stack frame already provides.
  ///
  /// This is the default.
  auto,
}
