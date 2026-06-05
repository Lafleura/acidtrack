import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import 'flare_episode.dart';

class FlareRepository {
  FlareRepository(this._appDatabase);

  final AppDatabase _appDatabase;
  final Uuid _uuid = const Uuid();

  Future<FlareEpisode?> activeFlare() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'flare_episodes',
      where: 'user_id = ? AND end_time IS NULL AND deleted_at IS NULL',
      whereArgs: [localUserId],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _hydrateFlare(db, rows.first);
  }

  Future<List<FlareEpisode>> recentFlares({int limit = 50}) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'flare_episodes',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [localUserId],
      orderBy: 'start_time DESC',
      limit: limit,
    );

    final flares = <FlareEpisode>[];
    for (final row in rows) {
      flares.add(await _hydrateFlare(db, row));
    }
    return flares;
  }

  Future<FlareEpisode> startFlare({
    required int currentSeverity,
    bool wokeFromSleep = false,
    String? notes,
  }) async {
    final active = await activeFlare();
    if (active != null) {
      return active;
    }

    final db = await _appDatabase.database;
    final now = _utcNow();
    final id = _uuid.v4();
    await db.insert('flare_episodes', {
      'id': id,
      'user_id': localUserId,
      'start_time': now,
      'current_severity_1_10': currentSeverity,
      'woke_from_sleep': wokeFromSleep ? 1 : 0,
      'notes': _emptyToNull(notes),
      'source_device_id': localDeviceId,
      'created_at': now,
      'updated_at': now,
    });

    final flare = await activeFlare();
    return flare!;
  }

  Future<void> updateSeverity(String flareId, int severity) async {
    final db = await _appDatabase.database;
    await db.update(
      'flare_episodes',
      {
        'current_severity_1_10': severity,
        'updated_at': _utcNow(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [flareId],
    );
  }

  Future<void> endFlare({
    required String flareId,
    required int peakSeverity,
    required List<String> symptomIds,
    String? notes,
  }) async {
    final db = await _appDatabase.database;
    final now = _utcNow();

    await db.transaction((txn) async {
      await txn.update(
        'flare_episodes',
        {
          'end_time': now,
          'peak_severity_1_10': peakSeverity,
          'current_severity_1_10': peakSeverity,
          'notes': _emptyToNull(notes),
          'updated_at': now,
        },
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [flareId],
      );

      await txn.delete(
        'flare_episode_symptoms',
        where: 'flare_id = ?',
        whereArgs: [flareId],
      );

      for (final symptomId in symptomIds) {
        await txn.insert('flare_episode_symptoms', {
          'id': _uuid.v4(),
          'flare_id': flareId,
          'symptom_id': symptomId,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<List<SymptomOption>> symptomOptions() async {
    final db = await _appDatabase.database;
    final rows = await db.query('symptoms', orderBy: 'name ASC');
    return rows
        .map(
          (row) => SymptomOption(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  Future<FlareEpisode> _hydrateFlare(
    Database db,
    Map<String, Object?> row,
  ) async {
    final symptoms = await db.rawQuery(
      '''
      SELECT s.name
      FROM flare_episode_symptoms fes
      INNER JOIN symptoms s ON s.id = fes.symptom_id
      WHERE fes.flare_id = ? AND fes.deleted_at IS NULL
      ORDER BY s.name ASC
      ''',
      [row['id']],
    );

    return FlareEpisode.fromMap(
      row,
      symptoms: symptoms.map((item) => item['name'] as String).toList(),
    );
  }

  String _utcNow() => DateTime.now().toUtc().toIso8601String();

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}

class SymptomOption {
  const SymptomOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
