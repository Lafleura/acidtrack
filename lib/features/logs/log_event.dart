enum LogEventType {
  food,
  liquid,
  medicine,
  sleep,
  bodyState,
  flare,
}

class LogEvent {
  const LogEvent({
    required this.id,
    required this.type,
    required this.occurredAt,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  final String id;
  final LogEventType type;
  final DateTime occurredAt;
  final String title;
  final String subtitle;
  final List<String> details;
}
