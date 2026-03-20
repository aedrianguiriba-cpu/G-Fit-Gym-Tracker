import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Debug logging utility - only prints in debug mode
void _log(String message) {
  if (kDebugMode) {
    print(message);
  }
}

class SupabaseService {
  static late final SupabaseClient supabaseClient;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      _log('✅ Supabase already initialized');
      return;
    }

    try {
      // Load environment variables from .env file
      _log('⚠️ Loading .env file...');
      await dotenv.load(fileName: '.env');
      _log('✅ .env file loaded');

      final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      _log('Supabase URL: ${supabaseUrl.isNotEmpty ? 'Found' : 'MISSING'} ');
      _log('Supabase Key: ${supabaseAnonKey.isNotEmpty ? 'Found' : 'MISSING'} ');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception(
          '\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '❌ SUPABASE CONFIGURATION MISSING\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
          '\n'
          'Your .env file is missing values!\n'
          '\n'
          'Location: G-Fit-Gym-Tracker/.env\n'
          '\n'
          'Required Content:\n'
          'SUPABASE_URL=https://your-project-id.supabase.co\n'
          'SUPABASE_ANON_KEY=your_anon_key_from_dashboard\n'
          '\n'
          'Steps to fix:\n'
          '1. Go to https://app.supabase.com/projects\n'
          '2. Select your project\n'
          '3. Go to Settings → API\n'
          '4. Copy the Project URL (full URL starting with https://)\n'
          '5. Copy the Anon Key (long string starting with eyJ)\n'
          '6. Update your .env file with these values\n'
          '7. Save the file\n'
          '8. Run: flutter clean && flutter pub get && flutter run\n'
          '\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        );
      }

      _log('\ud83d\udd04 Initializing Supabase with provider: ${supabaseUrl.substring(8, 20)}...');
      
      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      supabaseClient = Supabase.instance.client;
      _isInitialized = true;
      _log('\u2705 Supabase initialized successfully!');
    } catch (error) {
      _log('\u274c Supabase initialization error:');
      _log('   Type: ${error.runtimeType}');
      _log('   Message: $error');
      rethrow;
    }
  }

  static SupabaseClient getClient() {
    if (!_isInitialized) {
      throw StateError(
        'Supabase has not been initialized yet. '
        'Call await SupabaseService.initialize() first.',
      );
    }
    return supabaseClient;
  }

  static bool get isInitialized => _isInitialized;
}
