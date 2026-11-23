import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Connects the app to the Wird Supabase project.
///
/// The publishable key (`sb_publishable_...`, or the legacy anon key) is
/// meant to ship inside the app, so it can live here. Paste it from
/// Supabase → Project Settings → API Keys into [_bundledKey], or pass it at
/// build time: `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
/// Never put the secret / service_role key in the app.
///
/// Until a key is set, [init] does nothing and the app works as before
/// (built-in themes only).
abstract final class SupabaseConfig {
  static const url = 'https://eyiwzvfkyhiuuibavwpv.supabase.co';

  static const _bundledKey = 'sb_publishable_N19IiZEn14eZAgLElP-SLw_F3Z8ydsR';

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _bundledKey,
  );

  static bool get isConfigured => publishableKey.isNotEmpty;

  static bool _ready = false;

  /// True after [init] connected; check it before using [client].
  static bool get isReady => _ready;

  static SupabaseClient get client => Supabase.instance.client;

  /// Sets up the client. Needs no internet and never throws: a failure only
  /// leaves [isReady] false, so the app keeps working offline.
  static Future<void> init() async {
    if (!isConfigured || _ready) return;
    try {
      await Supabase.initialize(url: url, publishableKey: publishableKey);
      _ready = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }
}
