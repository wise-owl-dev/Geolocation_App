// lib/features/admin/screens/assignment/add_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/assignment.dart';
import '../../../../shared/widgets/widgets.dart';

class AddAssignmentScreen extends ConsumerStatefulWidget {
  final String? assignmentId;
  final String? preselectedOperatorId;
  final String? preselectedBusId;
  final String? preselectedRouteId;
  
  const AddAssignmentScreen({
    Key? key,
    this.assignmentId,
    this.preselectedOperatorId,
    this.preselectedBusId,
    this.preselectedRouteId,
  }) : super(key: key);

  @override
  ConsumerState<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends ConsumerState<AddAssignmentScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _error;
  
  // Listas de datos precargados
  List<dynamic> _operators = [];
  List<dynamic> _buses = [];
  List<dynamic> _routes = [];
  
  // Valores seleccionados
  String? _selectedOperatorId;
  String? _selectedBusId;
  String? _selectedRouteId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
  AssignmentStatus _status = AssignmentStatus.programada;
  
  @override
  void initState() {
  super.initState();
  _isEditMode = widget.assignmentId != null;
  _selectedOperatorId = widget.preselectedOperatorId;
  _selectedBusId = widget.preselectedBusId;
  _selectedRouteId = widget.preselectedRouteId;
  _loadInitialData();
}
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Cargar operadores, autobuses y recorridos
      final operatorsResult = await _supabase
          .from('usuarios')
          .select('id, nombre, apellido_paterno, apellido_materno')
          .eq('rol', 'operador')
          .order('nombre');
      
      final busesResult = await _supabase
          .from('autobuses')
          .select('id, numero_unidad, placa')
          .eq('estado', 'activo')
          .order('numero_unidad');
      
      final routesResult = await _supabase
          .from('recorridos')
          .select('id, nombre, horario_inicio, horario_fin')
          .eq('estado', 'activo')
          .order('nombre');
      
      setState(() {
        _operators = operatorsResult;
        _buses = busesResult;
        _routes = routesResult;
      });
      
      // Si estamos en modo edición, cargar datos de la asignación
      if (_isEditMode) {
        await _loadAssignmentData();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos iniciales: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error al cargar datos iniciales: $e';
      });
    }
  }
  
  Future<void> _loadAssignmentData() async {
    try {
      final result = await _supabase
          .from('asignaciones')
          .select()
          .eq('id', widget.assignmentId ?? '')
          .single();
      
      // Formatear las fechas y horas
      final startDate = DateTime.parse(result['fecha_inicio']);
      final endDate = result['fecha_fin'] != null 
          ? DateTime.parse(result['fecha_fin']) 
          : null;
      
      // Convertir string de hora a TimeOfDay
      TimeOfDay parseTimeString(String timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1].split(':')[0]),
        );
      }
      
      final startTime = parseTimeString(result['hora_inicio']);
      final endTime = parseTimeString(result['hora_fin']);
      
      setState(() {
        _selectedOperatorId = result['operador_id'];
        _selectedBusId = result['autobus_id'];
        _selectedRouteId = result['recorrido_id'];
        _startDate = startDate;
        _endDate = endDate;
        _startTime = startTime;
        _endTime = endTime;
        _status = AssignmentStatusExtension.fromString(result['estado']);
      });
    } catch (e) {
      print('Error cargando datos de asignación: $e');
      setState(() {
        _error = 'Error al cargar datos de la asignación: $e';
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : (_endDate ?? DateTime.now());
    final DateTime firstDate = isStartDate ? DateTime.now() : _startDate;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la fecha de fin es anterior a la de inicio, actualizarla
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Si la hora de fin es anterior a la de inicio, actualizarla
          final startMinutes = _startTime.hour * 60 + _startTime.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;
          if (endMinutes <= startMinutes) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }
  
  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Formatear TimeOfDay a string
      String formatTimeOfDay(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      }
      
      final data = {
        'operador_id': _selectedOperatorId,
        'autobus_id': _selectedBusId,
        'recorrido_id': _selectedRouteId,
        'fecha_inicio': _startDate.toIso8601String().split('T')[0],
        'fecha_fin': _endDate?.toIso8601String().split('T')[0],
        'hora_inicio': formatTimeOfDay(_startTime),
        'hora_fin': formatTimeOfDay(_endTime),
        'estado': _status.name,
      };
      
      if (_isEditMode) {
        // Actualizar asignación existente
        await _supabase
            .from('asignaciones')
            .update(data)
            .eq('id', widget.assignmentId ?? '');
      } else {
        // Crear nueva asignación
        await _supabase
            .from('asignaciones')
            .insert(data);
      }
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
                ? 'Asignación actualizada correctamente' 
                : 'Asignación creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Regresar a la pantalla anterior con resultado exitoso
        context.pop(true);
      }
    } catch (e) {
      print('Error guardando asignación: $e');
      setState(() {
        _isLoading = false;
        _error = 'Error al guardar la asignación: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Asignación' : 'Crear Asignación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildForm(),
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
            'Error al cargar datos',
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
            onPressed: _loadInitialData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de selección de operador, autobús y recorrido
            const Text(
              'Información de la asignación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Operador
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Operador',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              value: _selectedOperatorId,
              items: _operators.map((op) {
                final fullName = '${op['nombre']} ${op['apellido_paterno'] ?? ''} ${op['apellido_materno'] ?? ''}'.trim();
                return DropdownMenuItem<String>(
                  value: op['id'],
                  child: Text(fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOperatorId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, seleccione un operador';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Autobús
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Autobús',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bus),
              ),
              value: _selectedBusId,
              items: _buses.map((bus) {
                return DropdownMenuItem<String>(
                  value: bus['id'],
                  child: Text('${bus['numero_unidad']} (${bus['placa']})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBusId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, seleccione un autobús';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Recorrido
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Recorrido',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.route),
              ),
              value: _selectedRouteId,
              items: _routes.map((route) {
                return DropdownMenuItem<String>(
                  value: route['id'],
                  child: Text(route['nombre']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRouteId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, seleccione un recorrido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Sección de fechas y horas
            const Text(
              'Programación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Fecha de inicio
            InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de inicio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(_startDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Fecha de fin (opcional)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _endDate == null ? null : () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha de fin (opcional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        enabled: _endDate != null,
                      ),
                      child: Text(
                        _endDate != null 
                            ? DateFormat('dd/MM/yyyy').format(_endDate!) 
                            : 'Indefinido',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _endDate = _endDate == null ? _startDate : null;
                      });
                    },
                    icon: Icon(_endDate == null ? Icons.add : Icons.remove),
                    label: Text(_endDate == null ? 'Agregar' : 'Quitar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _endDate == null ? Colors.blue : Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Hora de inicio y fin
            Row(
              children: [
                // Hora de inicio
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Hora de fin
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Hora de fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Estado (solo en modo edición)
            if (_isEditMode) ...[
              const Text(
                'Estado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
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
                      groupValue: _status,
                      onChanged: (AssignmentStatus? value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                      activeColor: status.color,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Botón de guardar
            CustomFilledButton(
              text: _isEditMode ? 'Actualizar Asignación' : 'Crear Asignación',
              isLoading: _isLoading,
              onPressed: _saveAssignment,
            ),
          ],
        ),
      ),
    );
  }
}