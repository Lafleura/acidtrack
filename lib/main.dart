import 'package:flutter/material.dart';

import 'data/local/app_database.dart';
import 'features/daily/body_state_screen.dart';
import 'features/daily/daily_repository.dart';
import 'features/daily/sleep_screen.dart';
import 'features/flares/flare_repository.dart';
import 'features/home/home_screen.dart';
import 'features/intake/intake_repository.dart';
import 'features/intake/intake_screen.dart';
import 'features/logs/log_repository.dart';
import 'features/logs/logs_screen.dart';

void main() {
  runApp(const AcidTrackApp());
}

class AcidTrackApp extends StatelessWidget {
  const AcidTrackApp({
    super.key,
    FlareRepository? flareRepository,
    IntakeRepository? intakeRepository,
    DailyRepository? dailyRepository,
    LogRepository? logRepository,
  })  : _flareRepository = flareRepository,
        _intakeRepository = intakeRepository,
        _dailyRepository = dailyRepository,
        _logRepository = logRepository;

  final FlareRepository? _flareRepository;
  final IntakeRepository? _intakeRepository;
  final DailyRepository? _dailyRepository;
  final LogRepository? _logRepository;

  @override
  Widget build(BuildContext context) {
    final appDatabase = AppDatabase.instance;
    final flareRepository = _flareRepository ?? FlareRepository(appDatabase);
    final intakeRepository = _intakeRepository ??
        IntakeRepository(
          appDatabase,
          flareRepository: flareRepository,
        );
    final dailyRepository = _dailyRepository ?? DailyRepository(appDatabase);
    final logRepository = _logRepository ??
        LogRepository(
          appDatabase,
          flareRepository: flareRepository,
        );

    return MaterialApp(
      title: 'AcidTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f7d6f),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f4ee),
        useMaterial3: true,
      ),
      home: HomeScreen(
        flareRepository: flareRepository,
        intakeRepository: intakeRepository,
        dailyRepository: dailyRepository,
      ),
      routes: {
        IntakeScreen.routeName: (_) => IntakeScreen(
              intakeRepository: intakeRepository,
            ),
        SleepScreen.routeName: (_) => SleepScreen(
              dailyRepository: dailyRepository,
            ),
        BodyStateScreen.routeName: (_) => BodyStateScreen(
              dailyRepository: dailyRepository,
            ),
        LogsScreen.routeName: (_) => LogsScreen(
              logRepository: logRepository,
            ),
      },
    );
  }
}
