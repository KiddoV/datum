import 'package:datum/datum.dart';
import 'package:example/sync/isolate_stratergy.dart';
import 'package:example/sync/test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IsolateStrategy', () {
    late List<DatumSyncOperation<TestEntity>> operations;
    late List<String> processedOrder;
    late List<(int, int)> progressUpdates;
    var isCancelled = false;

    setUp(() {
      operations = List.generate(
        5,
        (i) => DatumSyncOperation<TestEntity>(
          id: 'op$i',
          userId: 'user1',
          entityId: 'e$i',
          type: DatumOperationType.create,
          timestamp: DateTime.now(),
        ),
      );
      processedOrder = [];
      progressUpdates = [];
      isCancelled = false;
    });

    Future<void> processOperation(DatumSyncOperation<TestEntity> op) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      processedOrder.add(op.id);
    }

    void onProgress(int completed, int total) {
      progressUpdates.add((completed, total));
    }

    test('processes all operations successfully via isolate', () async {
      // Arrange
      const strategy = IsolateStrategy(SequentialStrategy());

      // Act
      await strategy.execute<TestEntity>(
        operations,
        processOperation,
        () => isCancelled,
        onProgress,
      );

      // Assert
      expect(processedOrder, ['op0', 'op1', 'op2', 'op3', 'op4']);
      expect(progressUpdates, [(1, 5), (2, 5), (3, 5), (4, 5), (5, 5)]);
      expect(progressUpdates.last, (5, 5));
    });

    test('stops processing when cancelled', () async {
      // Arrange
      const strategy = IsolateStrategy(SequentialStrategy());

      // Act
      await strategy.execute<TestEntity>(
        operations,
        (op) async {
          // Wrap the original processOperation to also handle progress updates
          // This ensures progress is reported before the cancellation check runs.
          await processOperation(op);
          onProgress(processedOrder.length, operations.length);
        },
        () {
          // Cancel after 2 operations
          if (processedOrder.length >= 2) isCancelled = true;
          return isCancelled;
        },
        (completed, total) {
          /* No-op, handled in processOperation */
        },
      );

      // Assert
      // Allow a moment for the isolate to be killed and processing to stop.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(processedOrder, ['op0', 'op1']);
      expect(progressUpdates, hasLength(2));
    });

    test('propagates errors from processOperation', () async {
      // Arrange
      // Localize operations list for this test to ensure isolation
      final localOperations = List.generate(
        5,
        (i) => DatumSyncOperation<TestEntity>(
          id: 'op$i',
          userId: 'user1',
          entityId: 'e$i',
          type: DatumOperationType.create,
          timestamp: DateTime.now(),
        ),
      );
      final processedOrder = <String>[];
      final progressUpdates = <(int, int)>[];
      var isCancelled = false; // Localize cancellation flag too

      Future<void> localProcessOperation(
        DatumSyncOperation<TestEntity> op,
      ) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        processedOrder.add(op.id);
      }

      void localOnProgress(int completed, int total) {
        progressUpdates.add((completed, total));
      }

      const strategy = IsolateStrategy(SequentialStrategy());
      final exception = Exception('Processing failed in isolate');

      // Act
      Future<void> action() async {
        await strategy.execute<TestEntity>(
          localOperations, // Use localized operations
          (op) async {
            if (op.id == 'op2') throw exception;
            await localProcessOperation(op);
          }, // Use local processOperation
          () => isCancelled, // Use local isCancelled
          localOnProgress, // Use local onProgress
        );
      }

      // Assert
      // Use a try-catch block for a more robust assertion with isolates.
      try {
        await action();
        fail('Expected an exception to be thrown, but none was.');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(
          (e as Exception).toString(),
          contains('Processing failed in isolate'),
        );
      }
    });

    test('handles empty operation list gracefully', () async {
      // Arrange
      const strategy = IsolateStrategy(SequentialStrategy());

      // Act
      await strategy.execute<TestEntity>(
        [],
        processOperation,
        () => isCancelled,
        onProgress,
      );

      // Assert
      expect(processedOrder, isEmpty);
      expect(progressUpdates, isEmpty);
    });
  });
}
