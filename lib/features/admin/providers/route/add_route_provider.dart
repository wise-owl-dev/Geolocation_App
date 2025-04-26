import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/route.dart' as app_route;

class AddRouteState {
  final bool isLoading;
  final app_route.Route? route;
  final bool isSuccess;
  final String? error;
  final String? errorCode;

  AddRouteState({
    required this.isLoading,
    this.route,
    required this.isSuccess,
    this.error,
    this.errorCode,
  });

  // Initial state
  factory AddRouteState.initial() => AddRouteState(
    isLoading: false,
    route: null,
    isSuccess: false,
    error: null,
    errorCode: null,
  );

  // CopyWith method for immutability
  AddRouteState copyWith({
    bool? isLoading,
    app_route.Route? route,
    bool? isSuccess,
    String? error,
    String? errorCode,
  }) {
    return AddRouteState(
      isLoading: isLoading ?? this.isLoading,
      route: route ?? this.route,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      errorCode: errorCode,
    );
  }
}

class AddRouteNotifier extends StateNotifier<AddRouteState> {
  final _supabase = Supabase.instance.client;

  AddRouteNotifier() : super(AddRouteState.initial());

  Future<void> createRoute({
    required String name,
    String? description,
    required String startTime,
    required String endTime,
    required List<String> days,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null, isSuccess: false);
    
    try {
      // Insert data into 'recorridos' table
      final result = await _supabase.from('recorridos').insert({
        'nombre': name,
        'descripcion': description,
        'horario_inicio': startTime,
        'horario_fin': endTime,
        'dias': days,
        'estado': status,
      }).select();
      
      if (result.isEmpty) {
        throw Exception('No se pudo crear el recorrido. Intenta de nuevo.');
      }
      
      // Get the created route data
      final routeData = result[0];
      final createdRoute = app_route.Route.fromJson(routeData);
      
      state = state.copyWith(
        isLoading: false, 
        route: createdRoute,
        isSuccess: true,
      );
    } catch (e) {
      String errorMessage = e.toString();
      String errorCode = 'unknown-error';
      
      state = state.copyWith(
        isLoading: false, 
        error: errorMessage,
        errorCode: errorCode,
        isSuccess: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null, errorCode: null);
  }
  
  void reset() {
    state = AddRouteState.initial();
  }
}

final addRouteProvider = StateNotifierProvider<AddRouteNotifier, AddRouteState>((ref) {
  return AddRouteNotifier();
});