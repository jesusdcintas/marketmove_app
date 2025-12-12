import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pantalla de bienvenida para usuarios nuevos sin empresa asignada
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido a MarketMove'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.business_center,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              Text(
                '¡Hola ${profile?.nombre ?? "Usuario"}!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tu cuenta ha sido creada exitosamente.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Esperando asignación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Un administrador debe asignarte a una empresa para que puedas comenzar a usar la aplicación.',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Recibirás una notificación cuando tu cuenta esté lista.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (profile != null) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Información de tu cuenta:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(profile.email),
                  subtitle: const Text('Email'),
                ),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: Text(profile.role.name),
                  subtitle: const Text('Rol asignado'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
