import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/router/app_router.dart' show routerProvider;
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await initializeSupabase();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    )
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'TransporteTrack',
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colores principales del camión
        primaryColor: const Color(0xFF191970), // Azul Marino Oscuro
        scaffoldBackgroundColor: Colors.white,
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF191970), // Azul Marino Oscuro
          primary: const Color(0xFF191970), // Azul Marino Oscuro
          secondary: const Color(0xFFC71585), // Rojo/Magenta
          tertiary: const Color(0xFFADD8E6), // Azul Cielo
          surface: Colors.white,
          error: const Color(0xFFC71585), // Rojo/Magenta para errores
        ),
        
        // 🎨 TEMA DE ICONOS - NUEVO
        iconTheme: const IconThemeData(
          color: Color(0xFF191970), // Azul Marino Oscuro por defecto
          size: 24,
        ),
        
        // Iconos en AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF191970), // Azul Marino Oscuro
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
          iconTheme: IconThemeData(
            color: Colors.white, // Iconos blancos en AppBar
            size: 24,
          ),
          actionsIconTheme: IconThemeData(
            color: Colors.white, // Iconos de acciones blancos
            size: 24,
          ),
        ),
        
        // Botones elevados (botones principales)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF191970), // Azul Marino Oscuro
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            iconColor: Colors.white, // Iconos blancos en botones
          ),
        ),
        
        // Botones de texto
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF191970), // Azul Marino Oscuro
            iconColor: const Color(0xFF191970), // Iconos del mismo color
          ),
        ),
        
        // Botones outlined
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF191970), // Azul Marino Oscuro
            side: const BorderSide(color: Color(0xFF191970)),
            iconColor: const Color(0xFF191970), // Iconos del mismo color
          ),
        ),
        
        // FloatingActionButton
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFC71585), // Rojo/Magenta
          foregroundColor: Colors.white,
          iconSize: 28,
        ),
        
        // Indicador de progreso
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF191970), // Azul Marino Oscuro
        ),
        
        // Inputs/TextFields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF191970), width: 2), // Azul Marino
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFC71585), width: 1.5), // Rojo/Magenta
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFC71585), width: 2), // Rojo/Magenta
          ),
          // Iconos en inputs
          iconColor: Color(0xFF191970), // Azul Marino
          prefixIconColor: Color(0xFF191970), // Azul Marino
          suffixIconColor: Color(0xFF191970), // Azul Marino
        ),
        
        // Colores de texto
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2F4F4F)), // Gris Oscuro
          bodyMedium: TextStyle(color: Color(0xFF2F4F4F)), // Gris Oscuro
          titleLarge: TextStyle(color: Color(0xFF191970)), // Azul Marino
        ),
        
        // Cards
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        
        // ListTile
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF191970), // Azul Marino para iconos en ListTile
        ),
        
        // Chips
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFADD8E6).withOpacity(0.3), // Azul Cielo claro
          labelStyle: const TextStyle(color: Color(0xFF191970)),
          iconTheme: const IconThemeData(
            color: Color(0xFF191970), // Azul Marino
            size: 18,
          ),
        ),
        
        // BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF191970), // Azul Marino
          unselectedItemColor: Color(0xFF2F4F4F), // Gris Oscuro
          selectedIconTheme: IconThemeData(
            color: Color(0xFF191970),
            size: 28,
          ),
          unselectedIconTheme: IconThemeData(
            color: Color(0xFF2F4F4F),
            size: 24,
          ),
        ),
        
        // NavigationRail
        navigationRailTheme: NavigationRailThemeData(
          selectedIconTheme: const IconThemeData(
            color: Color(0xFF191970), // Azul Marino
            size: 28,
          ),
          unselectedIconTheme: IconThemeData(
            color: Colors.grey.shade600,
            size: 24,
          ),
        ),
        
        // Drawer
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
        ),
        
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}