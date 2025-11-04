import 'package:datum/source/core/models/datum_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:test/test.dart';

abstract class EquatableBase extends Equatable {
  const EquatableBase();
}

class TestEntity extends EquatableBase with DatumEntityMixin {
  @override
  final String id;
  @override
  final String userId;
  @override
  final DateTime modifiedAt;
  @override
  final DateTime createdAt;
  @override
  final int version;
  @override
  final bool isDeleted;

  TestEntity({
    required this.id,
    required this.userId,
    required this.modifiedAt,
    required this.createdAt,
    required this.version,
    this.isDeleted = false,
  });

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    throw UnimplementedError();
  }

  @override
  TestEntity copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
    String? id,
    String? userId,
    DateTime? createdAt,
  }) {
    return TestEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdAt: createdAt ?? this.createdAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityBase oldVersion) {
    throw UnimplementedError();
  }

  @override
  bool? get stringify => true;
}

void main() {
  group('DatumEntityMixin Equality', () {
    final now = DateTime.now();
    final entity1 = TestEntity(
      id: '1',
      userId: 'user1',
      modifiedAt: now,
      createdAt: now,
      version: 1,
    );

    test('entities with same props are equal', () {
      final entity2 = TestEntity(
        id: '1',
        userId: 'user1',
        modifiedAt: now,
        createdAt: now,
        version: 1,
      );
      expect(entity1, equals(entity2));
      expect(entity1.hashCode, equals(entity2.hashCode));
    });

    test('entities with different id are not equal', () {
      final entity2 = entity1.copyWith(id: '2');
      expect(entity1, isNot(equals(entity2)));
    });

    test('entities with different userId are not equal', () {
      final entity2 = entity1.copyWith(userId: 'user2');
      expect(entity1, isNot(equals(entity2)));
    });

    test('entities with different modifiedAt are not equal', () {
      final entity2 = entity1.copyWith(modifiedAt: now.add(const Duration(seconds: 1)));
      expect(entity1, isNot(equals(entity2)));
    });

    test('entities with different createdAt are not equal', () {
      final entity2 = entity1.copyWith(createdAt: now.add(const Duration(seconds: 1)));
      expect(entity1, isNot(equals(entity2)));
    });

    test('entities with different version are not equal', () {
      final entity2 = entity1.copyWith(version: 2);
      expect(entity1, isNot(equals(entity2)));
    });

    test('entities with different isDeleted are not equal', () {
      final entity2 = entity1.copyWith(isDeleted: true);
      expect(entity1, isNot(equals(entity2)));
    });
  });
}
