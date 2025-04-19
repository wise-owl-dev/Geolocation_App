// config/constants/environment.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static bool _initialized = false;

  static Future<void> initEnvironment() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
    } catch (e) {
      print('No se pudo cargar el archivo .env: $e');
      // Continuamos de todos modos, usando valores por defecto
    }
  }

  // Supabase
  static String get supabaseUrl {
    return 'https://ghpwbyyzwnfezokjqida.supabase.co';
  }

  static String get supabaseAnonKey {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdocHdieXl6d25mZXpva2pxaWRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM1NjE2MzUsImV4cCI6MjA1OTEzNzYzNX0.3MHKF75qCfH-VHJPteK96AtWGwUARPwYxT-Bn_IE8t0';
  }

  // Mapbox (para mapas)
  static String get mapboxAccessToken {
    return dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? 'tu-token-mapbox';
  }

  // Configuración general
  static String get appName {
    return 'TransporteTrack';
  }

  // Determinar si estamos en desarrollo
  static bool get isDevelopment {
    return true; // Valor fijo para desarrollo
  }
}
