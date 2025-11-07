import 'package:datum/datum.dart';
import 'package:example/data/task/entity/task.dart';
import 'package:example/features/simple_datum/controller/simple_datum_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

final nextSyncTimeProvider = StreamProvider.autoDispose<DateTime?>(
  (ref) {
    // This provider does not depend on the user, so it can be a simple provider.
    final taskManager = Datum.manager<Task>();
    return taskManager.onNextSyncTimeChanged;
  },
  name: 'nextSyncTimeProvider',
);

final countdownProvider = StreamProvider.autoDispose<Duration?>(
  (ref) {
    final nextSyncTimeAsync = ref.watch(nextSyncTimeProvider);

    return nextSyncTimeAsync.when(
      data: (nextSyncTime) {
        print(nextSyncTime);
        if (nextSyncTime == null) return Stream.value(null);

        return Stream.periodic(const Duration(seconds: 1), (_) {
          final now = DateTime.now();
          final remaining = nextSyncTime.difference(now);
          return remaining.isNegative ? Duration.zero : remaining;
        }).startWith(nextSyncTime.difference(DateTime.now()));
      },
      loading: () => Stream.value(null),
      error: (_, __) => Stream.value(null),
    );
  },
  name: 'countdownProvider',
);

final storageSizeProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, userId) {
    final taskManager = Datum.manager<Task>();
    return taskManager.watchStorageSize(userId: userId);
  },
  name: 'storageSizeProvider',
);

final allHealths = StreamProvider(
  (ref) async* {
    final datum = ref.watch(simpleDatumProvider);
    yield* datum.allHealths;
  },
  name: 'allHealths',
);

final metricsProvider = StreamProvider(
  (ref) async* {
    final datum = ref.watch(simpleDatumProvider);
    yield* datum.metrics;
  },
  name: 'metricsProvider',
);

final pendingOperationsProvider =
    StreamProvider.autoDispose.family<int, String>(
  (ref, userId) async* {
    final datum = ref.watch(simpleDatumProvider);
    yield* datum.statusForUser(userId).map((snapshot) {
      return snapshot?.pendingOperations ?? 0;
    });
  },
  name: 'pendingOperationsProvider',
);
