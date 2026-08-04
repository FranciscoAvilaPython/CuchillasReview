import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db.dart';
import '../models.dart';
import 'camera_screen.dart';
import 'comparacion_screen.dart';
import 'registro_screen.dart';

class JuegoScreen extends StatefulWidget {
  final Juego juego;
  const JuegoScreen({super.key, required this.juego});

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> {
  List<Cuchilla> _cuchillas = [];
  final Map<int, Revision?> _ultimas = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final cuchillas = await DB.instance.getCuchillas(widget.juego.id!);
    for (final c in cuchillas) {
      _ultimas[c.id!] = await DB.instance.getUltimaRevision(c.id!);
    }
    if (mounted) setState(() => _cuchillas = cuchillas);
  }

  Future<void> _nuevaFoto(Cuchilla c) async {
    final revisiones = await DB.instance.getRevisiones(c.id!);
    final referencia = revisiones.isEmpty ? null : revisiones.first.rutaFoto;
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(cuchilla: c, rutaReferencia: referencia),
      ),
    );
    _cargar();
  }

  Future<void> _comparar(Cuchilla c) async {
    final revisiones = await DB.instance.getRevisiones(c.id!);
    if (revisiones.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Esta cuchilla aún no tiene fotos',
              style: TextStyle(fontSize: 18))));
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ComparacionScreen(cuchilla: c)),
    );
    _cargar();
  }

  Future<void> _subirGaleria(Cuchilla c) async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final docs = await getApplicationDocumentsDirectory();
    final dirFotos = Directory(p.join(docs.path, 'fotos'));
    if (!dirFotos.existsSync()) dirFotos.createSync(recursive: true);
    final destino = p.join(dirFotos.path,
        'c${c.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(img.path).copy(destino);
    final revisiones = await DB.instance.getRevisiones(c.id!);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegistroScreen(
          cuchilla: c,
          rutaFoto: destino,
          esPrimeraFoto: revisiones.isEmpty,
        ),
      ),
    );
    _cargar();
  }

  Future<void> _editarMaterial(Cuchilla c) async {
    final ctrl = TextEditingController(text: c.material ?? '');
    final material = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Material · Cuchilla ${c.numero}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Ej: acero antidesgaste'),
        ),
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
    if (material == null) return;
    await DB.instance.setMaterial(c.id!, material);
    _cargar();
  }

  Widget _accion(IconData icono, String texto, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icono, size: 28, color: color),
      title: Text(texto, style: TextStyle(fontSize: 18, color: color)),
      dense: false,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.juego.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _cuchillas.map((c) {
          final ultima = _ultimas[c.id!];
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: ultima == null
                  ? Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          size: 28, color: Colors.black38),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(ultima.rutaFoto),
                          width: 56, height: 56, fit: BoxFit.cover),
                    ),
              title: Text('Cuchilla ${c.numero}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              subtitle: Text(
                ultima == null
                    ? 'Sin fotos'
                    : '${ultima.fecha} · Rev. ${ultima.orden}'
                        '${c.material == null ? '' : ' · ${c.material}'}',
                style:
                    const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              children: [
                _accion(Icons.photo_camera, 'Nueva revisión (cámara)',
                    () => _nuevaFoto(c)),
                _accion(Icons.photo_library, 'Subir desde galería',
                    () => _subirGaleria(c)),
                _accion(
                    Icons.compare,
                    ultima == null
                        ? 'Comparar (sin fotos)'
                        : 'Comparar (${ultima.orden} fotos)',
                    () => _comparar(c)),
                _accion(Icons.edit, 'Editar material',
                    () => _editarMaterial(c)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
