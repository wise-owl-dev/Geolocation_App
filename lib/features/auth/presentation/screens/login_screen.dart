// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscurePassword = true;
  
  // Valores del formulario
  String email = '';
  String password = '';
  bool isFormPosted = false;
  bool isPosting = false;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),

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
                'Ingrese un email válido' 
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
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
              errorMessage: isFormPosted && password.isEmpty ?
                  'La contraseña es obligatoria' 
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
        _buildForgotPasswordLink(),

        const SizedBox(height: 24),
        CustomFilledButton(
          text: isPosting ? 'Iniciando sesión...' : 'Iniciar Sesión',
          isLoading: isPosting,
          onPressed: isPosting 
            ? null 
            : () {
                setState(() {
                  isFormPosted = true;
                });
                
                // Validar el formulario
                if (email.isNotEmpty && email.contains('@') && password.isNotEmpty) {
                  // Aquí iría la lógica de inicio de sesión
                  setState(() {
                    isPosting = true;
                  });
                  
                  // Simulamos un inicio de sesión exitoso después de un breve retraso
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      isPosting = false;
                    });
                    
                    // Navegar a la pantalla principal
                    context.go('/home');
                  });
                }
              },
        ),

        const SizedBox(height: 24),
        _buildOrDivider(),
        const SizedBox(height: 24),
        _buildGoogleSignInButton(),
        const SizedBox(height: 24),
        _buildSignUpLink(),
      ],
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
              child: const Icon(Icons.lock, color: Colors.blue),
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
            const SnackBar(content: Text('Funcionalidad no implementada'))
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


  Widget _buildOrDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('O', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: OutlinedButton.icon(
        onPressed: () {
          // Esta funcionalidad necesitaría ser implementada
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidad no implementada'))
          );
        },
        icon: Image.asset(
          'assets/google_logo.png',
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.login, color: Colors.blue);
          },
        ),
        label: const Text(
          'Iniciar con Google',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
          onPressed: () {
            // Usar go_router para navegar a la pantalla de registro
            context.push('/signup');
          },
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