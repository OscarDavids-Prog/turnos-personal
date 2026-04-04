import '../models/empleado.dart';
import 'supabase_service.dart';

/// Service for reading and updating [Empleado] records.
class EmpleadosService {
  static const _table = 'empleados';

  /// Returns all active employees, ordered by name.
  Future<List<Empleado>> getEmpleados() async {
    final rows = await SupabaseService.client
        .from(_table)
        .select()
        .order('nombre');
    return (rows as List).map((r) => Empleado.fromJson(r)).toList();
  }

  /// Returns a single employee by [id].
  Future<Empleado?> getEmpleado(String id) async {
    final rows = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return Empleado.fromJson(rows.first as Map<String, dynamic>);
  }

  /// Updates the extension fields of an employee (only the new columns added
  /// by this module). Does not modify any existing columns.
  Future<void> actualizarExtension(Empleado empleado) async {
    await SupabaseService.client.from(_table).update({
      'fecha_nacimiento': empleado.fechaNacimiento
          ?.toIso8601String()
          .split('T')
          .first,
      'direccion': empleado.direccion,
      'fecha_ingreso':
          empleado.fechaIngreso?.toIso8601String().split('T').first,
      'categoria': empleado.categoria,
      'asignacion_principal': empleado.asignacionPrincipal,
      'asignacion_secundaria_1': empleado.asignacionSecundaria1,
      'asignacion_secundaria_2': empleado.asignacionSecundaria2,
      'descanso_habitual': empleado.descansoHabitual,
      'descanso_alternativo': empleado.descansoAlternativo,
    }).eq('id', empleado.id);
  }
}
