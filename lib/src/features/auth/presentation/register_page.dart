import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/core/constants/routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _working = false;
  String? _feedbackMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    await _runWithFeedback(() async {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      debugPrint('Intentando registrar usuario: $email');
      
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // No redirección necesaria para apps móviles
      );
      
      debugPrint('Respuesta de signUp: user=${response.user?.id}, session=${response.session != null}');
      
      if (response.user == null) {
        throw AuthException('No se pudo crear la cuenta. Intenta de nuevo.');
      }
      
      // Si ya hay sesión activa (confirmación de email desactivada), navegar directamente
      if (response.session != null) {
        debugPrint('Usuario registrado con sesión activa: ${response.user!.id}');
        _navigateToHome();
        return;
      }
      
      // Si no hay sesión, significa que requiere confirmación de email
      debugPrint('Registro exitoso. Se requiere confirmación de email.');
      setState(() {
        _feedbackMessage = 'Cuenta creada. Por favor, confirma tu email para iniciar sesión.';
      });
      
      // Esperar 2 segundos y volver al login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _goToLogin();
      }
    });
  }

  Future<void> _runWithFeedback(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _working = true;
      _feedbackMessage = null;
    });
    try {
      await action();
    } on AuthException catch (error) {
      setState(() => _feedbackMessage = error.message);
    } catch (error) {
      setState(() => _feedbackMessage = 'Error inesperado: $error');
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    // go_router maneja la redirección automáticamente
    context.go(AppRoutes.login);
  }

  void _goToLogin() {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text('MarketMove', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    enabled: !_working,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'El email es obligatorio.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_working,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es obligatoria.';
                      }
                      if (value.length < 6) {
                        return 'Debe tener al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_feedbackMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _feedbackMessage!,
                  style: TextStyle(
                    color: _feedbackMessage!.toLowerCase().contains('error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _working ? null : _handleRegister,
              child: _working
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear cuenta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _working ? null : _goToLogin,
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
