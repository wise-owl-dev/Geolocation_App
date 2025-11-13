import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/operator/operators_provider.dart';
import '../../../../shared/widgets/custom_filled_button.dart';

class OperatorsListScreen extends ConsumerStatefulWidget {
  const OperatorsListScreen({super.key});

  @override
  ConsumerState<OperatorsListScreen> createState() => _OperatorsListScreenState();
}

class _OperatorsListScreenState extends ConsumerState<OperatorsListScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar operadores al iniciar la pantalla
    Future.microtask(() {
      ref.read(operatorsProvider.notifier).loadOperators();
    });
  }

  // Método para mostrar diálogo de confirmación de eliminación
  Future<void> _confirmDeleteOperator(BuildContext context, String operatorId, String operatorName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe presionar un botón para cerrar el diálogo
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('¿Está seguro que desea eliminar al operador $operatorName?'),
                const SizedBox(height: 8),
                const Text('Esta acción no se puede deshacer.', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
              },
            ),
            TextButton(
              child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Cerrar el diálogo primero
                Navigator.of(dialogContext).pop();
                
                // Mostrar indicador de carga
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Eliminando operador...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Eliminar el operador
                await ref.read(operatorsProvider.notifier).deleteOperator(operatorId);
                
                // Mostrar mensaje de éxito
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Operador eliminado exitosamente'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
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
    final operatorsState = ref.watch(operatorsProvider);
    
    // Mostrar SnackBar si hay un error
    if (operatorsState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(operatorsState.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Operadores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(operatorsProvider.notifier).loadOperators();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // Lista de operadores
              Expanded(
                child: operatorsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : operatorsState.operators.isEmpty
                        ? _buildEmptyState()
                        : _buildOperatorsList(operatorsState),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomFilledButton(
                      height: 60,
                      text: 'Agregar Operador',
                      prefixIcon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () async {
                        // Navegar a la pantalla de agregar operador
                        final result = await context.push('/admin/add-operator');
                        // Si regresamos con éxito, recargar la lista
                        if (result == true && mounted) {
                          ref.read(operatorsProvider.notifier).loadOperators();
                        }
                      },
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
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay conductores registrados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega un nuevo conductor con el botón superior',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildOperatorsList(OperatorsState state) {
    return ListView.separated(
      itemCount: state.operators.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final operator = state.operators[index];
        return GestureDetector(
          onTap: () {
            // Aquí podrías navegar a una pantalla de detalles del operador
            // context.push('/admin/operator-details/${operator.id}');
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  operator.name.isNotEmpty ? operator.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                operator.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Licencia: ${operator.licenseNumber}'),
                  Text('Experiencia: ${operator.yearsExperience} años'),
                  Text(
                    'Contratado: ${DateFormat('dd/MM/yyyy').format(operator.hireDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Botón para asignar
                  IconButton(
                    icon: const Icon(Icons.assignment, color: Colors.purple),
                    tooltip: 'Asignar recorrido',
                    onPressed: () {
                      _showAssignRouteDialog(context, operator.id, operator.fullName);
                    },
                  ),
                  // Botón de editar
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      // Navegar a la pantalla de edición del operador
                      final result = await context.push('/admin/edit-operator/${operator.id}');
                      // Si regresamos con éxito, recargar la lista
                      if (result == true && mounted) {
                        ref.read(operatorsProvider.notifier).loadOperators();
                      }
                    },
                  ),
                  // Nuevo botón de eliminar
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Mostrar diálogo de confirmación
                      _confirmDeleteOperator(
                        context, 
                        operator.id, 
                        operator.fullName
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Añadir este método
void _showAssignRouteDialog(BuildContext context, String operatorId, String operatorName) async {
  // Navegar a la pantalla de creación de asignación con el operador preseleccionado
  final result = await context.push('/admin/add-assignment?operatorId=$operatorId');
  if (result == true && mounted) {
    // Recargar la lista si es necesario
    ref.read(operatorsProvider.notifier).loadOperators();
  }
}
}