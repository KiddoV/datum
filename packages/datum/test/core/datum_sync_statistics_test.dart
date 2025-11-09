import 'package:datum/source/core/events/datum_sync_statistics.dart';
import 'package:test/test.dart';

void main() {
  group('DatumSyncStatistics', () {
    test('constructor provides correct default values', () {
      // Arrange & Act
      const stats = DatumSyncStatistics();

      // Assert
      expect(stats.totalSyncs, 0);
      expect(stats.successfulSyncs, 0);
      expect(stats.failedSyncs, 0);
      expect(stats.conflictsDetected, 0);
      expect(stats.conflictsAutoResolved, 0);
      expect(stats.conflictsUserResolved, 0);
      expect(stats.averageDuration, Duration.zero);
      expect(stats.totalSyncDuration, Duration.zero);
    });

    test('constructor sets all fields correctly', () {
      // Arrange & Act
      const stats = DatumSyncStatistics(
        totalSyncs: 10,
        successfulSyncs: 8,
        failedSyncs: 2,
        conflictsDetected: 3,
        conflictsAutoResolved: 2,
        conflictsUserResolved: 1,
        averageDuration: Duration(seconds: 5),
        totalSyncDuration: Duration(seconds: 50),
      );

      // Assert
      expect(stats.totalSyncs, 10);
      expect(stats.successfulSyncs, 8);
      expect(stats.failedSyncs, 2);
      expect(stats.conflictsDetected, 3);
      expect(stats.conflictsAutoResolved, 2);
      expect(stats.conflictsUserResolved, 1);
      expect(stats.averageDuration, const Duration(seconds: 5));
      expect(stats.totalSyncDuration, const Duration(seconds: 50));
    });

    test('copyWith creates a new instance with updated values', () {
      // Arrange
      const original = DatumSyncStatistics(totalSyncs: 10, successfulSyncs: 5);

      // Act
      final copied = original.copyWith(successfulSyncs: 6, failedSyncs: 1);

      // Assert
      expect(copied.totalSyncs, 10); // Unchanged
      expect(copied.successfulSyncs, 6); // Changed
      expect(copied.failedSyncs, 1); // Changed
    });

    test('copyWith with successfulSyncs parameter updates only successfulSyncs', () {
      // Arrange
      const original = DatumSyncStatistics(
        totalSyncs: 10,
        successfulSyncs: 5,
        failedSyncs: 2,
      );

      // Act
      final copied = original.copyWith(successfulSyncs: 8);

      // Assert
      expect(copied.totalSyncs, 10); // Unchanged
      expect(copied.successfulSyncs, 8); // Changed
      expect(copied.failedSyncs, 2); // Unchanged
      expect(copied.conflictsDetected, 0); // Unchanged
    });

    test('copyWith with failedSyncs parameter updates only failedSyncs', () {
      // Arrange
      const original = DatumSyncStatistics(
        totalSyncs: 10,
        successfulSyncs: 8,
        failedSyncs: 1,
      );

      // Act
      final copied = original.copyWith(failedSyncs: 3);

      // Assert
      expect(copied.totalSyncs, 10); // Unchanged
      expect(copied.successfulSyncs, 8); // Unchanged
      expect(copied.failedSyncs, 3); // Changed
      expect(copied.conflictsDetected, 0); // Unchanged
    });

    test('copyWith with multiple parameters updates all specified fields', () {
      // Arrange
      const original = DatumSyncStatistics(
        totalSyncs: 5,
        successfulSyncs: 3,
        failedSyncs: 1,
        conflictsDetected: 2,
        conflictsAutoResolved: 1,
        conflictsUserResolved: 0,
        averageDuration: Duration(seconds: 10),
        totalSyncDuration: Duration(seconds: 50),
      );

      // Act
      final copied = original.copyWith(
        successfulSyncs: 4,
        failedSyncs: 2,
        conflictsDetected: 5,
        conflictsAutoResolved: 3,
        conflictsUserResolved: 2,
        averageDuration: const Duration(seconds: 15),
        totalSyncDuration: const Duration(seconds: 75),
      );

      // Assert
      expect(copied.totalSyncs, 5); // Unchanged
      expect(copied.successfulSyncs, 4); // Changed
      expect(copied.failedSyncs, 2); // Changed
      expect(copied.conflictsDetected, 5); // Changed
      expect(copied.conflictsAutoResolved, 3); // Changed
      expect(copied.conflictsUserResolved, 2); // Changed
      expect(copied.averageDuration, const Duration(seconds: 15)); // Changed
      expect(copied.totalSyncDuration, const Duration(seconds: 75)); // Changed
    });

    test('copyWith with null values keeps original values', () {
      // Arrange
      const original = DatumSyncStatistics(
        totalSyncs: 10,
        successfulSyncs: 7,
        failedSyncs: 3,
        conflictsDetected: 5,
      );

      // Act
      final copied = original.copyWith(
        successfulSyncs: null,
        failedSyncs: null,
        conflictsDetected: null,
      );

      // Assert
      expect(copied.totalSyncs, 10); // Unchanged
      expect(copied.successfulSyncs, 7); // Unchanged (null keeps original)
      expect(copied.failedSyncs, 3); // Unchanged (null keeps original)
      expect(copied.conflictsDetected, 5); // Unchanged (null keeps original)
    });

    test('copyWith with totalSyncs parameter updates only totalSyncs', () {
      // Arrange
      const original = DatumSyncStatistics(
        totalSyncs: 5,
        successfulSyncs: 3,
        failedSyncs: 2,
      );

      // Act
      final copied = original.copyWith(totalSyncs: 10);

      // Assert
      expect(copied.totalSyncs, 10); // Changed
      expect(copied.successfulSyncs, 3); // Unchanged
      expect(copied.failedSyncs, 2); // Unchanged
    });

    test('copyWith with conflict parameters updates only conflict fields', () {
      // Arrange
      const original = DatumSyncStatistics(
        conflictsDetected: 10,
        conflictsAutoResolved: 7,
        conflictsUserResolved: 3,
      );

      // Act
      final copied = original.copyWith(
        conflictsDetected: 15,
        conflictsAutoResolved: 10,
        conflictsUserResolved: 5,
      );

      // Assert
      expect(copied.conflictsDetected, 15); // Changed
      expect(copied.conflictsAutoResolved, 10); // Changed
      expect(copied.conflictsUserResolved, 5); // Changed
      expect(copied.totalSyncs, 0); // Unchanged
      expect(copied.successfulSyncs, 0); // Unchanged
      expect(copied.failedSyncs, 0); // Unchanged
    });

    test('copyWith with duration parameters updates only duration fields', () {
      // Arrange
      const original = DatumSyncStatistics(
        averageDuration: Duration(seconds: 10),
        totalSyncDuration: Duration(seconds: 100),
      );

      // Act
      final copied = original.copyWith(
        averageDuration: const Duration(seconds: 15),
        totalSyncDuration: const Duration(seconds: 150),
      );

      // Assert
      expect(copied.averageDuration, const Duration(seconds: 15)); // Changed
      expect(copied.totalSyncDuration, const Duration(seconds: 150)); // Changed
      expect(copied.totalSyncs, 0); // Unchanged
      expect(copied.successfulSyncs, 0); // Unchanged
    });

    test('supports value equality', () {
      // Arrange
      const stats1 = DatumSyncStatistics(
        totalSyncs: 10,
        successfulSyncs: 8,
        failedSyncs: 2,
      );
      const stats2 = DatumSyncStatistics(
        totalSyncs: 10,
        successfulSyncs: 8,
        failedSyncs: 2,
      );
      const stats3 = DatumSyncStatistics(
        totalSyncs: 11, // Different
        successfulSyncs: 8,
        failedSyncs: 2,
      );

      // Assert
      expect(stats1, equals(stats2));
      expect(stats1.hashCode, equals(stats2.hashCode));
      expect(stats1, isNot(equals(stats3)));
    });

    test('props list is correct for equality check', () {
      const stats = DatumSyncStatistics();
      expect(stats.props, [0, 0, 0, 0, 0, 0, Duration.zero, Duration.zero]);
    });
  });
}
