import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class AppDatabase {
  static Database? _database;
  static const dbName = 'rkfm_broadcast.db';
  static const dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);
    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        display_name TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        must_change_password INTEGER DEFAULT 0,
        failed_login_attempts INTEGER DEFAULT 0,
        locked_until TEXT,
        created_at TEXT NOT NULL,
        last_login_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE login_history (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        username TEXT NOT NULL,
        device_id TEXT NOT NULL,
        success INTEGER NOT NULL,
        failure_reason TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        username TEXT NOT NULL,
        category TEXT NOT NULL,
        level TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE program_cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        logo_path TEXT,
        background_path TEXT,
        template_id TEXT NOT NULL,
        facebook_destination_id TEXT NOT NULL,
        rtmp_destination_id TEXT,
        program_title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        ticker_text TEXT NOT NULL,
        camera_profile_id TEXT NOT NULL,
        audio_profile_id TEXT NOT NULL,
        bitrate INTEGER DEFAULT 4000,
        recording_profile_id TEXT NOT NULL,
        overlay_profile_id TEXT NOT NULL,
        countdown_duration INTEGER DEFAULT 10,
        card_color INTEGER NOT NULL,
        recording_path TEXT NOT NULL,
        is_archived INTEGER DEFAULT 0,
        is_outdoor INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE facebook_destinations (
        id TEXT PRIMARY KEY,
        page_name TEXT NOT NULL,
        rtmp_url TEXT NOT NULL,
        stream_key TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        is_built_in INTEGER DEFAULT 0,
        elements_json TEXT NOT NULL,
        width INTEGER DEFAULT 1920,
        height INTEGER DEFAULT 1080,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE camera_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        camera_facing TEXT DEFAULT 'rear',
        zoom REAL DEFAULT 1.0,
        filter TEXT DEFAULT 'none',
        fps INTEGER DEFAULT 30,
        background_blur INTEGER DEFAULT 0,
        face_enhancement INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE audio_profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        input_source TEXT DEFAULT 'builtin',
        gain REAL DEFAULT 1.0,
        noise_gate INTEGER DEFAULT 1,
        compressor INTEGER DEFAULT 1,
        limiter INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY,
        countdown_duration INTEGER DEFAULT 10,
        resolution TEXT DEFAULT '1920x1080',
        bitrate INTEGER DEFAULT 4000,
        fps INTEGER DEFAULT 30,
        audio_input TEXT DEFAULT 'builtin',
        audio_gain REAL DEFAULT 1.0,
        recording_quality TEXT DEFAULT '1080p',
        recording_path TEXT,
        auto_record INTEGER DEFAULT 1,
        pin TEXT DEFAULT '9750',
        session_timeout INTEGER DEFAULT 30,
        auto_logout INTEGER DEFAULT 1,
        language TEXT DEFAULT 'en'
      )
    ''');

    await db.execute('''
      CREATE TABLE recordings (
        id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        program_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        duration_seconds INTEGER DEFAULT 0,
        resolution TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
