import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

class DB {
  DB._();
  static final DB instance = DB._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final ruta = join(await getDatabasesPath(), 'cuchillas.db');
    _db = await openDatabase(ruta, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE maquinas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE juegos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        fecha_alta TEXT NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1
      )''');
    await db.execute('''
      CREATE TABLE cuchillas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        juego_id INTEGER NOT NULL REFERENCES juegos(id),
        numero INTEGER NOT NULL,
        material TEXT
      )''');
    await db.execute('''
      CREATE TABLE revisiones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cuchilla_id INTEGER NOT NULL REFERENCES cuchillas(id),
        ruta_foto TEXT NOT NULL,
        fecha TEXT NOT NULL,
        llapada INTEGER NOT NULL DEFAULT 0,
        maquina_id INTEGER REFERENCES maquinas(id),
        orden INTEGER NOT NULL,
        dx REAL NOT NULL DEFAULT 0,
        dy REAL NOT NULL DEFAULT 0,
        escala REAL NOT NULL DEFAULT 1,
        rotacion REAL NOT NULL DEFAULT 0
      )''');
    await db.insert('maquinas', {'nombre': 'Máquina 1'});
    await db.insert('maquinas', {'nombre': 'Máquina 2'});
  }

  // ---- Máquinas ----
  Future<List<Maquina>> getMaquinas() async {
    final db = await database;
    final filas = await db.query('maquinas', orderBy: 'id');
    return filas.map(Maquina.fromMap).toList();
  }

  Future<int> insertMaquina(String nombre) async {
    final db = await database;
    return db.insert('maquinas', {'nombre': nombre});
  }

  // ---- Juegos ----
  Future<List<Juego>> getJuegos() async {
    final db = await database;
    final filas = await db.query('juegos', orderBy: 'id DESC');
    return filas.map(Juego.fromMap).toList();
  }

  /// Crea el juego y sus 4 cuchillas.
  Future<int> insertJuego(String nombre) async {
    final db = await database;
    final id = await db.insert('juegos', {
      'nombre': nombre,
      'fecha_alta': fmtFecha(DateTime.now()),
      'activo': 1,
    });
    for (var n = 1; n <= 4; n++) {
      await db.insert('cuchillas', {'juego_id': id, 'numero': n});
    }
    return id;
  }

  // ---- Cuchillas ----
  Future<List<Cuchilla>> getCuchillas(int juegoId) async {
    final db = await database;
    final filas = await db.query('cuchillas',
        where: 'juego_id = ?', whereArgs: [juegoId], orderBy: 'numero');
    return filas.map(Cuchilla.fromMap).toList();
  }

  Future<void> setMaterial(int cuchillaId, String material) async {
    final db = await database;
    await db.update('cuchillas', {'material': material},
        where: 'id = ?', whereArgs: [cuchillaId]);
  }

  // ---- Revisiones ----
  Future<List<Revision>> getRevisiones(int cuchillaId) async {
    final db = await database;
    final filas = await db.query('revisiones',
        where: 'cuchilla_id = ?', whereArgs: [cuchillaId], orderBy: 'orden');
    return filas.map(Revision.fromMap).toList();
  }

  Future<Revision?> getUltimaRevision(int cuchillaId) async {
    final db = await database;
    final filas = await db.query('revisiones',
        where: 'cuchilla_id = ?',
        whereArgs: [cuchillaId],
        orderBy: 'orden DESC',
        limit: 1);
    return filas.isEmpty ? null : Revision.fromMap(filas.first);
  }

  Future<int> insertRevision({
    required int cuchillaId,
    required String rutaFoto,
    required String fecha,
    required bool llapada,
    int? maquinaId,
  }) async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COALESCE(MAX(orden),0)+1 AS sig FROM revisiones WHERE cuchilla_id = ?',
        [cuchillaId]);
    final orden = r.first['sig'] as int;
    return db.insert('revisiones', {
      'cuchilla_id': cuchillaId,
      'ruta_foto': rutaFoto,
      'fecha': fecha,
      'llapada': llapada ? 1 : 0,
      'maquina_id': maquinaId,
      'orden': orden,
    });
  }

  Future<void> guardarAlineacion(
      int revisionId, double dx, double dy, double escala, double rotacion) async {
    final db = await database;
    await db.update(
        'revisiones', {'dx': dx, 'dy': dy, 'escala': escala, 'rotacion': rotacion},
        where: 'id = ?', whereArgs: [revisionId]);
  }
}
