import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabaseHelper {
  static final AppDatabaseHelper _instance = AppDatabaseHelper._internal();
  factory AppDatabaseHelper() => _instance;
  AppDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();

    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wheely.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notify ADD COLUMN created_at TEXT');
      await db.execute('ALTER TABLE notify ADD COLUMN is_read INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE notify ADD COLUMN ref_id TEXT');
    }
  }
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notify(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        action TEXT,
        topic TEXT,
        created_at TEXT,
        is_read INTEGER DEFAULT 0,
        ref_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ride(
        id INTEGER PRIMARY KEY,
        userId INTEGER,
        carId INTEGER,
        departureDate TEXT,
        departureTime TEXT,
        startLat TEXT,
        startLng TEXT,
        startName TEXT,
        destLat TEXT,
        destLng TEXT,
        destName TEXT,
        seats INTEGER,
        price INTEGER,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT,
        timestamp TEXT,
        isRead INTEGER
      )
    ''');
  }
}
