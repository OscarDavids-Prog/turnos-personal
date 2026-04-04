import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/turno.dart';
import '../providers/turnos_provider.dart';

/// Screen for creating or editing a single shift.
class EditarTurnoScreen extends StatefulWidget {
  const EditarTurnoScreen({super.key, required this.turno});

  final Turno turno;

  @override
  State<EditarTurnoScreen> createState() => _EditarTurnoScreenState();
}

class _EditarTurnoScreenState extends State<EditarTurnoScreen> {
  late TipoTurno _tipoTurno;
  EstadoTurno? _estado;
  bool _compensado = false;

  @override
  void initState() {
    super.initState();
    _tipoTurno = widget.turno.tipoTurno;
    _estado = widget.turno.estado;
    _compensado = widget.turno.compensado;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Turno'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Empleado ID: ${widget.turno.empleadoId}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Fecha: ${widget.turno.fecha.toIso8601String().split("T").first}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Divider(height: 32),
            Text('Tipo de turno',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _TipoTurnoSelector(
              value: _tipoTurno,
              onChanged: (v) => setState(() {
                _tipoTurno = v;
                if (v == TipoTurno.descanso) _estado = null;
              }),
            ),
            const SizedBox(height: 24),
            Text('Estado', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _EstadoSelector(
              value: _estado,
              enabled: _tipoTurno != TipoTurno.descanso,
              onChanged: (v) => setState(() => _estado = v),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Compensado'),
              subtitle: const Text(
                'Marcar si este día compensa un feriado trabajado',
              ),
              value: _compensado,
              onChanged: (v) => setState(() => _compensado = v),
            ),
            const Spacer(),
            Consumer<TurnosProvider>(
              builder: (context, provider, _) {
                if (provider.error != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final turnoActualizado = widget.turno.copyWith(
      tipoTurno: _tipoTurno,
      estado: _estado,
      compensado: _compensado,
    );
    final ok = await context
        .read<TurnosProvider>()
        .guardarTurno(turnoActualizado);
    if (ok && mounted) Navigator.of(context).pop();
  }
}

class _TipoTurnoSelector extends StatelessWidget {
  const _TipoTurnoSelector({
    required this.value,
    required this.onChanged,
  });

  final TipoTurno value;
  final ValueChanged<TipoTurno> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: TipoTurno.values.map((tipo) {
        return ChoiceChip(
          label: Text(tipo.label),
          selected: value == tipo,
          onSelected: (_) => onChanged(tipo),
        );
      }).toList(),
    );
  }
}

class _EstadoSelector extends StatelessWidget {
  const _EstadoSelector({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final EstadoTurno? value;
  final ValueChanged<EstadoTurno?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Sin estado'),
          selected: value == null,
          onSelected: enabled ? (_) => onChanged(null) : null,
        ),
        ...EstadoTurno.values.map((estado) {
          return ChoiceChip(
            label: Text(estado.label),
            selected: value == estado,
            onSelected: enabled ? (_) => onChanged(estado) : null,
          );
        }),
      ],
    );
  }
}
