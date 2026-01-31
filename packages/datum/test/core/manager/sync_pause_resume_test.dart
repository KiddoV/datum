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
      datumConfig: const DatumConfig<TestEntity>(
        schemaVersion: 0,
        autoSyncInterval: Duration(minutes: 15),
      ),
    );
    await manager.initialize();
  });

  tearDown(() {
    manager.dispose();
  });

  test('should restore auto-sync timers after pause and resume', () async {
    const userId = 'test-user';

    // 1. Start auto-sync
    manager.startAutoSync(userId);

    // Verify it's scheduled
    var nextSyncTime = await manager.getNextSyncTime();
    expect(nextSyncTime, isNotNull, reason: 'Auto-sync should be scheduled after startAutoSync');

    // 2. Pause sync
    manager.pauseSync();

    // Verify it's stopped
    nextSyncTime = await manager.getNextSyncTime();
    expect(nextSyncTime, isNull, reason: 'Auto-sync should be stopped after pauseSync');

    // 3. Resume sync
    manager.resumeSync();

    // Verify it's restored
    nextSyncTime = await manager.getNextSyncTime();
    expect(nextSyncTime, isNotNull, reason: 'Auto-sync should be restored after resumeSync');
  });
}
