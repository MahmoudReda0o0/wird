import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:my_guide/features/about/data/release_info.dart';

/// Where the app learns about the latest published version.
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
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return ReleaseInfo.fromJson(jsonDecode(body));
    } catch (e) {
      debugPrint('Release check failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
