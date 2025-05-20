// lib/features/routes/widgets/route_card.dart
import 'package:flutter/material.dart';
import '../../../shared/models/route.dart' as app_route;

class RouteCard extends StatelessWidget {
  final app_route.Route route;
  final VoidCallback onTap;

  const RouteCard({
    Key? key,
    required this.route,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con nombre de ruta
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Horario: ${route.startTime} - ${route.endTime}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              
              // Días de operación
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Días: ${_formatOperationDays(route.days)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatOperationDays(List<String> days) {
    if (days.isEmpty) return 'No disponible';
    
    // Ordenar días de la semana
    const dayOrder = {
      'lunes': 0, 'martes': 1, 'miércoles': 2, 'miercoles': 2,
      'jueves': 3, 'viernes': 4, 'sábado': 5, 'sabado': 5, 'domingo': 6
    };
    
    days.sort((a, b) {
      final aIndex = dayOrder[a.toLowerCase()] ?? 7;
      final bIndex = dayOrder[b.toLowerCase()] ?? 7;
      return aIndex.compareTo(bIndex);
    });
    
    // Capitalizar primera letra
    final formattedDays = days.map((day) {
      if (day.isEmpty) return day;
      return day[0].toUpperCase() + day.substring(1).toLowerCase();
    }).toList();
    
    // Si tiene todos los días de L-V, simplificar
    final weekdaySet = {'Lunes', 'Martes', 'Miércoles', 'Miercoles', 'Jueves', 'Viernes'};
    final daySet = formattedDays.toSet();
    
    if (weekdaySet.difference(daySet).isEmpty && daySet.containsAll(weekdaySet)) {
      // Si también tiene S-D, es toda la semana
      if (daySet.contains('Sábado') || daySet.contains('Sabado') && daySet.contains('Domingo')) {
        return 'Todos los días';
      }
      return 'Lunes a Viernes';
    }
    
    // De lo contrario, listar los días
    return formattedDays.join(', ');
  }
}