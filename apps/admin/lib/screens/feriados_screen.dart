import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/feriado.dart';
import '../providers/feriados_provider.dart';

/// Screen for managing holidays (list, add, delete) and worked holidays.
class FeriadosScreen extends StatefulWidget {
  const FeriadosScreen({super.key});

  @override
  State<FeriadosScreen> createState() => _FeriadosScreenState();
}

class _FeriadosScreenState extends State<FeriadosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _anio = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeriadosProvider>().cargarFeriadosDelAnio(_anio);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feriados'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Catálogo'),
            Tab(text: 'Trabajados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _CatalogoFeriados(anio: _anio),
          const _FeriadosTrabajadosTab(),
        ],
      ),
      floatingActionButton: _tabs.index == 0
          ? FloatingActionButton(
              onPressed: _agregarFeriado,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _agregarFeriado() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogAgregarFeriado(anio: _anio),
    );
  }
}

class _CatalogoFeriados extends StatelessWidget {
  const _CatalogoFeriados({required this.anio});
  final int anio;

  @override
  Widget build(BuildContext context) {
    return Consumer<FeriadosProvider>(
      builder: (context, provider, _) {
        if (provider.cargando) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.feriados.isEmpty) {
          return const Center(
            child: Text('No hay feriados registrados para este año.'),
          );
        }
        return ListView.builder(
          itemCount: provider.feriados.length,
          itemBuilder: (context, i) {
            final f = provider.feriados[i];
            return ListTile(
              leading: Icon(
                f.esEspecial ? Icons.star : Icons.calendar_today,
                color: f.esEspecial ? Colors.amber : null,
              ),
              title: Text(f.nombre),
              subtitle: Text(
                '${DateFormat('dd/MM/yyyy').format(f.fecha)} · ${f.tipo.label}',
              ),
              trailing: f.esEspecial
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          provider.eliminarFeriado(f.id!),
                    ),
            );
          },
        );
      },
    );
  }
}

class _FeriadosTrabajadosTab extends StatelessWidget {
  const _FeriadosTrabajadosTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Seleccionar empleado para ver feriados trabajados.'),
    );
  }
}

class _DialogAgregarFeriado extends StatefulWidget {
  const _DialogAgregarFeriado({required this.anio});
  final int anio;

  @override
  State<_DialogAgregarFeriado> createState() => _DialogAgregarFeriadoState();
}

class _DialogAgregarFeriadoState extends State<_DialogAgregarFeriado> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fecha;
  final _nombreController = TextEditingController();
  TipoFeriado _tipo = TipoFeriado.nacional;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar feriado'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Ingrese un nombre' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                _fecha == null
                    ? 'Seleccionar fecha'
                    : DateFormat('dd/MM/yyyy').format(_fecha!),
              ),
              leading: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(widget.anio, 1, 1),
                  firstDate: DateTime(widget.anio, 1, 1),
                  lastDate: DateTime(widget.anio, 12, 31),
                );
                if (picked != null) setState(() => _fecha = picked);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoFeriado>(
              decoration: const InputDecoration(labelText: 'Tipo'),
              value: _tipo,
              items: TipoFeriado.values
                  .where((t) => t != TipoFeriado.especial)
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _fecha == null) return;
    final feriado = Feriado(
      fecha: _fecha!,
      nombre: _nombreController.text.trim(),
      tipo: _tipo,
    );
    final ok = await context.read<FeriadosProvider>().agregarFeriado(feriado);
    if (ok && mounted) Navigator.of(context).pop();
  }
}
