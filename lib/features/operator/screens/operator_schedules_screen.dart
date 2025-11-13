
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importación necesaria para inicializar localización
import '../providers/operator_schedules_provider.dart';
import '../../../shared/models/assignment.dart';
import '../../../shared/widgets/widgets.dart';

class OperatorSchedulesScreen extends ConsumerStatefulWidget {
  const OperatorSchedulesScreen({super.key});

  @override
  ConsumerState<OperatorSchedulesScreen> createState() => _OperatorSchedulesScreenState();
}

class _OperatorSchedulesScreenState extends ConsumerState<OperatorSchedulesScreen> {
  @override
  void initState() {
    super.initState();
    // Inicializar datos de localización para español
    initializeDateFormatting('es', null);
    
    // Cargar asignaciones al iniciar la pantalla
    Future.microtask(() {
      ref.read(operatorSchedulesProvider.notifier).loadOperatorAssignments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedulesState = ref.watch(operatorSchedulesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Horarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filtros de fecha
          _buildFilterButtons(schedulesState.activeFilter),
          
          // Indicador de carga o mensaje de error
          if (schedulesState.isLoading)
            const LinearProgressIndicator(),
            
          if (schedulesState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                schedulesState.error!,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Lista de asignaciones
          Expanded(
            child: schedulesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : schedulesState.assignments.isEmpty
                    ? _buildEmptyState()
                    : _buildAssignmentsList(schedulesState.assignments),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterButtons(String activeFilter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _FilterButton(
              label: 'Todos',
              isActive: activeFilter == 'all',
              onTap: () => ref.read(operatorSchedulesProvider.notifier).changeFilter('all'),
            ),
            _FilterButton(
              label: 'Hoy',
              isActive: activeFilter == 'today',
              onTap: () => ref.read(operatorSchedulesProvider.notifier).changeFilter('today'),
            ),
            _FilterButton(
              label: 'Esta Semana',
              isActive: activeFilter == 'week',
              onTap: () => ref.read(operatorSchedulesProvider.notifier).changeFilter('week'),
            ),
            _FilterButton(
              label: 'Próximos',
              isActive: activeFilter == 'upcoming',
              onTap: () => ref.read(operatorSchedulesProvider.notifier).changeFilter('upcoming'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay horarios asignados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No tienes asignaciones para el periodo seleccionado',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            onPressed: () {
              ref.read(operatorSchedulesProvider.notifier).loadOperatorAssignments();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssignmentsList(List<Assignment> assignments) {
    // Agrupar asignaciones por fecha
    final Map<String, List<Assignment>> groupedAssignments = {};
    
    for (var assignment in assignments) {
      final dateStr = DateFormat('yyyy-MM-dd').format(assignment.startDate);
      if (!groupedAssignments.containsKey(dateStr)) {
        groupedAssignments[dateStr] = [];
      }
      groupedAssignments[dateStr]!.add(assignment);
    }
    
    // Ordenar las fechas
    final sortedDates = groupedAssignments.keys.toList()..sort();
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateStr = sortedDates[index];
        final dateAssignments = groupedAssignments[dateStr]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de fecha
            _buildDateHeader(DateTime.parse(dateStr)),
            
            // Asignaciones de ese día
            ...dateAssignments.map((assignment) => _buildAssignmentCard(assignment)),
            
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
  
  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    String dateText;
    Color backgroundColor;
    
    if (dateOnly.isAtSameMomentAs(today)) {
      dateText = 'Hoy, ${DateFormat('d MMM').format(date)}';
      backgroundColor = Colors.blue;
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      dateText = 'Mañana, ${DateFormat('d MMM').format(date)}';
      backgroundColor = Colors.green;
    } else {
      dateText = DateFormat('EEEE, d MMM', 'es').format(date);
      backgroundColor = Colors.grey.shade700;
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        dateText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildAssignmentCard(Assignment assignment) {
    // Formatear horas
    String timeFormat(time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final timeRange = '${timeFormat(assignment.startTime)} - ${timeFormat(assignment.endTime)}';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(assignment.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con ruta y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.routeName ?? 'Ruta sin nombre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(assignment.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(assignment.status),
                    style: TextStyle(
                      color: _getStatusColor(assignment.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información de horario y autobús
            Row(
              children: [
                // Horario
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        timeRange,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Autobús
                Row(
                  children: [
                    Icon(Icons.directions_bus, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Unidad: ${assignment.busNumber ?? 'No asignada'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Botón de acción según el estado
            if (assignment.status == AssignmentStatus.programada || 
                assignment.status == AssignmentStatus.en_curso)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (assignment.status == AssignmentStatus.programada)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Iniciar Ruta'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                        onPressed: () {
                          // Navegar a la pantalla de mapa para el operador con esta asignación
                          context.push('/operator/map/${assignment.id}');
                        },
                      ),
                    if (assignment.status == AssignmentStatus.en_curso) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Finalizar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () {
                          // Aquí iría la lógica para finalizar la ruta
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Finalizando ruta...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.pause, size: 18),
                        label: const Text('Pausar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                        onPressed: () {
                          // Aquí iría la lógica para pausar la ruta
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Pausando ruta...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(AssignmentStatus status) {
    return status.color;
  }
  
  String _getStatusText(AssignmentStatus status) {
    return status.displayName.toUpperCase();
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.blue : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.blue,
          elevation: isActive ? 2 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isActive ? Colors.blue : Colors.grey.shade300,
            ),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}