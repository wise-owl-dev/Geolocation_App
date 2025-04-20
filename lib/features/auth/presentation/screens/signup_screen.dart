import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/features/auth/auth.dart';
import 'package:maps/features/shared/shared.dart';


class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

    @override
    ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
  }
  
  class _SignUpScreenState extends ConsumerState<SignUpScreen> {
    bool _obscurePassword = true;
  
    @override
    Widget build(BuildContext context) {
      
       final signUpForm = ref.watch(signUpFormProvider);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
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
              CustomTextFormField(
                label: 'Nombre',
                hint: 'Ingrese su nombre',
                onChanged: ref.read(signUpFormProvider.notifier).onNameChanged,
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.name.errorMessage 
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                label: 'Apellido Paterno',
                hint: 'Ingrese su apellido paterno',
                onChanged: ref.read(signUpFormProvider.notifier).onLastNameChanged,
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.lastName.errorMessage 
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                label: 'Apellido Materno',
                hint: 'Ingrese su apellido materno',
                onChanged: ref.read(signUpFormProvider.notifier).onLastNameChanged,
                errorMessage: signUpForm.isFormPosted ?
                    signUpForm.lastName.errorMessage 
                    : null,
              ),
              const SizedBox(height: 16),
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
              Stack(
              alignment: Alignment.centerRight,
              children: [
                CustomTextFormField(
                  label: 'Contraseña',
                  hint: '********',
                  obscureText: _obscurePassword,
                  onChanged: ref.read(signUpFormProvider.notifier).onPasswordChanged,
                  errorMessage:signUpForm.isFormPosted ?
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
              const SizedBox(height: 16),
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
              CustomFilledButton(
                text: 'Registrarse',
                onPressed: () { 
                  ref.read(signUpFormProvider.notifier).onFormSubmit();
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
                    onPressed: () => context.push('/login'),
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
