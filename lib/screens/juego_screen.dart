import 'dart:io';
import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';
import 'camera_screen.dart';
import 'comparacion_screen.dart';

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

  void _opciones(Cuchilla c) {
    final ultima = _ultimas[c.id!];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cuchilla ${c.numero}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w600)),
              if (c.material != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Material: ${c.material}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera, size: 30),
                label: const Text('Nueva revisión'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _nuevaFoto(c);
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.compare, size: 30),
                label: Text(ultima == null
                    ? 'Comparar (sin fotos)'
                    : 'Comparar (${ultima.orden} fotos)'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _comparar(c);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.juego.nombre)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: _cuchillas.map((c) {
          final ultima = _ultimas[c.id!];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _opciones(c),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ultima == null
                        ? Container(
                            color: Colors.black26,
                            child: const Icon(Icons.photo_camera_outlined,
                                size: 48, color: Colors.white38),
                          )
                        : Image.file(File(ultima.rutaFoto), fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text('Cuchilla ${c.numero}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                        Text(
                          ultima == null
                              ? 'Sin fotos'
                              : '${ultima.fecha} · Rev. ${ultima.orden}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
