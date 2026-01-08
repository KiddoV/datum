import 'dart:async';
import 'package:datum/datum.dart';
import 'package:test/test.dart';

// Top-level function to be sendable
Future<void> processOperation(DatumSyncOperation<TestEntity> op) async {
  // Simulate work
  await Future.delayed(const Duration(milliseconds: 10));
}

// Top-level function for cancellation
bool isCancelled() => false;

// Top-level function for progress
void onProgress(int completed, int total) {}

void main() {
  group('IsolateStrategy', () {
    test('should execute operations in background isolate', () async {
      const delegate = SequentialStrategy();
      const strategy = IsolateStrategy(delegate);

      final ops = <DatumSyncOperation<TestEntity>>[
        DatumSyncOperation<TestEntity>(
          id: 'op1',
          userId: 'user1',
          entityId: '1',
          type: DatumOperationType.create,
          data: TestEntity(
            id: '1',
            userId: 'user1',
            name: 'Test',
            modifiedAt: DateTime.now(),
            createdAt: DateTime.now(),
            version: 1,
            isDeleted: false,
          ),
          timestamp: DateTime.now(),
        ),
      ];

      await strategy.execute(
        ops,
        processOperation,
        isCancelled,
        onProgress,
      );
    });
  });
}

class TestEntity with DatumEntityMixin {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime modifiedAt;
  @override
  final DateTime createdAt;
  @override
  final int version;
  @override
  final bool isDeleted;

  final String name;

  const TestEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.modifiedAt,
    required this.createdAt,
    required this.version,
    required this.isDeleted,
  });

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      'id': id,
      'userId': userId,
      'modifiedAt': modifiedAt.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'version': version,
      'isDeleted': isDeleted,
      'name': name,
    };
  }

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) => null;

  @override
  List<Object?> get props => [...super.props, name];

  @override
  bool? get stringify => true;
}
