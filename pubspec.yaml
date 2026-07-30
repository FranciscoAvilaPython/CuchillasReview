import 'dart:io';
import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';

/// P4: función central. Foto N.º 1 de fondo (referencia) y la revisión
/// seleccionada superpuesta semitransparente, ajustable con gestos.
class ComparacionScreen extends StatefulWidget {
  final Cuchilla cuchilla;
  const ComparacionScreen({super.key, required this.cuchilla});

  @override
  State<ComparacionScreen> createState() => _ComparacionScreenState();
}

class _ComparacionScreenState extends State<ComparacionScreen> {
  List<Revision> _revisiones = [];
  Map<int, String> _nombresMaquinas = {};
  int _indice = 0; // índice dentro de _revisiones de la revisión superpuesta
  double _opacidad = 0.5;

  // Alineación de la revisión actual.
  double _dx = 0, _dy = 0, _escala = 1, _rotacion = 0;
  // Valores al comenzar el gesto.
  double _dx0 = 0, _dy0 = 0, _escala0 = 1, _rot0 = 0;
  Offset _focal0 = Offset.zero;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final revisiones = await DB.instance.getRevisiones(widget.cuchilla.id!);
    final maquinas = await DB.instance.getMaquinas();
    if (!mounted) return;
    setState(() {
      _revisiones = revisiones;
      _nombresMaquinas = {for (final m in maquinas) m.id!: m.nombre};
      // Empezar en la última revisión (la más reciente).
      _indice = revisiones.length - 1;
      _aplicarAlineacion();
    });
  }

  void _aplicarAlineacion() {
    if (_revisiones.isEmpty) return;
    final r = _revisiones[_indice];
    _dx = r.dx;
    _dy = r.dy;
    _escala = r.escala;
    _rotacion = r.rotacion;
  }

  void _cambiar(int delta) {
    final nuevo = _indice + delta;
    if (nuevo < 0 || nuevo >= _revisiones.length) return;
    setState(() {
      _indice = nuevo;
      _aplicarAlineacion();
    });
  }

  Future<void> _guardarAlineacion() async {
    final r = _revisiones[_indice];
    await DB.instance.guardarAlineacion(r.id!, _dx, _dy, _escala, _rotacion);
    _revisiones[_indice] = Revision(
      id: r.id,
      cuchillaId: r.cuchillaId,
      rutaFoto: r.rutaFoto,
      fecha: r.fecha,
      llapada: r.llapada,
      maquinaId: r.maquinaId,
      orden: r.orden,
      dx: _dx,
      dy: _dy,
      escala: _escala,
      rotacion: _rotacion,
    );
  }

  void _resetAlineacion() {
    setState(() {
      _dx = 0;
      _dy = 0;
      _escala = 1;
      _rotacion = 0;
    });
    _guardarAlineacion();
  }

  @override
  Widget build(BuildContext context) {
    if (_revisiones.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final referencia = _revisiones.first;
    final actual = _revisiones[_indice];
    final maquina = actual.maquinaId == null
        ? '—'
        : (_nombresMaquinas[actual.maquinaId] ?? '—');
    final esReferencia = _indice == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Cuchilla ${widget.cuchilla.numero}',
            style: const TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            tooltip: 'Restablecer ajuste',
            iconSize: 28,
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetAlineacion,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white10,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                esReferencia
                    ? 'Rev. 1 (referencia) · ${actual.fecha}'
                    : 'Rev. ${actual.orden} · ${actual.fecha} · $maquina'
                        ' · Llapada: ${actual.llapada ? 'Sí' : 'No'}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onScaleStart: (d) {
                  _dx0 = _dx;
                  _dy0 = _dy;
                  _escala0 = _escala;
                  _rot0 = _rotacion;
                  _focal0 = d.focalPoint;
                },
                onScaleUpdate: (d) {
                  setState(() {
                    _dx = _dx0 + (d.focalPoint.dx - _focal0.dx);
                    _dy = _dy0 + (d.focalPoint.dy - _focal0.dy);
                    _escala = (_escala0 * d.scale).clamp(0.3, 4.0);
                    _rotacion = _rot0 + d.rotation;
                  });
                },
                onScaleEnd: (_) => _guardarAlineacion(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(referencia.rutaFoto), fit: BoxFit.contain),
                    if (!esReferencia)
                      Opacity(
                        opacity: _opacidad,
                        child: Transform.translate(
                          offset: Offset(_dx, _dy),
                          child: Transform.rotate(
                            angle: _rotacion,
                            child: Transform.scale(
                              scale: _escala,
                              child: Image.file(File(actual.rutaFoto),
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!esReferencia)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.opacity, color: Colors.white70, size: 26),
                    Expanded(
                      child: Slider(
                        value: _opacidad,
                        min: 0,
                        max: 1,
                        onChanged: (v) => setState(() => _opacidad = v),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Estás viendo la foto de referencia',
                    style: TextStyle(color: Colors.white54, fontSize: 15)),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 48,
                    color: _indice > 0 ? Colors.white : Colors.white24,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _cambiar(-1),
                  ),
                  Text(
                    'Rev. ${actual.orden} / ${_revisiones.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  IconButton(
                    iconSize: 48,
                    color: _indice < _revisiones.length - 1
                        ? Colors.white
                        : Colors.white24,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _cambiar(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
