import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/data/models/profile.dart';

/// Provider global del AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<Profile?>>((ref) {
  return AuthNotifier();
});

/// Notifier para gestionar autenticación y sesión del usuario
class AuthNotifier extends StateNotifier<AsyncValue<Profile?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  final _supabase = Supabase.instance.client;

  /// Inicializar auth y listener de cambios de sesión
  Future<void> _init() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _loadProfile(user.id);
    } else {
      state = const AsyncValue.data(null);
    }

    // Escuchar cambios de autenticación
    _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _loadProfile(user.id);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  /// Cargar perfil completo del usuario con empresa
  Future<void> _loadProfile(String userId) async {
    try {
      // PRIMERO cargar solo el perfil (sin JOIN)
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Si tiene empresa_id, cargar la empresa por separado
      final empresaId = profileResponse['empresa_id'] as String?;
      Map<String, dynamic>? empresaData;
      
      if (empresaId != null) {
        try {
          empresaData = await _supabase
              .from('empresas')
              .select()
              .eq('id', empresaId)
              .maybeSingle();
        } catch (e) {
          // Si falla cargar empresa, continuar sin ella
          empresaData = null;
        }
      }

      // Combinar datos para fromMap
      final combinedData = {
        ...profileResponse,
        if (empresaData != null) 'empresas': empresaData,
      };

      final profile = Profile.fromMap(combinedData);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Iniciar sesión
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final currentUser = _supabase.auth.currentUser;
      if (response.user == null || currentUser == null || currentUser.id.isEmpty) {
        throw AuthException('No se pudo iniciar sesión. Revisa el correo y la contraseña.');
      }

      // _loadProfile se llama automáticamente vía listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Registrar nuevo usuario (solo para SUPERADMIN o auto-registro como CLIENTE)
  Future<void> signUp(String email, String password, String nombre) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nombre': nombre},
      );

      if (response.user == null) {
        throw AuthException('No se pudo crear la cuenta. Intenta de nuevo.');
      }

      // Asegurar sesión activa
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.id.isEmpty) {
        throw AuthException('No se pudo iniciar sesión después de registrarte.');
      }

      // _loadProfile se llama automáticamente vía listener
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AsyncValue.data(null);
  }

  /// Recargar perfil (útil después de cambios de rol o empresa)
  Future<void> refreshProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _loadProfile(user.id);
    }
  }

  // Getters de conveniencia
  Profile? get currentProfile => state.value;
  String? get currentUserId => state.value?.id;
  String? get currentEmpresaId => state.value?.empresaId;
  bool get isSuperAdmin => state.value?.isSuperAdmin ?? false;
  bool get isAdmin => state.value?.isAdmin ?? false;
  bool get isCliente => state.value?.isCliente ?? false;
  bool get isAuthenticated => state.value != null;
}

/// Provider helper para obtener el perfil actual
final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(authProvider).value;
});

/// Provider helper para obtener el ID de empresa actual
final currentEmpresaIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).value?.empresaId;
});

/// Provider helper para verificar si está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).value != null;
});
