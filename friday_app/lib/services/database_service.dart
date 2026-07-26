import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Low-level SQLite database service.
///
/// The ONLY class in the app that directly touches sqflite.
/// All reads and writes go through repository classes — never through this
/// service directly from UI or business logic.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'friday_lite.db';
  static const int _dbVersion = 5;

  Database? _database;

  // ---------------------------------------------------------------------------
  // Public
  // ---------------------------------------------------------------------------

  /// Returns the open [Database] instance, initialising it on first call.
  Future<Database> get database async {
    _database ??= await _init();
    return _database!;
  }

  /// Close the database connection — called on full app shutdown.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    FridayLogger.log(LogCategory.assistant, 'DatabaseService: closed');
  }

  // ---------------------------------------------------------------------------
  // Initialisation / Migrations
  // ---------------------------------------------------------------------------

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    FridayLogger.log(LogCategory.assistant, 'DatabaseService: opening $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    FridayLogger.log(
      LogCategory.assistant,
      'DatabaseService: creating schema v$version',
    );

    // ── Chat messages ─────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        role      TEXT    NOT NULL,
        content   TEXT    NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // ── Notes ─────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        title      TEXT    NOT NULL,
        body       TEXT    NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // ── Reminders ─────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT    NOT NULL,
        scheduled_at INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Favourite contacts ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contacts (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        name         TEXT    NOT NULL,
        phone_number TEXT    NOT NULL,
        relation     TEXT
      )
    ''');

    // ── Settings ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // ── Calendar Events ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS calendar_events (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT    NOT NULL,
        start_time   INTEGER NOT NULL,
        location     TEXT,
        description  TEXT
      )
    ''');

    // ── Alarms ────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alarms (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        label        TEXT    NOT NULL,
        alarm_time   INTEGER NOT NULL,
        is_enabled   INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // ── To-Do Items ───────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS todo_items (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        task         TEXT    NOT NULL,
        is_done      INTEGER NOT NULL DEFAULT 0,
        created_at   INTEGER NOT NULL
      )
    ''');

    // ── Installed Apps Database ───────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS installed_apps (
        package_name  TEXT PRIMARY KEY,
        app_name      TEXT NOT NULL,
        category      TEXT NOT NULL,
        launch_count  INTEGER NOT NULL DEFAULT 0,
        last_launched INTEGER
      )
    ''');

    // ── Long-Term Memory Table ─────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS long_term_memory (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_type TEXT    NOT NULL,
        key         TEXT    NOT NULL,
        value       TEXT    NOT NULL,
        ranking     INTEGER NOT NULL DEFAULT 1,
        created_at  INTEGER NOT NULL,
        expires_at  INTEGER
      )
    ''');

    // ── Automation Rules Table ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS automation_rules (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        name           TEXT    NOT NULL,
        trigger_type   TEXT    NOT NULL,
        condition_json TEXT    NOT NULL,
        action_command TEXT    NOT NULL,
        is_enabled     INTEGER NOT NULL DEFAULT 1,
        created_at     INTEGER NOT NULL
      )
    ''');

    // ── Automation Execution History Table ────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS automation_history (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        rule_id        INTEGER NOT NULL,
        rule_name      TEXT    NOT NULL,
        triggered_at   INTEGER NOT NULL,
        result_speech  TEXT    NOT NULL
      )
    ''');

    FridayLogger.log(LogCategory.assistant, 'DatabaseService: schema created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    FridayLogger.log(
      LogCategory.assistant,
      'DatabaseService: migrating v$oldVersion → v$newVersion',
    );

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS calendar_events (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          title        TEXT    NOT NULL,
          start_time   INTEGER NOT NULL,
          location     TEXT,
          description  TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alarms (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          label        TEXT    NOT NULL,
          alarm_time   INTEGER NOT NULL,
          is_enabled   INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS todo_items (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          task         TEXT    NOT NULL,
          is_done      INTEGER NOT NULL DEFAULT 0,
          created_at   INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS installed_apps (
          package_name  TEXT PRIMARY KEY,
          app_name      TEXT NOT NULL,
          category      TEXT NOT NULL,
          launch_count  INTEGER NOT NULL DEFAULT 0,
          last_launched INTEGER
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS long_term_memory (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          memory_type TEXT    NOT NULL,
          key         TEXT    NOT NULL,
          value       TEXT    NOT NULL,
          ranking     INTEGER NOT NULL DEFAULT 1,
          created_at  INTEGER NOT NULL,
          expires_at  INTEGER
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS automation_rules (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          name           TEXT    NOT NULL,
          trigger_type   TEXT    NOT NULL,
          condition_json TEXT    NOT NULL,
          action_command TEXT    NOT NULL,
          is_enabled     INTEGER NOT NULL DEFAULT 1,
          created_at     INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS automation_history (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          rule_id        INTEGER NOT NULL,
          rule_name      TEXT    NOT NULL,
          triggered_at   INTEGER NOT NULL,
          result_speech  TEXT    NOT NULL
        )
      ''');
    }
  }
}
