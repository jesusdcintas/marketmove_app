import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_router.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final startupInfo = await _prepareAppStartup();
    runApp(ProviderScope(child: MarketMoveApp(startupResult: startupInfo)));
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

class MarketMoveApp extends ConsumerWidget {
  const MarketMoveApp({super.key, required this.startupResult});

  final AppStartupStatus startupResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!startupResult.success) {
      return MaterialApp(
        home: StartupErrorScreen(startupResult.message),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MarketMove CRM',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      routerConfig: router,
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
