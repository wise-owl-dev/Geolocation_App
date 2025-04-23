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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error!),
            backgroundColor: Colors.red,
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
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.name.errorMessage 
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Campo de apellido paterno
              CustomTextFormField(
                label: 'Apellido Paterno',
                hint: 'Ingrese su apellido paterno',
                onChanged: ref.read(signUpFormProvider.notifier).onLastNameChanged,
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.lastName.errorMessage 
                    : null,
              ),
              const SizedBox(height: 16),
              
              // Campo de apellido materno
              CustomTextFormField(
                label: 'Apellido Materno',
                hint: 'Ingrese su apellido materno',
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
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.email.errorMessage 
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
                    onChanged: ref.read(signUpFormProvider.notifier).onPasswordChanged,
                    errorMessage: signUpForm.isFormPosted ?
                        signUpForm.password.errorMessage 
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
              const SizedBox(height: 16),
              
              // Campo de teléfono
              CustomTextFormField(
                label: 'Teléfono',
                hint: 'Ingrese su número de teléfono',
                keyboardType: TextInputType.phone,
                onChanged: ref.read(signUpFormProvider.notifier).onPhoneChanged,
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.phone.errorMessage 
                    : null,
              ),
              const SizedBox(height: 32),
              
              // Botón de registro
              CustomFilledButton(
                text: 'Registrarse',
                isLoading: authState.isLoading,
                onPressed: () async {
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