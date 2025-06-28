import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:logger/logger.dart';

class DatabaseRepository {
  final Logger log = Logger();
  static Database? _database;
  static const String _databaseName = "todo_app.db";
  static const int _databaseVersion = 2;

  static final DatabaseRepository _instance = DatabaseRepository._internal();
  factory DatabaseRepository() => _instance;
  DatabaseRepository._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      log.d("DatabaseRepository::_initDatabase::Initializing database...");

      if (kIsWeb) {
        log.d("DatabaseRepository::_initDatabase::Initializing for web platform");
        databaseFactory = databaseFactoryFfiWeb;
      } else if (Platform.isWindows || Platform.isLinux) {
        log.d("DatabaseRepository::_initDatabase::Initializing for desktop platform");
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbPath = await _getDatabasePath();
      log.d("DatabaseRepository::_initDatabase::Database path: $dbPath");

      try {
        final exists = await databaseFactory.databaseExists(dbPath);
        if (exists) {
          log.d("DatabaseRepository::_initDatabase::Database exists, checking version...");
          final tempDb = await databaseFactory.openDatabase(dbPath);
          final version = await tempDb.getVersion();
          await tempDb.close();
          log.d("DatabaseRepository::_initDatabase::Current database version: $version");

          if (version != _databaseVersion) {
            log.d("DatabaseRepository::_initDatabase::Version mismatch, deleting old database");
            await databaseFactory.deleteDatabase(dbPath);
          }
        }
      } catch (e) {
        log.w("DatabaseRepository::_initDatabase::Error checking existing database: $e");

        try {
          await databaseFactory.deleteDatabase(dbPath);
        } catch (deleteError) {
          log.w("DatabaseRepository::_initDatabase::Could not delete database: $deleteError");
        }
      }

      return await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade, onDowngrade: _onDowngrade),
      );
    } catch (error) {
      log.e("DatabaseRepository::_initDatabase::Error: $error");
      rethrow;
    }
  }

  Future<String> _getDatabasePath() async {
    if (kIsWeb) {
      return _databaseName;
    } else if (Platform.isWindows || Platform.isLinux) {
      final databasePath = await databaseFactory.getDatabasesPath();
      return '$databasePath/$_databaseName';
    } else {
      final databasePath = await databaseFactory.getDatabasesPath();
      return '$databasePath/$_databaseName';
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      log.d("DatabaseRepository::_onCreate::Creating database tables...");

      final createTableSQL =
          '''
        CREATE TABLE ${Constants.database.TABLE_TODOS} (
          ${Constants.database.COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${Constants.database.COLUMN_TODO_TITLE} TEXT NOT NULL,
          ${Constants.database.COLUMN_TODO_DESCRIPTION} TEXT,
          ${Constants.database.COLUMN_TODO_IS_COMPLETED} INTEGER DEFAULT 0,
          ${Constants.database.COLUMN_TODO_PRIORITY} TEXT DEFAULT '${Constants.database.PRIORITY_MEDIUM}',
          ${Constants.database.COLUMN_TODO_DUE_DATE} TEXT,
          ${Constants.database.COLUMN_FIRESTORE_ID} TEXT,
          ${Constants.database.COLUMN_NEEDS_SYNC} INTEGER DEFAULT 0,
          ${Constants.database.COLUMN_CREATED_AT} TEXT NOT NULL,
          ${Constants.database.COLUMN_UPDATED_AT} TEXT NOT NULL,
          ${Constants.database.COLUMN_IS_DELETED} INTEGER DEFAULT 0
        )
      ''';

      log.d("DatabaseRepository::_onCreate::Executing SQL: $createTableSQL");
      await db.execute(createTableSQL);

      log.d("DatabaseRepository::_onCreate::Database tables created successfully");
    } catch (error) {
      log.e("DatabaseRepository::_onCreate::Error: $error");
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      log.d("DatabaseRepository::_onUpgrade::Upgrading database from $oldVersion to $newVersion");

      if (oldVersion < 2) {
        log.d("DatabaseRepository::_onUpgrade::Adding sync columns");

        await db.execute('ALTER TABLE ${Constants.database.TABLE_TODOS} ADD COLUMN ${Constants.database.COLUMN_FIRESTORE_ID} TEXT');
        log.d("DatabaseRepository::_onUpgrade::Added firestore_id column");

        await db.execute('ALTER TABLE ${Constants.database.TABLE_TODOS} ADD COLUMN ${Constants.database.COLUMN_NEEDS_SYNC} INTEGER DEFAULT 0');
        log.d("DatabaseRepository::_onUpgrade::Added needs_sync column");
      }

      log.d("DatabaseRepository::_onUpgrade::Database upgrade completed");
    } catch (error) {
      log.e("DatabaseRepository::_onUpgrade::Error: $error");
      rethrow;
    }
  }

  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    try {
      log.d("DatabaseRepository::_onDowngrade::Downgrading database from $oldVersion to $newVersion");

      log.d("DatabaseRepository::_onDowngrade::Database downgrade completed");
    } catch (error) {
      log.e("DatabaseRepository::_onDowngrade::Error: $error");
      rethrow;
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      final db = await database;
      final now = DateTime.now().toUtc().toIso8601String();

      data[Constants.database.COLUMN_CREATED_AT] = now;
      data[Constants.database.COLUMN_UPDATED_AT] = now;

      log.d("DatabaseRepository::insert::Inserting into $table: $data");

      final id = await db.insert(table, data);
      log.d("DatabaseRepository::insert::Inserted with ID: $id");

      return id;
    } catch (error) {
      log.e("DatabaseRepository::insert::Error: $error");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;

      log.d("DatabaseRepository::query::Querying $table with where: $where");

      final results = await db.query(
        table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      log.d("DatabaseRepository::query::Found ${results.length} records");
      return results;
    } catch (error) {
      log.e("DatabaseRepository::query::Error: $error");
      rethrow;
    }
  }

  Future<int> update(String table, Map<String, dynamic> data, {String? where, List<Object?>? whereArgs}) async {
    try {
      final db = await database;

      data[Constants.database.COLUMN_UPDATED_AT] = DateTime.now().toUtc().toIso8601String();

      log.d("DatabaseRepository::update::Updating $table: $data where: $where");

      final count = await db.update(table, data, where: where, whereArgs: whereArgs);

      log.d("DatabaseRepository::update::Updated $count records");
      return count;
    } catch (error) {
      log.e("DatabaseRepository::update::Error: $error");
      rethrow;
    }
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    try {
      final db = await database;

      log.d("DatabaseRepository::delete::Deleting from $table where: $where");

      final count = await db.delete(table, where: where, whereArgs: whereArgs);

      log.d("DatabaseRepository::delete::Deleted $count records");
      return count;
    } catch (error) {
      log.e("DatabaseRepository::delete::Error: $error");
      rethrow;
    }
  }

  Future<int> softDelete(String table, {String? where, List<Object?>? whereArgs}) async {
    try {
      final db = await database;

      log.d("DatabaseRepository::softDelete::Soft deleting from $table where: $where");

      final data = {Constants.database.COLUMN_IS_DELETED: 1, Constants.database.COLUMN_UPDATED_AT: DateTime.now().toUtc().toIso8601String()};

      final count = await db.update(table, data, where: where, whereArgs: whereArgs);

      log.d("DatabaseRepository::softDelete::Soft deleted $count records");
      return count;
    } catch (error) {
      log.e("DatabaseRepository::softDelete::Error: $error");
      rethrow;
    }
  }

  Future<void> close() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        log.d("DatabaseRepository::close::Database closed successfully");
      }
    } catch (error) {
      log.e("DatabaseRepository::close::Error: $error");
      rethrow;
    }
  }

  Future<void> deleteDatabase() async {
    try {
      final dbPath = await _getDatabasePath();
      await databaseFactory.deleteDatabase(dbPath);
      _database = null;
      log.d("DatabaseRepository::deleteDatabase::Database deleted successfully");
    } catch (error) {
      log.e("DatabaseRepository::deleteDatabase::Error: $error");
      rethrow;
    }
  }
}
