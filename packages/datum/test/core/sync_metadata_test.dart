import 'package:datum/source/core/models/datum_sync_metadata.dart';
import 'package:test/test.dart';

void main() {
  group('DatumEntitySyncDetails', () {
    const details = DatumEntitySyncDetails(count: 10, hash: 'hash123');

    test('toMap and fromJson work correctly', () {
      final map = details.toMap();
      final fromMap = DatumEntitySyncDetails.fromJson(map);
      expect(fromMap, details);
    });

    test('toMap and fromJson work correctly with null hash', () {
      const detailsWithNullHash = DatumEntitySyncDetails(count: 5);
      final map = detailsWithNullHash.toMap();
      final fromMap = DatumEntitySyncDetails.fromJson(map);

      expect(map.containsKey('hash'), isFalse);
      expect(fromMap, detailsWithNullHash);
      expect(fromMap.hash, isNull);
    });

    test('equality works correctly', () {
      const same = DatumEntitySyncDetails(count: 10, hash: 'hash123');
      const differentCount = DatumEntitySyncDetails(count: 11, hash: 'hash123');
      const differentHash = DatumEntitySyncDetails(count: 10, hash: 'hash456');
      expect(details, same);
      expect(details.hashCode, same.hashCode);
      expect(details == differentCount, isFalse);
      expect(details == differentHash, isFalse);
    });

    test('toString provides a useful representation', () {
      expect(
        details.toString(),
        'DatumEntitySyncDetails(count: 10, hash: hash123, lastModified: null, pendingChanges: 0)',
      );
    });
  });

  group('DatumSyncMetadata', () {
    final now = DateTime.now().toUtc();
    final metadata = DatumSyncMetadata(
      userId: 'user-123',
      lastSyncTime: now, // Use UTC time for consistent testing
      dataHash: 'hash123',
      deviceId: 'device-abc',
      entityCounts: const {
        'tasks': DatumEntitySyncDetails(count: 10, hash: 'task_hash'),
        'projects': DatumEntitySyncDetails(count: 2, hash: 'project_hash'),
        'notes': DatumEntitySyncDetails(count: 5, hash: 'notes_hash'),
      },
      customMetadata: const {'isPremium': true},
    );

    test('toMap and fromJson work correctly', () {
      // Arrange
      final map = metadata.toMap();

      // Act
      final fromMap = DatumSyncMetadata.fromMap(map);

      // Assert
      expect(fromMap, metadata);
    });

    test('toMap and fromJson handle null values', () {
      // Arrange
      final minimalMetadata = DatumSyncMetadata(
        userId: 'user-456',
        lastSyncTime: now, // Use UTC time for consistent testing
      );
      final map = minimalMetadata.toMap();

      // Act
      final fromMap = DatumSyncMetadata.fromMap(map);

      // Assert
      expect(fromMap.userId, 'user-456');
      expect(fromMap.lastSyncTime?.toIso8601String(), now.toIso8601String());
      expect(fromMap.dataHash, isNull);
      expect(fromMap.deviceId, isNull);
      expect(fromMap.entityCounts, isNull);
      expect(fromMap.customMetadata, isNull);
    });

    test('copyWith creates a correct copy with new values', () {
      // Arrange
      final newTime = now.add(const Duration(minutes: 5));
      const newEntityCounts = {'notes': DatumEntitySyncDetails(count: 20)};

      // Act
      final copied = metadata.copyWith(
        lastSyncTime: newTime,
        entityCounts: newEntityCounts,
      );

      // Assert
      expect(copied.userId, metadata.userId);
      expect(copied.lastSyncTime, newTime);
      expect(copied.entityCounts, newEntityCounts);
      expect(copied.dataHash, metadata.dataHash); // Should remain unchanged
    });

    test('copyWith correctly updates a single entity in entityCounts', () {
      // Arrange
      final updatedCounts = Map<String, DatumEntitySyncDetails>.from(
        metadata.entityCounts!,
      );
      updatedCounts['tasks'] = const DatumEntitySyncDetails(
        count: 15,
        hash: 'new_task_hash',
      );

      // Act
      final copied = metadata.copyWith(entityCounts: updatedCounts);

      // Assert
      expect(copied.entityCounts, isNotNull);
      expect(copied.entityCounts!.length, 3);
      // Check that 'tasks' was updated
      expect(
        copied.entityCounts!['tasks'],
        const DatumEntitySyncDetails(count: 15, hash: 'new_task_hash'),
      );
      // Check that 'projects' remains unchanged
      expect(
        copied.entityCounts!['projects'],
        metadata.entityCounts!['projects'],
      );
      expect(copied.entityCounts!['notes'], metadata.entityCounts!['notes']);
    });

    test('equality operator (==) works correctly', () {
      // Arrange
      final same = DatumSyncMetadata(
        userId: 'user-123',
        lastSyncTime: now,
        dataHash: 'hash123',
        deviceId: 'device-abc',
        entityCounts: const {
          'tasks': DatumEntitySyncDetails(count: 10, hash: 'task_hash'),
          'projects': DatumEntitySyncDetails(count: 2, hash: 'project_hash'),
          'notes': DatumEntitySyncDetails(count: 5, hash: 'notes_hash'),
        },
        customMetadata: const {'isPremium': true},
      );
      final different = metadata.copyWith(dataHash: 'different-hash');

      // Assert
      expect(metadata == same, isTrue);
      expect(metadata == different, isFalse);
    });

    test('equality is false if entityCounts have different details', () {
      // Arrange
      final differentCounts = metadata.copyWith(
        entityCounts: {
          'tasks': const DatumEntitySyncDetails(count: 10, hash: 'task_hash'),
          'projects': const DatumEntitySyncDetails(
            count: 3,
            hash: 'different_project_hash',
          ),
        },
      );

      // Assert
      expect(metadata == differentCounts, isFalse);
    });

    test('hashCode is consistent with equality', () {
      // Arrange
      final same = metadata.copyWith();
      final different = metadata.copyWith(dataHash: 'different-hash');

      // Assert
      expect(metadata.hashCode, same.hashCode);
      expect(metadata.hashCode, isNot(different.hashCode));
    });
  });

  group('DatumSyncMetadata Getters and Methods', () {
    final now = DateTime.now().toUtc();
    final entityCounts = {
      'tasks': const DatumEntitySyncDetails(count: 10, pendingChanges: 2),
      'projects': const DatumEntitySyncDetails(count: 5, pendingChanges: 3),
    };
    final devices = {
      'device1': now.subtract(const Duration(hours: 1)),
      'device2': now,
    };

    test('isSyncing returns true when syncStatus is syncing', () {
      const syncingMetadata = DatumSyncMetadata(
        userId: 'user1',
        syncStatus: SyncStatus.syncing,
      );
      expect(syncingMetadata.isSyncing, isTrue);
    });

    test('isSyncing returns false when syncStatus is not syncing', () {
      const notSyncingMetadata = DatumSyncMetadata(
        userId: 'user1',
        syncStatus: SyncStatus.synced,
      );
      expect(notSyncingMetadata.isSyncing, isFalse);
    });

    test('isLastSyncSuccessful returns true when syncStatus is synced', () {
      const syncedMetadata = DatumSyncMetadata(
        userId: 'user1',
        syncStatus: SyncStatus.synced,
      );
      expect(syncedMetadata.isLastSyncSuccessful, isTrue);
    });

    test('isLastSyncSuccessful returns false when syncStatus is not synced', () {
      const notSyncedMetadata = DatumSyncMetadata(
        userId: 'user1',
        syncStatus: SyncStatus.failed,
      );
      expect(notSyncedMetadata.isLastSyncSuccessful, isFalse);
    });

    test('hasConflicts returns true when conflictCount is greater than 0', () {
      const conflictMetadata = DatumSyncMetadata(
        userId: 'user1',
        conflictCount: 1,
      );
      expect(conflictMetadata.hasConflicts, isTrue);
    });

    test('hasConflicts returns false when conflictCount is 0', () {
      const noConflictMetadata = DatumSyncMetadata(
        userId: 'user1',
        conflictCount: 0,
      );
      expect(noConflictMetadata.hasConflicts, isFalse);
    });

    test('isNeverSynced returns true when syncStatus is neverSynced', () {
      const neverSyncedMetadata = DatumSyncMetadata(
        userId: 'user1',
        syncStatus: SyncStatus.neverSynced,
      );
      expect(neverSyncedMetadata.isNeverSynced, isTrue);
    });

    test('isNeverSynced returns false when syncStatus is not neverSynced', () {
      const syncedMetadata = DatumSyncMetadata(
        userId: 'user1',
        syncStatus: SyncStatus.synced,
      );
      expect(syncedMetadata.isNeverSynced, isFalse);
    });

    test('totalPendingChanges calculates correctly with entityCounts', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        entityCounts: entityCounts,
      );
      expect(metadata.totalPendingChanges, 5); // 2 + 3
    });

    test('totalPendingChanges returns 0 when entityCounts is null', () {
      const metadata = DatumSyncMetadata(userId: 'user1');
      expect(metadata.totalPendingChanges, 0);
    });

    test('allDeviceIds returns correct list when devices is not null', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        devices: devices,
      );
      expect(metadata.allDeviceIds, containsAll(['device1', 'device2']));
      expect(metadata.allDeviceIds.length, 2);
    });

    test('allDeviceIds returns deviceId when devices is null and deviceId is not null', () {
      const metadata = DatumSyncMetadata(
        userId: 'user1',
        deviceId: 'singleDevice',
      );
      expect(metadata.allDeviceIds, ['singleDevice']);
    });

    test('allDeviceIds returns empty list when devices and deviceId are null', () {
      const metadata = DatumSyncMetadata(userId: 'user1');
      expect(metadata.allDeviceIds, isEmpty);
    });

    test('deviceCount returns correct count when devices is not null', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        devices: devices,
      );
      expect(metadata.deviceCount, 2);
    });

    test('deviceCount returns 1 when devices is null and deviceId is not null', () {
      const metadata = DatumSyncMetadata(
        userId: 'user1',
        deviceId: 'singleDevice',
      );
      expect(metadata.deviceCount, 1);
    });

    test('deviceCount returns 0 when devices and deviceId are null', () {
      const metadata = DatumSyncMetadata(userId: 'user1');
      expect(metadata.deviceCount, 0);
    });

    test('getDeviceLastSync returns correct DateTime for existing device', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        devices: devices,
      );
      expect(metadata.getDeviceLastSync('device1'), now.subtract(const Duration(hours: 1)));
    });

    test('getDeviceLastSync returns null for non-existing device', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        devices: devices,
      );
      expect(metadata.getDeviceLastSync('device3'), isNull);
    });

    test('hasDeviceSynced returns true for existing device', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        devices: devices,
      );
      expect(metadata.hasDeviceSynced('device1'), isTrue);
    });

    test('hasDeviceSynced returns false for non-existing device', () {
      final metadata = DatumSyncMetadata(
        userId: 'user1',
        devices: devices,
      );
      expect(metadata.hasDeviceSynced('device3'), isFalse);
    });

    test('hasDeviceSynced returns false when devices is null', () {
      const metadata = DatumSyncMetadata(userId: 'user1');
      expect(metadata.hasDeviceSynced('device1'), isFalse);
    });
  });
}
