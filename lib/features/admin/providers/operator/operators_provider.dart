import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/operator.dart';

class OperatorsState {
  final bool isLoading;
  final List<Operator> operators;
  final String? error;

  OperatorsState({
    required this.isLoading,
    required this.operators,
    this.error,
  });

  // Estado inicial
  factory OperatorsState.initial() => OperatorsState(
    isLoading: false,
    operators: [],
    error: null,
  );

  // Método copyWith para inmutabilidad
  OperatorsState copyWith({
    bool? isLoading,
    List<Operator>? operators,
    String? error,
  }) {
    return OperatorsState(
      isLoading: isLoading ?? this.isLoading,
      operators: operators ?? this.operators,
      error: error,
    );
  }
}

class OperatorsNotifier extends StateNotifier<OperatorsState> {
  final _supabase = Supabase.instance.client;

  OperatorsNotifier() : super(OperatorsState.initial());

  // Método para cargar todos los operadores
  Future<void> loadOperators() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Consultamos join entre usuarios y operadores directamente
      final result = await _supabase
          .from('usuarios')
          .select('*, operadores(*)')
          .eq('rol', 'operador');
      
      print('Resultado de la consulta: $result');
      
      if (result.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          operators: [],
        );
        return;
      }
      
      // Transformamos los datos en objetos Operator
      final List<Operator> operators = [];
      
      for (var userData in result) {
        print('Procesando usuario: $userData');
        // Verificamos si tiene datos de operador
        final operatorData = userData['operadores'];
        print('Datos de operador: $operatorData');
        
        if (operatorData != null) {
          // Combinamos los datos
          final Map<String, dynamic> combinedData = {
            ...userData,
            ...operatorData,
          };
          
          try {
            print('Datos combinados: $combinedData');
            final operator = Operator.fromJson(combinedData);
            operators.add(operator);
            print('Operador añadido correctamente');
          } catch (e) {
            print('Error procesando operador: $e');
            // Continuamos con el siguiente
          }
        }
      }
      
      print('Total de operadores procesados: ${operators.length}');
      
      state = state.copyWith(
        isLoading: false,
        operators: operators,
      );
    } catch (e) {
      print('Error cargando operadores: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar operadores: $e',
      );
    }
  }
  
  // Método simplificado para eliminar un operador - enfoque más directo
  Future<void> deleteOperator(String operatorId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('Eliminando operador con ID: $operatorId');
      
      // Enfoque principal: Eliminar de la tabla usuarios (esto eliminará en cascada de operadores)
      await _supabase
          .from('usuarios')
          .delete()
          .eq('id', operatorId);
      
      print('Usuario eliminado de la tabla usuarios correctamente');
      
      // Una vez eliminado de la base de datos, actualizamos el estado local
      final updatedOperators = state.operators.where((op) => op.id != operatorId).toList();
      
      state = state.copyWith(
        isLoading: false,
        operators: updatedOperators,
      );
      
      // Como paso adicional, intentamos llamar a la función RPC para limpiar auth
      // Pero no dejamos que esto afecte el flujo principal
      try {
        await _supabase.rpc('delete_complete_user', params: {'input_user_id': operatorId});
        print('Limpieza adicional completada');
      } catch (rpcError) {
        // Simplemente registramos el error pero no lo propagamos
        print('Nota: Error en limpieza adicional: $rpcError');
      }
      
      print('Operador eliminado exitosamente');
    } catch (e) {
      print('Error eliminando operador: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar el operador: $e',
      );
    }
  }

  // Método para refrescar la lista después de agregar un nuevo operador
  void refreshAfterAdd() {
    loadOperators();
  }
}

final operatorsProvider = StateNotifierProvider<OperatorsNotifier, OperatorsState>((ref) {
  return OperatorsNotifier();
});