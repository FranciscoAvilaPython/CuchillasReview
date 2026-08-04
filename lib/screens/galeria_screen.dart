import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db.dart';
import '../models.dart';

/// Pestaña Galería: todas las fotos existentes, con filtros y edición
/// completa de datos, imagen e información.
class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Juego> _juegos = [];
  List<Maquina> _maquinas = [];
  int? _filtroJuego;
  int? _filtroCuchilla;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final juegos = await DB.instance.getJuegos();
    final maquinas = await DB.instance.getMaquinas();
    final items = await DB.instance
        .getRevisionesDetalle(juegoId: _filtroJuego, numero: _filtroCuchilla);
    if (mounted) {
      setState(() {
        _juegos = juegos;
        _maquinas = maquinas;
        _items = items;
      });
    }
  }

  DateTime _parseFecha(String f) {
    final partes = f.split('-');
    if (partes.length == 3) {
      final d = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      final a = int.tryParse(partes[2]);
      if (d != null && m != null && a != null) return DateTime(a, m, d);
    }
    return DateTime.now();
  }

  Future<void> _editarDatos(Map<String, dynamic> it) async {
    var fecha = _parseFecha(it['fecha'] as String);
    int? maquinaId = it['maquina_id'] as int?;
    var llapada = (it['llapada'] as int) == 1;
    final turnosCtrl =
        TextEditingController(text: (it['turnos'] as int?)?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('${it['juego_nombre']} · Cuchilla '
              '${it['cuchilla_numero']} · Rev. ${it['orden']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(fmtFecha(fecha)),
                  onPressed: () async {
                    final f = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (f != null) setD(() => fecha = f);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Máquina'),
                Wrap(
                  spacing: 8,
                  children: _maquinas
                      .map((m) => ChoiceChip(
                            label: Text(m.nombre),
                            selected: maquinaId == m.id,
                            onSelected: (_) => setD(() => maquinaId = m.id),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('¿Llapada?'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Sí'),
                      selected: llapada,
                      onSelected: (_) => setD(() => llapada = true),
                    ),
                    ChoiceChip(
                      label: const Text('No'),
                      selected: !llapada,
                      onSelected: (_) => setD(() => llapada = false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: turnosCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Turnos trabajados',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await DB.instance.updateRevision(it['id'] as int,
        fecha: fmtFecha(fecha),
        llapada: llapada,
        maquinaId: maquinaId,
        turnos: int.tryParse(turnosCtrl.text.trim()));
    _cargar();
  }

  Future<void> _reemplazarFoto(Map<String, dynamic> it) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dirFotos = Directory(p.join(docs.path, 'fotos'));
    if (!dirFotos.existsSync()) dirFotos.createSync(recursive: true);
    final destino = p.join(dirFotos.path,
        'c${it['cuchilla_id']}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(img.path).copy(destino);
    await DB.instance.updateRevisionFoto(it['id'] as int, destino);
    try {
      final viejo = File(it['ruta_foto'] as String);
      if (viejo.existsSync()) viejo.deleteSync();
    } catch (_) {}
    _cargar();
  }

  Future<void> _eliminar(Map<String, dynamic> it) async {
    final esRef = (it['orden'] as int) == 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿Eliminar Rev. ${it['orden']}?'),
        content: Text(esRef
            ? 'Es la foto de REFERENCIA de esta cuchilla. La siguiente foto pasará a ser la nueva referencia.'
            : 'La foto se borrará definitivamente.'),
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
    try {
      final f = File(it['ruta_foto'] as String);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    await DB.instance.deleteRevision(it['id'] as int);
    _cargar();
  }

  void _opciones(Map<String, dynamic> it) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, size: 30),
              title:
                  const Text('Editar datos', style: TextStyle(fontSize: 20)),
              onTap: () {
                Navigator.pop(ctx);
                _editarDatos(it);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 30),
              title: const Text('Reemplazar foto (galería)',
                  style: TextStyle(fontSize: 20)),
              onTap: () {
                Navigator.pop(ctx);
                _reemplazarFoto(it);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red, size: 30),
              title: const Text('Eliminar revisión',
                  style: TextStyle(fontSize: 20, color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _eliminar(it);
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
      appBar: AppBar(title: const Text('Galería de fotos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _filtroJuego,
                    decoration: const InputDecoration(
                        labelText: 'Juego', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Todos')),
                      ..._juegos.map((j) => DropdownMenuItem<int?>(
                          value: j.id, child: Text(j.nombre))),
                    ],
                    onChanged: (v) {
                      _filtroJuego = v;
                      _cargar();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _filtroCuchilla,
                    decoration: const InputDecoration(
                        labelText: 'Cuchilla', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                      DropdownMenuItem<int?>(value: 1, child: Text('1')),
                      DropdownMenuItem<int?>(value: 2, child: Text('2')),
                      DropdownMenuItem<int?>(value: 3, child: Text('3')),
                      DropdownMenuItem<int?>(value: 4, child: Text('4')),
                    ],
                    onChanged: (v) {
                      _filtroCuchilla = v;
                      _cargar();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text('Sin fotos que mostrar',
                        style:
                            TextStyle(fontSize: 18, color: Colors.black54)))
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final it = _items[i];
                      final turnos = it['turnos'] as int?;
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(it['ruta_foto'] as String),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.black26),
                            ),
                          ),
                          title: Text(
                            '${it['juego_nombre']} · Cuchilla ${it['cuchilla_numero']}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Rev. ${it['orden']} · ${it['fecha']}'
                            ' · ${it['maquina_nombre'] ?? 'Sin máquina'}'
                            ' · Llapada: ${(it['llapada'] as int) == 1 ? 'Sí' : 'No'}'
                            '${turnos == null ? '' : ' · $turnos turnos'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing:
                              const Icon(Icons.more_vert, size: 28),
                          onTap: () => _opciones(it),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
