// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/constants/environment.dart';
import 'config/router/app_router.dart';

void main() async {
  // Asegurar que se inicializa Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientación de la app (solo vertical)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar environment (incluso si falla)
  await Environment.initEnvironment();
  
  // Inicializar Supabase con los valores definidos en Environment
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    anonKey: Environment.supabaseAnonKey,
  );
  
  // Ejecutar la app con Riverpod como gestor de estado
  runApp(
    const ProviderScope(
      child: MainApp()
    )
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener el router configurado
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Autotransportes Zaachila-Yoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 33, 150, 243),
          primary: const Color.fromARGB(255, 33, 150, 243),
          secondary: const Color.fromARGB(255, 139, 29, 60), // Rojo burgundy
        ),
        useMaterial3: true,
        // Personalización adicional del tema
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      
      // Usar el router configurado
      routerConfig: router,
    );
  }
}