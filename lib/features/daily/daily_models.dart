class DailyStatus {
  const DailyStatus({
    required this.sleepLogged,
    required this.bodyStateLogged,
  });

  final bool sleepLogged;
  final bool bodyStateLogged;
}

class SleepEntryDraft {
  const SleepEntryDraft({
    required this.forDate,
    required this.sleepDurationMinutes,
    required this.sleepQuality,
    required this.notes,
  });

  final DateTime forDate;
  final int sleepDurationMinutes;
  final int? sleepQuality;
  final String? notes;
}

class BodyStateDraft {
  const BodyStateDraft({
    required this.forDate,
    required this.stressAverage,
    required this.anxietySpike,
    required this.exerciseType,
    required this.exerciseTimeOfDay,
    required this.exerciseIntensity,
    required this.exerciseDurationMinutes,
    required this.heavyLifting,
    required this.coreStrain,
    required this.illness,
    required this.bristolStoolType,
    required this.travelDay,
    required this.timeZoneChange,
    required this.altitudeChange,
    required this.notes,
  });

  final DateTime forDate;
  final int? stressAverage;
  final bool anxietySpike;
  final String? exerciseType;
  final String? exerciseTimeOfDay;
  final String? exerciseIntensity;
  final int? exerciseDurationMinutes;
  final bool heavyLifting;
  final bool coreStrain;
  final bool illness;
  final int? bristolStoolType;
  final bool travelDay;
  final bool timeZoneChange;
  final bool altitudeChange;
  final String? notes;
}
