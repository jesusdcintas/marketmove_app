import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    await _runWithFeedback(() async {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (response.user == null || currentUser == null || currentUser.id.isEmpty) {
        throw AuthException('No se pudo iniciar sesión. Revisa el correo y la contraseña.');
      }
      
      debugPrint('Usuario iniciado sesión: ${currentUser.id}');
      _navigateToHome();
    });
  }

  Future<void> _handlePasswordRecovery() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      setState(() => _feedbackMessage = 'Ingresa el correo asociado a tu cuenta.');
      return;
    }
    await _runWithFeedback(() async {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _feedbackMessage = 'Te enviamos un enlace para restablecer la contraseña.';
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
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
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
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El email es obligatorio.';
                      }
                      return null;
                    },
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
              onPressed: _working ? null : _handleSignIn,
              child: _working
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Crear cuenta'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _working ? null : _handlePasswordRecovery,
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ],
        ),
      ),
    );
  }
}
