import 'package:datum/source/core/models/relational_datum_entity.dart';
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

  /// Converts the entity to a **Map<String, dynamic>** for persistence.
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local});

  /// Creates a **new instance** of the entity with updated values.
  DatumEntityBase copyWith({DateTime? modifiedAt, int? version, bool? isDeleted});

  /// Computes the **difference** between the current entity state and an
  /// [oldVersion] of the entity.
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);

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

/// The **base abstract class** for entities that **manage relationships**
/// to other [DatumEntityBase] entities.
///
/// Concrete entity classes should extend this class if they contain
/// relationship definitions.
abstract class RelationalDatumEntity extends DatumEntityBase {
  const RelationalDatumEntity();

  /// A **map of relationship definitions**.
  Map<String, Relation> get relations => {};
}

/// A **mixin** that provides **core Datum entity functionality**
/// for synchronization and versioning.
///
/// Any class that needs to be tracked, versioned, and synced by the
/// Datum framework should use this mixin.
///
/// It enforces the presence of standard sync metadata fields like
/// [id], [userId], [modifiedAt], [version], and [isDeleted].
mixin DatumEntityMixin implements DatumEntityBase {
  /// A **unique identifier** for the entity.
  @override
  String get id;

  /// The ID of the user who owns or created this entity.
  @override
  String get userId;

  /// The **timestamp** of the last time this entity was modified.
  /// This is a crucial field for determining sync conflicts and order.
  @override
  DateTime get modifiedAt;

  /// The **timestamp** of when this entity was first created.
  @override
  DateTime get createdAt;

  /// A **sequential integer** used for optimistic concurrency and tracking
  /// changes. It increments with every modification.
  @override
  int get version;

  /// A flag indicating if this entity has been locally marked for **deletion**.
  @override
  bool get isDeleted;

  /// Converts the entity to a **Map<String, dynamic>** for persistence.
  ///
  /// The optional [target] parameter dictates which set of fields to include,
  /// e.g., excluding heavy local-only fields for remote sync.
  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local});

  /// Creates a **new instance** of the entity with updated values.
  ///
  /// This method is primarily used to update the sync-related fields
  /// like [modifiedAt], [version], and [isDeleted] during a sync operation.
  ///
  /// **Subclasses must override** this method to include their own fields
  /// in the copy process.
  @override
  DatumEntityMixin copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  });

  /// Computes the **difference** between the current entity state and an
  /// [oldVersion] of the entity.
  ///
  /// Returns a **Map<String, dynamic>** containing only the fields that have
  /// changed, with their new values.
  /// Returns `null` if the entities are identical (no changes detected).
  @override
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);

  /// Provides the list of properties to be used by the [Equatable] mixin
  /// for value equality checks.
  @override
  List<Object?> get props => [id, userId, modifiedAt, createdAt, version, isDeleted];
}

/// A **mixin** for entities that manage **relationships** to other
/// [DatumEntityBase] entities.
///
/// This should be mixed into any class that uses [DatumEntityMixin] and
/// also defines relations, such as 'one-to-many' or 'many-to-many'.
mixin RelationalDatumEntityMixin on DatumEntityMixin implements RelationalDatumEntity {
  /// A **map of relationship definitions**.
  ///
  /// The key is the name of the relation (e.g., 'tasks'), and the value
  /// is a [Relation] object defining the target type and keys.
  @override
  Map<String, Relation> get relations => {};
}
