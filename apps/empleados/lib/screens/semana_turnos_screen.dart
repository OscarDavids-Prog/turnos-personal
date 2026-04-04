import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/turno.dart';
import '../services/turnos_service.dart';
import '../services/supabase_service.dart';

/// Shows the current employee's shifts for the selected week.
class SemanaTurnosScreen extends StatefulWidget {
  const SemanaTurnosScreen({super.key});

  @override
  State<SemanaTurnosScreen> createState() => _SemanaTurnosScreenState();
}

class _SemanaTurnosScreenState extends State<SemanaTurnosScreen> {
  final _service = TurnosService();
  late DateTime _semana;
  List<Turno> _turnos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _semana = _lunes(DateTime.now());
    _cargar();
  }

  String get _empleadoId =>
      SupabaseService.client.auth.currentUser?.id ?? '';

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _turnos = await _service.getTurnosSemana(_empleadoId, _semana);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domingo = _semana.add(const Duration(days: 6));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi semana'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Esta semana',
            onPressed: () {
              setState(() => _semana = _lunes(DateTime.now()));
              _cargar();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _NavegadorSemana(
            titulo:
                '${DateFormat('dd/MM').format(_semana)} – ${DateFormat('dd/MM/yyyy').format(domingo)}',
            onAnterior: () {
              setState(
                  () => _semana = _semana.subtract(const Duration(days: 7)));
              _cargar();
            },
            onSiguiente: () {
              setState(
                  () => _semana = _semana.add(const Duration(days: 7)));
              _cargar();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, i) {
        final fecha = _semana.add(Duration(days: i));
        final turno = _turnos.firstWhere(
          (t) =>
              t.fecha.year == fecha.year &&
              t.fecha.month == fecha.month &&
              t.fecha.day == fecha.day,
          orElse: () =>
              Turno(empleadoId: _empleadoId, fecha: fecha, tipoTurno: 'descanso'),
        );
        return _TarjetaDia(fecha: fecha, turno: turno);
      },
    );
  }

  static DateTime _lunes(DateTime dt) {
    final base = DateTime(dt.year, dt.month, dt.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }
}

class _NavegadorSemana extends StatelessWidget {
  const _NavegadorSemana({
    required this.titulo,
    required this.onAnterior,
    required this.onSiguiente,
  });

  final String titulo;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onAnterior,
          ),
          Text(titulo, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onSiguiente,
          ),
        ],
      ),
    );
  }
}

class _TarjetaDia extends StatelessWidget {
  const _TarjetaDia({required this.fecha, required this.turno});
  final DateTime fecha;
  final Turno turno;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color(),
          child: Text(
            turno.etiqueta.substring(0, 1),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(DateFormat('EEEE dd/MM', 'es').format(fecha)),
        subtitle: Text(turno.etiqueta),
        trailing: turno.compensado
            ? const Chip(label: Text('Compensado'))
            : null,
      ),
    );
  }

  Color _color() {
    if (turno.estado != null) {
      switch (turno.estado) {
        case 'ENF':
          return Colors.red;
        case 'CAP':
          return Colors.amber.shade700;
        case 'VAC':
          return Colors.purple;
        default:
          return Colors.black54;
      }
    }
    switch (turno.tipoTurno) {
      case 'manana':
        return Colors.green;
      case 'tarde':
        return Colors.blue;
      case 'intermedio':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
