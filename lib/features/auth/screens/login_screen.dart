import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/login_form_provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_form_field.dart';
import '../../../shared/widgets/custom_filled_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    // Obtener el estado del formulario
    final loginForm = ref.watch(loginFormProvider);

    // Obtener el estado de autenticación
    final authState = ref.watch(authProvider);

    // Mostrar SnackBar si hay un error de autenticación
    if (authState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Personalizar mensaje de error basado en el código
        String errorMessage = authState.error!;
        
        // No mostrar mensajes de error técnicos
        if (authState.errorCode == 'auth/invalid-credentials') {
          errorMessage = 'Email o contraseña incorrectos. Intenta de nuevo.';
        } else if (authState.errorCode == 'auth/email-not-verified') {
          errorMessage = 'Por favor, confirma tu email antes de iniciar sesión.';
        } else if (authState.errorCode == 'auth/too-many-requests') {
          errorMessage = 'Demasiados intentos fallidos. Intenta más tarde.';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),

                // Campo de email
                CustomTextFormField(
                  label: 'Email',
                  hint: 'correo@ejemplo.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: ref.read(loginFormProvider.notifier).onEmailChange,
                  errorMessage:
                      loginForm.isFormPosted
                          ? loginForm.email.errorMessage
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
                      onChanged:
                          ref
                              .read(loginFormProvider.notifier)
                              .onPasswordChanged,
                      errorMessage:
                          loginForm.isFormPosted
                              ? loginForm.password.errorMessage
                              : null,
                    ),

                    // Botón para mostrar/ocultar contraseña
                    Positioned(
                      right: 15,
                      child: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                _buildForgotPasswordLink(),

                const SizedBox(height: 24),

                // Botón de inicio de sesión
                CustomFilledButton(
                  text: 'Iniciar Sesión',
                  isLoading: authState.isLoading,
                  onPressed: () async {
                    // Cerrar el teclado
                    FocusScope.of(context).unfocus();
                    
                    // Usar el método onFormSubmit para validar el formulario
                    final isValid =
                        await ref
                            .read(loginFormProvider.notifier)
                            .onFormSubmit();

                    if (!isValid) return;

                    // Llamar al servicio de autenticación real
                    await ref
                        .read(authProvider.notifier)
                        .login(loginForm.email.value, loginForm.password.value);
                  },
                ),

                const SizedBox(height: 24),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
   Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            const Text(
              'Autotransportes Zaachila-Yoo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingrese su correo electrónico y contraseña para continuar',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad no implementada'),
              behavior: SnackBarBehavior.floating,
            )
          );
        },
        child: const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "¿No tienes una cuenta?",
          style: TextStyle(color: Colors.black54),
        ),
        TextButton(
          onPressed: () => context.push('/signup'),
          child: const Text(
            'Regístrate',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
}