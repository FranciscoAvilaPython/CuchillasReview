import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Máquinas')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _maquinas.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) => ListTile(
          leading: const Icon(Icons.precision_manufacturing, size: 32),
          title: Text(_maquinas[i].nombre,
              style: const TextStyle(fontSize: 20)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nueva,
        icon: const Icon(Icons.add, size: 28),
        label: const Text('Agregar', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
