/// Basic employee information for the employee-facing app.
class Empleado {
  final String id;
  final String nombre;
  final String? apellido;

  const Empleado({
    required this.id,
    required this.nombre,
    this.apellido,
  });

  String get nombreCompleto =>
      apellido != null ? '$nombre $apellido' : nombre;

  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String?,
    );
  }
}
