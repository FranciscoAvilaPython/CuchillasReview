import 'dart:io';
import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import 'juego_screen.dart';
import 'maquinas_screen.dart';

class JuegosScreen extends StatefulWidget {
  const JuegosScreen({super.key});

  @override
  State<JuegosScreen> createState() => _JuegosScreenState();
}

class _JuegosScreenState extends State<JuegosScreen> {
  List<Juego> _juegos = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final juegos = await DB.instance.getJuegos();
    if (mounted) setState(() => _juegos = juegos);
  }

  Future<void> _nuevoJuego() async {
    final ctrl = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo juego de cuchillas'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Número o nombre del juego',
            hintText: 'Ej: Juego 07',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    await DB.instance.insertJuego(nombre);
    _cargar();
  }

  Future<void> _renombrar(Juego j) async {
    final ctrl = TextEditingController(text: j.nombre);
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar juego'),
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
    await DB.instance.renameJuego(j.id!, nombre);
    _cargar();
  }

  Future<void> _eliminar(Juego j) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar "${j.nombre}"?'),
        content: const Text(
            'Se borrarán sus 4 cuchillas y TODAS sus fotos. Esto no se puede deshacer.'),
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
    final rutas = await DB.instance.deleteJuego(j.id!);
    for (final r in rutas) {
      try {
        final f = File(r);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    _cargar();
  }

  void _opcionesJuego(Juego j) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, size: 30),
              title: const Text('Renombrar', style: TextStyle(fontSize: 20)),
              onTap: () {
                Navigator.pop(ctx);
                _renombrar(j);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red, size: 30),
              title: const Text('Eliminar juego',
                  style: TextStyle(fontSize: 20, color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _eliminar(j);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juegos de cuchillas'),
        actions: [
          IconButton(
            tooltip: 'Máquinas',
            iconSize: 30,
            icon: const Icon(Icons.precision_manufacturing),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MaquinasScreen()));
            },
          ),
        ],
      ),
      body: _juegos.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Sin juegos todavía.\nCrea el primero con el botón +',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _juegos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final j = _juegos[i];
                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const Icon(Icons.hardware, size: 36),
                    title: Text(j.nombre,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600)),
                    subtitle: Text('Alta: ${j.fechaAlta}'),
                    trailing: const Icon(Icons.chevron_right, size: 32),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => JuegoScreen(juego: j)));
                      _cargar();
                    },
                    onLongPress: () => _opcionesJuego(j),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoJuego,
        icon: const Icon(Icons.add, size: 30),
        label: const Text('Nuevo juego', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
