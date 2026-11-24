import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:my_guide/core/supabase/supabase_config.dart';
import 'package:my_guide/features/seasons/data/season_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the seasonal themes on the phone, so they work without internet.
///
/// [refresh] reads the active themes from Supabase (REST, so it also works
/// in the background task), keeps the ones that matter now
/// ([SeasonTheme.isWanted]: on, or starting within [window] days), downloads
/// their images and saves both. Everything else is removed from the phone.
/// With no internet it only removes what's no longer wanted.
class SeasonStore {
  SeasonStore._();

  static const _themesKey = 'season_themes';
  static const _imagesKey = 'season_images';
  static const _notesKey = 'season_notes_seen';
  static const _hijriOffsetKey = 'hijri_offset';

  /// How many days ahead a theme (or its countdown) is downloaded.
  static const window = 15;

  static const _timeout = Duration(seconds: 15);

  /// The saved themes.
  static List<SeasonTheme> readThemes(SharedPreferences prefs) {
    final raw = prefs.getString(_themesKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final j in list)
          if (SeasonTheme.fromJson(j) case final t?) t,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The saved images, by bucket path.
  static Map<String, Uint8List> readImages(SharedPreferences prefs) {
    final raw = prefs.getString(_imagesKey);
    if (raw == null) return const {};
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const {};
      return {
        for (final e in map.entries)
          if (e.key is String && e.value is String)
            e.key as String: base64Decode(e.value as String),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Days added to the Hijri date (`app_config.hijri_offset`), as last read.
  static int hijriOffset(SharedPreferences prefs) =>
      prefs.getInt(_hijriOffsetKey) ?? 0;

  /// Whether the note dialog of [slug] was already shown.
  static bool noteSeen(SharedPreferences prefs, String slug) =>
      (prefs.getStringList(_notesKey) ?? const []).contains(slug);

  static Future<void> markNoteSeen(SharedPreferences prefs, String slug) {
    final seen = prefs.getStringList(_notesKey) ?? const [];
    if (seen.contains(slug)) return Future.value();
    return prefs.setStringList(_notesKey, [...seen, slug]);
  }

  /// Drops what's no longer wanted on [today], without the internet.
  static Future<void> prune(SharedPreferences prefs, DateTime today) async {
    final saved = readThemes(prefs);
    final keep = [
      for (final t in saved)
        if (t.isWanted(today, window: window)) t,
    ];
    if (keep.length == saved.length) return;
    await _save(prefs, keep, readImages(prefs));
  }

  /// Reads the themes from Supabase and saves what's wanted on [today].
  /// False when Supabase couldn't be read (nothing saved is lost then,
  /// except themes that are over).
  static Future<bool> refresh(SharedPreferences prefs, DateTime today) async {
    await _refreshHijriOffset(prefs);
    final rows = await _getJson(
      Uri.parse('${SupabaseConfig.url}/rest/v1/themes').replace(
        queryParameters: {
          'select': '*',
          'is_active': 'eq.true',
          'ends_on': 'gte.${_iso(today)}',
        },
      ),
    );
    if (rows is! List) {
      await prune(prefs, today);
      return false;
    }
    final themes = [
      for (final r in rows)
        if (SeasonTheme.fromJson(r) case final t?)
          if (t.isWanted(today, window: window)) t,
    ];
    final images = Map.of(readImages(prefs));
    for (final path in {for (final t in themes) ...t.images}) {
      if (images.containsKey(path)) continue;
      final bytes = await _getBytes(
        Uri.parse(
          '${SupabaseConfig.url}/storage/v1/object/public/themes/$path',
        ),
      );
      // A missing image just leaves that spot plain; it's tried again
      // next time.
      if (bytes != null) images[path] = bytes;
    }
    await _save(prefs, themes, images);
    return true;
  }

  static Future<void> _refreshHijriOffset(SharedPreferences prefs) async {
    final rows = await _getJson(
      Uri.parse('${SupabaseConfig.url}/rest/v1/app_config').replace(
        queryParameters: {'select': 'hijri_offset', 'id': 'eq.1'},
      ),
    );
    if (rows is! List || rows.isEmpty || rows.first is! Map) return;
    final offset = (rows.first as Map)['hijri_offset'];
    if (offset is int && offset.abs() <= 2) {
      await prefs.setInt(_hijriOffsetKey, offset);
    }
  }

  static Future<void> _save(
    SharedPreferences prefs,
    List<SeasonTheme> themes,
    Map<String, Uint8List> images,
  ) async {
    final used = {for (final t in themes) ...t.images};
    if (themes.isEmpty) {
      await prefs.remove(_themesKey);
      await prefs.remove(_imagesKey);
      return;
    }
    await prefs.setString(
      _themesKey,
      jsonEncode([for (final t in themes) t.toJson()]),
    );
    await prefs.setString(
      _imagesKey,
      jsonEncode({
        for (final e in images.entries)
          if (used.contains(e.key)) e.key: base64Encode(e.value),
      }),
    );
  }

  static Future<Object?> _getJson(Uri uri) async {
    final bytes = await _getBytes(uri, apiKey: true);
    if (bytes == null) return null;
    try {
      return jsonDecode(utf8.decode(bytes));
    } catch (_) {
      return null;
    }
  }

  /// GETs [uri]. Null on any failure; never throws.
  static Future<Uint8List?> _getBytes(Uri uri, {bool apiKey = false}) async {
    if (!SupabaseConfig.isConfigured) return null;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(uri).timeout(_timeout);
      if (apiKey) request.headers.set('apikey', SupabaseConfig.publishableKey);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(_timeout)) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } catch (e) {
      debugPrint('Season themes: $uri failed: $e');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
