import 'package:datum/datum.dart';
import 'package:equatable/equatable.dart';

class TestDatumEntity extends DatumEntity with EquatableMixin {
  @override
  final String id;
  @override
  final String userId;
  final String value;

  @override
  final DateTime createdAt;
  @override
  final DateTime modifiedAt;
  @override
  final int version;
  @override
  final bool isDeleted;

  TestDatumEntity({
    required this.id,
    required this.userId,
    required this.value,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        version = version ?? 1,
        isDeleted = isDeleted ?? false;

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      'id': id,
      'userId': userId,
      'value': value,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'version': version,
      'isDeleted': isDeleted,
    };
  }

  factory TestDatumEntity.fromMap(Map<String, dynamic> map) {
    return TestDatumEntity(
      id: map['id'] as String,
      userId: map['userId'] as String,
      value: map['value'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      modifiedAt: DateTime.parse(map['modifiedAt'] as String),
      version: map['version'] as int,
      isDeleted: map['isDeleted'] as bool,
    );
  }

  TestDatumEntity copyWith({
    String? id,
    String? userId,
    String? value,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  }) {
    return TestDatumEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion) {
    if (oldVersion is! TestDatumEntity) return null;
    final changes = <String, dynamic>{};
    if (value != oldVersion.value) {
      changes['value'] = value;
    }
    if (isDeleted != oldVersion.isDeleted) {
      changes['isDeleted'] = isDeleted;
    }
    return changes.isEmpty ? null : changes;
  }

  @override
  List<Object?> get props => [id, userId, value, createdAt, modifiedAt, version, isDeleted];
}
