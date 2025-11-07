// ignore_for_file: library_private_types_in_public_api

import 'package:datum/datum.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks/test_entity.dart';

class MockDatumManager<T extends DatumEntityBase> extends Mock implements DatumManager<T> {}

/// A minimal entity for testing different types.
class Post extends DatumEntity {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime modifiedAt;
  @override
  final int version;

  @override
  final bool isDeleted;

  const Post({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.version,
    this.isDeleted = false,
  });

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) => {
        'id': id,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'version': version,
        'isDeleted': isDeleted,
      };

  @override
  Map<String, dynamic>? diff(DatumEntity oldVersion) => null;
}

void main() {
  late TypeSafeManagerRegistry registry;

  setUp(() {
    registry = TypeSafeManagerRegistry();
  });

  group('TypeSafeManagerRegistry', () {
    late MockDatumManager<TestEntity> mockTestManager;
    late MockDatumManager<Post> mockPostManager;

    setUp(() {
      mockTestManager = MockDatumManager<TestEntity>();
      mockPostManager = MockDatumManager<Post>();
    });

    test('register stores manager for specific type', () {
      // Act
      registry.register<TestEntity>(mockTestManager);

      // Assert
      expect(registry.isRegistered(TestEntity), isTrue);
      expect(registry.keys.contains(TestEntity), isTrue);
    });

    test('get returns correctly typed manager for registered type', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Act
      final retrieved = registry.get<TestEntity>();

      // Assert
      expect(retrieved, same(mockTestManager));
      expect(retrieved, isA<DatumManager<TestEntity>>());
    });

    test('get throws StateError for unregistered type', () {
      // Act & Assert
      expect(
        () => registry.get<TestEntity>(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Entity type TestEntity is not registered'),
        )),
      );
    });

    test('getByType returns correctly typed manager for registered type', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Act
      final retrieved = registry.getByType(TestEntity);

      // Assert
      expect(retrieved, same(mockTestManager));
      expect(retrieved, isA<DatumManager<DatumEntityBase>>());
    });

    test('getByType throws StateError for unregistered type', () {
      // Act & Assert
      expect(
        () => registry.getByType(TestEntity),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Entity type TestEntity is not registered'),
        )),
      );
    });

    test('can register and retrieve multiple different types', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act & Assert
      expect(registry.get<TestEntity>(), same(mockTestManager));
      expect(registry.get<Post>(), same(mockPostManager));
      expect(registry.registeredTypes, containsAll([TestEntity, Post]));
    });

    test('allManagers returns all registered managers as base type', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act
      final allManagers = registry.allManagers.toList();

      // Assert
      expect(allManagers, hasLength(2));
      expect(allManagers, contains(mockTestManager));
      expect(allManagers, contains(mockPostManager));
    });

    test('isEmpty returns true for empty registry', () {
      // Assert
      expect(registry.isEmpty, isTrue);
      expect(registry.isNotEmpty, isFalse);
    });

    test('isEmpty returns false after registering managers', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Assert
      expect(registry.isEmpty, isFalse);
      expect(registry.isNotEmpty, isTrue);
    });

    test('keys returns all registered types', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act
      final keys = registry.keys.toList();

      // Assert
      expect(keys, hasLength(2));
      expect(keys, contains(TestEntity));
      expect(keys, contains(Post));
    });

    test('values returns all registered managers', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act
      final values = registry.values.toList();

      // Assert
      expect(values, hasLength(2));
      expect(values, contains(same(mockTestManager)));
      expect(values, contains(same(mockPostManager)));
    });

    test('entries returns correct key-value pairs', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act
      final entries = registry.entries.toList();

      // Assert
      expect(entries, hasLength(2));
      expect(entries, contains(const TypeMatcher<MapEntry<Type, Object>>()));

      final testEntry = entries.firstWhere((e) => e.key == TestEntity);
      final postEntry = entries.firstWhere((e) => e.key == Post);

      expect(testEntry.value, same(mockTestManager));
      expect(postEntry.value, same(mockPostManager));
    });

    test('containsKey returns true for registered types', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Assert
      expect(registry.containsKey(TestEntity), isTrue);
      expect(registry.containsKey(Post), isFalse);
    });

    test('operator [] returns registered manager', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Act
      final retrieved = registry[TestEntity];

      // Assert
      expect(retrieved, same(mockTestManager));
    });

    test('operator [] returns null for unregistered type', () {
      // Act
      final retrieved = registry[TestEntity];

      // Assert
      expect(retrieved, isNull);
    });

    test('operator []= stores manager', () {
      // Act
      registry[TestEntity] = mockTestManager;

      // Assert
      expect(registry[TestEntity], same(mockTestManager));
      expect(registry.isRegistered(TestEntity), isTrue);
    });

    test('registeredTypes getter returns all registered types', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act
      final types = registry.registeredTypes.toList();

      // Assert
      expect(types, hasLength(2));
      expect(types, contains(TestEntity));
      expect(types, contains(Post));
    });

    test('isRegistered returns true for registered types', () {
      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Assert
      expect(registry.isRegistered(TestEntity), isTrue);
      expect(registry.isRegistered(Post), isFalse);
    });

    test('type safety - cannot assign wrong type to registry', () {
      // This test ensures that the registry maintains type safety
      // by only allowing managers of the correct type to be stored

      // Arrange
      registry.register<TestEntity>(mockTestManager);

      // Act & Assert - This should work
      expect(registry.get<TestEntity>(), same(mockTestManager));

      // The following would be a compile-time error if we tried to do:
      // registry.register<Post>(mockTestManager); // Type mismatch
      // But we can test that different types are stored separately
      registry.register<Post>(mockPostManager);

      expect(registry.get<TestEntity>(), same(mockTestManager));
      expect(registry.get<Post>(), same(mockPostManager));
    });

    test('registry maintains type safety for different entity types', () {
      // This test ensures that the registry correctly handles different types
      // and maintains type safety by only allowing retrieval of the correct types

      // Arrange
      registry.register<TestEntity>(mockTestManager);
      registry.register<Post>(mockPostManager);

      // Act & Assert - Each type should only be retrievable with its exact type
      expect(registry.getByType(TestEntity), same(mockTestManager));
      expect(registry.getByType(Post), same(mockPostManager));

      // Different types should not be retrievable for the wrong type
      expect(registry[TestEntity], same(mockTestManager));
      expect(registry[Post], same(mockPostManager));
    });
  });
}
