import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';

/// Pestaña de administración y edición de máquinas.
class MaquinasScreen extends StatefulWidget {
  const MaquinasScreen({super.key});

  @override
  State<MaquinasScreen> createState() => _MaquinasScreenState();
}

class _MaquinasScreenState extends State<MaquinasScreen> {
  List<Maquina> _maquinas = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final m = await DB.instance.getMaquinas();
    if (mounted) setState(() => _maquinas = m);
  }

  Future<void> _nueva() async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva máquina'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    await DB.instance.insertMaquina(nombre);
    _cargar();
  }

  Future<void> _renombrar(Maquina m) async {
    final ctrl = TextEditingController(text: m.nombre);
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar máquina'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    await DB.instance.updateMaquina(m.id!, nombre);
    _cargar();
  }

  Future<void> _eliminar(Maquina m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${m.nombre}"?'),
        content: const Text(
            'Las revisiones que la usaban quedarán "sin máquina". Las fotos no se tocan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DB.instance.deleteMaquina(m.id!);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Máquinas')),
      body: _maquinas.isEmpty
          ? const Center(
              child: Text('Sin máquinas. Agrega la primera con +',
                  style: TextStyle(fontSize: 18, color: Colors.black54)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _maquinas.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                final m = _maquinas[i];
                return ListTile(
                  leading:
                      const Icon(Icons.precision_manufacturing, size: 32),
                  title:
                      Text(m.nombre, style: const TextStyle(fontSize: 20)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Renombrar',
                        iconSize: 28,
                        icon: const Icon(Icons.edit),
                        onPressed: () => _renombrar(m),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        iconSize: 28,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminar(m),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Agregar', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
