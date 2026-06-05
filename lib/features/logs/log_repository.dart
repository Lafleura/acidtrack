import 'package:intl/intl.dart';

import '../../data/local/app_database.dart';
import '../flares/flare_repository.dart';
import 'log_event.dart';

class LogRepository {
  LogRepository(
    this._appDatabase, {
    FlareRepository? flareRepository,
  }) : _flareRepository = flareRepository ?? FlareRepository(_appDatabase);

  final AppDatabase _appDatabase;
  final FlareRepository _flareRepository;

  Future<List<LogEvent>> recentEvents({int limit = 100}) async {
    final events = <LogEvent>[
      ...await _foodEvents(),
      ...await _liquidEvents(),
      ...await _medicineEvents(),
      ...await _sleepEvents(),
      ...await _bodyStateEvents(),
      ...await _flareEvents(),
    ];

    events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return events.take(limit).toList();
  }

  Future<List<LogEvent>> _foodEvents() async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        fi.id,
        fi.occurred_at,
        fi.preparation_method,
        fi.meal_size,
        fi.eating_speed,
        fi.source_type,
        fi.lay_down_within_2h,
        fi.notes,
        GROUP_CONCAT(gt.name, ', ') AS tags
      FROM food_intakes fi
      LEFT JOIN food_intake_tags fit ON fit.food_intake_id = fi.id
        AND fit.deleted_at IS NULL
      LEFT JOIN global_tags gt ON gt.id = fit.global_tag_id
      WHERE fi.user_id = ? AND fi.deleted_at IS NULL
      GROUP BY fi.id
      ORDER BY fi.occurred_at DESC
      ''',
      [localUserId],
    );

    return rows.map((row) {
      final tags = (row['tags'] as String?) ?? 'Food';
      final details = <String>[
        if (row['preparation_method'] != null)
          'Preparation: ${row['preparation_method']}',
        if (row['meal_size'] != null) 'Meal size: ${row['meal_size']}',
        if (row['eating_speed'] != null) 'Eating speed: ${row['eating_speed']}',
        if (row['source_type'] != null) 'Source: ${row['source_type']}',
        if (row['lay_down_within_2h'] != null)
          'Lay down within 2h: ${row['lay_down_within_2h']}',
        if (row['notes'] != null) row['notes'] as String,
      ];
      return LogEvent(
        id: row['id'] as String,
        type: LogEventType.food,
        occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
        title: tags,
        subtitle: 'Food intake',
        details: details,
      );
    }).toList();
  }

  Future<List<LogEvent>> _liquidEvents() async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        li.id,
        li.occurred_at,
        li.ounces,
        li.notes,
        gt.name AS tag_name
      FROM liquid_intakes li
      LEFT JOIN liquid_intake_tag lit ON lit.liquid_intake_id = li.id
        AND lit.deleted_at IS NULL
      LEFT JOIN global_tags gt ON gt.id = lit.global_tag_id
      WHERE li.user_id = ? AND li.deleted_at IS NULL
      ORDER BY li.occurred_at DESC
      ''',
      [localUserId],
    );

    return rows.map((row) {
      final ounces = row['ounces'] as num;
      final details = <String>[
        '${_formatNumber(ounces)} oz',
        if (row['notes'] != null) row['notes'] as String,
      ];
      return LogEvent(
        id: row['id'] as String,
        type: LogEventType.liquid,
        occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
        title: (row['tag_name'] as String?) ?? 'Liquid',
        subtitle: 'Liquid intake',
        details: details,
      );
    }).toList();
  }

  Future<List<LogEvent>> _medicineEvents() async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        mi.id,
        mi.occurred_at,
        mi.dose_value,
        mi.dose_unit,
        mi.taken_as,
        mi.linked_flare_id,
        mi.notes,
        mc.name AS class_name,
        m.name AS medication_name
      FROM medicine_intakes mi
      INNER JOIN medicine_classes mc ON mc.id = mi.class_id
      LEFT JOIN medications m ON m.id = mi.medication_id
      WHERE mi.user_id = ? AND mi.deleted_at IS NULL
      ORDER BY mi.occurred_at DESC
      ''',
      [localUserId],
    );

    return rows.map((row) {
      final dose = row['dose_value'] == null
          ? null
          : _formatNumber(row['dose_value'] as num);
      final unit = row['dose_unit'] as String?;
      final details = <String>[
        'Class: ${row['class_name']}',
        'Taken as: ${row['taken_as']}',
        if (dose != null) 'Dose: $dose${unit == null ? '' : ' $unit'}',
        if (row['linked_flare_id'] != null) 'Linked to active flare',
        if (row['notes'] != null) row['notes'] as String,
      ];
      return LogEvent(
        id: row['id'] as String,
        type: LogEventType.medicine,
        occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
        title:
            (row['medication_name'] as String?) ?? row['class_name'] as String,
        subtitle: 'Medicine intake',
        details: details,
      );
    }).toList();
  }

  Future<List<LogEvent>> _flareEvents() async {
    final flares = await _flareRepository.recentFlares();
    return flares.map((flare) {
      final severity = flare.peakSeverity ?? flare.currentSeverity;
      final details = <String>[
        'Started: ${DateFormat.yMMMd().add_jm().format(flare.startTime)}',
        if (flare.endTime == null)
          'Ended: Active'
        else
          'Ended: ${DateFormat.yMMMd().add_jm().format(flare.endTime!)}',
        if (severity != null) 'Severity: $severity/10',
        if (flare.wokeFromSleep) 'Woke from sleep',
        if (flare.symptoms.isNotEmpty) 'Symptoms: ${flare.symptoms.join(', ')}',
        if (flare.notes != null) flare.notes!,
      ];
      return LogEvent(
        id: flare.id,
        type: LogEventType.flare,
        occurredAt: flare.startTime,
        title: flare.isActive ? 'Active flare' : 'Flare episode',
        subtitle: severity == null ? 'Flare' : 'Severity $severity/10',
        details: details,
      );
    }).toList();
  }

  Future<List<LogEvent>> _sleepEvents() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'sleep_entries',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [localUserId],
      orderBy: 'for_date DESC',
    );

    return rows.map((row) {
      final minutes = row['sleep_duration_minutes'] as int;
      final quality = row['sleep_quality_1_5'] as int?;
      final details = <String>[
        'Duration: ${_formatMinutes(minutes)}',
        if (quality != null) 'Quality: $quality/5',
        if (row['notes'] != null) row['notes'] as String,
      ];
      return LogEvent(
        id: row['id'] as String,
        type: LogEventType.sleep,
        occurredAt: DateTime.parse(row['for_date'] as String).toLocal(),
        title: 'Sleep',
        subtitle: quality == null
            ? _formatMinutes(minutes)
            : '${_formatMinutes(minutes)} - quality $quality/5',
        details: details,
      );
    }).toList();
  }

  Future<List<LogEvent>> _bodyStateEvents() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'body_state_entries',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [localUserId],
      orderBy: 'for_date DESC',
    );

    return rows.map((row) {
      final stress = row['stress_avg_1_10'] as int?;
      final flags = <String>[
        if ((row['anxiety_spike'] as int? ?? 0) == 1) 'anxiety spike',
        if ((row['heavy_lifting'] as int? ?? 0) == 1) 'heavy lifting',
        if ((row['core_strain'] as int? ?? 0) == 1) 'core strain',
        if ((row['illness'] as int? ?? 0) == 1) 'illness',
        if ((row['travel_day'] as int? ?? 0) == 1) 'travel',
        if ((row['time_zone_change'] as int? ?? 0) == 1) 'time zone change',
        if ((row['altitude_change'] as int? ?? 0) == 1) 'altitude change',
      ];
      final details = <String>[
        if (stress != null) 'Stress: $stress/10',
        if (row['exercise_type'] != null) 'Exercise: ${row['exercise_type']}',
        if (row['exercise_time_of_day'] != null)
          'Exercise time: ${row['exercise_time_of_day']}',
        if (row['exercise_intensity'] != null)
          'Exercise intensity: ${row['exercise_intensity']}',
        if (row['exercise_duration_minutes'] != null)
          'Exercise duration: ${row['exercise_duration_minutes']}m',
        if (row['bristol_stool_type_1_7'] != null)
          'Bristol stool type: ${row['bristol_stool_type_1_7']}',
        if (flags.isNotEmpty) 'Flags: ${flags.join(', ')}',
        if (row['notes'] != null) row['notes'] as String,
      ];
      return LogEvent(
        id: row['id'] as String,
        type: LogEventType.bodyState,
        occurredAt: DateTime.parse(row['for_date'] as String).toLocal(),
        title: 'Daily body state',
        subtitle: stress == null ? 'Daily context' : 'Stress $stress/10',
        details: details,
      );
    }).toList();
  }

  String _formatNumber(num value) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toInt().toString();
    }
    return asDouble.toStringAsFixed(1);
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes.remainder(60);
    if (hours == 0) {
      return '${remainingMinutes}m';
    }
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }
}
