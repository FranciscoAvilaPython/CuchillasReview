import 'dart:io';
import 'package:flutter/material.dart';
import '../db.dart';
import '../models.dart';

/// P3: registro de datos tras tomar la foto.
class RegistroScreen extends StatefulWidget {
  final Cuchilla cuchilla;
  final String rutaFoto;
  final bool esPrimeraFoto;
  const RegistroScreen({
    super.key,
    required this.cuchilla,
    required this.rutaFoto,
    required this.esPrimeraFoto,
  });

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  DateTime _fecha = DateTime.now();
  List<Maquina> _maquinas = [];
  int? _maquinaId;
  bool _llapada = false;
  final _materialCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    DB.instance.getMaquinas().then((m) {
      if (mounted) {
        setState(() {
          _maquinas = m;
          if (m.isNotEmpty) _maquinaId = m.first.id;
        });
      }
    });
  }

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    setState(() => _guardando = true);
    await DB.instance.insertRevision(
      cuchillaId: widget.cuchilla.id!,
      rutaFoto: widget.rutaFoto,
      fecha: fmtFecha(_fecha),
      llapada: _llapada,
      maquinaId: _maquinaId,
    );
    final mat = _materialCtrl.text.trim();
    if (widget.esPrimeraFoto && mat.isNotEmpty) {
      await DB.instance.setMaterial(widget.cuchilla.id!, mat);
    }
    if (mounted) Navigator.pop(context, true);
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 16, color: Colors.white70)),
      );

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text('Registro · Cuchilla ${widget.cuchilla.numero}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(widget.rutaFoto),
                height: 160, fit: BoxFit.cover),
          ),
          _titulo('Fecha de cambio / revisión'),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(88, 56),
                textStyle: const TextStyle(fontSize: 20)),
            icon: const Icon(Icons.calendar_month, size: 26),
            label: Text(fmtFecha(_fecha)),
            onPressed: _elegirFecha,
          ),
          _titulo('Máquina donde está instalada'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _maquinas
                .map((m) => ChoiceChip(
                      label: Text(m.nombre,
                          style: const TextStyle(fontSize: 18)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      selected: _maquinaId == m.id,
                      onSelected: (_) => setState(() => _maquinaId = m.id),
                    ))
                .toList(),
          ),
          _titulo('¿Está llapada?'),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Text('Sí', style: TextStyle(fontSize: 20))),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  selected: _llapada,
                  selectedColor: color.errorContainer,
                  onSelected: (_) => setState(() => _llapada = true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                      child: Text('No', style: TextStyle(fontSize: 20))),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  selected: !_llapada,
                  onSelected: (_) => setState(() => _llapada = false),
                ),
              ),
            ],
          ),
          if (widget.esPrimeraFoto) ...[
            _titulo('Material de la cuchilla (solo esta vez)'),
            TextField(
              controller: _materialCtrl,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ej: acero antidesgaste',
              ),
            ),
          ],
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 30),
            label: const Text('Guardar revisión'),
            onPressed: _guardar,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
