import '../models/turno.dart';
import 'supabase_service.dart';

/// Service for CRUD operations on [Turno] records.
///
/// All write operations enforce operational validations before persisting.
class TurnosService {
  static const _table = 'turnos_personal';

  /// Returns all turns for [empleadoId] within the given [desde]–[hasta] range.
  Future<List<Turno>> getTurnosPorEmpleado(
    String empleadoId, {
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final rows = await SupabaseService.client
        .from(_table)
        .select()
        .eq('empleado_id', empleadoId)
        .gte('fecha', desde.toIso8601String().split('T').first)
        .lte('fecha', hasta.toIso8601String().split('T').first)
        .order('fecha');
    return (rows as List).map((r) => Turno.fromJson(r)).toList();
  }

  /// Returns all turns for the given week (Monday–Sunday).
  Future<List<Turno>> getTurnosSemana(DateTime lunesDeSemana) async {
    final lunes = _soloFecha(lunesDeSemana);
    final domingo = lunes.add(const Duration(days: 6));
    final rows = await SupabaseService.client
        .from(_table)
        .select()
        .gte('fecha', _formatFecha(lunes))
        .lte('fecha', _formatFecha(domingo))
        .order('fecha');
    return (rows as List).map((r) => Turno.fromJson(r)).toList();
  }

  /// Creates or updates a turn.
  ///
  /// Throws [ValidationException] if the turn violates operational rules.
  Future<Turno> upsertTurno(Turno turno) async {
    _validar(turno);
    final data = turno.toJson();
    final List<dynamic> rows = await SupabaseService.client
        .from(_table)
        .upsert(data, onConflict: 'empleado_id,fecha')
        .select();
    return Turno.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Deletes the turn with the given [id].
  Future<void> deleteTurno(int id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  /// Returns a summary of shift counts for [empleadoId] in the given month.
  Future<ResumenMensual> getResumenMensual(
    String empleadoId, {
    required int anio,
    required int mes,
  }) async {
    final desde = DateTime(anio, mes, 1);
    final hasta = DateTime(anio, mes + 1, 0);
    final turnos = await getTurnosPorEmpleado(
      empleadoId,
      desde: desde,
      hasta: hasta,
    );
    return ResumenMensual.fromTurnos(turnos);
  }

  // ── Validation ──────────────────────────────────────────────────────────────

  void _validar(Turno turno) {
    // Estado is incompatible with descanso
    if (turno.tipoTurno == TipoTurno.descanso && turno.estado != null) {
      throw ValidationException(
        'Un turno de descanso no puede tener un estado (ENF/CAP/VAC/X).',
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  static DateTime _soloFecha(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String _formatFecha(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

/// Aggregated monthly shift statistics for a single employee.
class ResumenMensual {
  final int diasManana;
  final int diasTarde;
  final int diasIntermedio;
  final int diasDescanso;
  final int diasEnf;
  final int diasCap;
  final int diasVac;
  final int diasX;
  final int diasCompensados;

  const ResumenMensual({
    required this.diasManana,
    required this.diasTarde,
    required this.diasIntermedio,
    required this.diasDescanso,
    required this.diasEnf,
    required this.diasCap,
    required this.diasVac,
    required this.diasX,
    required this.diasCompensados,
  });

  factory ResumenMensual.fromTurnos(List<Turno> turnos) {
    int manana = 0, tarde = 0, intermedio = 0, descanso = 0;
    int enf = 0, cap = 0, vac = 0, x = 0, compensados = 0;

    for (final t in turnos) {
      switch (t.tipoTurno) {
        case TipoTurno.manana:
          manana++;
        case TipoTurno.tarde:
          tarde++;
        case TipoTurno.intermedio:
          intermedio++;
        case TipoTurno.descanso:
          descanso++;
      }
      switch (t.estado) {
        case EstadoTurno.enf:
          enf++;
        case EstadoTurno.cap:
          cap++;
        case EstadoTurno.vac:
          vac++;
        case EstadoTurno.x:
          x++;
        case null:
          break;
      }
      if (t.compensado) compensados++;
    }

    return ResumenMensual(
      diasManana: manana,
      diasTarde: tarde,
      diasIntermedio: intermedio,
      diasDescanso: descanso,
      diasEnf: enf,
      diasCap: cap,
      diasVac: vac,
      diasX: x,
      diasCompensados: compensados,
    );
  }
}

/// Thrown when a [Turno] fails operational validation.
class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}
