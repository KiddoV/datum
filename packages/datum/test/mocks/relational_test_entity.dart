import 'package:datum/datum.dart';
import 'package:equatable/equatable.dart';

class RelationalTestEntity with EquatableMixin, DatumEntityMixin, RelationalDatumEntityMixin {
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

  final String name;

  RelationalTestEntity({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.modifiedAt,
    required this.version,
    required this.name,
    this.isDeleted = false,
  });

  factory RelationalTestEntity.create(String id, String userId, String name) {
    final now = DateTime.now();
    return RelationalTestEntity(
      id: id,
      userId: userId,
      createdAt: now,
      modifiedAt: now,
      version: 1,
      name: name,
    );
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'version': version,
      'isDeleted': isDeleted,
      'name': name,
    };
  }

  @override
  RelationalTestEntity copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
    String? name,
  }) {
    return RelationalTestEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, dynamic>? diff(RelationalTestEntity oldVersion) {
    final changes = <String, dynamic>{};
    if (name != oldVersion.name) changes['name'] = name;
    return changes.isEmpty ? null : changes;
  }

  @override
  List<Object?> get props => [id, userId, createdAt, modifiedAt, version, isDeleted, name];

  @override
  Map<String, Relation> get relations => {
        'relatedEntities': const HasMany('relationalTestEntityId'),
      };
}
