import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/turno.dart';
import '../services/turnos_service.dart';
import '../services/supabase_service.dart';

/// Shows the current employee's monthly activity summary.
class ActividadMensualScreen extends StatefulWidget {
  const ActividadMensualScreen({super.key});

  @override
  State<ActividadMensualScreen> createState() =>
      _ActividadMensualScreenState();
}

class _ActividadMensualScreenState extends State<ActividadMensualScreen> {
  final _service = TurnosService();
  int _anio = DateTime.now().year;
  int _mes = DateTime.now().month;
  List<Turno> _turnos = [];
  bool _cargando = false;
  String? _error;

  String get _empleadoId =>
      SupabaseService.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _turnos = await _service.getTurnosMes(
        _empleadoId,
        anio: _anio,
        mes: _mes,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi mes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SelectorMes(
              anio: _anio,
              mes: _mes,
              onChanged: (a, m) {
                setState(() {
                  _anio = a;
                  _mes = m;
                });
                _cargar();
              },
            ),
            const SizedBox(height: 24),
            if (_cargando)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(child: Center(child: Text('Error: $_error')))
            else
              Expanded(child: _ResumenWidget(turnos: _turnos)),
          ],
        ),
      ),
    );
  }
}

class _SelectorMes extends StatelessWidget {
  const _SelectorMes({
    required this.anio,
    required this.mes,
    required this.onChanged,
  });

  final int anio;
  final int mes;
  final void Function(int, int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: anio,
            decoration:
                const InputDecoration(labelText: 'Año', border: OutlineInputBorder()),
            items: List.generate(3, (i) => DateTime.now().year - 1 + i)
                .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                .toList(),
            onChanged: (v) => onChanged(v ?? anio, mes),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: mes,
            decoration:
                const InputDecoration(labelText: 'Mes', border: OutlineInputBorder()),
            items: List.generate(12, (i) => i + 1)
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(
                      DateFormat('MMMM', 'es').format(DateTime(anio, m)),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => onChanged(anio, v ?? mes),
          ),
        ),
      ],
    );
  }
}

class _ResumenWidget extends StatelessWidget {
  const _ResumenWidget({required this.turnos});
  final List<Turno> turnos;

  Map<String, int> _calcular() {
    final c = <String, int>{
      'manana': 0,
      'tarde': 0,
      'intermedio': 0,
      'descanso': 0,
      'ENF': 0,
      'CAP': 0,
      'VAC': 0,
      'X': 0,
      'compensados': 0,
    };
    for (final t in turnos) {
      c[t.tipoTurno] = (c[t.tipoTurno] ?? 0) + 1;
      if (t.estado != null) c[t.estado!] = (c[t.estado!] ?? 0) + 1;
      if (t.compensado) c['compensados'] = (c['compensados'] ?? 0) + 1;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    if (turnos.isEmpty) {
      return const Center(child: Text('Sin turnos registrados este mes.'));
    }
    final c = _calcular();
    final items = [
      _Item('Mañana', c['manana'] ?? 0, Colors.green),
      _Item('Tarde', c['tarde'] ?? 0, Colors.blue),
      _Item('Intermedio', c['intermedio'] ?? 0, Colors.orange),
      _Item('Descanso', c['descanso'] ?? 0, Colors.grey),
      _Item('Enfermedad', c['ENF'] ?? 0, Colors.red),
      _Item('Capacitación', c['CAP'] ?? 0, Colors.amber.shade700),
      _Item('Vacaciones', c['VAC'] ?? 0, Colors.purple),
      _Item('Ausencia', c['X'] ?? 0, Colors.black54),
      _Item('Compensados', c['compensados'] ?? 0, Colors.teal),
    ];
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = items[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: item.color,
            radius: 14,
            child: Text(
              '${item.valor}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          title: Text(item.label),
          trailing: Text(
            '${item.valor} día${item.valor == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}

class _Item {
  const _Item(this.label, this.valor, this.color);
  final String label;
  final int valor;
  final Color color;
}
