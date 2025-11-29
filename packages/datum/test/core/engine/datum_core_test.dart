import 'package:datum/datum.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks/mock_adapters.dart';
import '../../mocks/mock_connectivity_checker.dart';
import '../../mocks/test_entity.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(DatumQueryBuilder<TestEntity>().build());
    registerFallbackValue(DataSource.local);
    registerFallbackValue(const PaginationConfig(pageSize: 10));
    registerFallbackValue(
      TestEntity(
        id: 'fallback',
        userId: 'fallback',
        name: 'fallback',
        value: 0,
        modifiedAt: DateTime(0),
        createdAt: DateTime(0),
        version: 0,
      ),
    );
  });

  late MockLocalAdapter<TestEntity> localAdapter;
  late MockRemoteAdapter<TestEntity> remoteAdapter;
  late MockConnectivityChecker connectivityChecker;

  setUp(() async {
    localAdapter = MockLocalAdapter<TestEntity>();
    remoteAdapter = MockRemoteAdapter<TestEntity>();
    connectivityChecker = MockConnectivityChecker();
    when(() => connectivityChecker.isConnected).thenAnswer((_) async => true);
    when(() => connectivityChecker.onStatusChange).thenAnswer((_) => Stream.value(true));

    // Initialize Datum with TestEntity registration
    await Datum.initialize(
      config: const DatumConfig(schemaVersion: 0),
      connectivityChecker: connectivityChecker,
      registrations: [
        DatumRegistration<TestEntity>(
          localAdapter: localAdapter,
          remoteAdapter: remoteAdapter,
        ),
      ],
    );
  });

  tearDown(() async {
    if (Datum.instanceOrNull != null) {
      await Datum.instance.dispose();
    }
    Datum.resetForTesting();
  });

  group('Datum Core Methods', () {
    test('getRemoteSyncMetadata delegates to manager', () async {
      const userId = 'test_user';

      // Test that the method exists and can be called without throwing
      final result = await Datum.instance.getRemoteSyncMetadata<TestEntity>(userId);

      // Since we're using mock adapters, the result should be null (default behavior)
      expect(result, isNull);
    });

    test('createMany delegates to manager saveMany', () async {
      const userId = 'test_user';
      final items = [
        TestEntity.create('item1', userId, 'Item 1'),
        TestEntity.create('item2', userId, 'Item 2'),
      ];

      final result = await Datum.instance.createMany<TestEntity>(
        items: items,
        userId: userId,
        andSync: false,
      );

      expect(result.length, 2);
      expect(result[0].id, 'item1');
      expect(result[1].id, 'item2');

      // Verify that items were saved locally
      final localItems = await localAdapter.readAll(userId: userId);
      expect(localItems.length, 2);
      expect(localItems[0].id, 'item1');
      expect(localItems[1].id, 'item2');
    });

    test('createMany and updateMany handle empty item lists', () async {
      const userId = 'test_user';
      final emptyItems = <TestEntity>[];

      final createResult = await Datum.instance.createMany<TestEntity>(
        items: emptyItems,
        userId: userId,
        andSync: false,
      );

      final updateResult = await Datum.instance.updateMany<TestEntity>(
        items: emptyItems,
        userId: userId,
        andSync: false,
      );

      expect(createResult, isEmpty);
      expect(updateResult, isEmpty);
    });

    test('getRemoteSyncMetadata throws when entity type not registered', () async {
      print('Test start: getRemoteSyncMetadata throws when entity type not registered');
      // Reset Datum to test error case
      print('Disposing existing instance...');
      await Datum.instanceOrNull?.dispose();
      print('Resetting for testing...');
      Datum.resetForTesting();

      // Initialize without TestEntity registration
      print('Initializing Datum...');
      print('Initializing Datum...');
      final initResult = await Datum.initialize(
        config: const DatumConfig(schemaVersion: 0),
        connectivityChecker: connectivityChecker,
        registrations: [], // No registrations
      );
      print('Datum.initialize returned: $initResult');
      print('Is Success? ${initResult.isSuccess()}');
      if (initResult.isFailure()) {
        final (error, stackTrace) = initResult.getError();
        print('Failure value: $error');
        print('Failure stack: $stackTrace');
      }
      print('Datum initialized. Instance is null? ${Datum.instanceOrNull == null}');

      print('Expect throwsStateError...');
      expect(
        () {
          print('Calling getRemoteSyncMetadata...');
          return Datum.instance.getRemoteSyncMetadata<TestEntity>('user');
        },
        throwsStateError,
      );
    });
  });
}
