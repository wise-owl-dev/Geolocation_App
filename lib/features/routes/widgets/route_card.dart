// lib/features/routes/widgets/route_card.dart
import 'package:flutter/material.dart';
import '../../../shared/models/route.dart' as app_route;

class RouteCard extends StatelessWidget {
  final app_route.Route route;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.route,
    required this.onTap,
  });

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
                      color: const Color(0xFF191970),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: const Color.fromARGB(255, 255, 255, 255),
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
                  Expanded(  // Añadir Expanded para controlar el ancho
                    child: Text(
                      'Días: ${_formatOperationDays(route.days)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,  // Limitar a una línea
                      overflow: TextOverflow.ellipsis,  // Añadir puntos suspensivos si es muy largo
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
  
  // Mapeo de nombres completos a abreviaturas
  const Map<String, String> abbrevs = {
    'lunes': 'L', 'martes': 'M', 'miércoles': 'X', 'miercoles': 'X',
    'jueves': 'J', 'viernes': 'V', 'sábado': 'S', 'sabado': 'S', 'domingo': 'D'
  };
  
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
  
  // Si tiene todos los días de L-V, simplificar
  final weekdaySet = {'lunes', 'martes', 'miércoles', 'miercoles', 'jueves', 'viernes'};
  final daySetLower = days.map((d) => d.toLowerCase()).toSet();
  
  if (weekdaySet.difference(daySetLower).isEmpty && daySetLower.containsAll(weekdaySet)) {
    // Si también tiene S-D, es toda la semana
    if (daySetLower.contains('sábado') || daySetLower.contains('sabado') && daySetLower.contains('domingo')) {
      return 'Todos los días';
    }
    return 'L-V';  // Formato más compacto
  }

  // De lo contrario, usar abreviaturas con guiones cuando son consecutivos
  List<String> abbr = days.map((day) => abbrevs[day.toLowerCase()] ?? day).toList();
  
  // Verificar si hay secuencias consecutivas para usar guiones
  if (abbr.length > 2) {
    bool allConsecutive = true;
    for (int i = 1; i < abbr.length; i++) {
      if (dayOrder[days[i-1].toLowerCase()]! + 1 != dayOrder[days[i].toLowerCase()]!) {
        allConsecutive = false;
        break;
      }
    }
    
    if (allConsecutive) {
      return '${abbr.first}-${abbr.last}';  // Por ejemplo: L-V
    }
  }
  
  // Si no son consecutivos, unir con comas
  return abbr.join(', ');
}
}