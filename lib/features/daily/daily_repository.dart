import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import 'daily_models.dart';

class DailyRepository {
  DailyRepository(this._appDatabase);

  final AppDatabase _appDatabase;
  final Uuid _uuid = const Uuid();

  Future<DailyStatus> statusForToday() async {
    final today = _dateKey(DateTime.now());
    final db = await _appDatabase.database;

    final sleepRows = await db.query(
      'sleep_entries',
      columns: ['id'],
      where: 'user_id = ? AND for_date = ? AND deleted_at IS NULL',
      whereArgs: [localUserId, today],
      limit: 1,
    );
    final bodyRows = await db.query(
      'body_state_entries',
      columns: ['id'],
      where: 'user_id = ? AND for_date = ? AND deleted_at IS NULL',
      whereArgs: [localUserId, today],
      limit: 1,
    );

    return DailyStatus(
      sleepLogged: sleepRows.isNotEmpty,
      bodyStateLogged: bodyRows.isNotEmpty,
    );
  }

  Future<void> saveSleepEntry(SleepEntryDraft draft) async {
    final db = await _appDatabase.database;
    final now = _utcNow();
    final forDate = _dateKey(draft.forDate);

    await db.insert(
      'sleep_entries',
      {
        'id': _uuid.v4(),
        'user_id': localUserId,
        'for_date': forDate,
        'sleep_duration_minutes': draft.sleepDurationMinutes,
        'sleep_quality_1_5': draft.sleepQuality,
        'wake_time': null,
        'notes': _emptyToNull(draft.notes),
        'source_device_id': localDeviceId,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveBodyState(BodyStateDraft draft) async {
    final db = await _appDatabase.database;
    final now = _utcNow();
    final forDate = _dateKey(draft.forDate);

    await db.insert(
      'body_state_entries',
      {
        'id': _uuid.v4(),
        'user_id': localUserId,
        'for_date': forDate,
        'stress_avg_1_10': draft.stressAverage,
        'anxiety_spike': draft.anxietySpike ? 1 : 0,
        'exercise_type': _emptyToNull(draft.exerciseType),
        'exercise_time_of_day': draft.exerciseTimeOfDay,
        'exercise_intensity': draft.exerciseIntensity,
        'exercise_duration_minutes': draft.exerciseDurationMinutes,
        'heavy_lifting': draft.heavyLifting ? 1 : 0,
        'core_strain': draft.coreStrain ? 1 : 0,
        'illness': draft.illness ? 1 : 0,
        'bristol_stool_type_1_7': draft.bristolStoolType,
        'travel_day': draft.travelDay ? 1 : 0,
        'time_zone_change': draft.timeZoneChange ? 1 : 0,
        'altitude_change': draft.altitudeChange ? 1 : 0,
        'notes': _emptyToNull(draft.notes),
        'source_device_id': localDeviceId,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  String _utcNow() => DateTime.now().toUtc().toIso8601String();

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
