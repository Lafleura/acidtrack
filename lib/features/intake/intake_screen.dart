import 'package:flutter/material.dart';

import 'intake_models.dart';
import 'intake_repository.dart';

class IntakeScreen extends StatelessWidget {
  const IntakeScreen({
    required this.intakeRepository,
    super.key,
  });

  static const routeName = '/intake';

  final IntakeRepository intakeRepository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Intake'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: 'Food'),
              Tab(icon: Icon(Icons.local_drink), text: 'Liquid'),
              Tab(icon: Icon(Icons.medication), text: 'Medicine'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FoodIntakeForm(intakeRepository: intakeRepository),
            LiquidIntakeForm(intakeRepository: intakeRepository),
            MedicineIntakeForm(intakeRepository: intakeRepository),
          ],
        ),
      ),
    );
  }
}

class FoodIntakeForm extends StatefulWidget {
  const FoodIntakeForm({
    required this.intakeRepository,
    super.key,
  });

  final IntakeRepository intakeRepository;

  @override
  State<FoodIntakeForm> createState() => _FoodIntakeFormState();
}

class _FoodIntakeFormState extends State<FoodIntakeForm> {
  final Set<String> _selectedTagIds = <String>{};
  final TextEditingController _notesController = TextEditingController();
  String? _preparationMethod;
  String? _mealSize;
  String? _eatingSpeed;
  String? _sourceType;
  String _layDownWithin2h = 'unknown';
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedTagIds.isEmpty) {
      _showMessage('Select at least one food tag.');
      return;
    }

    setState(() => _saving = true);
    await widget.intakeRepository.createFoodIntake(
      FoodIntakeDraft(
        globalTagIds: _selectedTagIds.toList(),
        preparationMethod: _preparationMethod,
        mealSize: _mealSize,
        eatingSpeed: _eatingSpeed,
        sourceType: _sourceType,
        layDownWithin2h: _layDownWithin2h,
        notes: _notesController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    _showSavedSheet('Food entry saved');
    setState(() => _saving = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSavedSheet(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TagOption>>(
      future: widget.intakeRepository.tagsForType('food'),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <TagOption>[];
        return IntakeFormScaffold(
          saving: _saving,
          onSave: _save,
          children: [
            SectionLabel('Food tags', action: '${_selectedTagIds.length}'),
            TagChipGrid(
              tags: tags,
              selectedIds: _selectedTagIds,
              onChanged: (tagId, selected) {
                setState(() {
                  if (selected) {
                    _selectedTagIds.add(tagId);
                  } else {
                    _selectedTagIds.remove(tagId);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            OptionDropdown(
              label: 'Preparation',
              value: _preparationMethod,
              values: const ['fried', 'baked', 'raw', 'grilled', 'steamed'],
              onChanged: (value) => setState(() => _preparationMethod = value),
            ),
            OptionDropdown(
              label: 'Meal size',
              value: _mealSize,
              values: const ['small', 'medium', 'large'],
              onChanged: (value) => setState(() => _mealSize = value),
            ),
            OptionDropdown(
              label: 'Eating speed',
              value: _eatingSpeed,
              values: const ['slow', 'normal', 'fast'],
              onChanged: (value) => setState(() => _eatingSpeed = value),
            ),
            OptionDropdown(
              label: 'Source',
              value: _sourceType,
              values: const ['home', 'restaurant'],
              onChanged: (value) => setState(() => _sourceType = value),
            ),
            SectionLabel('Lay down within 2h'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'no', label: Text('No')),
                ButtonSegment(value: 'yes', label: Text('Yes')),
                ButtonSegment(value: 'unknown', label: Text('Unknown')),
              ],
              selected: {_layDownWithin2h},
              onSelectionChanged: (selected) {
                setState(() => _layDownWithin2h = selected.first);
              },
            ),
            const SizedBox(height: 16),
            NotesField(controller: _notesController),
          ],
        );
      },
    );
  }
}

class LiquidIntakeForm extends StatefulWidget {
  const LiquidIntakeForm({
    required this.intakeRepository,
    super.key,
  });

  final IntakeRepository intakeRepository;

  @override
  State<LiquidIntakeForm> createState() => _LiquidIntakeFormState();
}

class _LiquidIntakeFormState extends State<LiquidIntakeForm> {
  final TextEditingController _ouncesController =
      TextEditingController(text: '8');
  final TextEditingController _notesController = TextEditingController();
  String? _selectedTagId;
  bool _saving = false;

  @override
  void dispose() {
    _ouncesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tagId = _selectedTagId;
    final ounces = double.tryParse(_ouncesController.text);
    if (tagId == null) {
      _showMessage('Choose a liquid type.');
      return;
    }
    if (ounces == null || ounces <= 0) {
      _showMessage('Enter a valid ounce amount.');
      return;
    }

    setState(() => _saving = true);
    await widget.intakeRepository.createLiquidIntake(
      LiquidIntakeDraft(
        globalTagId: tagId,
        ounces: ounces,
        notes: _notesController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    _showMessage('Liquid entry saved');
    setState(() => _saving = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TagOption>>(
      future: widget.intakeRepository.tagsForType('liquid'),
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <TagOption>[];
        _selectedTagId ??= tags.isEmpty ? null : tags.first.id;

        return IntakeFormScaffold(
          saving: _saving,
          onSave: _save,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Liquid type',
                border: OutlineInputBorder(),
              ),
              value: _selectedTagId,
              items: tags
                  .map(
                    (tag) => DropdownMenuItem(
                      value: tag.id,
                      child: Text(tag.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedTagId = value),
            ),
            const SizedBox(height: 16),
            SectionLabel('Ounces'),
            Wrap(
              spacing: 8,
              children: [4, 8, 12, 16]
                  .map(
                    (ounces) => ActionChip(
                      label: Text('$ounces oz'),
                      onPressed: () {
                        _ouncesController.text = ounces.toString();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ouncesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ounces',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            NotesField(controller: _notesController),
          ],
        );
      },
    );
  }
}

class MedicineIntakeForm extends StatefulWidget {
  const MedicineIntakeForm({
    required this.intakeRepository,
    super.key,
  });

  final IntakeRepository intakeRepository;

  @override
  State<MedicineIntakeForm> createState() => _MedicineIntakeFormState();
}

class _MedicineIntakeFormState extends State<MedicineIntakeForm> {
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _unitController =
      TextEditingController(text: 'mg');
  final TextEditingController _notesController = TextEditingController();
  String? _classId;
  String? _medicationId;
  String _takenAs = 'daily';
  bool _saving = false;

  @override
  void dispose() {
    _doseController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final classId = _classId;
    if (classId == null) {
      _showMessage('Choose a medicine class.');
      return;
    }

    setState(() => _saving = true);
    await widget.intakeRepository.createMedicineIntake(
      MedicineIntakeDraft(
        classId: classId,
        medicationId: _medicationId,
        doseValue: double.tryParse(_doseController.text),
        doseUnit: _unitController.text,
        takenAs: _takenAs,
        notes: _notesController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    _showMessage('Medicine entry saved');
    setState(() => _saving = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MedicineClassOption>>(
      future: widget.intakeRepository.medicineClasses(),
      builder: (context, classSnapshot) {
        final classes = classSnapshot.data ?? const <MedicineClassOption>[];
        _classId ??= classes.isEmpty ? null : classes.first.id;

        return FutureBuilder<List<MedicationOption>>(
          future: _classId == null
              ? Future.value(const <MedicationOption>[])
              : widget.intakeRepository.medicationsForClass(_classId!),
          builder: (context, medSnapshot) {
            final medications = medSnapshot.data ?? const <MedicationOption>[];
            if (_medicationId == null && medications.isNotEmpty) {
              _medicationId = medications.first.id;
            }

            return IntakeFormScaffold(
              saving: _saving,
              onSave: _save,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Medicine class',
                    border: OutlineInputBorder(),
                  ),
                  value: _classId,
                  items: classes
                      .map(
                        (medicineClass) => DropdownMenuItem(
                          value: medicineClass.id,
                          child: Text(medicineClass.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _classId = value;
                      _medicationId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Medication',
                    border: OutlineInputBorder(),
                  ),
                  value: _medicationId,
                  items: medications
                      .map(
                        (medication) => DropdownMenuItem(
                          value: medication.id,
                          child: Text(medication.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _medicationId = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _doseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dose',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        controller: _unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionLabel('Taken as'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'daily', label: Text('Daily')),
                    ButtonSegment(value: 'relief', label: Text('Relief')),
                  ],
                  selected: {_takenAs},
                  onSelectionChanged: (selected) {
                    setState(() => _takenAs = selected.first);
                  },
                ),
                const SizedBox(height: 16),
                NotesField(controller: _notesController),
              ],
            );
          },
        );
      },
    );
  }
}

class IntakeFormScaffold extends StatelessWidget {
  const IntakeFormScaffold({
    required this.children,
    required this.saving,
    required this.onSave,
    super.key,
  });

  final List<Widget> children;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...children,
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Save Entry'),
        ),
      ],
    );
  }
}

class TagChipGrid extends StatelessWidget {
  const TagChipGrid({
    required this.tags,
    required this.selectedIds,
    required this.onChanged,
    super.key,
  });

  final List<TagOption> tags;
  final Set<String> selectedIds;
  final void Function(String tagId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const Text('No tags available.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return FilterChip(
          selected: selectedIds.contains(tag.id),
          label: Text(tag.name),
          onSelected: (selected) => onChanged(tag.id, selected),
        );
      }).toList(),
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

class NotesField extends StatelessWidget {
  const NotesField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Notes',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.label, {
    this.action,
    super.key,
  });

  final String label;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (action != null) Chip(label: Text(action!)),
        ],
      ),
    );
  }
}
