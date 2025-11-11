import 'package:datum/datum.dart';
import 'package:datum/source/core/models/cold_start_strategy.dart';

import 'package:example/const/secrets.dart';
import 'package:example/custom_connectivity_checker.dart';
import 'package:example/custom_datum_logger.dart';
import 'package:example/data/task/adapters/hive_isolate_adapter.dart';
import 'package:example/data/task/entity/task.dart';
import 'package:example/data/user/adapters/supabase_adapter.dart';
import 'package:example/features/simple_datum/controller/simple_datum_provider.dart';
import 'package:example/my_datum_observer.dart';
import 'package:example/shared/riverpod_ext/riverpod_observer/riverpod_obs.dart';
import 'package:example/shared/riverpod_ext/riverpod_observer/talker_riverpod_settings.dart';
import 'package:example/sync/isolate_stratergy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:example/i18n/strings.g.dart';
import 'package:example/shared/pods/internet_checker_pod.dart';
import 'package:example/shared/pods/translation_pod.dart';
import 'package:platform_info/platform_info.dart';
import 'package:example/bootstrap.dart';
import 'package:example/core/local_storage/app_storage_pod.dart';
import 'package:example/features/splash/controller/box_encryption_key_pod.dart';
import 'package:example/init.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final futureInitializerPod = FutureProvider<ProviderContainer>((
  ref,
) async {
  ///Additional intial delay duration for app
  // await Future.delayed(const Duration(seconds: 1));
  await (init());
  await IsolatedHive.initFlutter();
  await Hive.initFlutter();

  await Supabase.initialize(
    url: Secrets.SUPABASE_URL,
    anonKey: Secrets.SUPABASE_ANON_KEY,
  );
  final encryptionCipher = await Platform.I.when(
    mobile: () async {
      final encryptionKey = await ref.watch(boxEncryptionKeyPod.future);
      return HiveAesCipher(encryptionKey);
    },
  );

  ///Load device translations
  ///
  AppLocale deviceLocale = AppLocaleUtils.findDeviceLocale();
  final translations = await deviceLocale.build();

  final appBox = await Hive.openBox(
    'DatumAppBox',
    encryptionCipher: encryptionCipher,
  );
  final config = DatumConfig(
    enableLogging: true,
    autoStartSync: true,
    initialUserId: Supabase.instance.client.auth.currentUser?.id,
    changeCacheDuration: Duration(milliseconds: 0),
    remoteEventDebounceTime: Duration(milliseconds: 0),
    autoSyncInterval: Duration(
      minutes: 30,
    ),
    syncRequestStrategy: SequentialRequestStrategy(),
    syncExecutionStrategy: IsolateStrategy(
      DatumSyncExecutionStrategy.parallel(),
    ),
    schemaVersion: 0,
    migrations: [],
    enablePerformanceLogging: true,
    logLevel: LogLevel.trace,
    onMigrationError: (error, stackTrace) async {
      talker.error(error, stackTrace);
    },
    // Configure cold start sync for the example app
    coldStartConfig: const ColdStartConfig(
      strategy: ColdStartStrategy.adaptive,
      syncThreshold:
          Duration(hours: 2), // Sync if more than 2 hours since last cold start
      maxDuration:
          Duration(seconds: 30), // Allow up to 30 seconds for cold start sync
      initialDelay:
          Duration(milliseconds: 500), // Wait 500ms after app start before sync
    ),
  );
  final datum = await Datum.initialize(
    config: config,
    connectivityChecker: CustomConnectivityChecker(),
    logger: CustomDatumLogger(enabled: config.enableLogging),
    observers: [
      MyDatumObserver(),
    ],
    registrations: [
      DatumRegistration<Task>(
        localAdapter: IsolatedHiveLocalAdapter<Task>(
          entityBoxName: "Task",
          fromMap: (map) => Task.fromMap(map),
          schemaVersion: 0,
        ),
        remoteAdapter: SupabaseRemoteAdapter<Task>(
          tableName: 'tasks',
          fromMap: Task.fromMap,
        ),
      ),
    ],
  );

  return ProviderContainer(
    overrides: [
      appBoxProvider.overrideWithValue(appBox),
      translationsPod.overrideWith((ref) => translations),
      enableInternetCheckerPod.overrideWithValue(false),
      simpleDatumProvider.overrideWith(
        (ref) => datum.fold(
          (l, s) => throw l,
          (r) => r,
        ),
      ),
    ],
    observers: [
      ///Added new talker riverpod observer
      ///
      /// If you want old behaviour
      /// Replace with
      ///
      ///  MyObserverLogger( talker: talker,)
      ///
      ///
      ///
      ///
      TalkerRiverpodObserver(
        talker: talker,
        settings: TalkerRiverpodLoggerSettings(
          printProviderDisposed: true,
          providerFilter: (provider) {
            if (provider.name == "countdownProvider") {
              return false;
            }
            return true;
          },
        ),
      ),
    ],
  );
});
