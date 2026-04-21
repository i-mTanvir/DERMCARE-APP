class SupabaseConfig {
  static const String _defaultUrl = 'https://zzwwbirgbyquqxsrvewy.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6d3diaXJnYnlxdXF4c3J2ZXd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3MDQ1ODMsImV4cCI6MjA5MjI4MDU4M30.y9mYu_0sfWpkD6Jk2DRNO1tFLpl8_ikSo3R-QnNRxFU';

  static const String _urlFromDefine = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKeyFromDefine =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url => _urlFromDefine.isNotEmpty ? _urlFromDefine : _defaultUrl;
  static String get anonKey =>
      _anonKeyFromDefine.isNotEmpty ? _anonKeyFromDefine : _defaultAnonKey;

  static void validate() {
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing Supabase configuration. Set SUPABASE_URL and SUPABASE_ANON_KEY '
        'or keep defaults in SupabaseConfig.',
      );
    }
  }
}
