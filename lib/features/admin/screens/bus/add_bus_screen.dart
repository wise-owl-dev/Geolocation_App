import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/bus/add_bus_form_provider.dart';
import '../../providers/bus/add_bus_provider.dart';
import '../../providers/bus/edit_bus_provider.dart';
import '../../../../shared/widgets/custom_text_form_field.dart';
import '../../../../shared/widgets/custom_filled_button.dart';

class AddBusScreen extends ConsumerStatefulWidget {
  final String? busId;
  
  const AddBusScreen({
    Key? key, 
    this.busId,
  }) : super(key: key);

  @override
  ConsumerState<AddBusScreen> createState() => _AddBusScreenState();
}

class _AddBusScreenState extends ConsumerState<AddBusScreen> {
  final _scrollController = ScrollController();
  bool _isEditMode = false;
  bool _isLoading = false;
  String _selectedStatus = 'activo';

  // Text controllers
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  void dispose() {
    _busNumberController.dispose();
    _licensePlateController.dispose();
    _capacityController.dispose();
    _modelController.dispose();
    _brandController.dispose();
    _yearController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode
    _isEditMode = widget.busId != null;
    
    if (_isEditMode) {
      // Wait for the widget to be completely built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadBusData();
        }
      });
    }
  }

  Future<void> _loadBusData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Loading bus data for ID: ${widget.busId}');
      
      // Load the bus
      await ref.read(editBusProvider.notifier).loadBus(widget.busId!);
      
      // Get the data
      final busState = ref.read(editBusProvider);
      
      print('Bus state: ${busState.isLoading}, Error: ${busState.error}');
      
      final bus = busState.bus;
      
      if (bus == null) {
        print('⚠️ Bus not found');
        setState(() => _isLoading = false);
        return;
      }
      
      print('✅ Data received. ID: ${bus.id}, Number: ${bus.busNumber}');
      
      // Set values in controllers
      _busNumberController.text = bus.busNumber;
      _licensePlateController.text = bus.licensePlate;
      _capacityController.text = bus.capacity.toString();
      _modelController.text = bus.model;
      _brandController.text = bus.brand;
      _yearController.text = bus.year.toString();
      
      // Update status
      setState(() {
        _selectedStatus = bus.status;
      });
      
      // Also update form state
      final formNotifier = ref.read(addBusFormProvider.notifier);
      formNotifier.onBusNumberChanged(bus.busNumber);
      formNotifier.onLicensePlateChanged(bus.licensePlate);
      formNotifier.onCapacityChanged(bus.capacity.toString());
      formNotifier.onModelChanged(bus.model);
      formNotifier.onBrandChanged(bus.brand);
      formNotifier.onYearChanged(bus.year.toString());
      formNotifier.onStatusChanged(bus.status);
      
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

  @override
  Widget build(BuildContext context) {
    // Get form state
    final busForm = ref.watch(addBusFormProvider);
    
    // Get bus creation/editing state
    final addBusState = ref.watch(addBusProvider);
    final editBusState = ref.watch(editBusProvider);
    
    // Determine values based on mode
    final isSubmitting = _isEditMode 
        ? editBusState.isLoading 
        : addBusState.isLoading;
    
    final errorMessage = _isEditMode 
        ? editBusState.error 
        : addBusState.error;
    
    final isSuccess = _isEditMode 
        ? editBusState.isSuccess 
        : addBusState.isSuccess;
    
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
          ref.read(editBusProvider.notifier).clearError();
        } else {
          ref.read(addBusProvider.notifier).clearError();
        }
      });
    }
    
    // Show success message and return to previous screen
    if (isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Autobús actualizado exitosamente'
                : 'Autobús creado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Reset state and return with a value to indicate success
        if (_isEditMode) {
          ref.read(editBusProvider.notifier).reset();
        } else {
          ref.read(addBusProvider.notifier).reset();
        }
        context.pop(true);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Autobús' : 'Agregar Autobús'),
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
                const Text('Cargando datos del autobús...'),
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
                    'Información del Autobús',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bus Number field
                  CustomTextFormField(
                    label: 'Número de Unidad',
                    hint: 'Ej. BUS001',
                    controller: _busNumberController,
                    onChanged: ref.read(addBusFormProvider.notifier).onBusNumberChanged,
                    errorMessage: busForm.isFormPosted ?
                        busForm.busNumber.errorMessage 
                        : null,
                    enabled: !_isEditMode, // Don't allow editing in edit mode
                  ),
                  const SizedBox(height: 16),
                  
                  // License Plate field
                  CustomTextFormField(
                    label: 'Placa',
                    hint: 'Ej. ABC-123',
                    controller: _licensePlateController,
                    onChanged: ref.read(addBusFormProvider.notifier).onLicensePlateChanged,
                    errorMessage: busForm.isFormPosted ?
                        busForm.licensePlate.errorMessage 
                        : null,
                    enabled: !_isEditMode, // Don't allow editing in edit mode
                  ),
                  const SizedBox(height: 16),
                  
                  // Capacity field
                  CustomTextFormField(
                    label: 'Capacidad',
                    hint: 'Ej. 40',
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    onChanged: ref.read(addBusFormProvider.notifier).onCapacityChanged,
                    errorMessage: busForm.isFormPosted ?
                        busForm.capacity.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Model field
                  CustomTextFormField(
                    label: 'Modelo',
                    hint: 'Ej. Sprinter',
                    controller: _modelController,
                    onChanged: ref.read(addBusFormProvider.notifier).onModelChanged,
                    errorMessage: busForm.isFormPosted ?
                        busForm.model.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Brand field
                  CustomTextFormField(
                    label: 'Marca',
                    hint: 'Ej. Mercedes-Benz',
                    controller: _brandController,
                    onChanged: ref.read(addBusFormProvider.notifier).onBrandChanged,
                    errorMessage: busForm.isFormPosted ?
                        busForm.brand.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Year field
                  CustomTextFormField(
                    label: 'Año',
                    hint: 'Ej. 2022',
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    onChanged: ref.read(addBusFormProvider.notifier).onYearChanged,
                    errorMessage: busForm.isFormPosted ?
                        busForm.year.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
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
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('ACTIVO'),
                                ],
                              ),
                              subtitle: const Text('El autobús está disponible para operaciones'),
                              value: 'activo',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addBusFormProvider.notifier).onStatusChanged(value);
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
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('INACTIVO'),
                                ],
                              ),
                              subtitle: const Text('El autobús no está en servicio'),
                              value: 'inactivo',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addBusFormProvider.notifier).onStatusChanged(value);
                                }
                              },
                              activeColor: Colors.red,
                              dense: true,
                            ),
                            const Divider(height: 1),
                            // Maintenance option
                            RadioListTile<String>(
                              title: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('MANTENIMIENTO'),
                                ],
                              ),
                              subtitle: const Text('El autobús está en mantenimiento o reparación'),
                              value: 'mantenimiento',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addBusFormProvider.notifier).onStatusChanged(value);
                                }
                              },
                              activeColor: Colors.orange,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                      if (busForm.isFormPosted && busForm.status.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, left: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                busForm.status.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Save button
                  CustomFilledButton(
                    text: _isEditMode ? 'Actualizar Autobús' : 'Guardar Autobús',
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
                              isValid = await ref.read(addBusFormProvider.notifier).onFormSubmitForEditing();
                            } else {
                              // In create mode, use complete validation
                              isValid = await ref.read(addBusFormProvider.notifier).onFormSubmit();
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
                            
                            // In edit mode
                            if (_isEditMode && widget.busId != null) {
                              print('Updating bus: ${widget.busId}');
                              try {
                                await ref.read(editBusProvider.notifier).updateBus(
                                  busId: widget.busId!,
                                  busNumber: busForm.busNumber.value,
                                  licensePlate: busForm.licensePlate.value,
                                  capacity: int.parse(busForm.capacity.value),
                                  model: busForm.model.value,
                                  brand: busForm.brand.value,
                                  year: int.parse(busForm.year.value),
                                  status: _selectedStatus,
                                );
                                print('Bus updated successfully');
                              } catch (e) {
                                print('Error updating bus: $e');
                              }
                            } 
                            // In create mode
                            else {
                              print('Creating new bus');
                              await ref.read(addBusProvider.notifier).createBus(
                                busNumber: busForm.busNumber.value,
                                licensePlate: busForm.licensePlate.value,
                                capacity: int.parse(busForm.capacity.value),
                                model: busForm.model.value,
                                brand: busForm.brand.value,
                                year: int.parse(busForm.year.value),
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