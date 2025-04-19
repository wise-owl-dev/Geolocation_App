// lib/features/auth/presentation/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/error_handler.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/signup_form_provider.dart';
import '../providers/auth_provider.dart';


class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final signUpForm = ref.watch(signUpFormProvider);
    
    // Escuchar cambios en el estado de autenticación
    ref.listen(authProvider, (previous, current) {
      if (current.isAuthenticated && previous?.isAuthenticated != true) {
        // Si se autentica correctamente después del registro, navegar a la pantalla principal
        context.go('/home');
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro exitoso.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
    
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
                    
                  // Posicionar el botón para mostrar/ocultar contraseña
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
              // Ayuda para la contraseña
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  'La contraseña debe tener al menos 6 caracteres, una mayúscula, una minúscula y un número.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Campo de confirmar contraseña
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CustomTextFormField(
                    label: 'Confirmar Contraseña',
                    hint: '********',
                    obscureText: _obscureConfirmPassword,
                    onChanged: ref.read(signUpFormProvider.notifier).onConfirmPasswordChanged,
                    errorMessage: signUpForm.isFormPosted ?
                        (signUpForm.confirmPassword.errorMessage ?? 
                        (!signUpForm.passwordsMatch ? 'Las contraseñas no coinciden' : null))
                        : null, 
                  ),
                    
                  // Posicionar el botón para mostrar/ocultar contraseña
                  Positioned(
                    right: 15,
                    child: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
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
                text: signUpForm.isPosting ? 'Registrando...' : 'Registrarse',
                isLoading: signUpForm.isPosting,
                onPressed: signUpForm.isPosting 
                  ? null 
                  : () async {
                      try {
                        await ref.read(signUpFormProvider.notifier).onFormSubmit();
                      } catch (e) {
                        // Usar el servicio mejorado de manejo de errores para mostrar mensajes amigables
                        if (mounted) {
                          ErrorHandler.showAuthErrorSnackBar(context, e);
                        }
                      }
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
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
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
}