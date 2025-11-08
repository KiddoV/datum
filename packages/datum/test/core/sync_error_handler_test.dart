import 'package:datum/datum.dart';
import 'package:test/test.dart';

import '../mocks/test_entity.dart';
import 'package:datum/source/core/engine/sync_error_handler.dart';

void main() {
  group('SyncErrorHandler', () {
    late List<DatumSyncEvent<TestEntity>> capturedEvents;
    late String testUserId;

    setUp(() {
      capturedEvents = [];
      testUserId = 'test-user';
    });

    void eventProcessor(List<DatumSyncEvent<TestEntity>> events) {
      capturedEvents.addAll(events);
    }

    group('handleManagerSyncError', () {
      test('processes events and re-throws SyncExceptionWithEvents original error', () {
        // Arrange
        final originalError = Exception('Original sync error');
        final stackTrace = StackTrace.current;
        final errorEvent = DatumSyncErrorEvent<TestEntity>(
          userId: testUserId,
          error: originalError,
          stackTrace: stackTrace,
        );
        final wrappedError = SyncExceptionWithEvents<TestEntity>(
          originalError,
          stackTrace,
          [errorEvent],
        );

        // Act & Assert
        expect(
          () => SyncErrorHandler.handleManagerSyncError<TestEntity>(
            wrappedError,
            stackTrace,
            [errorEvent],
            eventProcessor,
          ),
          throwsA(same(originalError)),
        );

        // Verify events were processed
        expect(capturedEvents, hasLength(1));
        expect(capturedEvents.first, same(errorEvent));
      });

      test('processes events and re-throws non-wrapped errors', () {
        // Arrange
        final error = Exception('Regular error');
        final stackTrace = StackTrace.current;
        final errorEvent = DatumSyncErrorEvent<TestEntity>(
          userId: testUserId,
          error: error,
          stackTrace: stackTrace,
        );

        // Act & Assert
        expect(
          () => SyncErrorHandler.handleManagerSyncError<TestEntity>(
            error,
            stackTrace,
            [errorEvent],
            eventProcessor,
          ),
          throwsA(same(error)),
        );

        // Verify events were processed
        expect(capturedEvents, hasLength(1));
        expect(capturedEvents.first, same(errorEvent));
      });

      test('handles empty event list', () {
        // Arrange
        final error = Exception('Error with no events');
        final stackTrace = StackTrace.current;

        // Act & Assert
        expect(
          () => SyncErrorHandler.handleManagerSyncError<TestEntity>(
            error,
            stackTrace,
            [], // Empty event list
            eventProcessor,
          ),
          throwsA(same(error)),
        );

        // Verify no events were processed
        expect(capturedEvents, isEmpty);
      });

      test('handles multiple events', () {
        // Arrange
        final error = Exception('Error with multiple events');
        final stackTrace = StackTrace.current;
        final events = [
          DatumSyncStartedEvent<TestEntity>(userId: testUserId, pendingOperations: 1),
          DatumSyncErrorEvent<TestEntity>(
            userId: testUserId,
            error: error,
            stackTrace: stackTrace,
          ),
          DatumSyncCompletedEvent<TestEntity>(
            userId: testUserId,
            result: DatumSyncResult.fromError(testUserId, error),
          ),
        ];

        // Act & Assert
        expect(
          () => SyncErrorHandler.handleManagerSyncError<TestEntity>(
            error,
            stackTrace,
            events,
            eventProcessor,
          ),
          throwsA(same(error)),
        );

        // Verify all events were processed
        expect(capturedEvents, hasLength(3));
        expect(capturedEvents, equals(events));
      });
    });

    group('handleSyncError', () {
      test('returns Future.error with original error for unwrapped errors', () async {
        // Arrange
        final error = Exception('Sync error');
        final stackTrace = StackTrace.current;
        final events = <DatumSyncEvent<TestEntity>>[
          DatumSyncStartedEvent<TestEntity>(userId: testUserId, pendingOperations: 1),
        ];

        // Act & Assert
        await expectLater(
          SyncErrorHandler.handleSyncError<TestEntity>(
            error,
            stackTrace,
            events,
            eventProcessor,
          ),
          throwsA(same(error)),
        );

        // Verify events were processed
        expect(capturedEvents, hasLength(1));
        expect(capturedEvents.first, isA<DatumSyncStartedEvent<TestEntity>>());
      });

      test('returns Future.error with original error for already wrapped errors', () async {
        // Arrange
        final originalError = Exception('Original sync error');
        final stackTrace = StackTrace.current;
        final wrappedError = SyncExceptionWithEvents<TestEntity>(
          originalError,
          stackTrace,
          [DatumSyncErrorEvent<TestEntity>(userId: testUserId, error: originalError, stackTrace: stackTrace)],
        );

        // Act & Assert
        await expectLater(
          SyncErrorHandler.handleSyncError<TestEntity>(
            wrappedError,
            stackTrace,
            [],
            eventProcessor,
          ),
          throwsA(same(originalError)),
        );

        // Verify events from wrapped error were processed
        expect(capturedEvents, hasLength(1));
        expect(capturedEvents.first, isA<DatumSyncErrorEvent<TestEntity>>());
      });
    });

    group('Integration with SyncExceptionWithEvents', () {
      test('manager handler correctly unwraps already wrapped errors', () {
        // Arrange
        final originalError = Exception('Original error');
        final stackTrace = StackTrace.current;
        final wrappedError = SyncExceptionWithEvents<TestEntity>(
          originalError,
          stackTrace,
          [DatumSyncErrorEvent<TestEntity>(userId: testUserId, error: originalError, stackTrace: stackTrace)],
        );

        // Act & Assert
        expect(
          () => SyncErrorHandler.handleManagerSyncError<TestEntity>(
            wrappedError,
            stackTrace,
            [],
            eventProcessor,
          ),
          throwsA(same(originalError)),
        );

        // Verify events from wrapped error were processed
        expect(capturedEvents, hasLength(1));
        expect(capturedEvents.first, isA<DatumSyncErrorEvent<TestEntity>>());
      });

      test('handles different error types correctly', () {
        // Test with various error types
        final errorTypes = [
          Exception('Regular exception'),
          ArgumentError('Argument error'),
          StateError('State error'),
          UnsupportedError('Unsupported error'),
        ];

        for (final error in errorTypes) {
          // Test manager handler with direct error
          expect(
            () => SyncErrorHandler.handleManagerSyncError<TestEntity>(
              error,
              StackTrace.current,
              [],
              eventProcessor,
            ),
            throwsA(same(error)),
          );
        }
      });
    });
  });
}
