import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'daily_models.dart';
import 'daily_repository.dart';

class BodyStateScreen extends StatefulWidget {
  const BodyStateScreen({
    required this.dailyRepository,
    super.key,
  });

  static const routeName = '/body-state';

  final DailyRepository dailyRepository;

  @override
  State<BodyStateScreen> createState() => _BodyStateScreenState();
}

class _BodyStateScreenState extends State<BodyStateScreen> {
  final TextEditingController _exerciseTypeController = TextEditingController();
  final TextEditingController _exerciseDurationController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _forDate = DateTime.now();
  int _stress = 5;
  bool _anxietySpike = false;
  String? _exerciseTimeOfDay;
  String? _exerciseIntensity;
  bool _heavyLifting = false;
  bool _coreStrain = false;
  bool _illness = false;
  int? _bristolType;
  bool _travelDay = false;
  bool _timeZoneChange = false;
  bool _altitudeChange = false;
  bool _saving = false;

  @override
  void dispose() {
    _exerciseTypeController.dispose();
    _exerciseDurationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _forDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _forDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.dailyRepository.saveBodyState(
      BodyStateDraft(
        forDate: _forDate,
        stressAverage: _stress,
        anxietySpike: _anxietySpike,
        exerciseType: _exerciseTypeController.text,
        exerciseTimeOfDay: _exerciseTimeOfDay,
        exerciseIntensity: _exerciseIntensity,
        exerciseDurationMinutes: int.tryParse(_exerciseDurationController.text),
        heavyLifting: _heavyLifting,
        coreStrain: _coreStrain,
        illness: _illness,
        bristolStoolType: _bristolType,
        travelDay: _travelDay,
        timeZoneChange: _timeZoneChange,
        altitudeChange: _altitudeChange,
        notes: _notesController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Body state saved')),
    );
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(_forDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Body State')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(dateLabel),
          ),
          const SizedBox(height: 16),
          Text('Average stress: $_stress/10'),
          Slider(
            value: _stress.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _stress.toString(),
            onChanged: (value) => setState(() => _stress = value.round()),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Anxiety spike'),
            value: _anxietySpike,
            onChanged: (value) => setState(() => _anxietySpike = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _exerciseTypeController,
            decoration: const InputDecoration(
              labelText: 'Exercise type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OptionDropdown(
            label: 'Exercise time',
            value: _exerciseTimeOfDay,
            values: const [
              'early_morning',
              'morning',
              'afternoon',
              'evening',
            ],
            onChanged: (value) => setState(() => _exerciseTimeOfDay = value),
          ),
          OptionDropdown(
            label: 'Exercise intensity',
            value: _exerciseIntensity,
            values: const ['light', 'moderate', 'hard'],
            onChanged: (value) => setState(() => _exerciseIntensity = value),
          ),
          TextField(
            controller: _exerciseDurationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Exercise duration minutes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Heavy lifting'),
            value: _heavyLifting,
            onChanged: (value) => setState(() => _heavyLifting = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Core strain'),
            value: _coreStrain,
            onChanged: (value) => setState(() => _coreStrain = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Illness'),
            value: _illness,
            onChanged: (value) => setState(() => _illness = value),
          ),
          OptionDropdown(
            label: 'Bristol stool type',
            value: _bristolType?.toString(),
            values: const ['1', '2', '3', '4', '5', '6', '7'],
            onChanged: (value) {
              setState(() => _bristolType = int.tryParse(value ?? ''));
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Travel day'),
            value: _travelDay,
            onChanged: (value) => setState(() => _travelDay = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Time zone change'),
            value: _timeZoneChange,
            onChanged: (value) => setState(() => _timeZoneChange = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Altitude change'),
            value: _altitudeChange,
            onChanged: (value) => setState(() => _altitudeChange = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save Body State'),
          ),
        ],
      ),
    );
  }
}

class OptionDropdown extends StatelessWidget {
  const OptionDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
