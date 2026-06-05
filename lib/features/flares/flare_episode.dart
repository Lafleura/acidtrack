class FlareEpisode {
  const FlareEpisode({
    required this.id,
    required this.startTime,
    required this.currentSeverity,
    required this.symptoms,
    this.endTime,
    this.peakSeverity,
    this.wokeFromSleep = false,
    this.notes,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int? peakSeverity;
  final int? currentSeverity;
  final bool wokeFromSleep;
  final String? notes;
  final List<String> symptoms;

  bool get isActive => endTime == null;

  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  factory FlareEpisode.fromMap(
    Map<String, Object?> map, {
    List<String> symptoms = const [],
  }) {
    return FlareEpisode(
      id: map['id'] as String,
      startTime: DateTime.parse(map['start_time'] as String).toLocal(),
      endTime: map['end_time'] == null
          ? null
          : DateTime.parse(map['end_time'] as String).toLocal(),
      peakSeverity: map['peak_severity_1_10'] as int?,
      currentSeverity: map['current_severity_1_10'] as int?,
      wokeFromSleep: (map['woke_from_sleep'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      symptoms: symptoms,
    );
  }
}
