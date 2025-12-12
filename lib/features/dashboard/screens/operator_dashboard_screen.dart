import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

    void _handleMenuOption(BuildContext context, String option) {
    print('Navegando a: $option');
    
    // Implementar navegación según la opción
    if (option == 'Ver Horarios') {
      context.push('/operator/schedules');
    } else if (option == 'Ver Recorrido') {
      context.push('/operator/route-selector'); // Esta ruta ahora está correctamente implementada
    } else if (option == 'Iniciar Ruta') {
      context.push('/operator/route-tracking');
    }
    // Las demás opciones se implementarán posteriormente
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    // Usar el AuthProvider para cerrar sesión
    await ref.read(authProvider.notifier).logout();
    
    // Navegar a login (esto debería hacerse automáticamente por el router,
    // pero por seguridad lo hacemos explícitamente)
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener información del usuario actual
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    if (user == null) {
      // Si no hay usuario, redirigir a login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      
      // Mostrar indicador de carga mientras se redirige
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado de usuario operador
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191970),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Color.fromARGB(255, 255, 255, 255),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Opciones del menú de operador
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _MenuOption(
                    icon: Icons.directions_bus_outlined,
                    title: 'Ver Recorrido',
                    onTap: () => _handleMenuOption(context, 'Ver Recorrido'),
                  ),
                  _MenuOption(
                    icon: Icons.schedule,
                    title: 'Ver Horarios',
                    onTap: () => _handleMenuOption(context, 'Ver Horarios'),
                  ),
                  _MenuOption(
                    icon: Icons.map_outlined,
                    title: 'Iniciar Ruta',
                    badge: 'Nuevo',
                    onTap: () => context.push('/operator/map'),
                  ),
                  /*
                  _MenuOption(
                    icon: Icons.report_problem_outlined,
                    title: 'Reportar Incidente',
                    onTap: () => _handleMenuOption(context, 'Reportar Incidente'),
                  ),
                  */
                  
                ],
              ),
            ),

            // Mover cerrar sesión al final
            const Divider(),
            _MenuOption(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              textColor: const Color(0xFF191970),
              iconColor: const Color.fromARGB(255, 255, 255, 255),
              onTap: () => _handleLogout(context, ref),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Widget personalizado para las opciones del menú
class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badge;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.title,
    this.badge,
    this.textColor = const Color(0xFF1F2937),
    this.iconColor = const Color.fromARGB(255, 255, 255, 255),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF191970),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF191970),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
      onTap: onTap,
    );
  }
}