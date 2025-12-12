import 'package:marketmove_app/core/constants/roles.dart';

/// Modelo de datos para Empresa
class Empresa {
  final String id;
  final String nombre;
  final String nif;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? logoUrl;
  final bool activa;
  final String plan;
  final int maxUsuarios;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Empresa({
    required this.id,
    required this.nombre,
    required this.nif,
    this.direccion,
    this.telefono,
    this.email,
    this.logoUrl,
    required this.activa,
    required this.plan,
    required this.maxUsuarios,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Empresa.fromMap(Map<String, dynamic> map) {
    return Empresa(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      nif: map['nif'] as String,
      direccion: map['direccion'] as String?,
      telefono: map['telefono'] as String?,
      email: map['email'] as String?,
      logoUrl: map['logo_url'] as String?,
      activa: map['activa'] as bool? ?? true,
      plan: map['plan'] as String? ?? 'basic',
      maxUsuarios: map['max_usuarios'] as int? ?? 10,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'nif': nif,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'logo_url': logoUrl,
      'activa': activa,
      'plan': plan,
      'max_usuarios': maxUsuarios,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Empresa copyWith({
    String? nombre,
    String? nif,
    String? direccion,
    String? telefono,
    String? email,
    String? logoUrl,
    bool? activa,
    String? plan,
    int? maxUsuarios,
  }) {
    return Empresa(
      id: id,
      nombre: nombre ?? this.nombre,
      nif: nif ?? this.nif,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      activa: activa ?? this.activa,
      plan: plan ?? this.plan,
      maxUsuarios: maxUsuarios ?? this.maxUsuarios,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Modelo de datos para Profile (usuario del sistema)
class Profile {
  final String id;
  final String email;
  final UserRole role;
  final String? empresaId;
  final String nombre;
  final String? telefono;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Empresa? empresa;

  const Profile({
    required this.id,
    required this.email,
    required this.role,
    this.empresaId,
    required this.nombre,
    this.telefono,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    this.empresa,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      empresaId: map['empresa_id'] as String?,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String?,
      activo: map['activo'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      empresa: map['empresas'] != null 
          ? Empresa.fromMap(map['empresas'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role.name,
      'empresa_id': empresaId,
      'nombre': nombre,
      'telefono': telefono,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isSuperAdmin => role == UserRole.SUPERADMIN;
  bool get isAdmin => role == UserRole.ADMIN;
  bool get isCliente => role == UserRole.CLIENTE;
  bool get hasEmpresa => empresaId != null;

  Profile copyWith({
    String? nombre,
    String? telefono,
    bool? activo,
    Empresa? empresa,
  }) {
    return Profile(
      id: id,
      email: email,
      role: role,
      empresaId: empresaId,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      empresa: empresa ?? this.empresa,
    );
  }
}
