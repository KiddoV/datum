import 'package:datum/source/core/models/relational_datum_entity.dart';
import 'package:equatable/equatable.dart';

/// The target for serialization, allowing different fields for local vs. remote.
enum MapTarget {
  /// For serialization to the local database.
  local,

  /// For serialization to the remote data source.
  remote,
}

/// Mixin that provides core Datum entity functionality
/// This can be mixed into any class to add sync capabilities
mixin DatumEntityMixin implements DatumEntityBase {
  @override
  String get id;
  @override
  String get userId;
  @override
  DateTime get modifiedAt;
  @override
  DateTime get createdAt;
  @override
  int get version;
  @override
  bool get isDeleted;

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local});

  /// Creates a copy with updated sync-related fields
  /// Subclasses should override to include their own fields
  @override
  DatumEntityMixin copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  });

  /// Computes the difference between this entity and an old version
  /// Returns null if there are no changes, otherwise returns a map of changed fields
  @override
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);

  @override
  List<Object?> get props => [id, userId, modifiedAt, createdAt, version, isDeleted];
}

/// Mixin for entities with relationships
mixin RelationalDatumEntityMixin on DatumEntityMixin implements RelationalDatumEntity {
  @override
  Map<String, Relation> get relations => {};
}

/// Base sealed class for all Datum entities (for backward compatibility)
sealed class DatumEntityBase extends Equatable {
  const DatumEntityBase();

  String get id;
  String get userId;
  DateTime get modifiedAt;
  DateTime get createdAt;
  int get version;
  bool get isDeleted;

  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local});
  DatumEntityBase copyWith({DateTime? modifiedAt, int? version, bool? isDeleted});
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);

  @override
  List<Object?> get props => [id, userId, modifiedAt, createdAt, version, isDeleted];
}

/// Base class for all entities managed by Datum (without relationships)
abstract class DatumEntity extends DatumEntityBase {
  const DatumEntity();
}

/// Base class for entities with relationships
abstract class RelationalDatumEntity extends DatumEntityBase {
  const RelationalDatumEntity();

  Map<String, Relation> get relations => {};
}
