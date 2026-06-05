import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'daily_models.dart';
import 'daily_repository.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({
    required this.dailyRepository,
    super.key,
  });

  static const routeName = '/sleep';

  final DailyRepository dailyRepository;

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _forDate = DateTime.now();
  int _quality = 3;
  bool _saving = false;

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
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
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final totalMinutes = (hours * 60) + minutes;
    if (totalMinutes <= 0) {
      _showMessage('Enter sleep duration.');
      return;
    }

    setState(() => _saving = true);
    await widget.dailyRepository.saveSleepEntry(
      SleepEntryDraft(
        forDate: _forDate,
        sleepDurationMinutes: totalMinutes,
        sleepQuality: _quality,
        notes: _notesController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    _showMessage('Sleep entry saved');
    setState(() => _saving = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMd().format(_forDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Log Sleep')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(dateLabel),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hours',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Sleep quality: $_quality/5'),
          Slider(
            value: _quality.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _quality.toString(),
            onChanged: (value) => setState(() => _quality = value.round()),
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
            label: const Text('Save Sleep'),
          ),
        ],
      ),
    );
  }
}
