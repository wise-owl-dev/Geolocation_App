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
    return '';
  }

  static String get supabaseAnonKey {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3cWdweWNqcmhzZWFsa3JncmpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUwOTkyMzAsImV4cCI6MjA2MDY3NTIzMH0.4WUUqp0CRLN--CmT0tZ-T0aZOukLa1J_s85Uqz1T3QE';
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
