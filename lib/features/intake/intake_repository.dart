import 'package:uuid/uuid.dart';

import '../../data/local/app_database.dart';
import '../flares/flare_repository.dart';
import 'intake_models.dart';

class IntakeRepository {
  IntakeRepository(
    this._appDatabase, {
    FlareRepository? flareRepository,
  }) : _flareRepository = flareRepository ?? FlareRepository(_appDatabase);

  final AppDatabase _appDatabase;
  final FlareRepository _flareRepository;
  final Uuid _uuid = const Uuid();

  Future<List<TagOption>> tagsForType(String tagType) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'global_tags',
      where: 'tag_type = ? AND deleted_at IS NULL',
      whereArgs: [tagType],
      orderBy: 'name ASC',
    );

    return rows
        .map(
          (row) => TagOption(
            id: row['id'] as String,
            name: row['name'] as String,
            category: row['category'] as String?,
          ),
        )
        .toList();
  }

  Future<List<MedicineClassOption>> medicineClasses() async {
    final db = await _appDatabase.database;
    final rows = await db.query('medicine_classes', orderBy: 'name ASC');
    return rows
        .map(
          (row) => MedicineClassOption(
            id: row['id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  Future<List<MedicationOption>> medicationsForClass(String classId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'medications',
      where: 'class_id = ? AND deleted_at IS NULL',
      whereArgs: [classId],
      orderBy: 'name ASC',
    );
    return rows
        .map(
          (row) => MedicationOption(
            id: row['id'] as String,
            classId: row['class_id'] as String,
            name: row['name'] as String,
          ),
        )
        .toList();
  }

  Future<void> createFoodIntake(FoodIntakeDraft draft) async {
    final db = await _appDatabase.database;
    final now = _utcNow();
    final foodId = _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('food_intakes', {
        'id': foodId,
        'user_id': localUserId,
        'occurred_at': now,
        'preparation_method': draft.preparationMethod,
        'meal_size': draft.mealSize,
        'eating_speed': draft.eatingSpeed,
        'source_type': draft.sourceType,
        'lay_down_within_2h': draft.layDownWithin2h,
        'notes': _emptyToNull(draft.notes),
        'source_device_id': localDeviceId,
        'created_at': now,
        'updated_at': now,
      });

      for (final tagId in draft.globalTagIds) {
        await txn.insert('food_intake_tags', {
          'id': _uuid.v4(),
          'food_intake_id': foodId,
          'tag_scope': 'global',
          'global_tag_id': tagId,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }

  Future<void> createLiquidIntake(LiquidIntakeDraft draft) async {
    final db = await _appDatabase.database;
    final now = _utcNow();
    final liquidId = _uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('liquid_intakes', {
        'id': liquidId,
        'user_id': localUserId,
        'occurred_at': now,
        'ounces': draft.ounces,
        'notes': _emptyToNull(draft.notes),
        'source_device_id': localDeviceId,
        'created_at': now,
        'updated_at': now,
      });

      await txn.insert('liquid_intake_tag', {
        'id': _uuid.v4(),
        'liquid_intake_id': liquidId,
        'tag_scope': 'global',
        'global_tag_id': draft.globalTagId,
        'created_at': now,
        'updated_at': now,
      });
    });
  }

  Future<void> createMedicineIntake(MedicineIntakeDraft draft) async {
    final db = await _appDatabase.database;
    final now = _utcNow();
    final activeFlare = await _flareRepository.activeFlare();
    final linkedFlareId = draft.takenAs == 'relief' && activeFlare != null
        ? activeFlare.id
        : null;

    await db.insert('medicine_intakes', {
      'id': _uuid.v4(),
      'user_id': localUserId,
      'occurred_at': now,
      'class_id': draft.classId,
      'medication_id': draft.medicationId,
      'dose_value': draft.doseValue,
      'dose_unit': _emptyToNull(draft.doseUnit),
      'taken_as': draft.takenAs,
      'linked_flare_id': linkedFlareId,
      'notes': _emptyToNull(draft.notes),
      'source_device_id': localDeviceId,
      'created_at': now,
      'updated_at': now,
    });
  }

  String _utcNow() => DateTime.now().toUtc().toIso8601String();

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
