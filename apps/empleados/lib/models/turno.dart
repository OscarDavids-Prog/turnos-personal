/// Represents a daily shift record for the current employee.
class Turno {
  final int? id;
  final String empleadoId;
  final DateTime fecha;
  final String tipoTurno;
  final String? estado;
  final bool compensado;

  const Turno({
    this.id,
    required this.empleadoId,
    required this.fecha,
    required this.tipoTurno,
    this.estado,
    this.compensado = false,
  });

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int?,
      empleadoId: json['empleado_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      tipoTurno: json['tipo_turno'] as String,
      estado: json['estado'] as String?,
      compensado: (json['compensado'] as bool?) ?? false,
    );
  }

  String get etiqueta {
    if (estado != null) return estado!;
    switch (tipoTurno) {
      case 'manana':
        return 'Mañana';
      case 'tarde':
        return 'Tarde';
      case 'intermedio':
        return 'Intermedio';
      default:
        return 'Descanso';
    }
  }
}
