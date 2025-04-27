// lib/features/admin/screens/assignment/assignments_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/assignment.dart';
import '../../../../shared/widgets/widgets.dart';

class AssignmentsListScreen extends ConsumerStatefulWidget {
  const AssignmentsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends ConsumerState<AssignmentsListScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Assignment> _assignments = [];
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }
  
  Future<void> _loadAssignments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Obtener las asignaciones con información adicional mediante joins
      final result = await _supabase
          .from('asignaciones')
          .select('''
            *,
            usuarios:operador_id (nombre, apellido_paterno),
            autobuses:autobus_id (numero_unidad),
            recorridos:recorrido_id (nombre)
          ''')
          .order('fecha_inicio', ascending: false);
      
      if (mounted) {
        setState(() {
          _assignments = result.map<Assignment>((data) {
            // Extraer los datos relacionados
            final operatorData = data['usuarios'] as Map<String, dynamic>;
            final busData = data['autobuses'] as Map<String, dynamic>;
            final routeData = data['recorridos'] as Map<String, dynamic>;
            
            // Formatear nombre del operador
            final operatorName = '${operatorData['nombre']} ${operatorData['apellido_paterno']}';
            
            return Assignment.fromJson(
              data,
              operatorName: operatorName,
              busNumber: busData['numero_unidad'],
              routeName: routeData['nombre'],
            );
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando asignaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar asignaciones: $e';
        });
      }
    }
  }
  
  Future<void> _confirmDeleteAssignment(String assignmentId, String description) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar la asignación "$description"?'),
                const SizedBox(height: 8),
                const Text(
                  'Esta acción no se puede deshacer.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                // Mostrar indicador de carga
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Eliminando asignación...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                try {
                  // Eliminar la asignación
                  await _supabase
                      .from('asignaciones')
                      .delete()
                      .eq('id', assignmentId);
                  
                  // Recargar la lista
                  _loadAssignments();
                  
                  // Mostrar mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Asignación eliminada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error eliminando asignación: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar asignación: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegar a la pantalla de creación de asignaciones
          final result = await context.push('/admin/add-assignment');
          if (result == true && mounted) {
            _loadAssignments();
          }
        },
        tooltip: 'Crear Asignación',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAssignments(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _assignments.isEmpty
                    ? _buildEmptyState()
                    : _buildAssignmentsList(),
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Error al cargar asignaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Error desconocido'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAssignments,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay asignaciones registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cree una nueva asignación con el botón +',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAssignmentsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        
        // Formatear fechas
        final dateFormat = DateFormat('dd/MM/yyyy');
        final startDateStr = dateFormat.format(assignment.startDate);
        final endDateStr = assignment.endDate != null 
            ? dateFormat.format(assignment.endDate!) 
            : 'Indefinido';
        
        // Formatear horas
        final timeFormat = (time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        final timeRange = '${timeFormat(assignment.startTime)} - ${timeFormat(assignment.endTime)}';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.routeName ?? 'Recorrido sin nombre',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: assignment.status.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        assignment.status.displayName,
                        style: TextStyle(
                          color: assignment.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Información de la asignación
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información del operador
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  assignment.operatorName ?? 'Operador desconocido',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Información del autobús
                          Row(
                            children: [
                              const Icon(Icons.directions_bus, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Unidad: ${assignment.busNumber ?? 'Desconocido'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fechas
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  startDateStr == endDateStr 
                                      ? startDateStr 
                                      : '$startDateStr - $endDateStr',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Horario
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                timeRange,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Botón para cambiar estado
                    IconButton(
                      icon: const Icon(Icons.sync, color: Colors.blue),
                      tooltip: 'Cambiar estado',
                      onPressed: () {
                        _showChangeStatusDialog(assignment);
                      },
                    ),
                    
                    // Botón de editar
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      tooltip: 'Editar asignación',
                      onPressed: () async {
                        final result = await context.push('/admin/edit-assignment/${assignment.id}');
                        if (result == true && mounted) {
                          _loadAssignments();
                        }
                      },
                    ),
                    
                    // Botón de eliminar
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Eliminar asignación',
                      onPressed: () {
                        final description = 'Operador: ${assignment.operatorName}, Ruta: ${assignment.routeName}';
                        _confirmDeleteAssignment(assignment.id, description);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showChangeStatusDialog(Assignment assignment) {
    AssignmentStatus selectedStatus = assignment.status;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: AssignmentStatus.values.map((status) {
              return RadioListTile<AssignmentStatus>(
                title: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(status.displayName.toUpperCase()),
                  ],
                ),
                value: status,
                groupValue: selectedStatus,
                onChanged: (AssignmentStatus? value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
                activeColor: status.color,
                dense: true,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedStatus != assignment.status) {
                Navigator.pop(context);
                
                // Mostrar indicador de carga
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Actualizando estado...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                try {
                  // Actualizar el estado
                  await _supabase
                      .from('asignaciones')
                      .update({'estado': selectedStatus.name})
                      .eq('id', assignment.id);
                  
                  // Recargar la lista
                  _loadAssignments();
                  
                  // Mostrar mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Estado actualizado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error actualizando estado: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al actualizar estado: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}