import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/assignment.dart';
import '../../../features/auth/providers/auth_provider.dart';

class OperatorSchedulesState {
  final bool isLoading;
  final List<Assignment> assignments;
  final String? error;
  final String activeFilter; // 'all', 'today', 'week', 'upcoming'

  OperatorSchedulesState({
    required this.isLoading,
    required this.assignments,
    this.error,
    required this.activeFilter,
  });

  // Estado inicial
  factory OperatorSchedulesState.initial() => OperatorSchedulesState(
    isLoading: false,
    assignments: [],
    error: null,
    activeFilter: 'all',
  );

  // Método copyWith para inmutabilidad
  OperatorSchedulesState copyWith({
    bool? isLoading,
    List<Assignment>? assignments,
    String? error,
    String? activeFilter,
  }) {
    return OperatorSchedulesState(
      isLoading: isLoading ?? this.isLoading,
      assignments: assignments ?? this.assignments,
      error: error,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class OperatorSchedulesNotifier extends StateNotifier<OperatorSchedulesState> {
  final _supabase = Supabase.instance.client;
  final Ref _ref;

  OperatorSchedulesNotifier(this._ref) : super(OperatorSchedulesState.initial());

  // Método para cargar las asignaciones del operador actual
  Future<void> loadOperatorAssignments({String filter = 'all'}) async {
    state = state.copyWith(isLoading: true, error: null, activeFilter: filter);
    
    try {
      // Obtener el ID del operador actual del AuthProvider
      final authState = _ref.read(authProvider);
      final operatorId = authState.user?.id;
      
      if (operatorId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Preparar la consulta base
      var query = _supabase
          .from('asignaciones')
          .select('''
            *,
            usuarios:operador_id (nombre, apellido_paterno),
            autobuses:autobus_id (numero_unidad),
            recorridos:recorrido_id (nombre)
          ''')
          .eq('operador_id', operatorId);
      
      // Aplicar filtros adicionales según el filtro seleccionado
      switch (filter) {
        case 'today':
          // Asignaciones para hoy
          final today = DateTime.now().toIso8601String().split('T')[0];
          query = query.eq('fecha_inicio', today);
          break;
        case 'week':
          // Asignaciones para esta semana
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          
          final startDate = startOfWeek.toIso8601String().split('T')[0];
          final endDate = endOfWeek.toIso8601String().split('T')[0];
          
          query = query.gte('fecha_inicio', startDate).lte('fecha_inicio', endDate);
          break;
        case 'upcoming':
          // Asignaciones futuras (desde mañana)
          final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
          query = query.gte('fecha_inicio', tomorrow);
          break;
        // El caso 'all' no necesita filtros adicionales
      }
      
      // Ordenar por fecha de inicio y hora de inicio
      final result = await query.order('fecha_inicio').order('hora_inicio');
      
      // Transformar los datos en objetos Assignment
      final List<Assignment> assignments = result.map<Assignment>((data) {
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
      
      state = state.copyWith(
        isLoading: false,
        assignments: assignments,
      );
    } catch (e) {
      print('Error cargando asignaciones: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar horarios: $e',
      );
    }
  }

  // Método para cambiar el filtro activo
  void changeFilter(String filter) {
    if (filter != state.activeFilter) {
      loadOperatorAssignments(filter: filter);
    }
  }
}

final operatorSchedulesProvider = StateNotifierProvider<OperatorSchedulesNotifier, OperatorSchedulesState>((ref) {
  return OperatorSchedulesNotifier(ref);
});