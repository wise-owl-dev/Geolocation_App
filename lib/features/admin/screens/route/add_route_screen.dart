import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../providers/route/add_route_form_provider.dart';
import '../../providers/route/add_route_provider.dart';
import '../../providers/route/edit_route_provider.dart';

class AddRouteScreen extends ConsumerStatefulWidget {
  final String? routeId;
  
  const AddRouteScreen({
    super.key, 
    this.routeId,
  });

  @override
  ConsumerState<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends ConsumerState<AddRouteScreen> {
  final _scrollController = ScrollController();
  bool _isEditMode = false;
  bool _isLoading = false;
  String _selectedStatus = 'activo';
  
  // Available days
  final List<Map<String, dynamic>> _availableDays = [
    {'name': 'lunes', 'label': 'Lunes', 'selected': false},
    {'name': 'martes', 'label': 'Martes', 'selected': false},
    {'name': 'miércoles', 'label': 'Miércoles', 'selected': false},
    {'name': 'jueves', 'label': 'Jueves', 'selected': false},
    {'name': 'viernes', 'label': 'Viernes', 'selected': false},
    {'name': 'sábado', 'label': 'Sábado', 'selected': false},
    {'name': 'domingo', 'label': 'Domingo', 'selected': false},
  ];

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode
    _isEditMode = widget.routeId != null;
    
    if (_isEditMode) {
      // Wait for the widget to be completely built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRouteData();
        }
      });
    }
  }

  Future<void> _loadRouteData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Loading route data for ID: ${widget.routeId}');
      
      // Load the route
      await ref.read(editRouteProvider.notifier).loadRoute(widget.routeId!);
      
      // Get the data
      final routeState = ref.read(editRouteProvider);
      
      print('Route state: ${routeState.isLoading}, Error: ${routeState.error}');
      
      final route = routeState.route;
      
      if (route == null) {
        print('⚠️ Route not found');
        setState(() => _isLoading = false);
        return;
      }
      
      print('✅ Data received. ID: ${route.id}, Name: ${route.name}');
      
      // Set values in controllers
      _nameController.text = route.name;
      if (route.description != null) _descriptionController.text = route.description!;
      
      _startTimeController.text = _formatTimeStringForDisplay(route.startTime);
    _endTimeController.text = _formatTimeStringForDisplay(route.endTime);
      
      // Update selected days
      for (int i = 0; i < _availableDays.length; i++) {
        _availableDays[i]['selected'] = route.days.contains(_availableDays[i]['name']);
      }
      
      // Update status
      setState(() {
        _selectedStatus = route.status;
      });
      
      // Also update form state
      final formNotifier = ref.read(addRouteFormProvider.notifier);
      formNotifier.onNameChanged(route.name);
      if (route.description != null) formNotifier.onDescriptionChanged(route.description!);
      formNotifier.onStartTimeChanged(_formatTimeStringForDisplay(route.startTime));
      formNotifier.onEndTimeChanged(_formatTimeStringForDisplay(route.endTime));
      formNotifier.onDaysChanged(route.days);
      formNotifier.onStatusChanged(route.status);
      
      print('✅ Controllers updated and form filled');
      
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // Método auxiliar para formatear tiempo de HH:MM:SS a HH:MM para mostrar
    String _formatTimeStringForDisplay(String timeStr) {
      // Si el formato ya es HH:MM, devolverlo como está
      if (!timeStr.contains(':')) return timeStr;
      
      // Si tiene formato HH:MM:SS, extraer HH:MM
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeStr;
    }

  // Method to show time picker
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime 
      ? (_startTimeController.text.isNotEmpty 
          ? _parseTimeString(_startTimeController.text) 
          : TimeOfDay.now())
      : (_endTimeController.text.isNotEmpty 
          ? _parseTimeString(_endTimeController.text) 
          : TimeOfDay.now());

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      // Formatear la hora seleccionada como HH:MM para la interfaz
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isStartTime) {
          _startTimeController.text = formattedTime;
          ref.read(addRouteFormProvider.notifier).onStartTimeChanged(formattedTime);
        } else {
          _endTimeController.text = formattedTime;
          ref.read(addRouteFormProvider.notifier).onEndTimeChanged(formattedTime);
        }
      });
    }
  }

  // Helper method to parse time string to TimeOfDay
  TimeOfDay _parseTimeString(String time) {
    final parts = time.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay.now();
  }

  // Method to handle day selection
  void _onDaySelected(int index, bool value) {
    setState(() {
      _availableDays[index]['selected'] = value;
    });
    
    // Update form with selected days
    List<String> selectedDays = _availableDays
        .where((day) => day['selected'])
        .map((day) => day['name'] as String)
        .toList();
    
    ref.read(addRouteFormProvider.notifier).onDaysChanged(selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    // Get form state
    final routeForm = ref.watch(addRouteFormProvider);
    
    // Get route creation/editing state
    final addRouteState = ref.watch(addRouteProvider);
    final editRouteState = ref.watch(editRouteProvider);
    
    // Determine values based on mode
    final isSubmitting = _isEditMode 
        ? editRouteState.isLoading 
        : addRouteState.isLoading;
    
    final errorMessage = _isEditMode 
        ? editRouteState.error 
        : addRouteState.error;
    
    final isSuccess = _isEditMode 
        ? editRouteState.isSuccess 
        : addRouteState.isSuccess;
    
    // Show SnackBar if there's an error
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        
        // Clear error after showing it
        if (_isEditMode) {
          ref.read(editRouteProvider.notifier).clearError();
        } else {
          ref.read(addRouteProvider.notifier).clearError();
        }
      });
    }
    
    // Show success message and return to previous screen
    if (isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Recorrido actualizado exitosamente'
                : 'Recorrido creado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Reset state and return with a value to indicate success
        if (_isEditMode) {
          ref.read(editRouteProvider.notifier).reset();
        } else {
          ref.read(addRouteProvider.notifier).reset();
        }
        context.pop(true);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Recorrido' : 'Agregar Recorrido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Cargando datos del recorrido...'),
              ],
            ),
          )
        : SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Recorrido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name field
                  CustomTextFormField(
                    label: 'Nombre del Recorrido',
                    hint: 'Ej. Ruta Centro - Norte',
                    controller: _nameController,
                    onChanged: ref.read(addRouteFormProvider.notifier).onNameChanged,
                    errorMessage: routeForm.name.errorMessage ,
                  ),
                  const SizedBox(height: 16),
                  
                  // Description field (optional)
                  CustomTextFormField(
                    label: 'Descripción (opcional)',
                    hint: 'Ej. Recorrido principal que conecta el centro con la zona norte',
                    controller: _descriptionController,
                    onChanged: ref.read(addRouteFormProvider.notifier).onDescriptionChanged,
                    maxLines: 3,
                    errorMessage: routeForm.isFormPosted ?
                        routeForm.description.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 24),
                  
                  // Schedule section
                  const Text(
                    'Horario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Start Time field
                  GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: AbsorbPointer(
                      child: CustomTextFormField(
                        label: 'Hora de Inicio',
                        hint: 'Ej. 08:00',
                        controller: _startTimeController,
                        keyboardType: TextInputType.datetime,
                        suffixIcon: const Icon(Icons.access_time),
                        errorMessage: routeForm.startTime.errorMessage ,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // End Time field
                  GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: AbsorbPointer(
                      child: CustomTextFormField(
                        label: 'Hora de Fin',
                        hint: 'Ej. 20:00',
                        controller: _endTimeController,
                        keyboardType: TextInputType.datetime,
                        suffixIcon: const Icon(Icons.access_time),
                        errorMessage: routeForm.endTime.errorMessage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Days section
                  const Text(
                    'Días de Operación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Days selection
                  ..._availableDays.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;
                    return CheckboxListTile(
                      title: Text(day['label']),
                      value: day['selected'],
                      onChanged: (bool? value) {
                        if (value != null) {
                          _onDaySelected(index, value);
                        }
                      },
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    );
                  }),
                  
                  // Show error message if no day is selected
                  if (routeForm.days.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 4),
                          Text(
                            routeForm.days.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Status selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            // Active option
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('ACTIVO'),
                                ],
                              ),
                              subtitle: const Text('El recorrido está disponible para uso'),
                              value: 'activo',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addRouteFormProvider.notifier).onStatusChanged(value);
                                }
                              },
                              activeColor: Colors.green,
                              dense: true,
                            ),
                            const Divider(height: 1),
                            // Inactive option
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('INACTIVO'),
                                ],
                              ),
                              subtitle: const Text('El recorrido no está en servicio'),
                              value: 'inactivo',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addRouteFormProvider.notifier).onStatusChanged(value);
                                }
                              },
                              activeColor: Colors.red,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  CustomFilledButton(
                    text: _isEditMode ? 'Actualizar Recorrido' : 'Guardar Recorrido',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting 
                        ? null
                        : () async {
                            // Close keyboard
                            FocusScope.of(context).unfocus();
                            
                            print('Button pressed. Edit mode: $_isEditMode');
                            
                            // Validate form
                            bool isValid;
                            if (_isEditMode) {
                              // In edit mode, use edit validation
                              isValid = await ref.read(addRouteFormProvider.notifier).onFormSubmitForEditing();
                            } else {
                              // In create mode, use complete validation
                              isValid = await ref.read(addRouteFormProvider.notifier).onFormSubmit();
                            }
                            
                            print('Form validation: $isValid');
                            
                            if (!isValid) {
                              // Scroll to top to show errors
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              return;
                            }
                            
                            // Get selected days
                            List<String> selectedDays = _availableDays
                                .where((day) => day['selected'])
                                .map((day) => day['name'] as String)
                                .toList();
                            // Asegurar formato HH:MM:SS para la base de datos
                            String formatTimeForDatabase(String timeStr) {
                              // Si ya tiene el formato HH:MM:SS, devolverlo como está
                              if (timeStr.split(':').length == 3) return timeStr;
                              
                              // Si tiene formato HH:MM, añadir :00 para segundos
                              return '$timeStr:00';
                            }
                            // In edit mode
                            if (_isEditMode && widget.routeId != null) {
                              print('Updating route: ${widget.routeId}');
                              try {
                                await ref.read(editRouteProvider.notifier).updateRoute(
                                  routeId: widget.routeId!,
                                  name: _nameController.text,
                                  description: _descriptionController.text.isNotEmpty 
                                      ? _descriptionController.text 
                                      : null,
                                  startTime: _startTimeController.text,
                                  endTime: _endTimeController.text,
                                  days: selectedDays,
                                  status: _selectedStatus,
                                );
                                print('Route updated successfully');
                              } catch (e) {
                                print('Error updating route: $e');
                              }
                            } 
                            // In create mode
                            else {
                              print('Creating new route');
                              await ref.read(addRouteProvider.notifier).createRoute(
                                name: _nameController.text,
                                description: _descriptionController.text.isNotEmpty 
                                    ? _descriptionController.text 
                                    : null,
                                startTime: _startTimeController.text,
                                endTime: _endTimeController.text,
                                days: selectedDays,
                                status: _selectedStatus,
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}