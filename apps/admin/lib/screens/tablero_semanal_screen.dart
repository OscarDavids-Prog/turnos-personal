import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/empleado.dart';
import '../models/turno.dart';
import '../providers/empleados_provider.dart';
import '../providers/turnos_provider.dart';
import 'editar_turno_screen.dart';

/// Weekly shift board displayed as a scrollable grid (employees × days).
class TableroSemanalScreen extends StatefulWidget {
  const TableroSemanalScreen({super.key});

  @override
  State<TableroSemanalScreen> createState() => _TableroSemanalScreenState();
}

class _TableroSemanalScreenState extends State<TableroSemanalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmpleadosProvider>().cargar();
      context.read<TurnosProvider>().cargarSemana();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero de Turnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Hoy',
            onPressed: () => context.read<TurnosProvider>().irAHoy(),
          ),
        ],
      ),
      body: Consumer2<TurnosProvider, EmpleadosProvider>(
        builder: (context, turnosP, empleadosP, _) {
          if (turnosP.cargando || empleadosP.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (turnosP.error != null) {
            return Center(child: Text('Error: ${turnosP.error}'));
          }
          return Column(
            children: [
              _NavegadorSemana(turnosProvider: turnosP),
              Expanded(
                child: _GridTurnos(
                  empleados: empleadosP.empleados,
                  turnos: turnosP.turnosSemana,
                  semana: turnosP.semanaActual,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavegadorSemana extends StatelessWidget {
  const _NavegadorSemana({required this.turnosProvider});
  final TurnosProvider turnosProvider;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final lunes = turnosProvider.semanaActual;
    final domingo = lunes.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: turnosProvider.semanaAnterior,
          ),
          Text(
            '${fmt.format(lunes)} – ${fmt.format(domingo)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: turnosProvider.semanaSiguiente,
          ),
        ],
      ),
    );
  }
}

class _GridTurnos extends StatelessWidget {
  const _GridTurnos({
    required this.empleados,
    required this.turnos,
    required this.semana,
  });

  final List<Empleado> empleados;
  final List<Turno> turnos;
  final DateTime semana;

  static const _dias = [
    'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.primaryContainer,
          ),
          columns: [
            const DataColumn(label: Text('Empleado')),
            ..._dias.asMap().entries.map((e) {
              final day = semana.add(Duration(days: e.key));
              return DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_dias[e.key]),
                    Text(
                      DateFormat('dd/MM').format(day),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          ],
          rows: empleados.map((emp) {
            return DataRow(
              cells: [
                DataCell(Text(emp.nombreCompleto)),
                ...List.generate(7, (i) {
                  final fecha = semana.add(Duration(days: i));
                  final turno = turnos.firstWhere(
                    (t) =>
                        t.empleadoId == emp.id &&
                        t.fecha.year == fecha.year &&
                        t.fecha.month == fecha.month &&
                        t.fecha.day == fecha.day,
                    orElse: () => Turno(
                      empleadoId: emp.id,
                      fecha: fecha,
                      tipoTurno: TipoTurno.descanso,
                    ),
                  );
                  return DataCell(
                    _CeldaTurno(turno: turno),
                    onTap: () => _editarTurno(context, turno),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _editarTurno(BuildContext context, Turno turno) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditarTurnoScreen(turno: turno),
      ),
    );
  }
}

class _CeldaTurno extends StatelessWidget {
  const _CeldaTurno({required this.turno});
  final Turno turno;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _color(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        turno.estado?.value ?? turno.tipoTurno.label.substring(0, 1),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _color() {
    if (turno.estado != null) {
      switch (turno.estado!) {
        case EstadoTurno.enf:
          return Colors.red;
        case EstadoTurno.cap:
          return Colors.amber.shade700;
        case EstadoTurno.vac:
          return Colors.purple;
        case EstadoTurno.x:
          return Colors.black54;
      }
    }
    switch (turno.tipoTurno) {
      case TipoTurno.manana:
        return Colors.green;
      case TipoTurno.tarde:
        return Colors.blue;
      case TipoTurno.intermedio:
        return Colors.orange;
      case TipoTurno.descanso:
        return Colors.grey;
    }
  }
}
