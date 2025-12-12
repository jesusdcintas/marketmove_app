import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/features/auth/presentation/home_page.dart';
import 'src/features/auth/presentation/login_page.dart';
import 'src/features/auth/presentation/register_page.dart';
import 'src/features/gastos/presentation/gastos_page.dart';
import 'src/features/productos/presentation/productos_page.dart';
import 'src/features/resumen/presentation/resumen_page.dart';
import 'src/features/ventas/presentation/ventas_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runZonedGuarded(() async {
    final startupInfo = await _prepareAppStartup();
    runApp(MarketMoveApp(startupResult: startupInfo));
  }, (error, stack) {
    debugPrint('Unhandled startup error: $error');
    debugPrintStack(stackTrace: stack);
  });
}

Future<AppStartupStatus> _prepareAppStartup() async {
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('dotenv loaded from .env');
  } catch (error, stack) {
    debugPrint('dotenv load failed: $error');
    debugPrintStack(stackTrace: stack);
    return AppStartupStatus.failure('No se pudo cargar .env: $error');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    final message = 'Faltan credenciales Supabase. Revisa .env';
    debugPrint(message);
    return AppStartupStatus.failure(message);
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint('Supabase inicializado correctamente.');
  } catch (error, stack) {
    debugPrint('Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stack);
    return AppStartupStatus.failure('Supabase no arrancó: $error');
  }

  return const AppStartupStatus.success();
}

class MarketMoveApp extends StatelessWidget {
  const MarketMoveApp({super.key, required this.startupResult});

  final AppStartupStatus startupResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MarketMove',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: startupResult.success
          ? const LoginPage()
          : StartupErrorScreen(startupResult.message),
      initialRoute: startupResult.success ? '/login' : null,
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/home': (_) => const HomePage(),
        '/productos': (_) => const ProductosPage(),
        '/ventas': (_) => const VentasPage(),
        '/gastos': (_) => const GastosPage(),
        '/resumen': (_) => const ResumenPage(),
      },
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error de inicio')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                message ?? 'No se pudo arrancar la app.',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _retry(context),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class AppStartupStatus {
  const AppStartupStatus({required this.success, this.message});

  const AppStartupStatus.success() : success = true, message = null;
  const AppStartupStatus.failure(this.message) : success = false;

  final bool success;
  final String? message;
}
