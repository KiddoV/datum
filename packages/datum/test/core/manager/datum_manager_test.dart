import 'package:datum/datum.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks/mock_adapters.dart';
import '../../mocks/mock_connectivity_checker.dart';
import '../../mocks/test_entity.dart';

void main() {
  late MockLocalAdapter<TestEntity> localAdapter;
  late MockRemoteAdapter<TestEntity> remoteAdapter;
  late MockConnectivityChecker connectivityChecker;
  late DatumManager<TestEntity> manager;

  setUp(() async {
    localAdapter = MockLocalAdapter<TestEntity>();
    remoteAdapter = MockRemoteAdapter<TestEntity>();
    connectivityChecker = MockConnectivityChecker();
    when(() => connectivityChecker.isConnected).thenAnswer((_) async => true);

    manager = DatumManager<TestEntity>(
      localAdapter: localAdapter,
      remoteAdapter: remoteAdapter,
      connectivity: connectivityChecker,
      datumConfig: const DatumConfig<TestEntity>(schemaVersion: 0),
    );
    await manager.initialize();
  });

  tearDown(() {
    manager.dispose();
  });

  group('DatumManager saveMany', () {
    test('should save multiple items without syncing', () async {
      // Arrange
      final items = [
        TestEntity.create('e1', 'user1', 'Item 1'),
        TestEntity.create('e2', 'user1', 'Item 2'),
      ];

      // Act
      final savedItems = await manager.saveMany(
        items: items,
        userId: 'user1',
        source: DataSource.local,
        forceRemoteSync: false,
        scope: null,
      );

      // Assert
      expect(savedItems.length, 2);
      final localItems = await localAdapter.readAll(userId: 'user1');
      expect(localItems.length, 2);
      final pendingOps = await localAdapter.getPendingOperations('user1');
      expect(pendingOps.length, 2);
    });

    test('should save multiple items and then sync', () async {
      // Arrange
      final items = [
        TestEntity.create('e1', 'user1', 'Item 1'),
        TestEntity.create('e2', 'user1', 'Item 2'),
      ];
      remoteAdapter.setProcessingDelay(const Duration(milliseconds: 10));

      // Act
      final savedItems = await manager.saveMany(
        items: items,
        userId: 'user1',
        andSync: true,
        source: DataSource.local,
        forceRemoteSync: false,
        scope: null,
      );

      // Assert
      expect(savedItems.length, 2);
      final localItems = await localAdapter.readAll(userId: 'user1');
      expect(localItems.length, 2);
      final pendingOps = await localAdapter.getPendingOperations('user1');
      expect(pendingOps.length, 0);
      final remoteItems = await remoteAdapter.readAll(userId: 'user1');
      expect(remoteItems.length, 2);
    });

    test('should handle an empty list of items', () async {
      // Arrange
      final items = <TestEntity>[];

      // Act
      final savedItems = await manager.saveMany(
        items: items,
        userId: 'user1',
        source: DataSource.local,
        forceRemoteSync: false,
      );

      // Assert
      expect(savedItems.isEmpty, isTrue);
      final localItems = await localAdapter.readAll(userId: 'user1');
      expect(localItems.isEmpty, isTrue);
      final pendingOps = await localAdapter.getPendingOperations('user1');
      expect(pendingOps.isEmpty, isTrue);
    });
  });
}
