import 'dart:async';

import 'package:datum/datum.dart' hide IsolateStrategy;
import 'package:example/sync/isolate_stratergy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatumSyncOperation extends Mock
    implements DatumSyncOperation<DatumEntity> {}

class MockDatumEntity extends Mock implements DatumEntity {}

void main() {
  group(
    'IsolateStrategy on I/O (VM)',
    () {
      test(
          'when forceIsolateInTest is true, uses IO runner which supports callbacks',
          () async {
        // ARRANGE
        // On I/O platforms, the isolate runner uses Isolate.spawn and can
        // communicate back to the main isolate to execute callbacks.
        // We expect processOperation and onProgress to be called.

        const wrappedStrategy = SequentialStrategy();
        const isolateStrategy = IsolateStrategy(
          wrappedStrategy,
          forceIsolateInTest: true,
        );

        final operations = [MockDatumSyncOperation()];
        when(() => operations.first.id).thenReturn('1');

        final processOperationCompleter = Completer<void>();
        Future<void> processOperation(
            DatumSyncOperation<DatumEntity> op) async {
          if (!processOperationCompleter.isCompleted) {
            processOperationCompleter.complete();
          }
        }

        final onProgressCompleter = Completer<void>();
        void onProgress(int completed, int total) {
          if (!onProgressCompleter.isCompleted) {
            onProgressCompleter.complete();
          }
        }

        bool isCancelled() => false;

        // ACT
        // Execute the strategy. The I/O runner (`_isolate_runner_io.dart`)
        // will be used due to the conditional import and test platform.
        await isolateStrategy.execute<DatumEntity>(
          operations,
          processOperation,
          isCancelled,
          onProgress,
        );

        // Wait for the async callbacks to be invoked from the main isolate listener.
        await Future.wait([
          processOperationCompleter.future,
          onProgressCompleter.future,
        ]);

        // ASSERT
        // The completers will only complete if the callbacks were invoked.
      });
    },
  );
}
