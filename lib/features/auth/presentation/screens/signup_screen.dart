// lib/features/auth/presentation/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Valores del formulario
  String name = '';
  String lastName = '';
  String maternalLastName = '';
  String email = '';
  String password = '';
  String confirmPassword = '';
  String phone = '';
  bool isFormPosted = false;
  bool isPosting = false;

  @override
  Widget build(BuildContext context) {
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
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
                errorMessage: isFormPosted && name.isEmpty ? 
                    'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              // Campo de apellido paterno
              CustomTextFormField(
                label: 'Apellido Paterno',
                hint: 'Ingrese su apellido paterno',
                onChanged: (value) {
                  setState(() {
                    lastName = value;
                  });
                },
                errorMessage: isFormPosted && lastName.isEmpty ? 
                    'El apellido paterno es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              // Campo de apellido materno
              CustomTextFormField(
                label: 'Apellido Materno',
                hint: 'Ingrese su apellido materno',
                onChanged: (value) {
                  setState(() {
                    maternalLastName = value;
                  });
                },
                errorMessage: isFormPosted && maternalLastName.isEmpty ? 
                    'El apellido materno es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              // Campo de email
              CustomTextFormField(
                label: 'Email',
                hint: 'correo@ejemplo.com',
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    email = value;
                  });
                },
                errorMessage: isFormPosted && (email.isEmpty || !email.contains('@')) ? 
                    'Ingrese un email válido' : null,
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
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    errorMessage: isFormPosted && password.length < 6 ? 
                        'La contraseña debe tener al menos 6 caracteres' : null, 
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
                    onChanged: (value) {
                      setState(() {
                        confirmPassword = value;
                      });
                    },
                    errorMessage: isFormPosted ? 
                        (confirmPassword.isEmpty ? 'Este campo es obligatorio' : 
                        (password != confirmPassword ? 'Las contraseñas no coinciden' : null)) : null, 
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
                onChanged: (value) {
                  setState(() {
                    phone = value;
                  });
                },
                errorMessage: isFormPosted && phone.isEmpty ? 
                    'El teléfono es obligatorio' : null,
              ),
              const SizedBox(height: 32),
              // Botón de registro
              CustomFilledButton(
                text: isPosting ? 'Registrando...' : 'Registrarse',
                isLoading: isPosting,
                onPressed: isPosting 
                  ? null 
                  : () {
                      setState(() {
                        isFormPosted = true;
                      });
                      
                      // Validar el formulario
                      if (name.isNotEmpty && 
                          lastName.isNotEmpty && 
                          maternalLastName.isNotEmpty &&
                          email.isNotEmpty && email.contains('@') &&
                          password.length >= 6 &&
                          password == confirmPassword &&
                          phone.isNotEmpty) {
                        
                        // Aquí iría la lógica de registro
                        setState(() {
                          isPosting = true;
                        });
                        
                        // Simulamos un registro exitoso después de un breve retraso
                        Future.delayed(const Duration(seconds: 2), () {
                          setState(() {
                            isPosting = false;
                          });
                          
                          // Navegar a la pantalla principal
                          context.go('/home');
                          
                          // Mostrar mensaje de éxito
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registro exitoso.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        });
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