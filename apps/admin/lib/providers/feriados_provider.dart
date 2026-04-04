import 'package:flutter/foundation.dart';
import '../models/feriado.dart';
import '../services/feriados_service.dart';

/// State management for holidays, worked holidays and rotation.
class FeriadosProvider extends ChangeNotifier {
  final FeriadosService _service;

  FeriadosProvider({FeriadosService? service})
      : _service = service ?? FeriadosService();

  // ── State ────────────────────────────────────────────────────────────────────

  List<Feriado> _feriados = [];
  List<Feriado> get feriados => List.unmodifiable(_feriados);

  List<FeriadoTrabajado> _feriadosTrabajados = [];
  List<FeriadoTrabajado> get feriadosTrabajados =>
      List.unmodifiable(_feriadosTrabajados);

  List<EspecialRotacion> _rotacion = [];
  List<EspecialRotacion> get rotacion => List.unmodifiable(_rotacion);

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> cargarFeriadosDelAnio(int anio) async {
    _cargando = true;
    notifyListeners();
    try {
      _feriados = await _service.getFeriadosDelAnio(anio);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> agregarFeriado(Feriado feriado) async {
    try {
      final nuevo = await _service.crearFeriado(feriado);
      _feriados.add(nuevo);
      _feriados.sort((a, b) => a.fecha.compareTo(b.fecha));
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarFeriado(int id) async {
    try {
      await _service.eliminarFeriado(id);
      _feriados.removeWhere((f) => f.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarFeriadosTrabajados(String empleadoId, int anio) async {
    _cargando = true;
    notifyListeners();
    try {
      _feriadosTrabajados =
          await _service.getFeriadosTrabajados(empleadoId, anio);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> registrarFeriadoTrabajado(FeriadoTrabajado ft) async {
    try {
      final registrado = await _service.registrarFeriadoTrabajado(ft);
      final idx = _feriadosTrabajados.indexWhere(
        (f) => f.empleadoId == ft.empleadoId && f.feriadoId == ft.feriadoId,
      );
      if (idx >= 0) {
        _feriadosTrabajados[idx] = registrado;
      } else {
        _feriadosTrabajados.add(registrado);
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarRotacion(int feriadoId, int anio) async {
    _cargando = true;
    notifyListeners();
    try {
      _rotacion = await _service.getRotacion(feriadoId, anio);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> guardarRotacion(List<EspecialRotacion> rotacion) async {
    try {
      await _service.guardarRotacion(rotacion);
      _rotacion = List.of(rotacion);
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
