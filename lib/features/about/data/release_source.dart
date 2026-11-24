import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:my_guide/core/supabase/supabase_config.dart';
import 'package:my_guide/features/about/data/app_info.dart';
import 'package:my_guide/features/about/data/release_info.dart';

/// Where the app learns about the latest published version.
///
/// The last one read is kept on the phone (`AppVersionCubit`), so a known
/// update still shows offline.
abstract class ReleaseSource {
  /// The latest release, or null when it can't be read (no internet, no
  /// file yet, a broken file). Never throws.
  Future<ReleaseInfo?> latest();
}

/// Reads `latest.json` from a public URL: the raw file on the
/// `new_version` branch on GitHub (`AppInfo.latestReleaseUrl`). An empty
/// [url] means nothing is checked.
class HttpReleaseSource implements ReleaseSource {
  const HttpReleaseSource(
    this.url, {
    this.timeout = const Duration(seconds: 10),
  });

  final String url;
  final Duration timeout;

  @override
  Future<ReleaseInfo?> latest() async {
    if (url.isEmpty) return null;
    final json = await _getJson(Uri.parse(url), timeout: timeout);
    return ReleaseInfo.fromJson(json);
  }
}

/// Reads the latest version from the `app_config` table on Supabase (the
/// one row with `id = 1`: `latest_version`, `latest_build`,
/// `release_notes`). Uses the REST API directly, so it also works in the
/// background task, where the Supabase client isn't set up.
class SupabaseReleaseSource implements ReleaseSource {
  const SupabaseReleaseSource({
    this.url = SupabaseConfig.url,
    this.key = SupabaseConfig.publishableKey,
    this.timeout = const Duration(seconds: 10),
  });

  final String url;
  final String key;
  final Duration timeout;

  @override
  Future<ReleaseInfo?> latest() async {
    if (url.isEmpty || key.isEmpty) return null;
    final rows = await _getJson(
      Uri.parse('$url/rest/v1/app_config').replace(
        queryParameters: {
          'select': 'latest_version,latest_build,release_notes',
          'id': 'eq.1',
        },
      ),
      headers: {'apikey': key},
      timeout: timeout,
    );
    if (rows is! List || rows.isEmpty || rows.first is! Map) return null;
    final row = rows.first as Map;
    return ReleaseInfo.fromJson({
      'version': row['latest_version'],
      'build': row['latest_build'],
      'notes': row['release_notes'],
    });
  }
}

/// Asks each source in order and answers with the first that can be read:
/// Supabase first, then `latest.json` on GitHub if Supabase is down (a
/// free project pauses after a week without use).
class FirstReleaseSource implements ReleaseSource {
  const FirstReleaseSource(this.sources);

  final List<ReleaseSource> sources;

  @override
  Future<ReleaseInfo?> latest() async {
    for (final source in sources) {
      final release = await source.latest();
      if (release != null) return release;
    }
    return null;
  }
}

/// Where the app reads the latest version: Supabase, then GitHub.
const appReleaseSource = FirstReleaseSource([
  SupabaseReleaseSource(),
  HttpReleaseSource(AppInfo.latestReleaseUrl),
]);

/// GETs [uri] and decodes its JSON. Null on any failure; never throws.
Future<Object?> _getJson(
  Uri uri, {
  Map<String, String> headers = const {},
  required Duration timeout,
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(uri).timeout(timeout);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) return null;
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return jsonDecode(body);
  } catch (e) {
    debugPrint('Release check failed ($uri): $e');
    return null;
  } finally {
    client.close(force: true);
  }
}
