import 'package:flutter/foundation.dart';

/// The latest published version, as written in `latest.json` on Drive:
///
/// ```json
/// {
///   "version": "1.1.0",
///   "build": 2,
///   "notes": ["أول تعديل", "تاني تعديل"]
/// }
/// ```
@immutable
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.build,
    required this.notes,
  });

  /// `1.1.0`, like `version:` in pubspec.yaml before the `+`.
  final String version;

  /// `2`, the number after the `+`.
  final int build;

  /// What's new, one change per line.
  final List<String> notes;

  /// Reads the file's JSON. Returns null when it isn't a valid release, so
  /// a broken file never shows a wrong update.
  static ReleaseInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final version = json['version'];
    final build = json['build'];
    final notes = json['notes'];
    if (version is! String || parseVersion(version) == null) return null;
    final buildNumber = build is int
        ? build
        : build is String
        ? int.tryParse(build)
        : null;
    if (buildNumber == null || buildNumber < 0) return null;
    return ReleaseInfo(
      version: version.trim(),
      build: buildNumber,
      notes: [
        if (notes is List)
          for (final n in notes)
            if (n is String && n.trim().isNotEmpty) n.trim(),
      ],
    );
  }

  Map<String, Object> toJson() => {
    'version': version,
    'build': build,
    'notes': notes,
  };

  /// Whether this release is newer than the installed [installedVersion]
  /// and [installedBuild]: a higher version, or the same version with a
  /// higher build number.
  bool isNewerThan(String installedVersion, String installedBuild) {
    final mine = parseVersion(installedVersion);
    final theirs = parseVersion(version);
    if (mine == null || theirs == null) return false;
    for (var i = 0; i < 3; i++) {
      if (theirs[i] != mine[i]) return theirs[i] > mine[i];
    }
    return build > (int.tryParse(installedBuild) ?? 0);
  }

  /// `1.2.3` → `[1, 2, 3]`; missing parts count as 0. Null if not a
  /// version.
  static List<int>? parseVersion(String v) {
    final parts = v.trim().split('.');
    if (parts.isEmpty || parts.length > 3) return null;
    final numbers = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0) return null;
      numbers.add(n);
    }
    while (numbers.length < 3) {
      numbers.add(0);
    }
    return numbers;
  }
}
