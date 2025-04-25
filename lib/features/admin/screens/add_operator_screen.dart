import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/add_operator_form_provider.dart';
import '../providers/add_operator_provider.dart';
import '../../../shared/widgets/custom_text_form_field.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class AddOperatorScreen extends ConsumerStatefulWidget {
  const AddOperatorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddOperatorScreen> createState() => _AddOperatorScreenState();
}

class _AddOperatorScreenState extends ConsumerState<AddOperatorScreen> {
  bool _obscurePassword = true;
  DateTime _selectedDate = DateTime.now();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el estado del formulario
    final operatorForm = ref.watch(addOperatorFormProvider);
    
    // Obtener el estado de la creación de operador
    final operatorState = ref.watch(addOperatorProvider);
    
    // Mostrar SnackBar si hay un error
    if (operatorState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(operatorState.error!),
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
        ref.read(addOperatorProvider.notifier).clearError();
      });
    }
    
    // Mostrar mensaje de éxito y regresar a la pantalla anterior
    if (operatorState.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Operador creado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Resetear el estado y regresar
        ref.read(addOperatorProvider.notifier).reset();
        context.pop();
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Operador'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
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
              ),
              const SizedBox(height: 16),
              
              // Campo de contraseña
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
                text: 'Guardar Operador',
                isLoading: operatorState.isLoading,
                onPressed: () async {
                  // Cerrar el teclado
                  FocusScope.of(context).unfocus();
                  
                  // Validar el formulario
                  final isValid = await ref.read(addOperatorFormProvider.notifier).onFormSubmit();
                  
                  if (!isValid) {
                    // Scroll al inicio para mostrar errores
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    return;
                  }
                  
                  // Crear el operador
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