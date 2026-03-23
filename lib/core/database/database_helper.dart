import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/default_categories.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'focus_track.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Categorías
    await db.execute('''
      CREATE TABLE categories (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        color      TEXT    NOT NULL,
        icon       TEXT    NOT NULL,
        productive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Reglas de categorización
    await db.execute('''
      CREATE TABLE tracking_rules (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern     TEXT    NOT NULL,
        match_type  TEXT    NOT NULL,
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        priority    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Sesiones de actividad
    await db.execute('''
      CREATE TABLE activity_sessions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        app_name     TEXT    NOT NULL,
        window_title TEXT,
        url          TEXT,
        started_at   TEXT    NOT NULL,
        ended_at     TEXT,
        duration_sec INTEGER,
        category_id  INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        is_productive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 4. Sesiones de foco (Pomodoro)
    await db.execute('''
      CREATE TABLE focus_sessions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at  TEXT    NOT NULL,
        ended_at    TEXT,
        target_min  INTEGER NOT NULL DEFAULT 25,
        completed   INTEGER NOT NULL DEFAULT 0,
        notes       TEXT
      )
    ''');

    // 5. Configuración clave-valor
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Índices de rendimiento
    await db.execute('CREATE INDEX idx_sessions_started ON activity_sessions(started_at)');
    await db.execute('CREATE INDEX idx_sessions_category ON activity_sessions(category_id)');

    // Insertar categorías y reglas por defecto
    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    // Insertar categorías
    final categoryIds = <String, int>{};
    for (final cat in kDefaultCategories) {
      final id = await db.insert('categories', {
        'name':       cat['name'],
        'color':      cat['color'],
        'icon':       cat['icon'],
        'productive': cat['productive'],
      });
      categoryIds[cat['name'] as String] = id;
    }

    // Insertar reglas vinculadas a las categorías por nombre
    for (final rule in kDefaultRules) {
      final catId = categoryIds[rule['category_name']];
      if (catId != null) {
        await db.insert('tracking_rules', {
          'pattern':     rule['pattern'],
          'match_type':  rule['match_type'],
          'category_id': catId,
          'priority':    rule['priority'],
        });
      }
    }

    // Settings por defecto
    await db.insert('settings', {'key': 'work_hours_daily', 'value': '8'});
    await db.insert('settings', {'key': 'focus_duration_min', 'value': '25'});
    await db.insert('settings', {'key': 'break_duration_min', 'value': '5'});
    await db.insert('settings', {'key': 'track_window_titles', 'value': 'true'});
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
