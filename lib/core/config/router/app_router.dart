import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/admin/screens/assignment/add_assignment_screen.dart';
import '../../../features/admin/screens/assignment/assignments_list_screen.dart';
import '../../../features/admin/screens/bus/add_bus_screen.dart';
import '../../../features/admin/screens/bus/list_buses_screen.dart';
import '../../../features/admin/screens/bus_stop/add_busstop_screen.dart';
import '../../../features/admin/screens/bus_stop/list_busstops_screen.dart';
import '../../../features/admin/screens/operator/add_operator_screen.dart';
import '../../../features/admin/screens/operator/list_operators_screen.dart';
import '../../../features/admin/screens/route/add_route_screen.dart';
import '../../../features/admin/screens/route/list_routes_screen.dart';
import '../../../features/admin/screens/route/route_stops_screen.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/screens/login_screen.dart';
import '../../../features/auth/screens/signup_screen.dart';
import '../../../features/bus_stops/screens/nearby_stops_screen.dart';
import '../../../features/bus_stops/screens/stop_details_screen.dart';
import '../../../features/map/screens/bus_map_screen.dart';
import '../../../features/map/screens/bus_tracking_screen.dart';
import '../../../features/map/screens/operator_map_screen.dart';
import '../../../features/map/screens/route_selector_screen.dart';
import '../../../features/operator/screens/operator_schedules_screen.dart';
import '../../../features/reports/screens/bus_utilization_report.dart';
import '../../../features/reports/screens/operator_performance_report.dart';
import '../../../features/reports/screens/reports_screen.dart';
import '../../../features/reports/screens/route_performance_report.dart';
import '../../../features/routes/screens/route_details_screen.dart';
import '../../../features/routes/screens/routes_screen.dart';
import '../../../features/user/screens/search_bus_screen.dart';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
      GoRoute(
        path: '/admin/route-stops/:id',
        builder: (context, state) {
          final routeId = state.pathParameters['id'];
          return RouteStopsScreen(routeId: routeId!);
        },
      ),
      GoRoute(
        path: '/admin/assignments',
        builder: (context, state) => const AssignmentsListScreen(),
      ),
      GoRoute(
        path: '/admin/add-assignment',
        builder: (context, state) {
          // Extraer parámetros de query
          final operatorId = state.uri.queryParameters['operatorId'];
          final busId = state.uri.queryParameters['busId'];
          final routeId = state.uri.queryParameters['routeId'];

          return AddAssignmentScreen(
            preselectedOperatorId: operatorId,
            preselectedBusId: busId,
            preselectedRouteId: routeId,
          );
        },
      ),
      GoRoute(
        path: '/admin/edit-assignment/:id',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id']!;
          return AddAssignmentScreen(assignmentId: assignmentId);
        },
      ),

      // Rutas de usuario
      GoRoute(
        path: '/user/bus-search',
        builder: (context, state) => const BusSearchScreen(),
      ),
      GoRoute(
        path: '/user/bus-map',
        builder: (context, state) => const BusMapScreen(),
      ),
      GoRoute(
        path: '/user/bus-tracking/:id',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id']!;
          return BusTrackingScreen(assignmentId: assignmentId);
        },
      ),
      GoRoute(
        path: '/user/routes',
        builder: (context, state) => const RoutesScreen(),
      ),
      GoRoute(
        path: '/user/nearby-stops',
        builder: (context, state) => const NearbyStopsScreen(),
      ),

      // Rutas de detalles
      GoRoute(
        path: '/user/route-details/:id',
        builder: (context, state) {
          final routeId = state.pathParameters['id']!;
          return RouteDetailsScreen(routeId: routeId);
        },
      ),
      GoRoute(
        path: '/user/stop-details/:id',
        builder: (context, state) {
          final stopId = state.pathParameters['id']!;
          return StopDetailsScreen(stopId: stopId);
        },
      ),

      // Rutas de operador
      GoRoute(
        path: '/operator/schedules',
        builder: (context, state) => const OperatorSchedulesScreen(),
      ),
      GoRoute(
        path: '/operator/map',
        builder: (context, state) => const OperatorMapScreen(),
      ),
      GoRoute(
        path: '/operator/map/:id',
        builder: (context, state) {
          final assignmentId = state.pathParameters['id'];
          return OperatorMapScreen(assignmentId: assignmentId);
        },
      ),
      GoRoute(
        path: '/operator/route-selector',
        builder: (context, state) => const RouteSelectionScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'admin-reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/admin/reports/routes',
        name: 'route-performance',
        builder: (context, state) => const RoutePerformanceReportScreen(),
      ),
      GoRoute(
        path: '/admin/reports/operators',
        name: 'operator-performance',
        builder: (context, state) => const OperatorPerformanceReportScreen(),
      ),
      GoRoute(
        path: '/admin/reports/buses',
        name: 'bus-utilization',
        builder: (context, state) => const BusUtilizationReportScreen(),
      ),
    ],

    // Lógica de redirección basada en el estado de autenticación
    redirect: (context, state) {
      // Verificar si hay error en el estado de autenticación
      final hasAuthError = authState.error != null;

      // Si hay un error de autenticación y el usuario está en una ruta de autenticación,
      // no redirigir (mantener en la misma página)
      if (hasAuthError) {
        final isAuthRoute =
            state.uri.toString() == '/login' ||
            state.uri.toString() == '/signup';
        if (isAuthRoute) {
          return null; // Mantener en la ruta actual
        }
        // Si tiene error pero no está en ruta de autenticación, redirigir a login
        return '/login';
      }

      // Rutas accesibles sin autenticación
      final isPublicRoute =
          state.uri.toString() == '/loading' ||
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
      if (authState.isAuthenticated &&
          isPublicRoute &&
          state.uri.toString() != '/loading') {
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
