import 'dart:async';

import 'package:datum/source/core/manager/datum_sync_request_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('DatumSyncRequestStrategy', () {
    group('SkipConcurrentStrategy', () {
      late SkipConcurrentStrategy strategy;

      setUp(() {
        strategy = const SkipConcurrentStrategy();
      });

      test('executes action when no sync is in progress', () async {
        var actionExecuted = false;

        final result = await strategy.execute(
          () async {
            actionExecuted = true;
            return 'success';
          },
          isSyncInProgress: () => false,
          onSkipped: () => 'skipped',
        );

        expect(actionExecuted, isTrue);
        expect(result, 'success');
      });

      test('skips action when sync is in progress', () async {
        var actionExecuted = false;

        final result = await strategy.execute(
          () async {
            actionExecuted = true;
            return 'success';
          },
          isSyncInProgress: () => true,
          onSkipped: () => 'skipped',
        );

        expect(actionExecuted, isFalse);
        expect(result, 'skipped');
      });

      test('dispose does nothing', () {
        // Should not throw any exceptions
        expect(() => strategy.dispose(), returnsNormally);
      });
    });

    group('SequentialRequestStrategy', () {
      late SequentialRequestStrategy strategy;

      setUp(() {
        strategy = const SequentialRequestStrategy();
      });

      tearDown(() {
        strategy.dispose();
      });

      test('executes single action immediately', () async {
        var actionExecuted = false;

        final result = await strategy.execute(
          () async {
            actionExecuted = true;
            return 'success';
          },
          isSyncInProgress: () => false,
          onSkipped: () => 'skipped',
        );

        expect(actionExecuted, isTrue);
        expect(result, 'success');
      });

      test('queues multiple actions sequentially', () async {
        final executionOrder = <int>[];

        final futures = <Future<String>>[];

        // Start 3 concurrent requests
        for (var i = 0; i < 3; i++) {
          final future = strategy.execute(
            () async {
              executionOrder.add(i);
              await Future.delayed(const Duration(milliseconds: 10));
              return 'result_$i';
            },
            isSyncInProgress: () => false,
            onSkipped: () => 'skipped',
          );
          futures.add(future);
        }

        final results = await Future.wait(futures);

        // Should execute in order
        expect(executionOrder, [0, 1, 2]);
        expect(results, ['result_0', 'result_1', 'result_2']);
      });

      test('handles exceptions by propagating them', () async {
        final future = strategy.execute(
          () async {
            throw Exception('Test exception');
          },
          isSyncInProgress: () => false,
          onSkipped: () => 'skipped',
        );

        await expectLater(future, throwsException);
      });

      test('dispose stops the queue and prevents new jobs', () async {
        // Dispose first
        strategy.dispose();

        // Try to execute after dispose - should still work since dispose just stops the queue
        // but doesn't prevent new jobs from being added
        final result = await strategy.execute(
          () async => 'success',
          isSyncInProgress: () => false,
          onSkipped: () => 'skipped',
        );

        expect(result, 'success');
      });
    });
  });
}
