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
    super.key,
    this.assignmentId,
    this.preselectedOperatorId,
    this.preselectedBusId,
    this.preselectedRouteId,
  });

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
  
  // Límites de operación dinámicos (inicializados con valores por defecto)
  TimeOfDay _minOperationTime = TimeOfDay(hour: 5, minute: 20);
  TimeOfDay _maxOperationTime = TimeOfDay(hour: 21, minute: 45);
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.assignmentId != null;
    _selectedOperatorId = widget.preselectedOperatorId;
    _selectedBusId = widget.preselectedBusId;
    _selectedRouteId = widget.preselectedRouteId;
    
    // Ajustar hora de inicio a la actual si es hoy
    _adjustStartTimeToNow();
    
    _loadInitialData();
  }
  
  // Método para ajustar la hora de inicio a la hora actual si es necesario
  void _adjustStartTimeToNow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    
    // Solo si la fecha seleccionada es hoy
    if (selectedDay.isAtSameMomentAs(today)) {
      final currentTime = TimeOfDay.now();
      
      // Si la hora actual es posterior a la hora de inicio seleccionada
      // actualizar la hora de inicio a la actual + 15 minutos (para dar margen)
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      final selectedMinutes = _startTime.hour * 60 + _startTime.minute;
      
      if (currentMinutes >= selectedMinutes) {
        // Sumar 15 minutos a la hora actual
        int newMinutes = currentMinutes + 15;
        _startTime = TimeOfDay(
          hour: newMinutes ~/ 60, 
          minute: newMinutes % 60
        );
        
        // Actualizar hora de fin para mantener al menos 30 minutos de duración
        int endMinutes = _startTime.hour * 60 + _startTime.minute + 30;
        _endTime = TimeOfDay(
          hour: endMinutes ~/ 60,
          minute: endMinutes % 60
        );
      }
    }
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // 1. Cargar los límites de operación desde los recorridos
      await _loadOperationLimits();
      
      // 2. Cargar operadores, autobuses y recorridos
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
      
      // 3. En modo edición, cargar datos de la asignación
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
  
  // Método para cargar los límites de operación desde los recorridos
  Future<void> _loadOperationLimits() async {
    try {
      final routesResult = await _supabase
          .from('recorridos')
          .select('horario_inicio, horario_fin')
          .eq('estado', 'activo');
      
      if (routesResult.isEmpty) {
        return; // Mantener los valores por defecto
      }
      
      // Función para convertir string de tiempo "HH:MM:SS" a TimeOfDay
      TimeOfDay parseTimeString(String timeStr) {
        final parts = timeStr.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1])
        );
      }
      
      // Función para convertir TimeOfDay a minutos totales para comparación
      int timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;
      
      // Inicializar con el primer recorrido
      var earliestStart = parseTimeString(routesResult[0]['horario_inicio']);
      var latestEnd = parseTimeString(routesResult[0]['horario_fin']);
      
      // Encontrar el inicio más temprano y el fin más tardío
      for (var route in routesResult) {
        final routeStart = parseTimeString(route['horario_inicio']);
        final routeEnd = parseTimeString(route['horario_fin']);
        
        if (timeToMinutes(routeStart) < timeToMinutes(earliestStart)) {
          earliestStart = routeStart;
        }
        
        if (timeToMinutes(routeEnd) > timeToMinutes(latestEnd)) {
          latestEnd = routeEnd;
        }
      }
      
      // Actualizar los límites de operación
      setState(() {
        _minOperationTime = earliestStart;
        _maxOperationTime = latestEnd;
        print('Límites de operación actualizados: ${_formatTimeOfDay(_minOperationTime)} - ${_formatTimeOfDay(_maxOperationTime)}');
      });
    } catch (e) {
      print('Error al cargar los límites de operación: $e');
      // Mantener los valores por defecto si hay error
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
  
  // Método para seleccionar fecha con validación de fecha actual
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime currentDate = DateTime.now();
    
    // Para fecha de inicio, no permitir fechas anteriores a hoy
    final DateTime initialDate = isStartDate 
        ? (_startDate.isBefore(currentDate) ? currentDate : _startDate)
        : (_endDate ?? DateTime.now());
    
    // Para fecha de inicio, establecer primera fecha como hoy
    final DateTime firstDate = isStartDate 
        ? currentDate 
        : _startDate;
    
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
          
          // Si se selecciona la fecha actual, ajustar la hora
          if (_isSameDay(picked, currentDate)) {
            _adjustStartTimeToNow();
          }
          
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
  
  // Método auxiliar para comparar si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  // Método para seleccionar hora con validaciones de tiempo
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    
    // Construir un objeto para la fecha y hora actual
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_startDate.year, _startDate.month, _startDate.day);
    
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      // Desactivar la selección de minutos que no sean múltiplos de 5
      minuteLabelText: 'Minutos (5 min)',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final currentTime = TimeOfDay.now();
      
      // Validar que la hora seleccionada esté dentro del rango de operación
      if (_isTimeWithinRange(picked)) {
        // Si es el día de hoy y seleccionamos la hora de inicio
        if (isStartTime && _isSameDay(selectedDay, today)) {
          // Convertir a minutos para comparar
          final pickedMinutes = picked.hour * 60 + picked.minute;
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          
          // No permitir seleccionar horas pasadas (dar 15 min de margen)
          if (pickedMinutes <= currentMinutes) {
            // Mostrar error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No puedes seleccionar una hora que ya pasó. La hora mínima para hoy es ${_formatTimeOfDay(currentTime)}'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
        
        setState(() {
          if (isStartTime) {
            _startTime = picked;
            
            // Actualizar hora de fin si es necesario
            final startMinutes = _startTime.hour * 60 + _startTime.minute;
            final endMinutes = _endTime.hour * 60 + _endTime.minute;
            
            // Si hora de fin <= hora de inicio, actualizar hora de fin
            if (endMinutes <= startMinutes) {
              // Añadir al menos 30 minutos
              int newEndMinutes = startMinutes + 30;
              _endTime = TimeOfDay(
                hour: newEndMinutes ~/ 60,
                minute: newEndMinutes % 60
              );
              
              // Verificar que no exceda el límite
              if (!_isTimeWithinRange(_endTime)) {
                _endTime = _maxOperationTime;
                
                // Notificar que se ajustó al límite
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La hora de fin ha sido ajustada al límite de operación (${_formatTimeOfDay(_maxOperationTime)})'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            _endTime = picked;
            
            // Validar que hora de fin sea posterior a hora de inicio
            final startMinutes = _startTime.hour * 60 + _startTime.minute;
            final endMinutes = _endTime.hour * 60 + _endTime.minute;
            
            if (endMinutes <= startMinutes) {
              // Hora de fin debe ser posterior a hora de inicio
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('La hora de fin debe ser posterior a la hora de inicio'),
                  backgroundColor: Colors.red,
                ),
              );
              
              // Revertir al valor anterior
              _endTime = initialTime;
            }
          }
        });
      } else {
        // Mostrar error: hora fuera de rango
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La hora debe estar entre ${_formatTimeOfDay(_minOperationTime)} y ${_formatTimeOfDay(_maxOperationTime)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Método auxiliar para formatear TimeOfDay
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  // Método para validar si un horario está dentro del rango permitido
  bool _isTimeWithinRange(TimeOfDay time) {
    // Convertir TimeOfDay a minutos para facilitar la comparación
    int timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
    
    final timeInMinutes = timeToMinutes(time);
    final minInMinutes = timeToMinutes(_minOperationTime);
    final maxInMinutes = timeToMinutes(_maxOperationTime);
    
    return timeInMinutes >= minInMinutes && timeInMinutes <= maxInMinutes;
  }
  
  // Método para verificar solapamiento de horarios
  bool _isTimeOverlap(String start1, String end1, String start2, String end2) {
    // Convertir cadenas de tiempo 'HH:MM:SS' a minutos para comparación confiable
    int timeToMinutes(String timeStr) {
      final parts = timeStr.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    
    final start1Minutes = timeToMinutes(start1);
    final end1Minutes = timeToMinutes(end1);
    final start2Minutes = timeToMinutes(start2);
    final end2Minutes = timeToMinutes(end2);
    
    // Verificar solapamiento usando valores numéricos
    return start1Minutes < end2Minutes && end1Minutes > start2Minutes;
  }
  
  // Método para validar la asignación completa
  Future<String?> _validateAssignment() async {
    // Validar horario de operación
    if (!_isTimeWithinRange(_startTime)) {
      return "La hora de inicio debe estar entre ${_formatTimeOfDay(_minOperationTime)} y ${_formatTimeOfDay(_maxOperationTime)}";
    }
    
    if (!_isTimeWithinRange(_endTime)) {
      return "La hora de fin debe estar entre ${_formatTimeOfDay(_minOperationTime)} y ${_formatTimeOfDay(_maxOperationTime)}";
    }
    
    // Validar selección de recursos
    if (_selectedOperatorId == null || _selectedBusId == null || _selectedRouteId == null) {
      return "Debe seleccionar un operador, un autobús y un recorrido";
    }
    
    // Validar duración mínima (30 minutos)
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    if (durationMinutes < 30) {
      return "La duración mínima de una asignación debe ser de 30 minutos";
    }
    
    // Validar duración máxima (8 horas)
    if (durationMinutes > 8 * 60) {
      return "La duración máxima de una asignación debe ser de 8 horas";
    }
    
    try {
      // Formatear fecha y horas para consultas
      final dateStr = _startDate.toIso8601String().split('T')[0];
      
      // Formatear horas a string (HH:MM:SS)
      String formatTimeOfDay(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      }
      
      final startTimeStr = formatTimeOfDay(_startTime);
      final endTimeStr = formatTimeOfDay(_endTime);
      
      // Validar disponibilidad del operador
      final operatorAssignments = await _supabase
          .from('asignaciones')
          .select()
          .eq('operador_id', _selectedOperatorId ?? '')
          .eq('fecha_inicio', dateStr)
          .neq('estado', 'cancelada');
      
      // Si estamos editando, excluir la asignación actual
      List filteredOperatorAssignments = operatorAssignments;
      if (_isEditMode && widget.assignmentId != null) {
        filteredOperatorAssignments = operatorAssignments.where(
          (a) => a['id'] != widget.assignmentId
        ).toList();
      }
      
      // Verificar solapamientos con asignaciones del operador
      for (var assignment in filteredOperatorAssignments) {
        if (_isTimeOverlap(
          startTimeStr, 
          endTimeStr, 
          assignment['hora_inicio'], 
          assignment['hora_fin']
        )) {
          return "El operador ya tiene una asignación en ese horario";
        }
      }
      
      // Validar disponibilidad del autobús
      final busAssignments = await _supabase
          .from('asignaciones')
          .select()
          .eq('autobus_id', _selectedBusId ?? '')
          .eq('fecha_inicio', dateStr)
          .neq('estado', 'cancelada');
      
      // Si estamos editando, excluir la asignación actual
      List filteredBusAssignments = busAssignments;
      if (_isEditMode && widget.assignmentId != null) {
        filteredBusAssignments = busAssignments.where(
          (a) => a['id'] != widget.assignmentId
        ).toList();
      }
      
      // Verificar solapamientos con asignaciones del autobús
      for (var assignment in filteredBusAssignments) {
        if (_isTimeOverlap(
          startTimeStr, 
          endTimeStr, 
          assignment['hora_inicio'], 
          assignment['hora_fin']
        )) {
          return "El autobús ya tiene una asignación en ese horario";
        }
      }
      
      // Validar tiempo de descanso mínimo para el operador (30 minutos)
      for (var assignment in filteredOperatorAssignments) {
        // Convertir la hora de fin de la asignación a minutos
        int timeToMinutes(String timeStr) {
          final parts = timeStr.split(':');
          return int.parse(parts[0]) * 60 + int.parse(parts[1]);
        }
        
        final assignmentEndMinutes = timeToMinutes(assignment['hora_fin']);
        
        // Si la nueva asignación comienza menos de 10 minutos después de otra
        if (startMinutes - assignmentEndMinutes < 10 && startMinutes > assignmentEndMinutes) {
          return "El operador debe tener al menos 10 minutos de descanso entre asignaciones";
        }
      }
      
      // Validar que el autobús esté activo
      final busData = await _supabase
          .from('autobuses')
          .select()
          .eq('id', _selectedBusId ?? '')
          .single();
      
      if (busData['estado'] != 'activo') {
        return "El autobús seleccionado no está activo";
      }
      
      // Verificar que la ruta esté activa
      final routeData = await _supabase
          .from('recorridos')
          .select()
          .eq('id', _selectedRouteId ?? '')
          .single();
      
      if (routeData['estado'] != 'activo') {
        return "La ruta seleccionada no está activa";
      }
      
      // Verificar que la ruta opere en el día seleccionado
      final dayOfWeek = _getDayOfWeek(_startDate);
      List<dynamic> routeDays = routeData['dias'];
      
      if (!routeDays.contains(dayOfWeek)) {
        return "La ruta seleccionada no opera los ${_getSpanishDayName(dayOfWeek)}";
      }
      
      // Si llegamos aquí, no hay problemas
      return null;
    } catch (e) {
      print('Error en validación: $e');
      return "Error al validar la asignación: $e";
    }
  }
  
  // Método auxiliar para obtener el día de la semana en español
  String _getDayOfWeek(DateTime date) {
    final days = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
    return days[date.weekday % 7]; // % 7 porque DateTime usa 1-7 con domingo=7
  }
  
  // Método auxiliar para obtener el nombre en español para mensajes
  String _getSpanishDayName(String day) {
    // Capitalizar la primera letra
    return day.substring(0, 1).toUpperCase() + day.substring(1);
  }
  
  // Método para guardar la asignación con validaciones
  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar la asignación antes de guardar
    final validationError = await _validateAssignment();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
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
            // Sección de información de la asignación
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
              initialValue: _selectedOperatorId,
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
              initialValue: _selectedBusId,
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
              initialValue: _selectedRouteId,
              items: _routes.map((route) {
                return DropdownMenuItem<String>(
                  value: route['id'],
                  child: Text('${route['nombre']} (${route['horario_inicio'].substring(0, 5)}-${route['horario_fin'].substring(0, 5)})'),
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
            
            // Sección de programación
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
            
            // Horario de operación permitido (mostrar al usuario)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                'Horario de operación: ${_formatTimeOfDay(_minOperationTime)} - ${_formatTimeOfDay(_maxOperationTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
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