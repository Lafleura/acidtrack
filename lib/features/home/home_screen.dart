import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../daily/body_state_screen.dart';
import '../daily/daily_models.dart';
import '../daily/daily_repository.dart';
import '../daily/sleep_screen.dart';
import '../flares/flare_episode.dart';
import '../flares/flare_repository.dart';
import '../intake/intake_repository.dart';
import '../intake/intake_screen.dart';
import '../logs/logs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.flareRepository,
    required this.intakeRepository,
    required this.dailyRepository,
    super.key,
  });

  final FlareRepository flareRepository;
  final IntakeRepository intakeRepository;
  final DailyRepository dailyRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<FlareEpisode?> _activeFlare;
  late Future<DailyStatus> _dailyStatus;

  @override
  void initState() {
    super.initState();
    _activeFlare = widget.flareRepository.activeFlare();
    _dailyStatus = widget.dailyRepository.statusForToday();
  }

  void _refresh() {
    setState(() {
      _activeFlare = widget.flareRepository.activeFlare();
      _dailyStatus = widget.dailyRepository.statusForToday();
    });
  }

  Future<void> _startFlare() async {
    final result = await showDialog<StartFlareResult>(
      context: context,
      builder: (_) => const StartFlareDialog(),
    );

    if (result == null) {
      return;
    }

    await widget.flareRepository.startFlare(
      currentSeverity: result.severity,
      wokeFromSleep: result.wokeFromSleep,
      notes: result.notes,
    );
    _refresh();
  }

  Future<void> _updateSeverity(FlareEpisode flare) async {
    final severity = await showDialog<int>(
      context: context,
      builder: (_) => SeverityDialog(
        title: 'Update severity',
        initialSeverity: flare.currentSeverity ?? flare.peakSeverity ?? 5,
      ),
    );

    if (severity == null) {
      return;
    }

    await widget.flareRepository.updateSeverity(flare.id, severity);
    _refresh();
  }

  Future<void> _endFlare(FlareEpisode flare) async {
    final symptoms = await widget.flareRepository.symptomOptions();
    if (!mounted) {
      return;
    }

    final result = await showDialog<EndFlareResult>(
      context: context,
      builder: (_) => EndFlareDialog(
        initialSeverity: flare.currentSeverity ?? 5,
        symptoms: symptoms,
      ),
    );

    if (result == null) {
      return;
    }

    await widget.flareRepository.endFlare(
      flareId: flare.id,
      peakSeverity: result.peakSeverity,
      symptomIds: result.symptomIds,
      notes: result.notes,
    );
    _refresh();
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is queued for the next sprint.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AcidTrack'),
        actions: [
          IconButton(
            tooltip: 'Logs',
            onPressed: () {
              Navigator.of(context).pushNamed(LogsScreen.routeName);
            },
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            tooltip: 'Analytics',
            onPressed: () => _showComingSoon('Analytics'),
            icon: const Icon(Icons.insights),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<FlareEpisode?>(
          future: _activeFlare,
          builder: (context, snapshot) {
            final activeFlare = snapshot.data;

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Structured tracking for doctor-legible flare patterns.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<DailyStatus>(
                    future: _dailyStatus,
                    builder: (context, statusSnapshot) {
                      final status = statusSnapshot.data;
                      return DailyStatusPanel(status: status);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (activeFlare != null) ...[
                    ActiveFlarePanel(
                      flare: activeFlare,
                      onUpdateSeverity: () => _updateSeverity(activeFlare),
                      onEndFlare: () => _endFlare(activeFlare),
                    ),
                    const SizedBox(height: 20),
                  ],
                  FilledButton.icon(
                    onPressed: activeFlare == null ? _startFlare : null,
                    icon: const Icon(Icons.local_fire_department),
                    label: const Text('Start Flare'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(IntakeScreen.routeName);
                    },
                    icon: const Icon(Icons.restaurant),
                    label: const Text('New Intake Entry'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context)
                          .pushNamed(SleepScreen.routeName);
                      _refresh();
                    },
                    icon: const Icon(Icons.bedtime),
                    label: const Text('Log Sleep'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context)
                          .pushNamed(BodyStateScreen.routeName);
                      _refresh();
                    },
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Daily Body State'),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(LogsScreen.routeName);
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Logs'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showComingSoon('Analytics'),
                          icon: const Icon(Icons.insights),
                          label: const Text('Analytics'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class DailyStatusPanel extends StatelessWidget {
  const DailyStatusPanel({
    required this.status,
    super.key,
  });

  final DailyStatus? status;

  @override
  Widget build(BuildContext context) {
    final sleepLogged = status?.sleepLogged ?? false;
    final bodyLogged = status?.bodyStateLogged ?? false;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        StatusChip(
          label: 'Sleep',
          logged: sleepLogged,
          icon: Icons.bedtime,
        ),
        StatusChip(
          label: 'Body state',
          logged: bodyLogged,
          icon: Icons.fact_check,
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.logged,
    required this.icon,
    super.key,
  });

  final String label;
  final bool logged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(
        icon,
        size: 18,
        color: logged
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      label: Text('$label ${logged ? 'logged' : 'open'}'),
      selected: logged,
    );
  }
}

class ActiveFlarePanel extends StatelessWidget {
  const ActiveFlarePanel({
    required this.flare,
    required this.onUpdateSeverity,
    required this.onEndFlare,
    super.key,
  });

  final FlareEpisode flare;
  final VoidCallback onUpdateSeverity;
  final VoidCallback onEndFlare;

  @override
  Widget build(BuildContext context) {
    final startedAt = DateFormat.jm().format(flare.startTime);
    final severity = flare.currentSeverity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.local_fire_department),
              Text(
                'Active flare since $startedAt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (severity != null) Chip(label: Text('Severity $severity/10')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpdateSeverity,
                  icon: const Icon(Icons.tune),
                  label: const Text('Update'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEndFlare,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('End'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StartFlareDialog extends StatefulWidget {
  const StartFlareDialog({super.key});

  @override
  State<StartFlareDialog> createState() => _StartFlareDialogState();
}

class _StartFlareDialogState extends State<StartFlareDialog> {
  int _severity = 5;
  bool _wokeFromSleep = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start flare'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeverityPicker(
            value: _severity,
            onChanged: (value) => setState(() => _severity = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Woke from sleep'),
            value: _wokeFromSleep,
            onChanged: (value) => setState(() => _wokeFromSleep = value),
          ),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              StartFlareResult(
                severity: _severity,
                wokeFromSleep: _wokeFromSleep,
                notes: _notesController.text,
              ),
            );
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class EndFlareDialog extends StatefulWidget {
  const EndFlareDialog({
    required this.initialSeverity,
    required this.symptoms,
    super.key,
  });

  final int initialSeverity;
  final List<SymptomOption> symptoms;

  @override
  State<EndFlareDialog> createState() => _EndFlareDialogState();
}

class _EndFlareDialogState extends State<EndFlareDialog> {
  late int _peakSeverity = widget.initialSeverity;
  final Set<String> _selectedSymptoms = <String>{};
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('End flare'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SeverityPicker(
              label: 'Peak severity',
              value: _peakSeverity,
              onChanged: (value) => setState(() => _peakSeverity = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Symptoms',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.symptoms.map((symptom) {
                final selected = _selectedSymptoms.contains(symptom.id);
                return FilterChip(
                  selected: selected,
                  label: Text(symptom.name),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedSymptoms.add(symptom.id);
                      } else {
                        _selectedSymptoms.remove(symptom.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              EndFlareResult(
                peakSeverity: _peakSeverity,
                symptomIds: _selectedSymptoms.toList(),
                notes: _notesController.text,
              ),
            );
          },
          child: const Text('End'),
        ),
      ],
    );
  }
}

class SeverityDialog extends StatefulWidget {
  const SeverityDialog({
    required this.title,
    required this.initialSeverity,
    super.key,
  });

  final String title;
  final int initialSeverity;

  @override
  State<SeverityDialog> createState() => _SeverityDialogState();
}

class _SeverityDialogState extends State<SeverityDialog> {
  late int _severity = widget.initialSeverity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SeverityPicker(
        value: _severity,
        onChanged: (value) => setState(() => _severity = value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_severity),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class SeverityPicker extends StatelessWidget {
  const SeverityPicker({
    required this.value,
    required this.onChanged,
    this.label = 'Current severity',
    super.key,
  });

  final int value;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value/10'),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: value.toString(),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}

class StartFlareResult {
  const StartFlareResult({
    required this.severity,
    required this.wokeFromSleep,
    required this.notes,
  });

  final int severity;
  final bool wokeFromSleep;
  final String notes;
}

class EndFlareResult {
  const EndFlareResult({
    required this.peakSeverity,
    required this.symptomIds,
    required this.notes,
  });

  final int peakSeverity;
  final List<String> symptomIds;
  final String notes;
}
