class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xbgqeeszwofzbynccbnu.supabase.co',
  );
  static const String publishableKey =
      'sb_publishable_br5CD1WePEPgM9S9a6igDA_KPeuFqCQ';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
