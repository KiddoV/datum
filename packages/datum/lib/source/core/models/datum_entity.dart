
import 'package:equatable/equatable.dart';

/// The **target for serialization**, allowing different fields to be included
/// or excluded based on whether the data is going to a **local** or **remote**
/// data source.
enum MapTarget {
  /// Used for serialization when saving the entity to the **local database**.
  /// May exclude fields only relevant for remote sync.
  local,

  /// Used for serialization when sending the entity to the **remote server**
  /// or data source. Typically includes all necessary sync metadata.
  remote,
}

/// The **base sealed class** for all entities managed by the Datum framework.
///
/// This class enforces the core sync and identification fields. It extends
/// [Equatable] for easy value comparison.
sealed class DatumEntityBase extends Equatable {
  const DatumEntityBase();

  /// A **unique identifier** for the entity.
  String get id;

  /// The ID of the user who owns or created this entity.
  String get userId;

  /// The **timestamp** of the last time this entity was modified.
  DateTime get modifiedAt;

  /// The **timestamp** of when this entity was first created.
  DateTime get createdAt;

  /// A **sequential integer** used for optimistic concurrency and tracking
  /// changes.
  int get version;

  /// A flag indicating if this entity has been locally marked for **deletion**.
  bool get isDeleted;

  /// Converts the entity to a `Map<String, dynamic>` for persistence.
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local});

  /// Creates a **new instance** of the entity with updated values.
  DatumEntityBase copyWith({DateTime? modifiedAt, int? version, bool? isDeleted});

  /// Computes the **difference** between the current entity state and an
  /// [oldVersion] of the entity.
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);

  /// Indicates whether this entity supports relationships.
  bool get isRelational => false;

  /// Provides the list of properties to be used by the [Equatable] mixin
  /// for value equality checks.
  @override
  List<Object?> get props => [id, userId, modifiedAt, createdAt, version, isDeleted];
}

/// The **base abstract class** for all entities managed by Datum **without**
/// built-in relationship handling.
///
/// Concrete entity classes should typically extend this class if they do
/// not manage relations to other Datum entities.
abstract class DatumEntity extends DatumEntityBase {
  const DatumEntity();
}


