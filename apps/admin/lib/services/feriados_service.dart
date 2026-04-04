import '../models/feriado.dart';
import 'supabase_service.dart';

/// Service for CRUD operations on holidays and worked-holiday records.
class FeriadosService {
  static const _tableFeriados = 'feriados';
  static const _tableTrabajados = 'feriado_trabajado';
  static const _tableEspeciales = 'feriado_especial_trabajado';
  static const _tableRotacion = 'especial_rotacion';

  // ── Feriados ────────────────────────────────────────────────────────────────

  /// Returns all holidays for a given [anio].
  Future<List<Feriado>> getFeriadosDelAnio(int anio) async {
    final desde = '$anio-01-01';
    final hasta = '$anio-12-31';
    final rows = await SupabaseService.client
        .from(_tableFeriados)
        .select()
        .gte('fecha', desde)
        .lte('fecha', hasta)
        .order('fecha');
    return (rows as List).map((r) => Feriado.fromJson(r)).toList();
  }

  /// Returns the 3 special holidays for a given [anio].
  Future<List<Feriado>> getFeriadosEspeciales(int anio) async {
    final todos = await getFeriadosDelAnio(anio);
    return todos.where((f) => f.esEspecial).toList();
  }

  /// Creates a new holiday.
  Future<Feriado> crearFeriado(Feriado feriado) async {
    final rows = await SupabaseService.client
        .from(_tableFeriados)
        .insert(feriado.toJson())
        .select();
    return Feriado.fromJson((rows as List).first as Map<String, dynamic>);
  }

  /// Deletes a holiday by [id].
  Future<void> eliminarFeriado(int id) async {
    await SupabaseService.client
        .from(_tableFeriados)
        .delete()
        .eq('id', id);
  }

  // ── Feriados trabajados ──────────────────────────────────────────────────────

  /// Returns worked (non-special) holidays for [empleadoId] in [anio].
  Future<List<FeriadoTrabajado>> getFeriadosTrabajados(
    String empleadoId,
    int anio,
  ) async {
    final rows = await SupabaseService.client
        .from(_tableTrabajados)
        .select('*, feriados!inner(fecha, nombre, tipo)')
        .eq('empleado_id', empleadoId)
        .gte('feriados.fecha', '$anio-01-01')
        .lte('feriados.fecha', '$anio-12-31');
    return (rows as List).map((r) => FeriadoTrabajado.fromJson(r)).toList();
  }

  /// Registers a worked (non-special) holiday for an employee.
  Future<FeriadoTrabajado> registrarFeriadoTrabajado(
    FeriadoTrabajado ft,
  ) async {
    final rows = await SupabaseService.client
        .from(_tableTrabajados)
        .upsert(ft.toJson(), onConflict: 'empleado_id,feriado_id')
        .select();
    return FeriadoTrabajado.fromJson(
      (rows as List).first as Map<String, dynamic>,
    );
  }

  // ── Feriados especiales trabajados ──────────────────────────────────────────

  /// Returns worked special holidays for [empleadoId] in [anio].
  Future<List<FeriadoEspecialTrabajado>> getFeriadosEspecialesTrabajados(
    String empleadoId,
    int anio,
  ) async {
    final rows = await SupabaseService.client
        .from(_tableEspeciales)
        .select('*, feriados!inner(fecha, nombre)')
        .eq('empleado_id', empleadoId)
        .gte('feriados.fecha', '$anio-01-01')
        .lte('feriados.fecha', '$anio-12-31');
    return (rows as List)
        .map((r) => FeriadoEspecialTrabajado.fromJson(r))
        .toList();
  }

  /// Registers a worked special holiday for an employee.
  Future<FeriadoEspecialTrabajado> registrarFeriadoEspecialTrabajado(
    FeriadoEspecialTrabajado fet,
  ) async {
    final rows = await SupabaseService.client
        .from(_tableEspeciales)
        .upsert(fet.toJson(), onConflict: 'empleado_id,feriado_id')
        .select();
    return FeriadoEspecialTrabajado.fromJson(
      (rows as List).first as Map<String, dynamic>,
    );
  }

  // ── Rotación especial ────────────────────────────────────────────────────────

  /// Returns the rotation list for a special holiday in [anio], ordered by [orden].
  Future<List<EspecialRotacion>> getRotacion(int feriadoId, int anio) async {
    final rows = await SupabaseService.client
        .from(_tableRotacion)
        .select()
        .eq('feriado_id', feriadoId)
        .eq('anio', anio)
        .order('orden');
    return (rows as List).map((r) => EspecialRotacion.fromJson(r)).toList();
  }

  /// Saves the rotation for a special holiday (replaces existing for that year).
  Future<void> guardarRotacion(List<EspecialRotacion> rotacion) async {
    if (rotacion.isEmpty) return;
    final anio = rotacion.first.anio;
    final feriadoId = rotacion.first.feriadoId;

    await SupabaseService.client
        .from(_tableRotacion)
        .delete()
        .eq('anio', anio)
        .eq('feriado_id', feriadoId);

    await SupabaseService.client
        .from(_tableRotacion)
        .insert(rotacion.map((r) => r.toJson()).toList());
  }
}
