import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  void _handleMenuOption(BuildContext context, String option) {
    print('Navegando a: $option');
    // Implementar navegación
  }

  void _handleLogout(BuildContext context) {
    // TODO: Implementar cierre de sesión real
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado de usuario
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pasajero',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'user@example.com',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // Opciones del menú de usuario
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _MenuOption(
                    icon: Icons.directions_bus,
                    title: 'Rutas en Tiempo Real',
                    badge: 'Nuevo',
                    onTap: () => _handleMenuOption(context, 'Rutas en Tiempo Real'),
                  ),
                  _MenuOption(
                    icon: Icons.calendar_today,
                    title: 'Horarios',
                    onTap: () => _handleMenuOption(context, 'Horarios'),
                  ),
                  _MenuOption(
                    icon: Icons.map,
                    title: 'Paradas Cercanas',
                    onTap: () => _handleMenuOption(context, 'Paradas Cercanas'),
                  ),
                  _MenuOption(
                    icon: Icons.search,
                    title: 'Buscar Ruta',
                    onTap: () => _handleMenuOption(context, 'Buscar Ruta'),
                  ),
                  _MenuOption(
                    icon: Icons.star_outline,
                    title: 'Rutas Favoritas',
                    onTap: () => _handleMenuOption(context, 'Rutas Favoritas'),
                  ),
                  _MenuOption(
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    badge: '3',
                    onTap: () => _handleMenuOption(context, 'Notificaciones'),
                  ),
                ],
              ),
            ),

            // Mover cerrar sesión al final
            const Divider(),
            _MenuOption(
              icon: Icons.logout,
              title: 'Cerrar sesión',
              textColor: Colors.blue,
              iconColor: Colors.blue,
              onTap: () => _handleLogout(context),
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
    this.iconColor = const Color(0xFF6B7280),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
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
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: Colors.blue.shade700,
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