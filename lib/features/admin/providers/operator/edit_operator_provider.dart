// lib/features/admin/providers/edit_operator_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/operator.dart';

class EditOperatorState {
  final bool isLoading;
  final Operator? operator;
  final bool isSuccess;
  final String? error;

  EditOperatorState({
    required this.isLoading,
    this.operator,
    required this.isSuccess,
    this.error,
  });

  // Estado inicial
  factory EditOperatorState.initial() => EditOperatorState(
    isLoading: false,
    operator: null,
    isSuccess: false,
    error: null,
  );

  // Método copyWith para inmutabilidad
  EditOperatorState copyWith({
    bool? isLoading,
    Operator? operator,
    bool? isSuccess,
    String? error,
  }) {
    return EditOperatorState(
      isLoading: isLoading ?? this.isLoading,
      operator: operator ?? this.operator,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

class EditOperatorNotifier extends StateNotifier<EditOperatorState> {
  final _supabase = Supabase.instance.client;

  EditOperatorNotifier() : super(EditOperatorState.initial());

  // Método para cargar los datos de un operador específico
  Future<void> loadOperator(String operatorId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      // Consultar datos del operador con join entre usuarios y operadores
      final result = await _supabase
          .from('usuarios')
          .select('*, operadores(*)')
          .eq('id', operatorId)
          .single();
      
      print('Datos del operador: $result');
      
      // Verificar si el resultado contiene datos de operador
      if (result == null || result['operadores'] == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se encontraron datos del operador',
        );
        return;
      }
      
      // Combinar los datos de usuario y operador
      final Map<String, dynamic> combinedData = {
        ...result,
        ...result['operadores'],
      };
      
      // Crear objeto Operator
      final operator = Operator.fromJson(combinedData);
      
      state = state.copyWith(
        isLoading: false,
        operator: operator,
      );
    } catch (e) {
      print('Error cargando operador: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los datos del operador: $e',
      );
    }
  }
  
  // Método para actualizar un operador
  Future<void> updateOperator({
    required String operatorId,
    required String name,
    required String lastName,
    required String phone,
    required String licenseType,
    required int yearsExperience,
    required DateTime hireDate,
    String? maternalLastName,
  }) async {
    // Aseguramos que isLoading sea true al inicio
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    
    try {
      print('Actualizando operador $operatorId');
      print('Datos de actualización: nombre=$name, apellido=$lastName, teléfono=$phone');
      
      // Actualizar datos en la tabla 'usuarios'
      await _supabase
          .from('usuarios')
          .update({
            'nombre': name,
            'apellido_paterno': lastName,
            'apellido_materno': maternalLastName,
            'telefono': phone,
          })
          .eq('id', operatorId);
      
      print('Tabla usuarios actualizada');
      
      // Actualizar datos específicos del operador
      final hireDateStr = hireDate.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
      
      await _supabase
          .from('operadores')
          .update({
            'tipo_licencia': licenseType,
            'experiencia_anios': yearsExperience,
            'fecha_contratacion': hireDateStr,
          })
          .eq('id', operatorId);
      
      print('Tabla operadores actualizada');
      
      // Marcar como éxito y asegurarse de que isLoading sea false
      state = state.copyWith(
        isLoading: false, // Este valor debe ser false
        isSuccess: true,
      );
      
      print('Estado actualizado: isLoading=${state.isLoading}, isSuccess=${state.isSuccess}');
    } catch (e) {
      print('Error actualizando operador: $e');
      state = state.copyWith(
        isLoading: false, // Asegurarse que también se establezca a false en caso de error
        error: 'Error al actualizar el operador: $e',
        isSuccess: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void reset() {
    state = EditOperatorState.initial();
  }
}

final editOperatorProvider = StateNotifierProvider<EditOperatorNotifier, EditOperatorState>((ref) {
  return EditOperatorNotifier();
});