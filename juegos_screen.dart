import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models.dart';
import 'registro_screen.dart';

/// P2: cámara con guía fantasma (la foto de referencia superpuesta
/// semitransparente para repetir el encuadre).
class CameraScreen extends StatefulWidget {
  final Cuchilla cuchilla;
  final String? rutaReferencia;
  const CameraScreen({super.key, required this.cuchilla, this.rutaReferencia});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _ctrl;
  double _opacidadGuia = 0.4;
  bool _linterna = false;
  bool _capturando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final camaras = await availableCameras();
      final trasera = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => camaras.first,
      );
      final ctrl = CameraController(trasera, ResolutionPreset.high,
          enableAudio: false);
      await ctrl.initialize();
      if (mounted) setState(() => _ctrl = ctrl);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo abrir la cámara: $e');
    }
  }

  Future<void> _toggleLinterna() async {
    if (_ctrl == null) return;
    _linterna = !_linterna;
    await _ctrl!
        .setFlashMode(_linterna ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> _capturar() async {
    if (_ctrl == null || _capturando) return;
    setState(() => _capturando = true);
    try {
      final foto = await _ctrl!.takePicture();
      final docs = await getApplicationDocumentsDirectory();
      final dirFotos = Directory(p.join(docs.path, 'fotos'));
      if (!dirFotos.existsSync()) dirFotos.createSync(recursive: true);
      final destino = p.join(dirFotos.path,
          'c${widget.cuchilla.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(foto.path).copy(destino);
      if (!mounted) return;
      // Apagar linterna antes de salir de la cámara.
      if (_linterna) await _ctrl!.setFlashMode(FlashMode.off);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RegistroScreen(
            cuchilla: widget.cuchilla,
            rutaFoto: destino,
            esPrimeraFoto: widget.rutaReferencia == null,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cámara')),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, style: const TextStyle(fontSize: 18)))),
      );
    }
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tieneGuia = widget.rutaReferencia != null;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Cuchilla ${widget.cuchilla.numero}'
                      '${tieneGuia ? ' · encuadra con la guía' : ' · primera foto'}',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    iconSize: 32,
                    color: _linterna ? Colors.amber : Colors.white,
                    icon: Icon(
                        _linterna ? Icons.flashlight_on : Icons.flashlight_off),
                    onPressed: _toggleLinterna,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_ctrl!),
                  if (tieneGuia)
                    IgnorePointer(
                      child: Opacity(
                        opacity: _opacidadGuia,
                        child: Image.file(File(widget.rutaReferencia!),
                            fit: BoxFit.contain),
                      ),
                    )
                  else
                    IgnorePointer(
                      child: CustomPaint(painter: _Reticula()),
                    ),
                ],
              ),
            ),
            if (tieneGuia)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.opacity, color: Colors.white70, size: 26),
                    Expanded(
                      child: Slider(
                        value: _opacidadGuia,
                        min: 0,
                        max: 0.9,
                        onChanged: (v) => setState(() => _opacidadGuia = v),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: GestureDetector(
                onTap: _capturar,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _capturando ? Colors.grey : Colors.white,
                    border: Border.all(color: Colors.white30, width: 6),
                  ),
                  child: const Icon(Icons.photo_camera,
                      color: Colors.black, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Reticula extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
