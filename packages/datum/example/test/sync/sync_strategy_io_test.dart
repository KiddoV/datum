import 'dart:async';

import 'package:datum/datum.dart' hide IsolateStrategy;
import 'package:example/sync/isolate_stratergy.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple test entity for sync operations
class TestEntity extends DatumEntity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime modifiedAt;
  @override
  final int version;
  @override
  final bool isDeleted;

  const TestEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    this.version = 1,
    this.isDeleted = false,
  });

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) => {
        'id': id,
        'userId': userId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'modifiedAt': modifiedAt.millisecondsSinceEpoch,
        'version': version,
        'isDeleted': isDeleted,
      };

  TestEntity copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  }) =>
      TestEntity(
        id: id,
        userId: userId,
        createdAt: createdAt,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        version: version ?? this.version,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) => null;

  @override
  List<Object?> get props => [id, userId, version, isDeleted];

  @override
  bool? get stringify => true;

  @override
  bool get isRelational => false;
}

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

        final entity = TestEntity(
          id: '1',
          userId: 'user1',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
        );

        final operations = [
          DatumSyncOperation<TestEntity>(
            id: 'op1',
            userId: 'user1',
            entityId: '1',
            type: DatumOperationType.create,
            timestamp: DateTime.now(),
            data: entity,
          ),
        ];

        final processOperationCompleter = Completer<void>();
        Future<void> processOperation(DatumSyncOperation<TestEntity> op) async {
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
        await isolateStrategy.execute<TestEntity>(
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
