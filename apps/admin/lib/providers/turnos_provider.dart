import 'package:flutter/foundation.dart';
import '../models/turno.dart';
import '../services/turnos_service.dart';

/// State management for the weekly shift board and monthly summaries.
class TurnosProvider extends ChangeNotifier {
  final TurnosService _service;

  TurnosProvider({TurnosService? service})
      : _service = service ?? TurnosService();

  // ── State ────────────────────────────────────────────────────────────────────

  List<Turno> _turnosSemana = [];
  List<Turno> get turnosSemana => List.unmodifiable(_turnosSemana);

  ResumenMensual? _resumen;
  ResumenMensual? get resumen => _resumen;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  DateTime _semanaActual = _lunes(DateTime.now());
  DateTime get semanaActual => _semanaActual;

  // ── Actions ──────────────────────────────────────────────────────────────────

  /// Loads all shifts for [_semanaActual].
  Future<void> cargarSemana() async {
    _iniciarCarga();
    try {
      _turnosSemana = await _service.getTurnosSemana(_semanaActual);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _finalizarCarga();
    }
  }

  /// Advances to the next week.
  Future<void> semanaAnterior() async {
    _semanaActual = _semanaActual.subtract(const Duration(days: 7));
    await cargarSemana();
  }

  /// Goes back to the previous week.
  Future<void> semanaSiguiente() async {
    _semanaActual = _semanaActual.add(const Duration(days: 7));
    await cargarSemana();
  }

  /// Resets to the current week.
  Future<void> irAHoy() async {
    _semanaActual = _lunes(DateTime.now());
    await cargarSemana();
  }

  /// Creates or updates a shift. Notifies listeners on success.
  Future<bool> guardarTurno(Turno turno) async {
    _iniciarCarga();
    try {
      final guardado = await _service.upsertTurno(turno);
      final idx = _turnosSemana.indexWhere(
        (t) =>
            t.empleadoId == guardado.empleadoId &&
            t.fecha.isAtSameMomentAs(guardado.fecha),
      );
      if (idx >= 0) {
        _turnosSemana[idx] = guardado;
      } else {
        _turnosSemana.add(guardado);
      }
      _error = null;
      return true;
    } on ValidationException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _finalizarCarga();
    }
  }

  /// Loads the monthly summary for [empleadoId].
  Future<void> cargarResumenMensual(
    String empleadoId, {
    required int anio,
    required int mes,
  }) async {
    _iniciarCarga();
    try {
      _resumen = await _service.getResumenMensual(
        empleadoId,
        anio: anio,
        mes: mes,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _finalizarCarga();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _iniciarCarga() {
    _cargando = true;
    notifyListeners();
  }

  void _finalizarCarga() {
    _cargando = false;
    notifyListeners();
  }

  static DateTime _lunes(DateTime dt) {
    final base = DateTime(dt.year, dt.month, dt.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }
}
