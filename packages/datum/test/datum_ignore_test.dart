import 'package:test/test.dart';
import 'package:datum/datum.dart';
import 'package:datum_generator/datum_generator.dart';

part 'datum_ignore_test.g.dart';

@DatumSerializable()
class IgnoredTestEntity extends DatumEntity {
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

  @DatumIgnore(copyWith: true)
  final String ignoreFromCopyWith;

  @DatumIgnore(equality: true)
  final String ignoreFromEquality;

  @DatumIgnore(fromMap: false, toMap: false)
  final String includeInSerialization;

  const IgnoredTestEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.version,
    required this.isDeleted,
    this.ignoreFromCopyWith = 'default',
    this.ignoreFromEquality = 'default',
    required this.includeInSerialization,
  });

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return datumToMap(target: target);
  }

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) {
    return datumDiff(oldVersion);
  }

  factory IgnoredTestEntity.fromMap(Map<String, dynamic> map) {
    return _$IgnoredTestEntityFromMap(map);
  }
}

@DatumSerializable()
class LegacyIgnoredEntity extends DatumEntity {
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

  @DatumIgnore()
  final String ignored;

  const LegacyIgnoredEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.version,
    required this.isDeleted,
    this.ignored = 'default',
  });

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return datumToMap(target: target);
  }

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) {
    return datumDiff(oldVersion);
  }

  factory LegacyIgnoredEntity.fromMap(Map<String, dynamic> map) {
    return _$LegacyIgnoredEntityFromMap(map);
  }
}

void main() {
  group('DatumIgnore Enhancement', () {
    test(
      'copyWith flag: true excludes from copyWith parameters but keeps in constructor',
      () {
        final entity = IgnoredTestEntity(
          id: '1',
          userId: 'u1',
          createdAt: DateTime.now(),
          modifiedAt: DateTime.now(),
          version: 1,
          isDeleted: false,
          ignoreFromCopyWith: 'keep-me',
          ignoreFromEquality: 'eq',
          includeInSerialization: 'serial',
        );

        // ignoreFromCopyWith should not be changeable via copyWithAll
        // so we check if the updated entity still has the original value
        // despite we have no way to even pass a new value to copyWithAll.
        final updated = entity.copyWithAll(includeInSerialization: 'new');
        expect(updated.ignoreFromCopyWith, equals('keep-me'));
      },
    );

    test('equality flag: true excludes from operator ==', () {
      final now = DateTime.now();
      final e1 = IgnoredTestEntity(
        id: '1',
        userId: 'u1',
        createdAt: now,
        modifiedAt: now,
        version: 1,
        isDeleted: false,
        ignoreFromCopyWith: 'x',
        ignoreFromEquality: 'val1',
        includeInSerialization: 's',
      );

      final e2 = IgnoredTestEntity(
        id: '1',
        userId: 'u1',
        createdAt: now,
        modifiedAt: now,
        version: 1,
        isDeleted: false,
        ignoreFromCopyWith: 'x',
        ignoreFromEquality: 'val2', // Different, but ignored
        includeInSerialization: 's',
      );

      expect(e1.datumEquals(e2), isTrue);
    });

    test('toMap/fromMap flags: true (default) excludes from serialization', () {
      final entity = IgnoredTestEntity(
        id: '1',
        userId: 'u1',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        version: 1,
        isDeleted: false,
        ignoreFromCopyWith: 'ignored1',
        ignoreFromEquality: 'ignored2',
        includeInSerialization: 'included',
      );

      final map = entity.toDatumMap();
      expect(map.containsKey('ignore_from_copy_with'), isFalse);
      expect(map.containsKey('ignore_from_equality'), isFalse);
      expect(map['include_in_serialization'], equals('included'));
    });

    test('Legacy @DatumIgnore() backward compatibility', () {
      final entity = LegacyIgnoredEntity(
        id: '1',
        userId: 'u1',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        version: 1,
        isDeleted: false,
        ignored: 'secret',
      );

      final map = entity.toDatumMap();
      expect(map.containsKey('ignored'), isFalse);

      // Should still be in copyWith parameter list (default is copyWith: false)
      final updated = entity.copyWithAll(ignored: 'new-secret');
      expect(updated.ignored, equals('new-secret'));
    });
  });
}
