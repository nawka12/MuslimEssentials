import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import '../models/prayer_time.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'prayer_times.db');
    return await openDatabase(
      path, 
      version: 4, // Increase version number to 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE prayer_times (
        id INTEGER PRIMARY KEY,
        date TEXT,
        fajr TEXT,
        sunrise TEXT,
        dhuhr TEXT,
        asr TEXT,
        maghrib TEXT,
        isha TEXT,
        hijri_date TEXT,
        hijri_day TEXT,
        hijri_weekday TEXT,
        hijri_month TEXT,
        hijri_year TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE location_settings (
        id INTEGER PRIMARY KEY,
        location_name TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE quran_last_read (
        id INTEGER PRIMARY KEY,
        surah_number INTEGER,
        ayah_number INTEGER,
        timestamp INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE quran_bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah_number INTEGER,
        ayah_number INTEGER,
        timestamp INTEGER
      )
    ''');
  }
  
  // Handle database upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the new columns if upgrading from version 1
      try {
        await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_date TEXT');
        await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_day TEXT');
        await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_weekday TEXT');
        await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_month TEXT');
        await db.execute('ALTER TABLE prayer_times ADD COLUMN hijri_year TEXT');
      } catch (e) {
        print('Error upgrading database: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Add location_settings table if upgrading from version 2
      try {
        await db.execute('''
          CREATE TABLE location_settings (
            id INTEGER PRIMARY KEY,
            location_name TEXT
          )
        ''');
      } catch (e) {
        print('Error creating location_settings table: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Add quran_last_read and quran_bookmarks tables if upgrading from version 3
      try {
        await db.execute('''
          CREATE TABLE quran_last_read (
            id INTEGER PRIMARY KEY,
            surah_number INTEGER,
            ayah_number INTEGER,
            timestamp INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE quran_bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER,
            ayah_number INTEGER,
            timestamp INTEGER
          )
        ''');
      } catch (e) {
        print('Error creating quran tables: $e');
      }
    }
  }

  Future<int> insertPrayerTime(PrayerTime prayerTime) async {
    Database db = await database;
    return await db.insert('prayer_times', prayerTime.toMap());
  }

  Future<void> insertPrayerTimes(List<PrayerTime> prayerTimes) async {
    Database db = await database;
    Batch batch = db.batch();
    
    for (var prayerTime in prayerTimes) {
      batch.insert('prayer_times', prayerTime.toMap());
    }
    
    await batch.commit(noResult: true);
  }

  Future<PrayerTime?> getPrayerTimeByDate(String date) async {
    Database db = await database;
    
    // First try exact match with the date format provided
    List<Map<String, dynamic>> maps = await db.query(
      'prayer_times',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isEmpty) {
      // If no match found, try alternative format
      // The API might return dates in 'DD-MM-YYYY' format, but we might look for dates in 'YYYY-MM-DD' format
      try {
        // Parse the date to handle different formats
        List<String> dateParts = date.split('-');
        if (dateParts.length == 3) {
          String alternativeDate;
          
          if (dateParts[0].length == 4) {
            // If input is YYYY-MM-DD, convert to DD-MM-YYYY
            alternativeDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
          } else {
            // If input is DD-MM-YYYY, convert to YYYY-MM-DD
            alternativeDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
          }
          
          maps = await db.query(
            'prayer_times',
            where: 'date = ?',
            whereArgs: [alternativeDate],
          );
        }
      } catch (e) {
        print('Error converting date format: $e');
      }
    }

    if (maps.isNotEmpty) {
      return PrayerTime.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PrayerTime>> getAllPrayerTimes() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('prayer_times');
    return List.generate(maps.length, (i) {
      return PrayerTime.fromMap(maps[i]);
    });
  }

  Future<int> deletePrayerTime(int id) async {
    Database db = await database;
    return await db.delete(
      'prayer_times',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllPrayerTimes() async {
    Database db = await database;
    return await db.delete('prayer_times');
  }

  Future<void> insertOrReplacePrayerTimes(List<PrayerTime> prayerTimes) async {
    Database db = await database;
    Batch batch = db.batch();
    
    for (var prayerTime in prayerTimes) {
      batch.insert(
        'prayer_times', 
        prayerTime.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  // Add methods to save and retrieve location name
  Future<void> saveLocationName(String locationName) async {
    Database db = await database;
    
    // Check if a record already exists
    List<Map<String, dynamic>> existingRecords = await db.query('location_settings');
    
    if (existingRecords.isEmpty) {
      // Insert new record
      await db.insert('location_settings', {'id': 1, 'location_name': locationName});
    } else {
      // Update existing record
      await db.update(
        'location_settings', 
        {'location_name': locationName},
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }
  
  Future<String> getLocationName() async {
    Database db = await database;
    List<Map<String, dynamic>> records = await db.query('location_settings');
    
    if (records.isEmpty) {
      return '';
    }
    
    return records.first['location_name'] ?? '';
  }
  
  // Methods for Quran last read position
  Future<void> saveLastReadPosition(int surahNumber, int ayahNumber) async {
    Database db = await database;
    
    // Check if a record already exists
    List<Map<String, dynamic>> existingRecords = await db.query('quran_last_read');
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    if (existingRecords.isEmpty) {
      // Insert new record
      await db.insert('quran_last_read', {
        'id': 1, 
        'surah_number': surahNumber, 
        'ayah_number': ayahNumber,
        'timestamp': timestamp
      });
    } else {
      // Update existing record
      await db.update(
        'quran_last_read', 
        {
          'surah_number': surahNumber, 
          'ayah_number': ayahNumber,
          'timestamp': timestamp
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    }
  }
  
  Future<Map<String, dynamic>?> getLastReadPosition() async {
    Database db = await database;
    List<Map<String, dynamic>> records = await db.query('quran_last_read');
    
    if (records.isEmpty) {
      return null;
    }
    
    return records.first;
  }
} 