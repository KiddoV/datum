import 'package:datum/datum.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/test_entity.dart';

class MockConflictResolver<T extends DatumEntityInterface> extends Mock implements DatumConflictResolver<T> {}

class AnotherTestEntity extends TestEntity {
  AnotherTestEntity({required super.id, required super.userId})
      : super(
          name: 'Another',
          value: 0,
          modifiedAt: DateTime.now(),
          createdAt: DateTime.now(),
          version: 1,
        );
}

void main() {
  group('DatumSyncOptions', () {
    test('constructor provides correct default values', () {
      const options = DatumSyncOptions();

      expect(options.includeDeletes, isTrue);
      expect(options.resolveConflicts, isTrue);
      expect(options.forceFullSync, isFalse);
      expect(options.overrideBatchSize, isNull);
      expect(options.timeout, isNull);
      expect(options.direction, isNull);
      expect(options.conflictResolver, isNull);
      expect(options.query, const DatumQuery());
    });

    test('copyWith creates a new instance with updated values', () {
      // Arrange
      final resolver = MockConflictResolver<TestEntity>();
      const customQuery = DatumQuery(filters: [Filter('status', FilterOperator.equals, 'active')]);
      const originalOptions = DatumSyncOptions<TestEntity>(
        includeDeletes: true,
        forceFullSync: false,
        direction: SyncDirection.pushThenPull,
      );

      // Act
      final newOptions = originalOptions.copyWith(
        forceFullSync: true,
        direction: SyncDirection.pullOnly,
        conflictResolver: resolver,
        query: customQuery,
      );

      // Assert
      expect(newOptions.forceFullSync, isTrue);
      expect(newOptions.direction, SyncDirection.pullOnly);
      expect(newOptions.conflictResolver, resolver);
      expect(newOptions.query, customQuery);
      // Check that other values are unchanged
      expect(newOptions.includeDeletes, originalOptions.includeDeletes);
    });

    test(
      'copyWith creates an identical copy when no arguments are provided',
      () {
        // Arrange
        final resolver = MockConflictResolver<TestEntity>();
        final originalOptions = DatumSyncOptions<TestEntity>(
          includeDeletes: false,
          direction: SyncDirection.pullThenPush,
          conflictResolver: resolver,
        );

        // Act
        final copiedOptions = originalOptions.copyWith();

        // Assert
        expect(copiedOptions, originalOptions);
        expect(copiedOptions.hashCode, originalOptions.hashCode);
      },
    );

    test('copyWith with query parameter updates query field correctly', () {
      // Arrange
      const originalQuery = DatumQuery();
      const customQuery = DatumQuery(filters: [Filter('status', FilterOperator.equals, 'active')]);
      const originalOptions = DatumSyncOptions<TestEntity>(
        query: originalQuery,
      );

      // Act
      final newOptions = originalOptions.copyWith(query: customQuery);

      // Assert
      expect(newOptions.query, customQuery);
      expect(newOptions.query, isNot(originalQuery));
    });

    test('equality considers query field', () {
      // Arrange
      const query1 = DatumQuery(filters: [Filter('status', FilterOperator.equals, 'active')]);
      const query2 = DatumQuery(filters: [Filter('status', FilterOperator.equals, 'inactive')]);

      const options1 = DatumSyncOptions<TestEntity>(query: query1);
      const options2 = DatumSyncOptions<TestEntity>(query: query1);
      const options3 = DatumSyncOptions<TestEntity>(query: query2);

      // Assert
      expect(options1, options2);
      expect(options1, isNot(options3));
      expect(options1.hashCode, options2.hashCode);
      expect(options1.hashCode, isNot(options3.hashCode));
    });
  });
}
