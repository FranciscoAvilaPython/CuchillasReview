class Maquina {
  final int? id;
  final String nombre;
  Maquina({this.id, required this.nombre});

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};
  factory Maquina.fromMap(Map<String, dynamic> m) =>
      Maquina(id: m['id'] as int?, nombre: m['nombre'] as String);
}

class Juego {
  final int? id;
  final String nombre;
  final String fechaAlta;
  final bool activo;
  Juego({this.id, required this.nombre, required this.fechaAlta, this.activo = true});

  Map<String, dynamic> toMap() =>
      {'id': id, 'nombre': nombre, 'fecha_alta': fechaAlta, 'activo': activo ? 1 : 0};
  factory Juego.fromMap(Map<String, dynamic> m) => Juego(
        id: m['id'] as int?,
        nombre: m['nombre'] as String,
        fechaAlta: m['fecha_alta'] as String,
        activo: (m['activo'] as int) == 1,
      );
}

class Cuchilla {
  final int? id;
  final int juegoId;
  final int numero;
  final String? material;
  Cuchilla({this.id, required this.juegoId, required this.numero, this.material});

  Map<String, dynamic> toMap() =>
      {'id': id, 'juego_id': juegoId, 'numero': numero, 'material': material};
  factory Cuchilla.fromMap(Map<String, dynamic> m) => Cuchilla(
        id: m['id'] as int?,
        juegoId: m['juego_id'] as int,
        numero: m['numero'] as int,
        material: m['material'] as String?,
      );
}

class Revision {
  final int? id;
  final int cuchillaId;
  final String rutaFoto;
  final String fecha;
  final bool llapada;
  final int? maquinaId;
  final int orden;
  final int? turnos;
  final double dx, dy, escala, rotacion;
  Revision({
    this.id,
    required this.cuchillaId,
    required this.rutaFoto,
    required this.fecha,
    required this.llapada,
    this.maquinaId,
    required this.orden,
    this.turnos,
    this.dx = 0,
    this.dy = 0,
    this.escala = 1,
    this.rotacion = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'cuchilla_id': cuchillaId,
        'ruta_foto': rutaFoto,
        'fecha': fecha,
        'llapada': llapada ? 1 : 0,
        'maquina_id': maquinaId,
        'orden': orden,
        'turnos': turnos,
        'dx': dx,
        'dy': dy,
        'escala': escala,
        'rotacion': rotacion,
      };
  factory Revision.fromMap(Map<String, dynamic> m) => Revision(
        id: m['id'] as int?,
        cuchillaId: m['cuchilla_id'] as int,
        rutaFoto: m['ruta_foto'] as String,
        fecha: m['fecha'] as String,
        llapada: (m['llapada'] as int) == 1,
        maquinaId: m['maquina_id'] as int?,
        orden: m['orden'] as int,
        turnos: m['turnos'] as int?,
        dx: (m['dx'] as num).toDouble(),
        dy: (m['dy'] as num).toDouble(),
        escala: (m['escala'] as num).toDouble(),
        rotacion: (m['rotacion'] as num).toDouble(),
      );
}

String fmtFecha(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}-${dos(d.month)}-${d.year}';
}
