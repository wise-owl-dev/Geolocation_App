
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/admin/screens/bus/add_bus_screen.dart';
import '../../../features/admin/screens/bus/list_buses_screen.dart';
import '../../../features/admin/screens/bus_stop/add_busstop_screen.dart';
import '../../../features/admin/screens/bus_stop/list_busstops_screen.dart';
import '../../../features/admin/screens/operator/add_operator_screen.dart';
import '../../../features/admin/screens/operator/list_operators_screen.dart';
import '../../../features/admin/screens/route/add_route_screen.dart';
import '../../../features/admin/screens/route/list_routes_screen.dart';
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
      
      // Rutas de administrador
      GoRoute(
        path: '/admin/operators',
        builder: (context, state) => const OperatorsListScreen(),
      ),
      GoRoute(
        path: '/admin/add-operator',
        builder: (context, state) => const AddOperatorScreen(),
      ),
      GoRoute(
        path: '/admin/edit-operator/:id',
        builder: (context, state) {
          final operatorId = state.pathParameters['id'];
          return AddOperatorScreen(operatorId: operatorId);
        },
      ),

       // Rutas de administrador para autobuses
      GoRoute(
        path: '/admin/buses',
        builder: (context, state) => const BusesListScreen(),
      ),
      GoRoute(
        path: '/admin/add-bus',
        builder: (context, state) => const AddBusScreen(),
      ),
      GoRoute(
        path: '/admin/edit-bus/:id',
        builder: (context, state) {
          final busId = state.pathParameters['id'];
          return AddBusScreen(busId: busId);
        },
      ),

      // Rutas de administrador para paradas
      GoRoute(
        path: '/admin/busstops',
        builder: (context, state) => const BusStopsListScreen(),
      ),
      GoRoute(
        path: '/admin/add-busstop',
        builder: (context, state) => const AddBusStopScreen(),
      ),
      GoRoute(
        path: '/admin/edit-busstop/:id',
        builder: (context, state) {
          final busStopId = state.pathParameters['id'];
          return AddBusStopScreen(busStopId: busStopId);
        },
      ),

       // Rutas de administrador para recorridos
      GoRoute(
        path: '/admin/routes',
        builder: (context, state) => const RoutesListScreen(),
      ),
      GoRoute(
        path: '/admin/add-route',
        builder: (context, state) => const AddRouteScreen(),
      ),
      GoRoute(
        path: '/admin/edit-route/:id',
        builder: (context, state) {
          final routeId = state.pathParameters['id'];
          return AddRouteScreen(routeId: routeId);
        },
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