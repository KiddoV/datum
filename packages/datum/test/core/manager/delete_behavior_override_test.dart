import 'package:datum/datum.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_adapters.dart';
import '../../mocks/mock_connectivity_checker.dart';
import '../../mocks/test_entity.dart';

// Helper function to create a properly stubbed MockConnectivityChecker
MockConnectivityChecker createMockConnectivityChecker() {
  final checker = MockConnectivityChecker();
  when(() => checker.isConnected).thenAnswer((_) async => true);
  when(() => checker.onStatusChange).thenAnswer((_) => Stream.value(true));
  return checker;
}

void main() {
  group('DeleteBehavior Override Tests', () {
    late MockLocalAdapter<TestEntity> localAdapter;
    late MockRemoteAdapter<TestEntity> remoteAdapter;
    late DatumManager<TestEntity> manager;
    const userId = 'test-user';
    final testEntity = TestEntity.create('e1', userId, 'Test Entity');

    setUpAll(() {
      registerFallbackValue(
        TestEntity.create('fb', 'fb', 'Fallback'),
      );
      registerFallbackValue(const DatumConfig());
      registerFallbackValue(DataSource.local);
    });

    setUp(() async {
      Datum.resetForTesting();
      localAdapter = MockLocalAdapter<TestEntity>(
        fromJson: (json) => TestEntity.fromJson(json),
      );
      remoteAdapter = MockRemoteAdapter<TestEntity>(
        fromJson: (json) => TestEntity.fromJson(json),
      );

      // Add the test entity to the mock storage
      localAdapter.addLocalItem(userId, testEntity);
    });

    tearDown(() async {
      if (Datum.isInitialized) {
        await Datum.instance.dispose();
      }
    });

    test('Soft delete override: Config=hardDelete, call with behavior=softDelete', () async {
      // Arrange: Initialize with hardDelete config
      await Datum.initialize(
        config: const DatumConfig(
          enableLogging: false,
          deleteBehavior: DeleteBehavior.hardDelete,
        ),
        connectivityChecker: createMockConnectivityChecker(),
        registrations: [
          DatumRegistration<TestEntity>(
            localAdapter: localAdapter,
            remoteAdapter: remoteAdapter,
          ),
        ],
      );
      manager = Datum.manager<TestEntity>();

      // Act: Delete with soft delete override
      final result = await manager.delete(
        id: 'e1',
        userId: userId,
        behavior: DeleteBehavior.softDelete,
      );

      // Assert: Verify soft delete was used (entity still exists but isDeleted=true)
      expect(result, isTrue);
      final entity = await localAdapter.read('e1', userId: userId);
      expect(entity, isNotNull);
      expect(entity!.isDeleted, isTrue);
    });

    test('Hard delete override: Config=softDelete, call with behavior=hardDelete', () async {
      // Arrange: Initialize with softDelete config (default)
      await Datum.initialize(
        config: const DatumConfig(
          enableLogging: false,
          deleteBehavior: DeleteBehavior.softDelete,
        ),
        connectivityChecker: createMockConnectivityChecker(),
        registrations: [
          DatumRegistration<TestEntity>(
            localAdapter: localAdapter,
            remoteAdapter: remoteAdapter,
          ),
        ],
      );
      manager = Datum.manager<TestEntity>();

      // Act: Delete with hard delete override
      final result = await manager.delete(
        id: 'e1',
        userId: userId,
        behavior: DeleteBehavior.hardDelete,
      );

      // Assert: Verify hard delete was used (entity no longer exists)
      expect(result, isTrue);
      final entity = await localAdapter.read('e1', userId: userId);
      expect(entity, isNull);
    });

    test('No override (null): Config=softDelete, call with behavior=null', () async {
      // Arrange: Initialize with softDelete config
      await Datum.initialize(
        config: const DatumConfig(
          enableLogging: false,
          deleteBehavior: DeleteBehavior.softDelete,
        ),
        connectivityChecker: createMockConnectivityChecker(),
        registrations: [
          DatumRegistration<TestEntity>(
            localAdapter: localAdapter,
            remoteAdapter: remoteAdapter,
          ),
        ],
      );
      manager = Datum.manager<TestEntity>();

      // Act: Delete with null behavior (should use config default)
      final result = await manager.delete(
        id: 'e1',
        userId: userId,
        behavior: null,
      );

      // Assert: Verify soft delete was used (config default)
      expect(result, isTrue);
      final entity = await localAdapter.read('e1', userId: userId);
      expect(entity, isNotNull);
      expect(entity!.isDeleted, isTrue);
    });

    test('No override (omitted): Config=hardDelete, call without behavior parameter', () async {
      // Arrange: Initialize with hardDelete config
      await Datum.initialize(
        config: const DatumConfig(
          enableLogging: false,
          deleteBehavior: DeleteBehavior.hardDelete,
        ),
        connectivityChecker: createMockConnectivityChecker(),
        registrations: [
          DatumRegistration<TestEntity>(
            localAdapter: localAdapter,
            remoteAdapter: remoteAdapter,
          ),
        ],
      );
      manager = Datum.manager<TestEntity>();

      // Act: Delete without behavior parameter (should use config default)
      final result = await manager.delete(
        id: 'e1',
        userId: userId,
      );

      // Assert: Verify hard delete was used (config default)
      expect(result, isTrue);
      final entity = await localAdapter.read('e1', userId: userId);
      expect(entity, isNull);
    });

    test('Datum facade delete with override: Config=softDelete, call with behavior=hardDelete', () async {
      // Arrange: Initialize with softDelete config
      await Datum.initialize(
        config: const DatumConfig(
          enableLogging: false,
          deleteBehavior: DeleteBehavior.softDelete,
        ),
        connectivityChecker: createMockConnectivityChecker(),
        registrations: [
          DatumRegistration<TestEntity>(
            localAdapter: localAdapter,
            remoteAdapter: remoteAdapter,
          ),
        ],
      );

      // Act: Delete via Datum facade with hard delete override
      final result = await Datum.instance.delete<TestEntity>(
        id: 'e1',
        userId: userId,
        behavior: DeleteBehavior.hardDelete,
      );

      // Assert: Verify hard delete was used (entity no longer exists)
      expect(result, isTrue);
      final entity = await localAdapter.read('e1', userId: userId);
      expect(entity, isNull);
    });
  });
}
