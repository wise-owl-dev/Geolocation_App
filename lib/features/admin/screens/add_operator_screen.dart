// lib/features/admin/screens/add_operator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/add_operator_form_provider.dart';
import '../providers/add_operator_provider.dart';
import '../providers/edit_operator_provider.dart';
import '../../../shared/widgets/custom_text_form_field.dart';
import '../../../shared/widgets/custom_filled_button.dart';
import '../../../shared/models/operator.dart';

class AddOperatorScreen extends ConsumerStatefulWidget {
  final String? operatorId;
  
  const AddOperatorScreen({
    Key? key, 
    this.operatorId,
  }) : super(key: key);

  @override
  ConsumerState<AddOperatorScreen> createState() => _AddOperatorScreenState();
}

class _AddOperatorScreenState extends ConsumerState<AddOperatorScreen> {
  bool _obscurePassword = true;
  DateTime _selectedDate = DateTime.now();
  final _scrollController = ScrollController();
  bool _isEditMode = false;
  bool _isLoading = false;

  
  @override
void initState() {
  super.initState();
  
  // Verificar si estamos en modo edición
  _isEditMode = widget.operatorId != null;
  
  // No cargar datos aquí, lo haremos después del primer frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_isEditMode && mounted) {
      _loadOperatorData();
    }
  });
}

