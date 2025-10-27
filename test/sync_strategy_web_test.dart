@Tags(['browser'])
library;

import 'package:datum/datum.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockDatumSyncOperation extends Mock implements DatumSyncOperation<DatumEntity> {}

class MockDatumEntity extends Mock implements DatumEntity {}

/// dart test -p chrome test/sync_strategy_web_test.dart
/// to run this
void main() {
  const isSkipped = !(0 == 0.0);
  group(
    'IsolateStrategy on Web',
    () {
      test('when forceIsolateInTest is true, uses web runner which does not support callbacks', () async {
        // ARRANGE
        // On web, `compute` is used. It cannot serialize and send back the
        // `processOperation`, `isCancelled`, or `onProgress` closures.
        // We expect them NOT to be called.

        const wrappedStrategy = SequentialStrategy();
        const isolateStrategy = IsolateStrategy(
          wrappedStrategy,
          forceIsolateInTest: true,
        );

        final operations = [MockDatumSyncOperation()];
        when(() => operations.first.id).thenReturn('1');
        when(() => operations.first.data).thenReturn(MockDatumEntity());

        var processOperationCalled = false;
        Future<void> processOperation(DatumSyncOperation<DatumEntity> op) async {
          processOperationCalled = true;
        }

        var onProgressCalled = false;
        void onProgress(int completed, int total) {
          onProgressCalled = true;
        }

        bool isCancelled() => false;

        // ACT
        // Execute the strategy. The web runner (`_isolate_runner_web.dart`)
        // will be used due to the conditional import and test platform.
        await isolateStrategy.execute<DatumEntity>(
          operations,
          processOperation,
          isCancelled,
          onProgress,
        );

        // ASSERT
        // Verify that the callbacks were NOT invoked, confirming the web-specific
        // `compute`-based runner was used. The `wrappedStrategy` inside the
        // compute callback receives placeholder functions.
        expect(processOperationCalled, isFalse, reason: 'processOperation should not be called on web isolate runner');
        expect(onProgressCalled, isFalse, reason: 'onProgress should not be called on web isolate runner');
      });
    },
    testOn: 'browser',
    skip: isSkipped,
  );
}
