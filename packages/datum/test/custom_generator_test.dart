import 'package:datum/datum.dart';
import 'package:datum_generator/annotations.dart';
import 'package:test/test.dart';

part 'custom_generator_test.g.dart';

class WrappedValue {
  final String value;
  WrappedValue(this.value);

  @override
  bool operator ==(Object other) => identical(this, other) || other is WrappedValue && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'WrappedValue($value)';

  Map<String, dynamic> toJson() => {'val': value};
  static WrappedValue fromJson(Map<String, dynamic> json) => WrappedValue(json['val'] as String);
}

@DatumSerializable()
class CustomGeneratorTestEntity extends DatumEntity {
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

  @DatumField(
    fromGenerator: 'WrappedValue.fromJson(%DATA_PROPERTY% as Map<String, dynamic>)',
    toGenerator: '%DATA_PROPERTY%.toJson()',
  )
  final WrappedValue wrapped;

  const CustomGeneratorTestEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.version,
    required this.isDeleted,
    required this.wrapped,
  });

  factory CustomGeneratorTestEntity.fromMap(Map<String, dynamic> map) => _$CustomGeneratorTestEntityFromMap(map);

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) => datumToMap(target: target);

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) => datumDiff(oldVersion);
}

void main() {
  group('Custom Generator', () {
    test('should utilize fromGenerator and toGenerator', () {
      final now = DateTime.now();
      final entity = CustomGeneratorTestEntity(
        id: '1',
        userId: 'u1',
        createdAt: now,
        modifiedAt: now,
        version: 1,
        isDeleted: false,
        wrapped: WrappedValue('test-val'),
      );

      final map = entity.toDatumMap();
      expect(map['wrapped'], equals({'val': 'test-val'}));

      final fromMap = CustomGeneratorTestEntity.fromMap(map);
      expect(fromMap.wrapped, equals(WrappedValue('test-val')));
      expect(fromMap.id, equals('1'));
    });
  });
}
