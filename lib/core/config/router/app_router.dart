import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../features/auth/screens/signup_screen.dart';
import '../../../shared/screens/splash_screen.dart';
import '../../../shared/screens/loading_screen.dart';
import '../../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../../features/dashboard/screens/operator_dashboard_screen.dart';
import '../../../features/dashboard/screens/user_dashboard_screen.dart';

// Provider para el router
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/loading',
    routes: [
      // Rutas de autenticación
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Rutas de carga y splash
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Rutas de dashboard según el rol
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/operator-dashboard',
        builder: (context, state) => const OperatorDashboardScreen(),
      ),
      GoRoute(
        path: '/user-dashboard',
        builder: (context, state) => const UserDashboardScreen(),
      ),
    ],
    
    // Lógica de redirección basada en el estado de autenticación
    redirect: (context, state) {
      // Verificar si hay error en el estado de autenticación
      final hasAuthError = authState.error != null;
      
      // Si hay un error de autenticación y el usuario está en una ruta de autenticación,
      // no redirigir (mantener en la misma página)
      if (hasAuthError) {
        final isAuthRoute = state.uri.toString() == '/login' || state.uri.toString() == '/signup';
        if (isAuthRoute) {
          return null; // Mantener en la ruta actual
        }
        // Si tiene error pero no está en ruta de autenticación, redirigir a login
        return '/login';
      }

      // Rutas accesibles sin autenticación
      final isPublicRoute = state.uri.toString() == '/loading' || 
                           state.uri.toString() == '/splash' || 
                           state.uri.toString() == '/login' || 
                           state.uri.toString() == '/signup';

      // Si la app está cargando, permitir la ruta /loading
      if (state.uri.toString() == '/loading') {
        return null;
      }
      
      // Durante la carga del estado de autenticación, mantener la ruta actual
      if (authState.isLoading) {
        return null;
      }

      // Si el usuario no está autenticado y no es una ruta pública, redirigir a login
      if (!authState.isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      // Si el usuario está autenticado y está en una ruta pública, redirigir al dashboard según su rol
      if (authState.isAuthenticated && isPublicRoute && state.uri.toString() != '/loading') {
        final user = authState.user;
        if (user != null) {
          if (user.isAdmin) {
            return '/admin-dashboard';
          } else if (user.isOperator) {
            return '/operator-dashboard';
          } else {
            return '/user-dashboard';
          }
        }
      }

      // En cualquier otro caso, permitir la navegación
      return null;
    },
    
    // Configuración adicional para el router
    debugLogDiagnostics: true,
  );
});