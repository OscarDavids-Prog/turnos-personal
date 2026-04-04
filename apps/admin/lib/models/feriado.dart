/// Represents a holiday entry.
class Feriado {
  final int? id;
  final DateTime fecha;
  final String nombre;
  final TipoFeriado tipo;
  final bool esEspecial;

  const Feriado({
    this.id,
    required this.fecha,
    required this.nombre,
    required this.tipo,
    this.esEspecial = false,
  });

  factory Feriado.fromJson(Map<String, dynamic> json) {
    return Feriado(
      id: json['id'] as int?,
      fecha: DateTime.parse(json['fecha'] as String),
      nombre: json['nombre'] as String,
      tipo: TipoFeriado.fromString(json['tipo'] as String),
      esEspecial: (json['es_especial'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fecha': fecha.toIso8601String().split('T').first,
      'nombre': nombre,
      'tipo': tipo.value,
      'es_especial': esEspecial,
    };
  }
}

enum TipoFeriado {
  nacional('nacional'),
  provincial('provincial'),
  comercio('comercio'),
  especial('especial');

  const TipoFeriado(this.value);
  final String value;

  static TipoFeriado fromString(String s) =>
      TipoFeriado.values.firstWhere((e) => e.value == s);

  String get label {
    switch (this) {
      case TipoFeriado.nacional:
        return 'Nacional';
      case TipoFeriado.provincial:
        return 'Provincial';
      case TipoFeriado.comercio:
        return 'Comercio';
      case TipoFeriado.especial:
        return 'Especial';
    }
  }
}

/// A regular (non-special) holiday worked by an employee.
class FeriadoTrabajado {
  final int? id;
  final String empleadoId;
  final int feriadoId;
  final ModalidadFeriado modalidad;
  final DateTime? creadoEn;

  const FeriadoTrabajado({
    this.id,
    required this.empleadoId,
    required this.feriadoId,
    required this.modalidad,
    this.creadoEn,
  });

  factory FeriadoTrabajado.fromJson(Map<String, dynamic> json) {
    return FeriadoTrabajado(
      id: json['id'] as int?,
      empleadoId: json['empleado_id'] as String,
      feriadoId: json['feriado_id'] as int,
      modalidad: ModalidadFeriado.fromString(json['modalidad'] as String),
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'empleado_id': empleadoId,
      'feriado_id': feriadoId,
      'modalidad': modalidad.value,
    };
  }
}

enum ModalidadFeriado {
  compensado('compensado'),
  cobrado('cobrado');

  const ModalidadFeriado(this.value);
  final String value;

  static ModalidadFeriado fromString(String s) =>
      ModalidadFeriado.values.firstWhere((e) => e.value == s);

  String get label {
    switch (this) {
      case ModalidadFeriado.compensado:
        return 'Compensado';
      case ModalidadFeriado.cobrado:
        return 'Cobrado';
    }
  }
}

/// A special holiday (1/1, 1/5, 25/12) worked by an employee.
class FeriadoEspecialTrabajado {
  final int? id;
  final String empleadoId;
  final int feriadoId;
  final String tipoTurno;
  final DateTime? creadoEn;

  const FeriadoEspecialTrabajado({
    this.id,
    required this.empleadoId,
    required this.feriadoId,
    required this.tipoTurno,
    this.creadoEn,
  });

  factory FeriadoEspecialTrabajado.fromJson(Map<String, dynamic> json) {
    return FeriadoEspecialTrabajado(
      id: json['id'] as int?,
      empleadoId: json['empleado_id'] as String,
      feriadoId: json['feriado_id'] as int,
      tipoTurno: json['tipo_turno'] as String,
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'empleado_id': empleadoId,
      'feriado_id': feriadoId,
      'tipo_turno': tipoTurno,
    };
  }
}

/// Annual rotation of employees for a special holiday.
class EspecialRotacion {
  final int? id;
  final int anio;
  final int feriadoId;
  final String empleadoId;
  final int orden;

  const EspecialRotacion({
    this.id,
    required this.anio,
    required this.feriadoId,
    required this.empleadoId,
    required this.orden,
  });

  factory EspecialRotacion.fromJson(Map<String, dynamic> json) {
    return EspecialRotacion(
      id: json['id'] as int?,
      anio: json['anio'] as int,
      feriadoId: json['feriado_id'] as int,
      empleadoId: json['empleado_id'] as String,
      orden: json['orden'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'anio': anio,
      'feriado_id': feriadoId,
      'empleado_id': empleadoId,
      'orden': orden,
    };
  }
}
