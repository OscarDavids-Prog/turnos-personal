import 'package:flutter/foundation.dart';
import '../models/empleado.dart';
import '../services/empleados_service.dart';

/// State management for the employees list.
class EmpleadosProvider extends ChangeNotifier {
  final EmpleadosService _service;

  EmpleadosProvider({EmpleadosService? service})
      : _service = service ?? EmpleadosService();

  // ── State ────────────────────────────────────────────────────────────────────

  List<Empleado> _empleados = [];
  List<Empleado> get empleados => List.unmodifiable(_empleados);

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  // ── Actions ──────────────────────────────────────────────────────────────────

  /// Loads all active employees.
  Future<void> cargar() async {
    _cargando = true;
    notifyListeners();
    try {
      _empleados = await _service.getEmpleados();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Updates the extension fields of [empleado].
  Future<bool> actualizarExtension(Empleado empleado) async {
    try {
      await _service.actualizarExtension(empleado);
      final idx = _empleados.indexWhere((e) => e.id == empleado.id);
      if (idx >= 0) _empleados[idx] = empleado;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
