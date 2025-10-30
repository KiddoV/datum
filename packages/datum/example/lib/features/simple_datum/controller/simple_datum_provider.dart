import 'package:datum/datum.dart';
import 'package:datum_hive/datum_hive.dart';
import 'package:example/custom_connectivity_checker.dart';
import 'package:example/custom_datum_logger.dart';
import 'package:example/data/task/entity/task.dart';
import 'package:example/data/user/adapters/supabase_adapter.dart';

import 'package:example/my_datum_observer.dart';
import 'package:example/sync/isolate_stratergy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final simpleDatumProvider = FutureProvider.autoDispose<Datum>(
  (ref) async {
    final config = DatumConfig(
      enableLogging: true,
      autoStartSync: true,
      initialUserId: Supabase.instance.client.auth.currentUser?.id,
      changeCacheDuration: Duration(milliseconds: 300),
      autoSyncInterval: Duration(
        minutes: 10,
      ),
      syncRequestStrategy: SequentialRequestStrategy(),
      syncExecutionStrategy: IsolateStrategy(
        DatumSyncExecutionStrategy.parallel(),
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
          remoteAdapter: SupabaseRemoteAdapter(
            tableName: 'tasks',
            fromMap: Task.fromMap,
          ),
        ),
      ],
    );

    ref.onDispose(
      () async => await datum.dispose(),
    );
    return datum;
  },
  name: "simpleDatumProvider",
);
