/// Represents a Lavasol employee with their shift assignments.
class Empleado {
  final String id;
  final String nombre;
  final String? apellido;
  final String? email;
  final DateTime? fechaNacimiento;
  final String? direccion;
  final DateTime? fechaIngreso;
  final String? categoria;
  final String? asignacionPrincipal;
  final String? asignacionSecundaria1;
  final String? asignacionSecundaria2;
  final String? descansoHabitual;
  final String? descansoAlternativo;

  const Empleado({
    required this.id,
    required this.nombre,
    this.apellido,
    this.email,
    this.fechaNacimiento,
    this.direccion,
    this.fechaIngreso,
    this.categoria,
    this.asignacionPrincipal,
    this.asignacionSecundaria1,
    this.asignacionSecundaria2,
    this.descansoHabitual,
    this.descansoAlternativo,
  });

  String get nombreCompleto =>
      apellido != null ? '$nombre $apellido' : nombre;

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String?,
      email: json['email'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] != null
          ? DateTime.parse(json['fecha_nacimiento'] as String)
          : null,
      direccion: json['direccion'] as String?,
      fechaIngreso: json['fecha_ingreso'] != null
          ? DateTime.parse(json['fecha_ingreso'] as String)
          : null,
      categoria: json['categoria'] as String?,
      asignacionPrincipal: json['asignacion_principal'] as String?,
      asignacionSecundaria1: json['asignacion_secundaria_1'] as String?,
      asignacionSecundaria2: json['asignacion_secundaria_2'] as String?,
      descansoHabitual: json['descanso_habitual'] as String?,
      descansoAlternativo: json['descanso_alternativo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (apellido != null) 'apellido': apellido,
      if (email != null) 'email': email,
      if (fechaNacimiento != null)
        'fecha_nacimiento':
            fechaNacimiento!.toIso8601String().split('T').first,
      if (direccion != null) 'direccion': direccion,
      if (fechaIngreso != null)
        'fecha_ingreso': fechaIngreso!.toIso8601String().split('T').first,
      if (categoria != null) 'categoria': categoria,
      if (asignacionPrincipal != null)
        'asignacion_principal': asignacionPrincipal,
      if (asignacionSecundaria1 != null)
        'asignacion_secundaria_1': asignacionSecundaria1,
      if (asignacionSecundaria2 != null)
        'asignacion_secundaria_2': asignacionSecundaria2,
      if (descansoHabitual != null) 'descanso_habitual': descansoHabitual,
      if (descansoAlternativo != null)
        'descanso_alternativo': descansoAlternativo,
    };
  }
}
