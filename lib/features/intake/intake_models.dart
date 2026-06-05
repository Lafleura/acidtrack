class TagOption {
  const TagOption({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final String? category;
}

class MedicineClassOption {
  const MedicineClassOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class MedicationOption {
  const MedicationOption({
    required this.id,
    required this.classId,
    required this.name,
  });

  final String id;
  final String classId;
  final String name;
}

class FoodIntakeDraft {
  const FoodIntakeDraft({
    required this.globalTagIds,
    required this.preparationMethod,
    required this.mealSize,
    required this.eatingSpeed,
    required this.sourceType,
    required this.layDownWithin2h,
    required this.notes,
  });

  final List<String> globalTagIds;
  final String? preparationMethod;
  final String? mealSize;
  final String? eatingSpeed;
  final String? sourceType;
  final String? layDownWithin2h;
  final String? notes;
}

class LiquidIntakeDraft {
  const LiquidIntakeDraft({
    required this.globalTagId,
    required this.ounces,
    required this.notes,
  });

  final String globalTagId;
  final double ounces;
  final String? notes;
}

class MedicineIntakeDraft {
  const MedicineIntakeDraft({
    required this.classId,
    required this.medicationId,
    required this.doseValue,
    required this.doseUnit,
    required this.takenAs,
    required this.notes,
  });

  final String classId;
  final String? medicationId;
  final double? doseValue;
  final String? doseUnit;
  final String takenAs;
  final String? notes;
}
