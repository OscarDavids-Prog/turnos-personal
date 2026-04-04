/// Represents a daily shift record for an employee.
class Turno {
  final int? id;
  final String empleadoId;
  final DateTime fecha;
  final TipoTurno tipoTurno;
  final EstadoTurno? estado;
  final bool compensado;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Turno({
    this.id,
    required this.empleadoId,
    required this.fecha,
    required this.tipoTurno,
    this.estado,
    this.compensado = false,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int?,
      empleadoId: json['empleado_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      tipoTurno: TipoTurno.fromString(json['tipo_turno'] as String),
      estado: json['estado'] != null
          ? EstadoTurno.fromString(json['estado'] as String)
          : null,
      compensado: (json['compensado'] as bool?) ?? false,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
      actualizadoEn: json['actualizado_en'] != null
          ? DateTime.parse(json['actualizado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'empleado_id': empleadoId,
      'fecha': fecha.toIso8601String().split('T').first,
      'tipo_turno': tipoTurno.value,
      'estado': estado?.value,
      'compensado': compensado,
    };
  }

  Turno copyWith({
    int? id,
    String? empleadoId,
    DateTime? fecha,
    TipoTurno? tipoTurno,
    EstadoTurno? estado,
    bool? compensado,
  }) {
    return Turno(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      fecha: fecha ?? this.fecha,
      tipoTurno: tipoTurno ?? this.tipoTurno,
      estado: estado ?? this.estado,
      compensado: compensado ?? this.compensado,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }
}

enum TipoTurno {
  manana('manana'),
  tarde('tarde'),
  intermedio('intermedio'),
  descanso('descanso');

  const TipoTurno(this.value);
  final String value;

  static TipoTurno fromString(String s) =>
      TipoTurno.values.firstWhere((e) => e.value == s);

  String get label {
    switch (this) {
      case TipoTurno.manana:
        return 'Mañana';
      case TipoTurno.tarde:
        return 'Tarde';
      case TipoTurno.intermedio:
        return 'Intermedio';
      case TipoTurno.descanso:
        return 'Descanso';
    }
  }
}

enum EstadoTurno {
  enf('ENF'),
  cap('CAP'),
  vac('VAC'),
  x('X');

  const EstadoTurno(this.value);
  final String value;

  static EstadoTurno fromString(String s) =>
      EstadoTurno.values.firstWhere((e) => e.value == s);

  String get label {
    switch (this) {
      case EstadoTurno.enf:
        return 'Enfermedad';
      case EstadoTurno.cap:
        return 'Capacitación';
      case EstadoTurno.vac:
        return 'Vacaciones';
      case EstadoTurno.x:
        return 'Ausencia';
    }
  }
}
