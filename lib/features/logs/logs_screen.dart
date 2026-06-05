import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'log_event.dart';
import 'log_repository.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({
    required this.logRepository,
    super.key,
  });

  static const routeName = '/logs';

  final LogRepository logRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: FutureBuilder<List<LogEvent>>(
        future: logRepository.recentEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? const <LogEvent>[];
          if (events.isEmpty) {
            return const Center(
              child: Text('No events logged yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => LogEventTile(
              event: events[index],
            ),
          );
        },
      ),
    );
  }
}

class LogEventTile extends StatelessWidget {
  const LogEventTile({
    required this.event,
    super.key,
  });

  final LogEvent event;

  @override
  Widget build(BuildContext context) {
    final timestamp = DateFormat.yMMMd().add_jm().format(event.occurredAt);

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(_iconForType(event.type)),
        title: Text(event.title),
        subtitle: Text('${event.subtitle} - $timestamp'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time: $timestamp'),
          for (final detail in event.details) ...[
            const SizedBox(height: 4),
            Text(detail),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(LogEventType type) {
    return switch (type) {
      LogEventType.food => Icons.restaurant,
      LogEventType.liquid => Icons.local_drink,
      LogEventType.medicine => Icons.medication,
      LogEventType.flare => Icons.local_fire_department,
    };
  }
}
