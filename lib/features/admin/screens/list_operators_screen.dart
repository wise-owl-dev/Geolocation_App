import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/operators_provider.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class OperatorsListScreen extends ConsumerStatefulWidget {
  const OperatorsListScreen({Key? key}) : super(key: key);

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
              trailing: IconButton(
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
            ),
          ),
        );
      },
    );
  }
}