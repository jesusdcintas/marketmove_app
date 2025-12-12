import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketmove_app/core/constants/roles.dart';
import 'package:marketmove_app/presentation/providers/auth_provider.dart';

/// Widget para proteger UI basado en roles
///
/// Ejemplo:
/// ```dart
/// RoleGuard(
///   allowedRoles: [UserRole.ADMIN, UserRole.SUPERADMIN],
///   child: ElevatedButton(...),
///   fallback: Text('Sin permisos'),
/// )
/// ```
class RoleGuard extends ConsumerWidget {
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final hasAccess = allowedRoles.contains(profile.role);
    return hasAccess ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Widget para mostrar solo a SUPERADMIN
class SuperAdminOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SuperAdminOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard(
      allowedRoles: const [UserRole.SUPERADMIN],
      child: child,
      fallback: fallback,
    );
  }
}

/// Widget para mostrar a ADMIN y SUPERADMIN
class AdminOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AdminOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard(
      allowedRoles: const [UserRole.ADMIN, UserRole.SUPERADMIN],
      child: child,
      fallback: fallback,
    );
  }
}

/// Widget para mostrar a CLIENTE, ADMIN y SUPERADMIN (todos)
class ClienteAccess extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ClienteAccess({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoleGuard(
      allowedRoles: UserRole.values,
      child: child,
      fallback: fallback,
    );
  }
}
