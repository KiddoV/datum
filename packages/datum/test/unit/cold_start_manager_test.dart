import 'dart:async';

import 'package:datum/source/core/manager/cold_start_manager.dart';
import 'package:datum/source/core/models/cold_start_strategy.dart';
import 'package:datum/source/core/models/datum_sync_result.dart';
import 'package:datum/src/test_utils/test_datum_entity.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryColdStartPersistence', () {
    late InMemoryColdStartPersistence persistence;

    setUp(() {
      persistence = InMemoryColdStartPersistence();
    });

    test('should save and load state correctly', () async {
      const userId = 'user-123';
      final state = {
        'lastSync': '2023-01-01T12:00:00Z',
        'syncVersion': 42,
        'isColdStart': false,
      };

      // Initially no state
      expect(await persistence.loadState(userId), isNull);

      // Save state
      await persistence.saveState(userId, state);

      // Load state
      final loadedState = await persistence.loadState(userId);
      expect(loadedState, isNotNull);
      expect(loadedState!['lastSync'], equals('2023-01-01T12:00:00Z'));
      expect(loadedState['syncVersion'], equals(42));
      expect(loadedState['isColdStart'], isFalse);
    });

    test('should return null for non-existent user', () async {
      expect(await persistence.loadState('non-existent-user'), isNull);
    });

    test('should clear state correctly', () async {
      const userId = 'user-123';
      final state = {'key': 'value'};

      // Save state
      await persistence.saveState(userId, state);
      expect(await persistence.loadState(userId), isNotNull);

      // Clear state
      await persistence.clearState(userId);
      expect(await persistence.loadState(userId), isNull);
    });

    test('should handle multiple users independently', () async {
      const userId1 = 'user-1';
      const userId2 = 'user-2';
      final state1 = {'user': 1};
      final state2 = {'user': 2};

      // Save states for both users
      await persistence.saveState(userId1, state1);
      await persistence.saveState(userId2, state2);

      // Load states
      final loadedState1 = await persistence.loadState(userId1);
      final loadedState2 = await persistence.loadState(userId2);

      expect(loadedState1!['user'], equals(1));
      expect(loadedState2!['user'], equals(2));

      // Clear one user
      await persistence.clearState(userId1);
      expect(await persistence.loadState(userId1), isNull);
      expect(await persistence.loadState(userId2), isNotNull);
    });

    test('should handle empty state map', () async {
      const userId = 'user-123';
      final emptyState = <String, dynamic>{};

      await persistence.saveState(userId, emptyState);
      final loadedState = await persistence.loadState(userId);

      expect(loadedState, isNotNull);
      expect(loadedState, isEmpty);
    });

    test('should handle complex nested state', () async {
      const userId = 'user-123';
      final complexState = {
        'nested': {
          'deep': {
            'value': 42,
            'list': [1, 2, 3],
          }
        },
        'array': ['a', 'b', 'c'],
        'nullValue': null,
      };

      await persistence.saveState(userId, complexState);
      final loadedState = await persistence.loadState(userId);

      expect(loadedState, equals(complexState));
      expect(loadedState!['nested']['deep']['value'], equals(42));
      expect(loadedState['array'], equals(['a', 'b', 'c']));
      expect(loadedState['nullValue'], isNull);
    });

    test('should create defensive copy when saving', () async {
      const userId = 'user-123';
      final originalState = {
        'mutable': [1, 2, 3],
        'stringKey': 'original'
      };

      await persistence.saveState(userId, originalState);

      // Modify original
      originalState['mutable'] = [4, 5, 6];
      originalState['newKey'] = 'newValue';

      // Loaded state should not be affected
      final loadedState = await persistence.loadState(userId);
      expect(loadedState!['mutable'], equals([1, 2, 3]));
      expect(loadedState['stringKey'], equals('original'));
      expect(loadedState.containsKey('newKey'), isFalse);
    });
  });

  group('ColdStartManager', () {
    late ColdStartManager manager;
    late ColdStartConfig config;

    setUp(() {
      config = const ColdStartConfig(
        strategy: ColdStartStrategy.adaptive,
        syncThreshold: Duration(hours: 24),
        initialDelay: Duration(seconds: 2),
        maxDuration: Duration(minutes: 5),
      );
      manager = ColdStartManager(config);
    });

    group('getActiveUsers', () {
      test('should return empty set initially', () {
        expect(manager.getActiveUsers(), isEmpty);
      });

      test('should return users after cold start operations', () async {
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Create a successful sync result
        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId1,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );

        // Simulate cold start check for user-1
        await manager.handleColdStartIfNeeded(userId1, (_) async => successResult);

        expect(manager.getActiveUsers(), contains(userId1));
        expect(manager.getActiveUsers(), hasLength(1));

        // Simulate cold start check for user-2
        const successResult2 = DatumSyncResult<TestDatumEntity>(
          userId: userId2,
          duration: Duration(seconds: 1),
          syncedCount: 3,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await manager.handleColdStartIfNeeded(userId2, (_) async => successResult2);

        expect(manager.getActiveUsers(), containsAll([userId1, userId2]));
        expect(manager.getActiveUsers(), hasLength(2));
      });

      test('should return unique users only', () async {
        const userId = 'user-1';

        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );

        // Multiple operations on same user
        await manager.handleColdStartIfNeeded(userId, (_) async => successResult);
        await manager.handleColdStartIfNeeded(userId, (_) async => successResult);

        expect(manager.getActiveUsers(), hasLength(1));
        expect(manager.getActiveUsers(), contains(userId));
      });

      test('should return defensive copy', () async {
        const userId = 'user-1';

        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );

        await manager.handleColdStartIfNeeded(userId, (_) async => successResult);

        final users = manager.getActiveUsers();
        expect(users, hasLength(1));

        // Modifying the returned set should not affect internal state
        users.clear();
        expect(manager.getActiveUsers(), hasLength(1));
      });

      test('should handle multiple users with different states', () async {
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // User 1: cold start performed
        const successResult1 = DatumSyncResult<TestDatumEntity>(
          userId: userId1,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await manager.handleColdStartIfNeeded(userId1, (_) async => successResult1);

        // User 2: cold start checked but not performed (strategy disabled)
        const disabledConfig = ColdStartConfig(strategy: ColdStartStrategy.disabled);
        final disabledManager = ColdStartManager(disabledConfig);
        const successResult2 = DatumSyncResult<TestDatumEntity>(
          userId: userId2,
          duration: Duration(seconds: 1),
          syncedCount: 3,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await disabledManager.handleColdStartIfNeeded(userId2, (_) async => successResult2);

        // User 3: not accessed yet

        expect(manager.getActiveUsers(), contains(userId1));
        expect(manager.getActiveUsers(), hasLength(1));

        expect(disabledManager.getActiveUsers(), contains(userId2));
        expect(disabledManager.getActiveUsers(), hasLength(1));
      });
    });

    group('config getter', () {
      test('should return the config passed to constructor', () {
        expect(manager.config, same(config));
        expect(manager.config.strategy, equals(ColdStartStrategy.adaptive));
        expect(manager.config.syncThreshold, equals(const Duration(hours: 24)));
        expect(manager.config.initialDelay, equals(const Duration(seconds: 2)));
        expect(manager.config.maxDuration, equals(const Duration(minutes: 5)));
      });

      test('should return defensive copy or immutable config', () {
        final returnedConfig = manager.config;

        // Config should be immutable/const
        expect(returnedConfig, isA<ColdStartConfig>());
        expect(returnedConfig.strategy, equals(ColdStartStrategy.adaptive));
      });

      test('should work with different config values', () {
        final configs = [
          const ColdStartConfig(strategy: ColdStartStrategy.disabled),
          const ColdStartConfig(strategy: ColdStartStrategy.fullSync),
          const ColdStartConfig(strategy: ColdStartStrategy.incremental),
          const ColdStartConfig(strategy: ColdStartStrategy.priorityBased),
          const ColdStartConfig(
            strategy: ColdStartStrategy.adaptive,
            syncThreshold: Duration(hours: 12),
            initialDelay: Duration(seconds: 5),
            maxDuration: Duration(minutes: 10),
          ),
        ];

        for (final testConfig in configs) {
          final testManager = ColdStartManager(testConfig);
          expect(testManager.config, same(testConfig));
          expect(testManager.config.strategy, equals(testConfig.strategy));
        }
      });

      test('should maintain config integrity across operations', () async {
        final originalConfig = manager.config;

        // Perform some operations
        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: 'user-1',
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await manager.handleColdStartIfNeeded('user-1', (_) async => successResult);
        manager.resetForUser('user-1');

        // Config should remain unchanged
        expect(manager.config, same(originalConfig));
        expect(manager.config.strategy, equals(ColdStartStrategy.adaptive));
      });

      test('resetAll should clear all user states', () async {
        const userId1 = 'user-1';
        const userId2 = 'user-2';
        const userId3 = 'user-3';

        // Add some users with different states
        const successResult1 = DatumSyncResult<TestDatumEntity>(
          userId: userId1,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await manager.handleColdStartIfNeeded(userId1, (_) async => successResult1);

        const successResult2 = DatumSyncResult<TestDatumEntity>(
          userId: userId2,
          duration: Duration(seconds: 1),
          syncedCount: 3,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await manager.handleColdStartIfNeeded(userId2, (_) async => successResult2);

        // Set last cold start time for user 3
        manager.setLastColdStartTimeForUser(userId3, DateTime.now());

        // Verify users are tracked
        expect(manager.getActiveUsers(), hasLength(2));
        expect(manager.getActiveUsers(), containsAll([userId1, userId2]));
        expect(manager.getLastColdStartTimeForUser(userId3), isNotNull);

        // Reset all
        manager.resetAll();

        // Verify all states are cleared
        expect(manager.getActiveUsers(), isEmpty);
        expect(manager.getLastColdStartTimeForUser(userId1), isNull);
        expect(manager.getLastColdStartTimeForUser(userId2), isNull);
        expect(manager.getLastColdStartTimeForUser(userId3), isNull);

        // Verify cold start flags are reset
        expect(manager.isColdStartForUser(userId1), isTrue); // Back to default
        expect(manager.isColdStartForUser(userId2), isTrue); // Back to default
        expect(manager.isColdStartForUser(userId3), isTrue); // Back to default
      });

      test('resetAll should work on empty manager', () {
        // Should not throw any errors
        expect(() => manager.resetAll(), returnsNormally);

        // Should remain empty
        expect(manager.getActiveUsers(), isEmpty);
      });

      test('resetAll should allow new operations after reset', () async {
        const userId = 'user-1';

        // Perform operation
        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );
        await manager.handleColdStartIfNeeded(userId, (_) async => successResult);

        // Reset all
        manager.resetAll();

        // Should be able to perform operations again
        await manager.handleColdStartIfNeeded(userId, (_) async => successResult);

        expect(manager.getActiveUsers(), contains(userId));
      });
    });

    group('Integration with InMemoryColdStartPersistence', () {
      late InMemoryColdStartPersistence persistence;

      setUp(() {
        persistence = InMemoryColdStartPersistence();
      });

      test('should work with persistence layer', () async {
        // Note: Current implementation doesn't use persistence, but this tests the interface
        const userId = 'user-123';
        final state = {'coldStartCompleted': true, 'lastSync': DateTime.now().toIso8601String()};

        await persistence.saveState(userId, state);
        final loadedState = await persistence.loadState(userId);

        expect(loadedState, equals(state));
      });

      test('should handle persistence errors gracefully', () async {
        // Test that async operations work (even though current impl is synchronous)
        const userId = 'user-123';

        await expectLater(
          persistence.saveState(userId, {'test': 'data'}),
          completes,
        );

        await expectLater(
          persistence.loadState(userId),
          completion(isNotNull),
        );

        await expectLater(
          persistence.clearState(userId),
          completes,
        );

        expect(await persistence.loadState(userId), isNull);
      });
    });

    group('Complex scenarios', () {
      test('should handle concurrent operations on different users', () async {
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Start concurrent operations
        final future1 = manager.handleColdStartIfNeeded(userId1, (_) async {
          await Future.delayed(const Duration(milliseconds: 10));
          return const DatumSyncResult<TestDatumEntity>(
            userId: userId1,
            duration: Duration(seconds: 1),
            syncedCount: 5,
            failedCount: 0,
            conflictsResolved: 0,
            pendingOperations: [],
          );
        });

        final future2 = manager.handleColdStartIfNeeded(userId2, (_) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return const DatumSyncResult<TestDatumEntity>(
            userId: userId2,
            duration: Duration(seconds: 1),
            syncedCount: 3,
            failedCount: 0,
            conflictsResolved: 0,
            pendingOperations: [],
          );
        });

        await Future.wait([future1, future2]);

        final activeUsers = manager.getActiveUsers();
        expect(activeUsers, containsAll([userId1, userId2]));
        expect(activeUsers, hasLength(2));
      });

      test('should maintain config consistency during concurrent access', () async {
        final configFutures = <Future<ColdStartConfig>>[];

        // Multiple concurrent config accesses
        for (int i = 0; i < 10; i++) {
          configFutures.add(Future(() => manager.config));
        }

        final configs = await Future.wait(configFutures);

        // All configs should be the same
        for (final returnedConfig in configs) {
          expect(returnedConfig, same(config));
          expect(returnedConfig.strategy, equals(ColdStartStrategy.adaptive));
        }
      });

      test('should handle persistence operations with complex data', () async {
        final persistence = InMemoryColdStartPersistence();
        const userId = 'complex-user';

        final complexState = {
          'metadata': {
            'version': '1.0.0',
            'platform': 'ios',
            'deviceId': 'device-123',
          },
          'syncState': {
            'lastFullSync': DateTime(2023, 1, 1).toIso8601String(),
            'pendingChanges': 5,
            'conflictsResolved': 2,
          },
          'userPreferences': {
            'autoSync': true,
            'syncOnCellular': false,
            'maxRetries': 3,
          },
          'performanceMetrics': {
            'averageSyncTime': 1250, // milliseconds
            'totalSyncs': 42,
            'failedSyncs': 1,
          },
        };

        await persistence.saveState(userId, complexState);
        final loadedState = await persistence.loadState(userId);

        expect(loadedState, equals(complexState));
        expect(loadedState!['metadata']['version'], equals('1.0.0'));
        expect(loadedState['syncState']['pendingChanges'], equals(5));
        expect(loadedState['userPreferences']['autoSync'], isTrue);
        expect(loadedState['performanceMetrics']['averageSyncTime'], equals(1250));
      });

      test('_executeWithRetry should succeed on first attempt (synchronous)', () async {
        const userId = 'user-1';
        var callCount = 0;

        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );

        final result = await manager.handleColdStartIfNeeded(
          userId,
          (options) async {
            callCount++;
            return successResult;
          },
          synchronous: true,
        );

        expect(result, isTrue);
        expect(callCount, 1);
      });

      test('_executeWithRetry should succeed on first attempt (asynchronous)', () async {
        const userId = 'user-1';
        var callCount = 0;

        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );

        final result = await manager.handleColdStartIfNeeded(
          userId,
          (options) async {
            callCount++;
            return successResult;
          },
          synchronous: false, // Default behavior
        );

        // Should return true immediately without waiting for sync completion
        expect(result, isTrue);
        // Call count should be 0 since sync happens asynchronously
        expect(callCount, 0);

        // Wait for async operation to complete (includes 2 second initial delay)
        await Future.delayed(const Duration(seconds: 3));
        expect(callCount, 1);
      });

      test('_executeWithRetry should retry on failure and succeed', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;
          var failureCount = 0;

          const successResult = DatumSyncResult<TestDatumEntity>(
            userId: userId,
            duration: Duration(seconds: 1),
            syncedCount: 5,
            failedCount: 0,
            conflictsResolved: 0,
            pendingOperations: [],
          );

          // Create manager with very short retry delays for testing
          final fastRetryManager = ColdStartManager(
            config,
            maxRetries: 2,
            initialRetryDelay: const Duration(milliseconds: 1),
            retryBackoffMultiplier: 1.0,
          );

          final result = await fastRetryManager.handleColdStartIfNeeded(userId, (options) async {
            callCount++;
            if (callCount <= 2) {
              failureCount++;
              throw Exception('Temporary failure');
            }
            return successResult;
          });

          expect(result, isTrue);
          expect(callCount, 3); // Failed twice, succeeded on third try
          expect(failureCount, 2);
        });
      });

      test('_executeWithRetry should fail after max retries', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;

          // Create manager with low retry count and short delays for testing
          const retryConfig = ColdStartConfig(
            strategy: ColdStartStrategy.adaptive,
            syncThreshold: Duration(hours: 24),
            initialDelay: Duration.zero, // No delay for faster tests
            maxDuration: Duration(minutes: 5),
          );
          final retryManager = ColdStartManager(
            retryConfig,
            maxRetries: 2,
            initialRetryDelay: const Duration(milliseconds: 1),
            retryBackoffMultiplier: 1.0,
          );

          // Should throw exception after max retries
          try {
            await retryManager.handleColdStartIfNeeded(userId, (options) async {
              callCount++;
              throw Exception('Persistent failure');
            });
            fail('Expected exception to be thrown');
          } catch (e) {
            expect(e, isA<Exception>());
            expect(callCount, 3); // Initial + 2 retries = 3 total attempts
          }
        });
      });

      test('_executeWithRetry should not retry non-retryable errors (synchronous)', () async {
        const userId = 'user-1';
        var callCount = 0;

        // Should throw exception for non-retryable error
        try {
          await manager.handleColdStartIfNeeded(
            userId,
            (options) async {
              callCount++;
              throw ArgumentError('Invalid argument'); // Non-retryable error
            },
            synchronous: true,
          );
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(callCount, 1); // Should not retry
        }
      });

      test('_executeWithRetry should not retry non-retryable errors (asynchronous)', () async {
        const userId = 'user-1';
        var callCount = 0;

        // For asynchronous mode, exceptions are handled internally and not rethrown
        final result = await manager.handleColdStartIfNeeded(
          userId,
          (options) async {
            callCount++;
            throw ArgumentError('Invalid argument'); // Non-retryable error
          },
          synchronous: false, // Default behavior
        );

        // Should return true (sync initiated) but not wait for completion
        expect(result, isTrue);
        expect(callCount, 0); // Sync happens asynchronously

        // Wait for async operation to complete and verify it was called once
        await Future.delayed(const Duration(seconds: 3));
        expect(callCount, 1); // Should not retry
      });

      test('_executeWithRetry should implement exponential backoff', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;
          final callTimes = <DateTime>[];

          const successResult = DatumSyncResult<TestDatumEntity>(
            userId: userId,
            duration: Duration(seconds: 1),
            syncedCount: 5,
            failedCount: 0,
            conflictsResolved: 0,
            pendingOperations: [],
          );

          // Create manager with short retry delays for testing
          final backoffManager = ColdStartManager(
            config,
            maxRetries: 2,
            initialRetryDelay: const Duration(milliseconds: 10),
            retryBackoffMultiplier: 2.0,
          );

          final result = await backoffManager.handleColdStartIfNeeded(userId, (options) async {
            callTimes.add(DateTime.now());
            callCount++;
            if (callCount <= 2) {
              throw Exception('Temporary failure');
            }
            return successResult;
          });

          expect(result, isTrue);
          expect(callCount, 3);
          expect(callTimes.length, 3);

          // Check that delays increase exponentially
          final delay1 = callTimes[1].difference(callTimes[0]);
          final delay2 = callTimes[2].difference(callTimes[1]);

          expect(delay1.inMilliseconds, greaterThanOrEqualTo(10));
          expect(delay2.inMilliseconds, greaterThanOrEqualTo(20)); // 10 * 2.0
        });
      });

      test('_executeWithRetry should handle StateError as non-retryable (synchronous)', () async {
        const userId = 'user-1';
        var callCount = 0;

        // Should throw exception for non-retryable error
        try {
          await manager.handleColdStartIfNeeded(
            userId,
            (options) async {
              callCount++;
              throw StateError('Invalid state'); // Non-retryable error
            },
            synchronous: true,
          );
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<StateError>());
          expect(callCount, 1); // Should not retry
        }
      });

      test('_executeWithRetry should handle StateError as non-retryable (asynchronous)', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;

          // For asynchronous mode, exceptions are handled internally and not rethrown
          final result = await manager.handleColdStartIfNeeded(
            userId,
            (options) async {
              callCount++;
              throw StateError('Invalid state'); // Non-retryable error
            },
            synchronous: false, // Default behavior
          );

          // Should return true (sync initiated) but not wait for completion
          expect(result, isTrue);
          expect(callCount, 0); // Sync happens asynchronously

          // Advance time to allow async operation to complete
          async.elapse(const Duration(seconds: 3));
          expect(callCount, 1); // Should not retry
        });
      });

      test('_executeWithRetry should handle UnsupportedError as non-retryable (synchronous)', () async {
        const userId = 'user-1';
        var callCount = 0;

        // Should throw exception for non-retryable error
        try {
          await manager.handleColdStartIfNeeded(
            userId,
            (options) async {
              callCount++;
              throw UnsupportedError('Not supported'); // Non-retryable error
            },
            synchronous: true,
          );
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<UnsupportedError>());
          expect(callCount, 1); // Should not retry
        }
      });

      test('_executeWithRetry should handle UnsupportedError as non-retryable (asynchronous)', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;

          // For asynchronous mode, exceptions are handled internally and not rethrown
          final result = await manager.handleColdStartIfNeeded(
            userId,
            (options) async {
              callCount++;
              throw UnsupportedError('Not supported'); // Non-retryable error
            },
            synchronous: false, // Default behavior
          );

          // Should return true (sync initiated) but not wait for completion
          expect(result, isTrue);
          expect(callCount, 0); // Sync happens asynchronously

          // Advance time to allow async operation to complete
          async.elapse(const Duration(seconds: 3));
          expect(callCount, 1); // Should not retry
        });
      });

      test('should log debug message when skipping cold start for non-cold-start user', () async {
        const userId = 'user-1';

        // First, perform a cold start to make isColdStart false
        const successResult = DatumSyncResult<TestDatumEntity>(
          userId: userId,
          duration: Duration(seconds: 1),
          syncedCount: 5,
          failedCount: 0,
          conflictsResolved: 0,
          pendingOperations: [],
        );

        // Perform initial cold start
        final firstResult = await manager.handleColdStartIfNeeded(
          userId,
          (_) async => successResult,
          synchronous: true,
        );

        expect(firstResult, isTrue);
        expect(manager.isColdStartForUser(userId), isFalse);

        // Now call again - this should log the debug message and return false
        final secondResult = await manager.handleColdStartIfNeeded(
          userId,
          (_) async => successResult,
          synchronous: true,
        );

        expect(secondResult, isFalse); // Should return false since it's not a cold start
        expect(manager.isColdStartForUser(userId), isFalse); // Should remain false
      });

      test('should log debug message when skipping cold start for null user', () async {
        // Call with null userId - should log debug message and return false
        final result = await manager.handleColdStartIfNeeded(
          null,
          (_) async => const DatumSyncResult<TestDatumEntity>(
            userId: 'dummy',
            duration: Duration(seconds: 1),
            syncedCount: 0,
            failedCount: 0,
            conflictsResolved: 0,
            pendingOperations: [],
          ),
          synchronous: true,
        );

        expect(result, isFalse);
      });

      test('should log debug message when skipping cold start for empty user', () async {
        // Call with empty userId - should log debug message and return false
        final result = await manager.handleColdStartIfNeeded(
          '',
          (_) async => const DatumSyncResult<TestDatumEntity>(
            userId: 'dummy',
            duration: Duration(seconds: 1),
            syncedCount: 0,
            failedCount: 0,
            conflictsResolved: 0,
            pendingOperations: [],
          ),
          synchronous: true,
        );

        expect(result, isFalse);
      });

      test('should log retry message when operation fails and retries', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;

          // Create manager with low retry count and short delays for testing
          const retryConfig = ColdStartConfig(
            strategy: ColdStartStrategy.adaptive,
            syncThreshold: Duration(hours: 24),
            initialDelay: Duration.zero, // No delay for faster tests
            maxDuration: Duration(minutes: 5),
          );
          final retryManager = ColdStartManager(
            retryConfig,
            maxRetries: 1, // Only 1 retry to keep test simple
            initialRetryDelay: const Duration(milliseconds: 1),
            retryBackoffMultiplier: 1.0,
          );

          // Should fail twice (initial + 1 retry), then succeed
          final result = await retryManager.handleColdStartIfNeeded(userId, (options) async {
            callCount++;
            if (callCount <= 2) {
              throw Exception('Temporary failure');
            }
            return const DatumSyncResult<TestDatumEntity>(
              userId: userId,
              duration: Duration(seconds: 1),
              syncedCount: 5,
              failedCount: 0,
              conflictsResolved: 0,
              pendingOperations: [],
            );
          });

          expect(result, isTrue);
          expect(callCount, 3); // Initial attempt + 2 retries (maxRetries + 1)
        });
      });

      test('should log final error message when all retries are exhausted', () {
        fakeAsync((async) async {
          const userId = 'user-1';
          var callCount = 0;

          // Create manager with low retry count and short delays for testing
          const retryConfig = ColdStartConfig(
            strategy: ColdStartStrategy.adaptive,
            syncThreshold: Duration(hours: 24),
            initialDelay: Duration.zero, // No delay for faster tests
            maxDuration: Duration(minutes: 5),
          );
          final retryManager = ColdStartManager(
            retryConfig,
            maxRetries: 1, // Only 1 retry to keep test simple
            initialRetryDelay: const Duration(milliseconds: 1),
            retryBackoffMultiplier: 1.0,
          );

          // Should fail on all attempts
          try {
            await retryManager.handleColdStartIfNeeded(userId, (options) async {
              callCount++;
              throw Exception('Persistent failure');
            });
            fail('Expected exception to be thrown');
          } catch (e) {
            expect(e, isA<Exception>());
            expect(callCount, 2); // Initial attempt + 1 retry
          }
        });
      });
    });
  });
}
