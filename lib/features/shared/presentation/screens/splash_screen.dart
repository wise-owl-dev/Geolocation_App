// features/shared/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simular tiempo de carga y luego navegar
    Future.delayed(const Duration(seconds: 2), () {
      _checkFirstTime();
    });
  }
  
  // Verificar si es la primera vez que se abre la app
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final firstTime = !(prefs.getBool('first_time_completed') ?? false);
    
    if (!mounted) return;
    
    if (firstTime) {
      // Es la primera vez, marcar como ya visto
      await prefs.setBool('first_time_completed', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 33, 150, 243), // AZUL más oscuro
              Color.fromARGB(255, 195, 223, 245), // AZUL más claro
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Sección superior con imagen
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    'assets/images/splash_image.png', // Cambia a un asset local
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_bus,
                        size: 120,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              
              // Sección inferior blanca
              Container(
                padding: const EdgeInsets.all(32.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Transporte Público\nModerno',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Viaja de manera eficiente y segura\ncon nuestro sistema de transporte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navegar a la pantalla de login usando go_router
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Comenzar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}