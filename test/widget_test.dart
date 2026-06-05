import 'package:acidtrack/data/local/app_database.dart';
import 'package:acidtrack/features/daily/daily_models.dart';
import 'package:acidtrack/features/daily/daily_repository.dart';
import 'package:acidtrack/features/flares/flare_episode.dart';
import 'package:acidtrack/features/flares/flare_repository.dart';
import 'package:acidtrack/features/intake/intake_models.dart';
import 'package:acidtrack/features/intake/intake_repository.dart';
import 'package:acidtrack/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts a flare from the home screen', (tester) async {
    final flareRepository = FakeFlareRepository();

    await tester.pumpWidget(
      AcidTrackApp(
        flareRepository: flareRepository,
        dailyRepository: FakeDailyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AcidTrack'), findsOneWidget);
    expect(find.text('Start Flare'), findsOneWidget);

    await tester.tap(find.text('Start Flare'));
    await tester.pumpAndSettle();

    expect(find.text('Start flare'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();

    expect(await flareRepository.activeFlare(), isNotNull);
    expect(find.textContaining('Active flare since'), findsOneWidget);
    expect(find.text('Severity 5/10'), findsOneWidget);
  });

  testWidgets('opens the intake entry flow', (tester) async {
    await tester.pumpWidget(
      AcidTrackApp(
        flareRepository: FakeFlareRepository(),
        intakeRepository: FakeIntakeRepository(),
        dailyRepository: FakeDailyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Intake Entry'));
    await tester.pumpAndSettle();

    expect(find.text('New Intake'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Liquid'), findsOneWidget);
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Tomato'), findsOneWidget);
  });

  testWidgets('opens daily context flows', (tester) async {
    await tester.pumpWidget(
      AcidTrackApp(
        flareRepository: FakeFlareRepository(),
        intakeRepository: FakeIntakeRepository(),
        dailyRepository: FakeDailyRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sleep open'), findsOneWidget);
    expect(find.text('Body state open'), findsOneWidget);

    await tester.tap(find.text('Log Sleep'));
    await tester.pumpAndSettle();

    expect(find.text('Log Sleep'), findsOneWidget);
    expect(find.text('Sleep quality: 3/5'), findsOneWidget);

    Navigator.of(tester.element(find.text('Log Sleep'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daily Body State'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Body State'), findsOneWidget);
    expect(find.text('Average stress: 5/10'), findsOneWidget);
  });
}

class FakeFlareRepository extends FlareRepository {
  FakeFlareRepository() : super(AppDatabase(databasePath: ':memory:'));

  FlareEpisode? _activeFlare;
  final List<FlareEpisode> _flares = <FlareEpisode>[];

  @override
  Future<FlareEpisode?> activeFlare() async => _activeFlare;

  @override
  Future<FlareEpisode> startFlare({
    required int currentSeverity,
    bool wokeFromSleep = false,
    String? notes,
  }) async {
    final flare = FlareEpisode(
      id: 'flare_1',
      startTime: DateTime(2026, 6, 4, 9),
      currentSeverity: currentSeverity,
      wokeFromSleep: wokeFromSleep,
      notes: notes,
      symptoms: const [],
    );
    _activeFlare = flare;
    _flares.add(flare);
    return flare;
  }

  @override
  Future<void> updateSeverity(String flareId, int severity) async {
    final active = _activeFlare;
    if (active == null) {
      return;
    }
    _activeFlare = FlareEpisode(
      id: active.id,
      startTime: active.startTime,
      currentSeverity: severity,
      wokeFromSleep: active.wokeFromSleep,
      notes: active.notes,
      symptoms: active.symptoms,
    );
  }

  @override
  Future<void> endFlare({
    required String flareId,
    required int peakSeverity,
    required List<String> symptomIds,
    String? notes,
  }) async {
    _activeFlare = null;
  }

  @override
  Future<List<FlareEpisode>> recentFlares({int limit = 50}) async => _flares;

  @override
  Future<List<SymptomOption>> symptomOptions() async => const [
        SymptomOption(id: 'symptom_1', name: 'Heartburn/burning'),
      ];
}

class FakeIntakeRepository extends IntakeRepository {
  FakeIntakeRepository() : super(AppDatabase(databasePath: ':memory:'));

  @override
  Future<List<TagOption>> tagsForType(String tagType) async {
    if (tagType == 'liquid') {
      return const [
        TagOption(id: 'tag_liquid_water', name: 'Water', category: 'water'),
        TagOption(id: 'tag_liquid_coffee', name: 'Coffee', category: 'coffee'),
      ];
    }

    return const [
      TagOption(id: 'tag_food_tomato', name: 'Tomato', category: 'acidic'),
      TagOption(id: 'tag_food_fried', name: 'Fried food', category: 'fried'),
    ];
  }

  @override
  Future<List<MedicineClassOption>> medicineClasses() async => const [
        MedicineClassOption(id: 'med_class_ppi', name: 'PPI'),
        MedicineClassOption(id: 'med_class_antacid', name: 'Antacid'),
      ];

  @override
  Future<List<MedicationOption>> medicationsForClass(String classId) async =>
      const [
        MedicationOption(
          id: 'med_omeprazole',
          classId: 'med_class_ppi',
          name: 'Omeprazole',
        ),
      ];

  @override
  Future<void> createFoodIntake(FoodIntakeDraft draft) async {}

  @override
  Future<void> createLiquidIntake(LiquidIntakeDraft draft) async {}

  @override
  Future<void> createMedicineIntake(MedicineIntakeDraft draft) async {}
}

class FakeDailyRepository extends DailyRepository {
  FakeDailyRepository() : super(AppDatabase(databasePath: ':memory:'));

  bool sleepLogged = false;
  bool bodyStateLogged = false;

  @override
  Future<DailyStatus> statusForToday() async => DailyStatus(
        sleepLogged: sleepLogged,
        bodyStateLogged: bodyStateLogged,
      );

  @override
  Future<void> saveSleepEntry(SleepEntryDraft draft) async {
    sleepLogged = true;
  }

  @override
  Future<void> saveBodyState(BodyStateDraft draft) async {
    bodyStateLogged = true;
  }
}
