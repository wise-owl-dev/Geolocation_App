import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255,33,150,243), // AZUL más oscuro
               // AZUL más claro
              Color.fromARGB(255, 195, 223, 245)
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
                    'assets/splash_image.png', // Cambia a un asset local
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_bus,
                        size: 700,
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
                        onPressed: ()=> context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255,33,150,243),
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