Future<void> _loadOperatorData() async {
  if (!mounted) return;
  
  setState(() => _isLoading = true);
  
  try {
    print('Cargando datos del operador ID: ${widget.operatorId}');
    
    // Primero, cargar el operador
    await ref.read(editOperatorProvider.notifier).loadOperator(widget.operatorId!);
    
    // Asegurarnos que el widget sigue montado
    if (!mounted) return;
    
    // Obtener los datos del operador
    final operatorState = ref.read(editOperatorProvider);
    final operator = operatorState.operator;
    
    if (operator == null) {
      print('No se pudieron obtener datos del operador');
      setState(() => _isLoading = false);
      return;
    }
    
    print('Datos obtenidos: Nombre=${operator.name}, Email=${operator.email}');
    
    // Necesitamos un pequeño delay para que el formulario se actualice correctamente
    await Future.delayed(Duration(milliseconds: 200));
    
    if (!mounted) return;
    
    // Actualizar los campos del formulario uno por uno
    final formNotifier = ref.read(addOperatorFormProvider.notifier);
    
    // Campos básicos
    formNotifier.onEmailChange(operator.email);
    print('Email actualizado: ${operator.email}');
    
    formNotifier.onNameChanged(operator.name);
    print('Nombre actualizado: ${operator.name}');
    
    if (operator.lastNamePaterno != null) {
      formNotifier.onLastNameChanged(operator.lastNamePaterno!);
      print('Apellido paterno actualizado: ${operator.lastNamePaterno}');
    }
    
    if (operator.lastNameMaterno != null && operator.lastNameMaterno!.isNotEmpty) {
      formNotifier.onMaternalLastNameChanged(operator.lastNameMaterno!);
      print('Apellido materno actualizado: ${operator.lastNameMaterno}');
    }
    
    if (operator.phone != null) {
      formNotifier.onPhoneChanged(operator.phone!);
      print('Teléfono actualizado: ${operator.phone}');
    }
    
    // Campos específicos de operador
    formNotifier.onLicenseNumberChanged(operator.licenseNumber);
    print('Número de licencia actualizado: ${operator.licenseNumber}');
    
    formNotifier.onLicenseTypeChanged(operator.licenseType);
    print('Tipo de licencia actualizado: ${operator.licenseType}');
    
    formNotifier.onYearsExperienceChanged(operator.yearsExperience.toString());
    print('Años de experiencia actualizado: ${operator.yearsExperience}');
    
    // Actualizar la fecha seleccionada
    setState(() {
      _selectedDate = operator.hireDate;
      print('Fecha de contratación actualizada: $_selectedDate');
    });
    
    formNotifier.onHireDateChanged(operator.hireDate);
    
    print('Formulario completamente actualizado');
    
  } catch (e) {
    print('Error cargando datos del operador: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el estado del formulario
    final operatorForm = ref.watch(addOperatorFormProvider);
    
    // Obtener el estado de la creación/edición de operador
    final addOperatorState = ref.watch(addOperatorProvider);
    final editOperatorState = ref.watch(editOperatorProvider);
    
    // Determinar valores según el modo
    final isSubmitting = _isEditMode 
        ? editOperatorState.isLoading 
        : addOperatorState.isLoading;
    
    final errorMessage = _isEditMode 
        ? editOperatorState.error 
        : addOperatorState.error;
    
    final isSuccess = _isEditMode 
        ? editOperatorState.isSuccess 
        : addOperatorState.isSuccess;
    
    // Mostrar SnackBar si hay un error
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
        
        // Limpiar el error después de mostrarlo
        if (_isEditMode) {
          ref.read(editOperatorProvider.notifier).clearError();
        } else {
          ref.read(addOperatorProvider.notifier).clearError();
        }
      });
    }
    
    // Mostrar mensaje de éxito y regresar a la pantalla anterior
    if (isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Operador actualizado exitosamente'
                : 'Operador creado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Resetear el estado y regresar con un valor para indicar éxito
        if (_isEditMode) {
          ref.read(editOperatorProvider.notifier).reset();
        } else {
          ref.read(addOperatorProvider.notifier).reset();
        }
        context.pop(true);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Conductor' : 'Agregar Conductor'),
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
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando datos del conductor...'),
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
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de nombre
                    CustomTextFormField(
                      label: 'Nombre',
                      hint: 'Ingrese el nombre',
                      onChanged: ref.read(addOperatorFormProvider.notifier).onNameChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.name.errorMessage 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de apellido paterno
                    CustomTextFormField(
                      label: 'Apellido Paterno',
                      hint: 'Ingrese el apellido paterno',
                      onChanged: ref.read(addOperatorFormProvider.notifier).onLastNameChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.lastName.errorMessage 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de apellido materno
                    CustomTextFormField(
                      label: 'Apellido Materno (opcional)',
                      hint: 'Ingrese el apellido materno',
                      onChanged: ref.read(addOperatorFormProvider.notifier).onMaternalLastNameChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.maternalLastName.errorMessage 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de email
                    CustomTextFormField(
                      label: 'Email',
                      hint: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      onChanged: ref.read(addOperatorFormProvider.notifier).onEmailChange,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.email.errorMessage 
                          : null,
                      enabled: !_isEditMode, // No permitir editar email en modo edición
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de contraseña (solo visible en modo creación)
                    if (!_isEditMode) ...[
                      Stack(
                        alignment: Alignment.centerRight,
                        children: [
                          CustomTextFormField(
                            label: 'Contraseña',
                            hint: '********',
                            obscureText: _obscurePassword,
                            onChanged: ref.read(addOperatorFormProvider.notifier).onPasswordChanged,
                            errorMessage: operatorForm.isFormPosted ?
                                operatorForm.password.errorMessage 
                                : null,
                          ),
                          
                          // Botón para mostrar/ocultar contraseña
                          Positioned(
                            right: 15,
                            child: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (operatorForm.isFormPosted && operatorForm.password.errorMessage == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Text(
                            'La contraseña debe tener al menos 6 caracteres, una mayúscula y un número',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Campo de teléfono
                    CustomTextFormField(
                      label: 'Teléfono',
                      hint: 'Ingrese el número de teléfono',
                      keyboardType: TextInputType.phone,
                      onChanged: ref.read(addOperatorFormProvider.notifier).onPhoneChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.phone.errorMessage 
                          : null,
                    ),
                    const SizedBox(height: 32),
                    
                    // Sección de información de operador
                    const Text(
                      'Información de Operador',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de número de licencia
                    CustomTextFormField(
                      label: 'Número de Licencia',
                      hint: 'Ej. A123456',
                      onChanged: ref.read(addOperatorFormProvider.notifier).onLicenseNumberChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.licenseNumber.errorMessage 
                          : null,
                      enabled: !_isEditMode, // No permitir editar licencia en modo edición
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de tipo de licencia
                    CustomTextFormField(
                      label: 'Tipo de Licencia',
                      hint: 'Ej. Profesional Tipo C',
                      onChanged: ref.read(addOperatorFormProvider.notifier).onLicenseTypeChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.licenseType.errorMessage 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de años de experiencia
                    CustomTextFormField(
                      label: 'Años de Experiencia',
                      hint: 'Ej. 5',
                      keyboardType: TextInputType.number,
                      onChanged: ref.read(addOperatorFormProvider.notifier).onYearsExperienceChanged,
                      errorMessage: operatorForm.isFormPosted ?
                          operatorForm.yearsExperience.errorMessage 
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de fecha de contratación
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fecha de Contratación',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Botón de guardar
                    CustomFilledButton(
                      text: _isEditMode ? 'Actualizar Conductor' : 'Guardar Conductor',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting 
                          ? null  // Si está cargando, deshabilitar el botón
                          : () async {
                              // Cerrar el teclado
                              FocusScope.of(context).unfocus();
                              
                              print('Botón presionado. Modo edición: $_isEditMode');
                              
                              // Validar el formulario
                              bool isValid;
                              if (_isEditMode) {
                                // En modo edición, usar la validación para edición
                                isValid = await ref.read(addOperatorFormProvider.notifier).onFormSubmitForEditing();
                              } else {
                                // En modo creación, usar la validación completa
                                isValid = await ref.read(addOperatorFormProvider.notifier).onFormSubmit();
                              }
                              
                              print('Validación del formulario: $isValid');
                              
                              if (!isValid) {
                                // Scroll al inicio para mostrar errores
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                return;
                              }
                              
                              // En modo edición
                              if (_isEditMode && widget.operatorId != null) {
                                print('Actualizando operador: ${widget.operatorId}');
                                try {
                                  await ref.read(editOperatorProvider.notifier).updateOperator(
                                    operatorId: widget.operatorId!,
                                    name: operatorForm.name.value,
                                    lastName: operatorForm.lastName.value,
                                    phone: operatorForm.phone.value,
                                    licenseType: operatorForm.licenseType.value,
                                    yearsExperience: int.parse(operatorForm.yearsExperience.value),
                                    hireDate: _selectedDate,
                                    maternalLastName: operatorForm.maternalLastName.value,
                                  );
                                  print('Operador actualizado correctamente');
                                } catch (e) {
                                  print('Error al actualizar operador: $e');
                                }
                              } 
                              // En modo creación
                              else {
                                print('Creando nuevo operador');
                                await ref.read(addOperatorProvider.notifier).createOperator(
                                  name: operatorForm.name.value,
                                  lastName: operatorForm.lastName.value,
                                  email: operatorForm.email.value,
                                  password: operatorForm.password.value,
                                  phone: operatorForm.phone.value,
                                  licenseNumber: operatorForm.licenseNumber.value,
                                  licenseType: operatorForm.licenseType.value,
                                  yearsExperience: int.parse(operatorForm.yearsExperience.value),
                                  hireDate: _selectedDate,
                                  maternalLastName: operatorForm.maternalLastName.value,
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
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      ref.read(addOperatorFormProvider.notifier).onHireDateChanged(picked);
    }
  }
}