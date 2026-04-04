import '../models/turno.dart';
import 'supabase_service.dart';

/// Service for reading shifts for the currently authenticated employee.
class TurnosService {
  static const _table = 'turnos_personal';

  /// Returns shifts for [empleadoId] in the week starting on [lunes].
  Future<List<Turno>> getTurnosSemana(
    String empleadoId,
    DateTime lunes,
  ) async {
    final domingo = lunes.add(const Duration(days: 6));
    final rows = await SupabaseService.client
        .from(_table)
        .select()
        .eq('empleado_id', empleadoId)
        .gte('fecha', _fmt(lunes))
        .lte('fecha', _fmt(domingo))
        .order('fecha');
    return (rows as List).map((r) => Turno.fromJson(r)).toList();
  }

  /// Returns shifts for [empleadoId] in the given month.
  Future<List<Turno>> getTurnosMes(
    String empleadoId, {
    required int anio,
    required int mes,
  }) async {
    final desde = DateTime(anio, mes, 1);
    final hasta = DateTime(anio, mes + 1, 0);
    final rows = await SupabaseService.client
        .from(_table)
        .select()
        .eq('empleado_id', empleadoId)
        .gte('fecha', _fmt(desde))
        .lte('fecha', _fmt(hasta))
        .order('fecha');
    return (rows as List).map((r) => Turno.fromJson(r)).toList();
  }

  static String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
