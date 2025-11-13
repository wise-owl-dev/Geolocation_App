import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../providers/bus_stop/add_busstop_form_provider.dart';
import '../../providers/bus_stop/add_busstop_provider.dart';
import '../../providers/bus_stop/edit_busstop_provider.dart';



class AddBusStopScreen extends ConsumerStatefulWidget {
  final String? busStopId;
  
  const AddBusStopScreen({
    super.key, 
    this.busStopId,
  });

  @override
  ConsumerState<AddBusStopScreen> createState() => _AddBusStopScreenState();
}

class _AddBusStopScreenState extends ConsumerState<AddBusStopScreen> {
  final _scrollController = ScrollController();
  bool _isEditMode = false;
  bool _isLoading = false;
  String _selectedStatus = 'activo';

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Check if we're in edit mode
    _isEditMode = widget.busStopId != null;
    
    if (_isEditMode) {
      // Wait for the widget to be completely built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadBusStopData();
        }
      });
    }
  }

  Future<void> _loadBusStopData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('Loading bus stop data for ID: ${widget.busStopId}');
      
      // Load the bus stop
      await ref.read(editBusStopProvider.notifier).loadBusStop(widget.busStopId!);
      
      // Get the data
      final busStopState = ref.read(editBusStopProvider);
      
      print('Bus stop state: ${busStopState.isLoading}, Error: ${busStopState.error}');
      
      final busStop = busStopState.busStop;
      
      if (busStop == null) {
        print('⚠️ Bus stop not found');
        setState(() => _isLoading = false);
        return;
      }
      
      print('✅ Data received. ID: ${busStop.id}, Name: ${busStop.name}');
      
      // Set values in controllers
      _nameController.text = busStop.name;
      _latitudeController.text = busStop.latitude.toString();
      _longitudeController.text = busStop.longitude.toString();
      if (busStop.address != null) _addressController.text = busStop.address!;
      if (busStop.reference != null) _referenceController.text = busStop.reference!;
      
      // Update status
      setState(() {
        _selectedStatus = busStop.status;
      });
      
      // Also update form state
      final formNotifier = ref.read(addBusStopFormProvider.notifier);
      formNotifier.onNameChanged(busStop.name);
      formNotifier.onLatitudeChanged(busStop.latitude.toString());
      formNotifier.onLongitudeChanged(busStop.longitude.toString());
      if (busStop.address != null) formNotifier.onAddressChanged(busStop.address!);
      if (busStop.reference != null) formNotifier.onReferenceChanged(busStop.reference!);
      formNotifier.onStatusChanged(busStop.status);
      
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
    final busStopForm = ref.watch(addBusStopFormProvider);
    
    // Get bus stop creation/editing state
    final addBusStopState = ref.watch(addBusStopProvider);
    final editBusStopState = ref.watch(editBusStopProvider);
    
    // Determine values based on mode
    final isSubmitting = _isEditMode 
        ? editBusStopState.isLoading 
        : addBusStopState.isLoading;
    
    final errorMessage = _isEditMode 
        ? editBusStopState.error 
        : addBusStopState.error;
    
    final isSuccess = _isEditMode 
        ? editBusStopState.isSuccess 
        : addBusStopState.isSuccess;
    
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
          ref.read(editBusStopProvider.notifier).clearError();
        } else {
          ref.read(addBusStopProvider.notifier).clearError();
        }
      });
    }
    
    // Show success message and return to previous screen
    if (isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Parada actualizada exitosamente'
                : 'Parada creada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Reset state and return with a value to indicate success
        if (_isEditMode) {
          ref.read(editBusStopProvider.notifier).reset();
        } else {
          ref.read(addBusStopProvider.notifier).reset();
        }
        context.pop(true);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Parada' : 'Agregar Parada'),
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
                const Text('Cargando datos de la parada...'),
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
                    'Información de la Parada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name field
                  CustomTextFormField(
                    label: 'Nombre de la Parada',
                    hint: 'Ej. Estación Central',
                    controller: _nameController,
                    onChanged: ref.read(addBusStopFormProvider.notifier).onNameChanged,
                    errorMessage: busStopForm.isFormPosted ?
                        busStopForm.name.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Location section
                  const Text(
                    'Ubicación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Latitude field
                  CustomTextFormField(
                    label: 'Latitud',
                    hint: 'Ej. 19.4326',
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: ref.read(addBusStopFormProvider.notifier).onLatitudeChanged,
                    errorMessage: busStopForm.isFormPosted ?
                        busStopForm.latitude.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Longitude field
                  CustomTextFormField(
                    label: 'Longitud',
                    hint: 'Ej. -99.1332',
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    onChanged: ref.read(addBusStopFormProvider.notifier).onLongitudeChanged,
                    errorMessage: busStopForm.isFormPosted ?
                        busStopForm.longitude.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Additional information section
                  const Text(
                    'Información Adicional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Address field (optional)
                  CustomTextFormField(
                    label: 'Dirección (opcional)',
                    hint: 'Ej. Av. Principal #123',
                    controller: _addressController,
                    onChanged: ref.read(addBusStopFormProvider.notifier).onAddressChanged,
                    errorMessage: busStopForm.isFormPosted ?
                        busStopForm.address.errorMessage 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Reference field (optional)
                  CustomTextFormField(
                    label: 'Referencia (opcional)',
                    hint: 'Ej. Frente al parque municipal',
                    controller: _referenceController,
                    onChanged: ref.read(addBusStopFormProvider.notifier).onReferenceChanged,
                    errorMessage: busStopForm.isFormPosted ?
                        busStopForm.reference.errorMessage 
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
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('ACTIVO'),
                                ],
                              ),
                              subtitle: const Text('La parada está disponible para uso'),
                              value: 'activo',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addBusStopFormProvider.notifier).onStatusChanged(value);
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
                              subtitle: const Text('La parada no está en servicio'),
                              value: 'inactivo',
                              groupValue: _selectedStatus,
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedStatus = value;
                                  });
                                  ref.read(addBusStopFormProvider.notifier).onStatusChanged(value);
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
                    text: _isEditMode ? 'Actualizar Parada' : 'Guardar Parada',
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
                              isValid = await ref.read(addBusStopFormProvider.notifier).onFormSubmitForEditing();
                            } else {
                              // In create mode, use complete validation
                              isValid = await ref.read(addBusStopFormProvider.notifier).onFormSubmit();
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
                            
                            // Get double values from text fields
                            final latitude = double.tryParse(_latitudeController.text) ?? 0.0;
                            final longitude = double.tryParse(_longitudeController.text) ?? 0.0;
                            
                            // In edit mode
                            if (_isEditMode && widget.busStopId != null) {
                              print('Updating bus stop: ${widget.busStopId}');
                              try {
                                await ref.read(editBusStopProvider.notifier).updateBusStop(
                                  busStopId: widget.busStopId!,
                                  name: _nameController.text,
                                  latitude: latitude,
                                  longitude: longitude,
                                  address: _addressController.text.isNotEmpty ? _addressController.text : null,
                                  reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
                                  status: _selectedStatus,
                                );
                                print('Bus stop updated successfully');
                              } catch (e) {
                                print('Error updating bus stop: $e');
                              }
                            } 
                            // In create mode
                            else {
                              print('Creating new bus stop');
                              await ref.read(addBusStopProvider.notifier).createBusStop(
                                name: _nameController.text,
                                latitude: latitude,
                                longitude: longitude,
                                address: _addressController.text.isNotEmpty ? _addressController.text : null,
                                reference: _referenceController.text.isNotEmpty ? _referenceController.text : null,
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