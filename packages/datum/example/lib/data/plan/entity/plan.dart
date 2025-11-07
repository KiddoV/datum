// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:datum/datum.dart';

class Plan extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final String name;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const Plan({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Map<String, Relation> get relations => {};

  @override
  Plan copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    return Plan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) {
    return null;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'version': version,
    };
  }
}
