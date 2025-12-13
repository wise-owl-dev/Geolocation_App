import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/signup_form_provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_form_field.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // Obtener el estado del formulario
    final signUpForm = ref.watch(signUpFormProvider);
    
    // Obtener el estado de autenticación
    final authState = ref.watch(authProvider);
    
    // Mostrar SnackBar si hay un error de autenticación
    if (authState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Personalizar mensaje de error basado en el código
        String errorMessage = authState.error!;
        
        // No mostrar mensajes de error técnicos
        if (authState.errorCode == 'auth/email-already-exists') {
          errorMessage = 'Este email ya está registrado. Intenta con otro o inicia sesión.';
        } else if (authState.errorCode == 'auth/weak-password') {
          errorMessage = 'La contraseña no cumple con los requisitos de seguridad.';
        }
        
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
        ref.read(authProvider.notifier).clearError();
      });
    }
    
    // Redirigir si ya está autenticado
    if (authState.isAuthenticated && authState.user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authState.user!.isAdmin) {
          context.go('/admin-dashboard');
        } else if (authState.user!.isOperator) {
          context.go('/operator-dashboard');
        } else {
          context.go('/user-dashboard');
        }
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Crear cuenta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete el formulario para registrarse',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Campo de nombre
              CustomTextFormField(
                label: 'Nombre',
                hint: 'Ingrese su nombre',
                onChanged: ref.read(signUpFormProvider.notifier).onNameChanged,
                errorMessage: signUpForm.name.errorMessage,
              ),
              const SizedBox(height: 16),
              
              // Campo de apellido paterno
              CustomTextFormField(
                label: 'Primer Apellido',
                hint: 'Ingrese su primer apellido',
                onChanged: ref.read(signUpFormProvider.notifier).onLastNameChanged,
                errorMessage: signUpForm.lastName.errorMessage ,
              ),
              const SizedBox(height: 16),
              
              // Campo de apellido materno
              CustomTextFormField(
                label: 'Segundo Apellido (opcional)',
                hint: 'Ingrese su segundo apellido',
                onChanged: ref.read(signUpFormProvider.notifier).onMaternalLastNameChanged,
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.maternalLastName.errorMessage 
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Campo de email
              CustomTextFormField(
                label: 'Email',
                hint: 'correo@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: ref.read(signUpFormProvider.notifier).onEmailChange,
                errorMessage: signUpForm.email.errorMessage ,
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
                    onChanged: ref.read(signUpFormProvider.notifier).onPasswordChanged,
                    errorMessage: signUpForm.password.errorMessage ,
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
              if (signUpForm.isFormPosted && signUpForm.password.errorMessage == null)
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
                hint: 'Ingrese su número de teléfono',
                keyboardType: TextInputType.phone,
                onChanged: ref.read(signUpFormProvider.notifier).onPhoneChanged,
                errorMessage: signUpForm.phone.errorMessage ,
              ),
              const SizedBox(height: 32),
              
              // Botón de registro
              CustomFilledButton(
                text: 'Registrarse',
                isLoading: authState.isLoading,
                onPressed: () async {
                  // Cerrar el teclado
                  FocusScope.of(context).unfocus();
                  
                  // Usar el método onFormSubmit para validar el formulario
                  final isValid = await ref.read(signUpFormProvider.notifier).onFormSubmit();
                  
                  if (!isValid) return;
                  
                  // Registrar el usuario utilizando el authProvider
                  await ref.read(authProvider.notifier).signUp(
                    signUpForm.name.value,
                    signUpForm.lastName.value,
                    signUpForm.maternalLastName.value,
                    signUpForm.email.value,
                    signUpForm.password.value,
                    signUpForm.phone.value,
                  );
                },
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿Ya tienes una cuenta? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}