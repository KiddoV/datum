import 'dart:async';

import 'package:datum/source/core/cascade_delete.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('CancellationToken', () {
    test('should initialize with isCancelled as false', () {
      final token = CancellationToken();
      expect(token.isCancelled, isFalse);
    });

    test('should call listeners when cancelled', () {
      final token = CancellationToken();
      var listenerCalled = false;

      token.onCancel(() {
        listenerCalled = true;
      });

      token.cancel();

      expect(token.isCancelled, isTrue);
      expect(listenerCalled, isTrue);
    });

    test('should call listeners immediately if already cancelled', () {
      final token = CancellationToken();
      token.cancel();

      var listenerCalled = false;
      token.onCancel(() {
        listenerCalled = true;
      });

      expect(listenerCalled, isTrue);
    });

    test('should handle multiple listeners', () {
      final token = CancellationToken();
      var callCount = 0;

      token.onCancel(() => callCount++);
      token.onCancel(() => callCount++);
      token.onCancel(() => callCount++);

      token.cancel();

      expect(callCount, 3);
    });

    test('should clear listeners after cancellation', () {
      final token = CancellationToken();
      var callCount = 0;

      token.onCancel(() => callCount++);
      token.cancel();

      // Adding another listener after cancellation should call it immediately
      token.onCancel(() => callCount++);

      expect(callCount, 2); // One from cancel, one from immediate call
    });

    test('should handle cancel being called multiple times safely', () {
      final token = CancellationToken();
      var callCount = 0;

      token.onCancel(() => callCount++);
      token.cancel();
      token.cancel(); // Should be safe to call again

      expect(callCount, 1); // Listener should only be called once
      expect(token.isCancelled, isTrue);
    });

    test('should work with async operations', () async {
      final token = CancellationToken();
      final completer = Completer<void>();

      token.onCancel(() {
        completer.complete();
      });

      // Cancel after a delay
      Future.delayed(const Duration(milliseconds: 10), () {
        token.cancel();
      });

      await completer.future;
      expect(token.isCancelled, isTrue);
    });
  });

  group('CascadeProgress', () {
    test('should calculate progressPercentage correctly', () {
      const progress = CascadeProgress(
        completed: 5,
        total: 10,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
        message: 'Processing users',
      );

      expect(progress.progressPercentage, 50.0);
    });

    test('should handle zero total correctly', () {
      const progress = CascadeProgress(
        completed: 0,
        total: 0,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );

      expect(progress.progressPercentage, 0.0);
    });

    test('should handle 100% completion', () {
      const progress = CascadeProgress(
        completed: 10,
        total: 10,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );

      expect(progress.progressPercentage, 100.0);
    });

    test('should handle fractional progress', () {
      const progress = CascadeProgress(
        completed: 1,
        total: 3,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );

      expect(progress.progressPercentage, closeTo(33.33, 0.01));
    });

    test('should store all properties correctly', () {
      const progress = CascadeProgress(
        completed: 7,
        total: 15,
        currentEntityType: 'Post',
        currentEntityId: 'post-123',
        message: 'Deleting related posts',
      );

      expect(progress.completed, 7);
      expect(progress.total, 15);
      expect(progress.currentEntityType, 'Post');
      expect(progress.currentEntityId, 'post-123');
      expect(progress.message, 'Deleting related posts');
    });

    test('should handle null message', () {
      const progress = CascadeProgress(
        completed: 3,
        total: 8,
        currentEntityType: 'Comment',
        currentEntityId: 'comment-456',
      );

      expect(progress.message, isNull);
      expect(progress.progressPercentage, 37.5);
    });
  });

  group('CascadeOptions', () {
    test('should initialize with default values', () {
      const options = CascadeOptions();

      expect(options.dryRun, isFalse);
      expect(options.onProgress, isNull);
      expect(options.cancellationToken, isNull);
      expect(options.timeout, const Duration(seconds: 30));
      expect(options.allowPartialDeletes, isFalse);
    });

    test('should initialize with custom values', () {
      final token = CancellationToken();
      void onProgress(CascadeProgress progress) {}

      final options = CascadeOptions(
        dryRun: true,
        onProgress: onProgress,
        cancellationToken: token,
        timeout: const Duration(minutes: 5),
        allowPartialDeletes: true,
      );

      expect(options.dryRun, isTrue);
      expect(options.onProgress, same(onProgress));
      expect(options.cancellationToken, same(token));
      expect(options.timeout, const Duration(minutes: 5));
      expect(options.allowPartialDeletes, isTrue);
    });

    test('should create copy with updated values', () {
      final originalToken = CancellationToken();
      final newToken = CancellationToken();

      void originalOnProgress(CascadeProgress progress) {}
      void newOnProgress(CascadeProgress progress) {}

      final original = CascadeOptions(
        dryRun: false,
        onProgress: originalOnProgress,
        cancellationToken: originalToken,
        timeout: const Duration(seconds: 30),
        allowPartialDeletes: false,
      );

      final updated = original.copyWith(
        dryRun: true,
        onProgress: newOnProgress,
        cancellationToken: newToken,
        timeout: const Duration(minutes: 2),
        allowPartialDeletes: true,
      );

      expect(updated.dryRun, isTrue);
      expect(updated.onProgress, same(newOnProgress));
      expect(updated.cancellationToken, same(newToken));
      expect(updated.timeout, const Duration(minutes: 2));
      expect(updated.allowPartialDeletes, isTrue);

      // Original should be unchanged
      expect(original.dryRun, isFalse);
      expect(original.onProgress, same(originalOnProgress));
      expect(original.cancellationToken, same(originalToken));
      expect(original.timeout, const Duration(seconds: 30));
      expect(original.allowPartialDeletes, isFalse);
    });

    test('should handle null values in copyWith', () {
      final token = CancellationToken();
      void onProgress(CascadeProgress progress) {}

      final original = CascadeOptions(
        dryRun: true,
        onProgress: onProgress,
        cancellationToken: token,
        timeout: const Duration(minutes: 5),
        allowPartialDeletes: true,
      );

      final updated = original.copyWith(
        dryRun: null,
        onProgress: null,
        cancellationToken: null,
        timeout: null,
        allowPartialDeletes: null,
      );

      // Should keep original values
      expect(updated.dryRun, isTrue);
      expect(updated.onProgress, same(onProgress));
      expect(updated.cancellationToken, same(token));
      expect(updated.timeout, const Duration(minutes: 5));
      expect(updated.allowPartialDeletes, isTrue);
    });

    test('should handle partial updates in copyWith', () {
      const original = CascadeOptions();

      final updated = original.copyWith(
        dryRun: true,
        timeout: const Duration(minutes: 1),
      );

      expect(updated.dryRun, isTrue);
      expect(updated.timeout, const Duration(minutes: 1));
      expect(updated.onProgress, isNull); // Unchanged
      expect(updated.cancellationToken, isNull); // Unchanged
      expect(updated.allowPartialDeletes, isFalse); // Unchanged
    });
  });

  group('CascadeDeleteBuilder', () {
    test('should initialize with provided options', () {
      final token = CancellationToken();
      final options = CascadeOptions(
        dryRun: true,
        cancellationToken: token,
        timeout: const Duration(minutes: 2),
      );

      final builder = CascadeDeleteBuilder(null, 'test-id');
      builder.withOptions(options);

      // We can't directly test the internal options, but we can test the fluent API
      expect(builder, isNotNull);
    });

    test('should support fluent API chaining', () {
      final builder = CascadeDeleteBuilder(null, 'test-id');

      final result = builder.forUser('user-123').dryRun().withTimeout(const Duration(seconds: 60)).allowPartialDeletes();

      expect(result, same(builder));
    });

    test('should validate required user ID', () async {
      final builder = CascadeDeleteBuilder(null, 'test-id');

      expect(
        () async => await builder.execute(),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('User ID must be specified'),
        )),
      );
    });

    test('should configure dry run mode', () {
      final builder = CascadeDeleteBuilder(null, 'test-id');

      final result = builder.dryRun();
      expect(result, same(builder));
    });

    test('should configure cancellation token', () {
      final builder = CascadeDeleteBuilder(null, 'test-id');
      final token = CancellationToken();

      final result = builder.withCancellation(token);
      expect(result, same(builder));
    });

    test('should configure timeout', () {
      final builder = CascadeDeleteBuilder(null, 'test-id');

      final result = builder.withTimeout(const Duration(minutes: 5));
      expect(result, same(builder));
    });

    test('should configure allow partial deletes', () {
      final builder = CascadeDeleteBuilder(null, 'test-id');

      final result = builder.allowPartialDeletes();
      expect(result, same(builder));
    });
  });

  group('CascadeError', () {
    test('should create entity not found error', () {
      final error = CascadeError.entityNotFound('user-123');

      expect(error.code, 'ENTITY_NOT_FOUND');
      expect(error.message, 'Entity with ID "user-123" does not exist');
      expect(error.entityId, 'user-123');
      expect(error.entityType, isNull);
      expect(error.relationName, isNull);
      expect(error.details, isNull);
    });

    test('should create restrict violation error', () {
      final error = CascadeError.restrictViolation('comments', ['comment-1', 'comment-2']);

      expect(error.code, 'RESTRICT_VIOLATION');
      expect(error.message, 'Cannot delete due to restrict constraint on relation "comments"');
      expect(error.relationName, 'comments');
      expect(error.details, {
        'restrictedEntities': ['comment-1', 'comment-2']
      });
      expect(error.entityId, isNull);
      expect(error.entityType, isNull);
    });

    test('should create delete failed error', () {
      final error = CascadeError.deleteFailed('User', 'user-123', 'Database connection failed');

      expect(error.code, 'DELETE_FAILED');
      expect(error.message, 'Failed to delete User "user-123": Database connection failed');
      expect(error.entityType, 'User');
      expect(error.entityId, 'user-123');
      expect(error.details, {'reason': 'Database connection failed'});
      expect(error.relationName, isNull);
    });

    test('should create timeout error', () {
      final error = CascadeError.timeout(const Duration(seconds: 45));

      expect(error.code, 'TIMEOUT');
      expect(error.message, 'Cascade delete operation timed out after 45 seconds');
      expect(error.details, {'timeoutSeconds': 45});
      expect(error.entityType, isNull);
      expect(error.entityId, isNull);
      expect(error.relationName, isNull);
    });

    test('should create cancelled error', () {
      final error = CascadeError.cancelled();

      expect(error.code, 'CANCELLED');
      expect(error.message, 'Cascade delete operation was cancelled');
      expect(error.details, isNull);
      expect(error.entityType, isNull);
      expect(error.entityId, isNull);
      expect(error.relationName, isNull);
    });

    test('should create custom error', () {
      const error = CascadeError(
        code: 'CUSTOM_ERROR',
        message: 'Custom error message',
        details: {'custom': 'data'},
        entityType: 'CustomEntity',
        entityId: 'custom-123',
        relationName: 'customRelation',
      );

      expect(error.code, 'CUSTOM_ERROR');
      expect(error.message, 'Custom error message');
      expect(error.details, {'custom': 'data'});
      expect(error.entityType, 'CustomEntity');
      expect(error.entityId, 'custom-123');
      expect(error.relationName, 'customRelation');
    });
  });

  group('Integration Tests', () {
    test('should integrate CancellationToken with CascadeOptions', () {
      final token = CancellationToken();
      final options = CascadeOptions(cancellationToken: token);

      expect(options.cancellationToken, same(token));

      final newToken = CancellationToken();
      final updatedOptions = options.copyWith(cancellationToken: newToken);

      expect(updatedOptions.cancellationToken, same(newToken));
      expect(options.cancellationToken, same(token)); // Original unchanged
    });

    test('should integrate progress callback with CascadeOptions', () {
      void onProgress(CascadeProgress progress) {}

      final options = CascadeOptions(onProgress: onProgress);
      expect(options.onProgress, same(onProgress));

      void newOnProgress(CascadeProgress progress) {}
      final updatedOptions = options.copyWith(onProgress: newOnProgress);

      expect(updatedOptions.onProgress, same(newOnProgress));
      expect(options.onProgress, same(onProgress)); // Original unchanged
    });

    test('should handle complex CascadeOptions combinations', () {
      final token = CancellationToken();
      // ignore: unused_local_variable
      var progressCallCount = 0;

      void onProgress(CascadeProgress progress) {
        progressCallCount++;
      }

      final options = CascadeOptions(
        dryRun: true,
        onProgress: onProgress,
        cancellationToken: token,
        timeout: const Duration(minutes: 10),
        allowPartialDeletes: true,
      );

      expect(options.dryRun, isTrue);
      expect(options.onProgress, same(onProgress));
      expect(options.cancellationToken, same(token));
      expect(options.timeout, const Duration(minutes: 10));
      expect(options.allowPartialDeletes, isTrue);

      // Test copyWith with mixed updates
      final updatedOptions = options.copyWith(
        dryRun: false,
        timeout: const Duration(seconds: 30),
      );

      expect(updatedOptions.dryRun, isFalse);
      expect(updatedOptions.timeout, const Duration(seconds: 30));
      expect(updatedOptions.onProgress, same(onProgress)); // Unchanged
      expect(updatedOptions.cancellationToken, same(token)); // Unchanged
      expect(updatedOptions.allowPartialDeletes, isTrue); // Unchanged
    });

    test('should handle progress calculation edge cases', () {
      // Test various progress scenarios
      const progress1 = CascadeProgress(
        completed: 0,
        total: 10,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );
      expect(progress1.progressPercentage, 0.0);

      const progress2 = CascadeProgress(
        completed: 10,
        total: 10,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );
      expect(progress2.progressPercentage, 100.0);

      const progress3 = CascadeProgress(
        completed: 7,
        total: 20,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );
      expect(progress3.progressPercentage, 35.0);

      const progress4 = CascadeProgress(
        completed: 1,
        total: 1,
        currentEntityType: 'User',
        currentEntityId: 'user-1',
      );
      expect(progress4.progressPercentage, 100.0);
    });

    test('should handle cancellation token lifecycle', () {
      fakeAsync((async) async {
        final token = CancellationToken();
        var cancelled = false;

        token.onCancel(() {
          cancelled = true;
        });

        // Initially not cancelled
        expect(token.isCancelled, isFalse);
        expect(cancelled, isFalse);

        // Cancel after some time
        async.elapse(const Duration(milliseconds: 100));
        token.cancel();

        expect(token.isCancelled, isTrue);
        expect(cancelled, isTrue);

        // Adding listener after cancellation should call immediately
        var lateListenerCalled = false;
        token.onCancel(() {
          lateListenerCalled = true;
        });

        expect(lateListenerCalled, isTrue);
      });
    });

    test('should handle multiple cancellation tokens independently', () {
      final token1 = CancellationToken();
      final token2 = CancellationToken();

      var token1Cancelled = false;
      var token2Cancelled = false;

      token1.onCancel(() => token1Cancelled = true);
      token2.onCancel(() => token2Cancelled = true);

      // Cancel only token1
      token1.cancel();

      expect(token1.isCancelled, isTrue);
      expect(token2.isCancelled, isFalse);
      expect(token1Cancelled, isTrue);
      expect(token2Cancelled, isFalse);

      // Cancel token2
      token2.cancel();

      expect(token2.isCancelled, isTrue);
      expect(token2Cancelled, isTrue);
    });
  });
}
