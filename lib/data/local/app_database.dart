import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({this.databasePath});

  static final AppDatabase instance = AppDatabase();

  final String? databasePath;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final dbPath = databasePath ??
        path.join(await getDatabasesPath(), 'acidtrack_v1.sqlite');

    _database = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedData(db);
      },
    );

    return _database!;
  }

  Future<void> close() async {
    final existing = _database;
    if (existing != null) {
      await existing.close();
      _database = null;
    }
  }

  Future<void> _createSchema(Database db) async {
    final statements = <String>[
      '''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        display_name TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        platform TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE global_tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        tag_type TEXT NOT NULL CHECK (tag_type IN ('food', 'liquid')),
        category TEXT NULL,
        is_acidic INTEGER NOT NULL DEFAULT 0,
        is_high_fat INTEGER NOT NULL DEFAULT 0,
        is_spicy_typical INTEGER NOT NULL DEFAULT 0,
        contains_caffeine INTEGER NOT NULL DEFAULT 0,
        contains_alcohol INTEGER NOT NULL DEFAULT 0,
        is_carbonated INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE global_tag_aliases (
        id TEXT PRIMARY KEY,
        global_tag_id TEXT NOT NULL REFERENCES global_tags(id),
        alias TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE user_tags (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        name TEXT NOT NULL,
        tag_type TEXT NOT NULL CHECK (tag_type IN ('food', 'liquid')),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE (user_id, tag_type, name)
      )
      ''',
      '''
      CREATE TABLE tag_mappings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        user_tag_id TEXT NOT NULL REFERENCES user_tags(id),
        global_tag_id TEXT NOT NULL REFERENCES global_tags(id),
        confidence REAL NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE food_intakes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        occurred_at TEXT NOT NULL,
        preparation_method TEXT NULL,
        meal_size TEXT NULL,
        eating_speed TEXT NULL,
        source_type TEXT NULL,
        lay_down_within_2h TEXT NULL,
        notes TEXT NULL,
        source_device_id TEXT NOT NULL REFERENCES devices(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE food_intake_tags (
        id TEXT PRIMARY KEY,
        food_intake_id TEXT NOT NULL REFERENCES food_intakes(id),
        tag_scope TEXT NOT NULL CHECK (tag_scope IN ('global', 'user')),
        global_tag_id TEXT NULL REFERENCES global_tags(id),
        user_tag_id TEXT NULL REFERENCES user_tags(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        CHECK (
          (tag_scope = 'global' AND global_tag_id IS NOT NULL AND user_tag_id IS NULL)
          OR
          (tag_scope = 'user' AND user_tag_id IS NOT NULL AND global_tag_id IS NULL)
        )
      )
      ''',
      '''
      CREATE TABLE liquid_intakes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        occurred_at TEXT NOT NULL,
        ounces REAL NOT NULL,
        notes TEXT NULL,
        source_device_id TEXT NOT NULL REFERENCES devices(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE liquid_intake_tag (
        id TEXT PRIMARY KEY,
        liquid_intake_id TEXT NOT NULL UNIQUE REFERENCES liquid_intakes(id),
        tag_scope TEXT NOT NULL CHECK (tag_scope IN ('global', 'user')),
        global_tag_id TEXT NULL REFERENCES global_tags(id),
        user_tag_id TEXT NULL REFERENCES user_tags(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        CHECK (
          (tag_scope = 'global' AND global_tag_id IS NOT NULL AND user_tag_id IS NULL)
          OR
          (tag_scope = 'user' AND user_tag_id IS NOT NULL AND global_tag_id IS NULL)
        )
      )
      ''',
      '''
      CREATE TABLE medicine_classes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
      ''',
      '''
      CREATE TABLE medications (
        id TEXT PRIMARY KEY,
        class_id TEXT NOT NULL REFERENCES medicine_classes(id),
        name TEXT NOT NULL,
        is_global INTEGER NOT NULL DEFAULT 1,
        user_id TEXT NULL REFERENCES users(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE (class_id, name, user_id)
      )
      ''',
      '''
      CREATE TABLE medicine_intakes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        occurred_at TEXT NOT NULL,
        class_id TEXT NOT NULL REFERENCES medicine_classes(id),
        medication_id TEXT NULL REFERENCES medications(id),
        dose_value REAL NULL,
        dose_unit TEXT NULL,
        taken_as TEXT NOT NULL CHECK (taken_as IN ('daily', 'relief')),
        linked_flare_id TEXT NULL REFERENCES flare_episodes(id),
        notes TEXT NULL,
        source_device_id TEXT NOT NULL REFERENCES devices(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE sleep_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        for_date TEXT NOT NULL,
        sleep_duration_minutes INTEGER NOT NULL,
        sleep_quality_1_5 INTEGER NULL,
        wake_time TEXT NULL,
        notes TEXT NULL,
        source_device_id TEXT NOT NULL REFERENCES devices(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE (user_id, for_date)
      )
      ''',
      '''
      CREATE TABLE body_state_entries (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        for_date TEXT NOT NULL,
        stress_avg_1_10 INTEGER NULL,
        anxiety_spike INTEGER NOT NULL DEFAULT 0,
        exercise_type TEXT NULL,
        exercise_time_of_day TEXT NULL,
        exercise_intensity TEXT NULL,
        exercise_duration_minutes INTEGER NULL,
        heavy_lifting INTEGER NOT NULL DEFAULT 0,
        core_strain INTEGER NOT NULL DEFAULT 0,
        illness INTEGER NOT NULL DEFAULT 0,
        bristol_stool_type_1_7 INTEGER NULL,
        travel_day INTEGER NOT NULL DEFAULT 0,
        time_zone_change INTEGER NOT NULL DEFAULT 0,
        altitude_change INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        source_device_id TEXT NOT NULL REFERENCES devices(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE (user_id, for_date)
      )
      ''',
      '''
      CREATE TABLE flare_episodes (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id),
        start_time TEXT NOT NULL,
        end_time TEXT NULL,
        peak_severity_1_10 INTEGER NULL,
        current_severity_1_10 INTEGER NULL,
        woke_from_sleep INTEGER NOT NULL DEFAULT 0,
        notes TEXT NULL,
        source_device_id TEXT NOT NULL REFERENCES devices(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL
      )
      ''',
      '''
      CREATE TABLE symptoms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
      ''',
      '''
      CREATE TABLE flare_episode_symptoms (
        id TEXT PRIMARY KEY,
        flare_id TEXT NOT NULL REFERENCES flare_episodes(id),
        symptom_id TEXT NOT NULL REFERENCES symptoms(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE (flare_id, symptom_id)
      )
      ''',
      '''
      CREATE TABLE relief_actions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
      ''',
      '''
      CREATE TABLE flare_episode_relief_actions (
        id TEXT PRIMARY KEY,
        flare_id TEXT NOT NULL REFERENCES flare_episodes(id),
        relief_action_id TEXT NOT NULL REFERENCES relief_actions(id),
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        UNIQUE (flare_id, relief_action_id)
      )
      ''',
      'CREATE INDEX idx_food_user_time ON food_intakes(user_id, occurred_at)',
      'CREATE INDEX idx_liquid_user_time ON liquid_intakes(user_id, occurred_at)',
      'CREATE INDEX idx_medicine_user_time ON medicine_intakes(user_id, occurred_at)',
      'CREATE INDEX idx_flare_user_start ON flare_episodes(user_id, start_time)',
      'CREATE INDEX idx_sleep_user_date ON sleep_entries(user_id, for_date)',
      'CREATE INDEX idx_body_state_user_date ON body_state_entries(user_id, for_date)',
    ];

    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _seedData(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await db.insert('users', {
      'id': localUserId,
      'display_name': 'Local user',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('devices', {
      'id': localDeviceId,
      'user_id': localUserId,
      'platform': 'local',
      'created_at': now,
      'updated_at': now,
    });

    final globalTags = <Map<String, Object?>>[
      _globalTag('tag_food_tomato', 'Tomato', 'food', 'acidic', acidic: true),
      _globalTag('tag_food_citrus', 'Citrus', 'food', 'citrus', acidic: true),
      _globalTag('tag_food_fried', 'Fried food', 'food', 'fried',
          highFat: true),
      _globalTag('tag_food_spicy', 'Spicy food', 'food', 'spicy', spicy: true),
      _globalTag('tag_food_chocolate', 'Chocolate', 'food', 'sweets',
          highFat: true),
      _globalTag('tag_food_dairy', 'Dairy', 'food', 'dairy', highFat: true),
      _globalTag('tag_liquid_coffee', 'Coffee', 'liquid', 'coffee',
          caffeine: true),
      _globalTag('tag_liquid_decaf', 'Decaf coffee', 'liquid', 'coffee'),
      _globalTag('tag_liquid_soda', 'Soda', 'liquid', 'carbonated',
          caffeine: true, carbonated: true),
      _globalTag('tag_liquid_beer', 'Beer', 'liquid', 'alcohol',
          alcohol: true, carbonated: true),
      _globalTag('tag_liquid_water', 'Water', 'liquid', 'water'),
    ];

    for (final tag in globalTags) {
      await db.insert('global_tags', {
        ...tag,
        'created_at': now,
        'updated_at': now,
      });
    }

    final medicineClasses = <String, String>{
      'med_class_ppi': 'PPI',
      'med_class_h2': 'H2 blocker',
      'med_class_antacid': 'Antacid',
      'med_class_probiotic': 'Probiotic',
      'med_class_nsaid': 'NSAID',
      'med_class_creatine': 'Creatine',
      'med_class_magnesium': 'Magnesium',
    };
    for (final entry in medicineClasses.entries) {
      await db.insert('medicine_classes', {
        'id': entry.key,
        'name': entry.value,
      });
    }

    final medications = <Map<String, String>>[
      {
        'id': 'med_omeprazole',
        'class_id': 'med_class_ppi',
        'name': 'Omeprazole'
      },
      {
        'id': 'med_famotidine',
        'class_id': 'med_class_h2',
        'name': 'Famotidine'
      },
      {'id': 'med_tums', 'class_id': 'med_class_antacid', 'name': 'Tums'},
      {
        'id': 'med_gaviscon',
        'class_id': 'med_class_antacid',
        'name': 'Gaviscon'
      },
    ];
    for (final medication in medications) {
      await db.insert('medications', {
        ...medication,
        'is_global': 1,
        'created_at': now,
        'updated_at': now,
      });
    }

    final symptoms = <String>[
      'Heartburn/burning',
      'Regurgitation',
      'Chest pressure/tightness',
      'Throat irritation / globus',
      'Cough',
      'Hoarseness',
      'Nausea',
      'Bloating',
      'Burping',
      'Sour taste',
      'Arm / Shoulder discomfort',
      'Shortness of breath sensation',
    ];
    for (var i = 0; i < symptoms.length; i++) {
      await db.insert('symptoms', {
        'id': 'symptom_${i + 1}',
        'name': symptoms[i],
      });
    }

    final reliefActions = <String>[
      'Antacid',
      'H2 blocker',
      'Water',
      'Walk',
      'Sit upright',
      'Breathing',
    ];
    for (var i = 0; i < reliefActions.length; i++) {
      await db.insert('relief_actions', {
        'id': 'relief_${i + 1}',
        'name': reliefActions[i],
      });
    }
  }

  Map<String, Object?> _globalTag(
    String id,
    String name,
    String tagType,
    String category, {
    bool acidic = false,
    bool highFat = false,
    bool spicy = false,
    bool caffeine = false,
    bool alcohol = false,
    bool carbonated = false,
  }) {
    return {
      'id': id,
      'name': name,
      'tag_type': tagType,
      'category': category,
      'is_acidic': acidic ? 1 : 0,
      'is_high_fat': highFat ? 1 : 0,
      'is_spicy_typical': spicy ? 1 : 0,
      'contains_caffeine': caffeine ? 1 : 0,
      'contains_alcohol': alcohol ? 1 : 0,
      'is_carbonated': carbonated ? 1 : 0,
    };
  }
}

const localUserId = 'local_user';
const localDeviceId = 'local_device';
