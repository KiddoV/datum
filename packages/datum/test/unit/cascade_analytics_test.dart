import 'package:clock/clock.dart';
import 'package:datum/source/core/cascade_delete.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

void main() {
  group('CascadeAnalytics', () {
    test('should calculate total entities processed correctly', () {
      final analytics = CascadeAnalytics(
        totalDuration: const Duration(seconds: 5),
        queriesExecuted: 10,
        relationshipsTraversed: 5,
        entitiesProcessedByType: {String: 3, int: 2},
        entitiesDeletedByType: {String: 2, int: 1},
        restrictViolations: 1,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: false,
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        completedAt: DateTime.now(),
      );

      expect(analytics.totalEntitiesProcessed, 5);
      expect(analytics.totalEntitiesDeleted, 3);
    });

    test('should calculate success rate correctly', () {
      final analytics = CascadeAnalytics(
        totalDuration: const Duration(seconds: 5),
        queriesExecuted: 10,
        relationshipsTraversed: 5,
        entitiesProcessedByType: {String: 4},
        entitiesDeletedByType: {String: 2},
        restrictViolations: 0,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: false,
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        completedAt: DateTime.now(),
      );

      expect(analytics.successRate, 50.0);
    });

    test('should calculate average time per entity correctly', () {
      final analytics = CascadeAnalytics(
        totalDuration: const Duration(seconds: 10),
        queriesExecuted: 10,
        relationshipsTraversed: 5,
        entitiesProcessedByType: {String: 2},
        entitiesDeletedByType: {String: 1},
        restrictViolations: 0,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: false,
        startedAt: DateTime.now().subtract(const Duration(seconds: 10)),
        completedAt: DateTime.now(),
      );

      expect(analytics.averageTimePerEntity, const Duration(seconds: 5));
    });

    test('should handle zero entities processed', () {
      final analytics = CascadeAnalytics(
        totalDuration: const Duration(seconds: 5),
        queriesExecuted: 0,
        relationshipsTraversed: 0,
        entitiesProcessedByType: {},
        entitiesDeletedByType: {},
        restrictViolations: 0,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: false,
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        completedAt: DateTime.now(),
      );

      expect(analytics.successRate, 100.0);
      expect(analytics.averageTimePerEntity, Duration.zero);
    });

    test('should create copy with updated values', () {
      final original = CascadeAnalytics(
        totalDuration: const Duration(seconds: 5),
        queriesExecuted: 10,
        relationshipsTraversed: 5,
        entitiesProcessedByType: {String: 3},
        entitiesDeletedByType: {String: 2},
        restrictViolations: 1,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: false,
        startedAt: DateTime.now().subtract(const Duration(seconds: 5)),
        completedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        queriesExecuted: 15,
        restrictViolations: 0,
      );

      expect(updated.queriesExecuted, 15);
      expect(updated.restrictViolations, 0);
      expect(updated.totalDuration, original.totalDuration);
    });

    test('should provide readable string representation', () {
      final analytics = CascadeAnalytics(
        totalDuration: const Duration(seconds: 5),
        queriesExecuted: 10,
        relationshipsTraversed: 5,
        entitiesProcessedByType: {String: 3, int: 2},
        entitiesDeletedByType: {String: 2, int: 1},
        restrictViolations: 1,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: false,
        startedAt: DateTime(2023, 1, 1, 12, 0, 0),
        completedAt: DateTime(2023, 1, 1, 12, 0, 5),
      );

      final string = analytics.toString();

      expect(string, startsWith('CascadeAnalytics('));
      expect(string, endsWith(')'));
      expect(string, contains('totalDuration: 0:00:05.000000'));
      expect(string, contains('queriesExecuted: 10'));
      expect(string, contains('relationshipsTraversed: 5'));
      expect(string, contains('totalEntitiesProcessed: 5'));
      expect(string, contains('totalEntitiesDeleted: 3'));
      expect(string, contains('restrictViolations: 1'));
      expect(string, contains('setNullOperations: 0'));
      expect(string, contains('errorsEncountered: 0'));
      expect(string, contains('successRate: 60.0%'));
      expect(string, contains('wasDryRun: false'));
    });

    test('should handle empty analytics in toString', () {
      final analytics = CascadeAnalytics(
        totalDuration: Duration.zero,
        queriesExecuted: 0,
        relationshipsTraversed: 0,
        entitiesProcessedByType: {},
        entitiesDeletedByType: {},
        restrictViolations: 0,
        setNullOperations: 0,
        errorsEncountered: 0,
        wasDryRun: true,
        startedAt: DateTime(2023, 1, 1, 12, 0, 0),
        completedAt: DateTime(2023, 1, 1, 12, 0, 0),
      );

      final string = analytics.toString();

      expect(string, contains('totalDuration: 0:00:00.000000'));
      expect(string, contains('queriesExecuted: 0'));
      expect(string, contains('relationshipsTraversed: 0'));
      expect(string, contains('totalEntitiesProcessed: 0'));
      expect(string, contains('totalEntitiesDeleted: 0'));
      expect(string, contains('restrictViolations: 0'));
      expect(string, contains('setNullOperations: 0'));
      expect(string, contains('errorsEncountered: 0'));
      expect(string, contains('successRate: 100.0%'));
      expect(string, contains('wasDryRun: true'));
    });
  });

  group('CascadeAnalyticsBuilder', () {
    test('should build analytics correctly', () {
      fakeAsync((async) async {
        final builder = CascadeAnalyticsBuilder();
        final startTime = clock.now();

        builder.startOperation(dryRun: true);
        builder.recordQueryExecuted();
        builder.recordQueryExecuted();
        builder.recordRelationshipTraversed();
        builder.recordEntityProcessed(String);
        builder.recordEntityProcessed(int);
        builder.recordEntityDeleted(String);
        builder.recordRestrictViolation();
        builder.recordSetNullOperation();
        builder.recordError();

        // Simulate some time passing
        async.elapse(const Duration(milliseconds: 10));
        builder.completeOperation();

        final analytics = builder.build();

        expect(analytics.queriesExecuted, 2);
        expect(analytics.relationshipsTraversed, 1);
        expect(analytics.entitiesProcessedByType[String], 1);
        expect(analytics.entitiesProcessedByType[int], 1);
        expect(analytics.entitiesDeletedByType[String], 1);
        expect(analytics.restrictViolations, 1);
        expect(analytics.setNullOperations, 1);
        expect(analytics.errorsEncountered, 1);
        expect(analytics.wasDryRun, true);
        expect(analytics.startedAt.isAfter(startTime.subtract(const Duration(seconds: 1))), true);
        expect(analytics.completedAt.isAfter(analytics.startedAt), true);
      });
    });

    test('should handle operations without explicit start/complete', () {
      final builder = CascadeAnalyticsBuilder();

      builder.recordQueryExecuted();
      final analytics = builder.build();

      expect(analytics.queriesExecuted, 1);
      expect(analytics.wasDryRun, false);
      expect(analytics.totalDuration, Duration.zero);
    });
  });
}
