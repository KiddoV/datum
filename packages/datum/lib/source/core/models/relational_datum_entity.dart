import 'package:datum/datum.dart';
import 'package:equatable/equatable.dart';

// A sealed class representing the different types of relationships between entities.
sealed class Relation<T extends DatumEntityBase> {
  final RelationalDatumEntity _parent;
  const Relation(this._parent);

  dynamic get value;

  DatumManager<T> getRelatedManager();
}

class BelongsTo<T extends DatumEntityBase> extends Relation<T> {
  final String foreignKey;
  final String localKey;
  T? _value;
  bool _isLoaded = false;

  BelongsTo(super._parent, this.foreignKey, {this.localKey = 'id', T? value}) : _value = value {
    if (value != null) {
      _isLoaded = true;
    }
  }

  @override
  T? get value => _value;

  void set(T? value) {
    _value = value;
    _isLoaded = true;
  }

  Future<T?> fetch() async {
    if (_isLoaded) {
      return _value;
    }
    final foreignKeyValue = _parent.toDatumMap()[foreignKey];
    if (foreignKeyValue == null) {
      return null;
    }
    final manager = getRelatedManager();
    final related = await manager.read(foreignKeyValue, userId: _parent.userId);
    _value = related;
    _isLoaded = true;
    return related;
  }

  @override
  DatumManager<T> getRelatedManager() {
    return Datum.manager<T>();
  }
}

class HasMany<T extends DatumEntityBase> extends Relation<T> {
  final String foreignKey;
  final String localKey;
  List<T>? _value;
  bool _isLoaded = false;

  HasMany(super._parent, this.foreignKey, {this.localKey = 'id', List<T>? value}) : _value = value {
    if (value != null) {
      _isLoaded = true;
    }
  }

  @override
  List<T>? get value => _value;

  void set(List<T>? value) {
    _value = value;
    _isLoaded = true;
  }

  Future<List<T>?> fetch() async {
    if (_isLoaded) {
      return _value;
    }
    final localKeyValue = _parent.toDatumMap()[localKey];
    if (localKeyValue == null) {
      return [];
    }
    final manager = getRelatedManager();
    final related = await manager.query(
      DatumQuery(filters: [Filter(foreignKey, FilterOperator.equals, localKeyValue)]),
      source: DataSource.local,
      userId: _parent.userId,
    );
    _value = related;
    _isLoaded = true;
    return related;
  }

  @override
  DatumManager<T> getRelatedManager() {
    return Datum.manager<T>();
  }
}

class HasOne<T extends DatumEntityBase> extends Relation<T> {
  final String foreignKey;
  final String localKey;
  T? _value;
  bool _isLoaded = false;

  HasOne(super._parent, this.foreignKey, {this.localKey = 'id', T? value}) : _value = value {
    if (value != null) {
      _isLoaded = true;
    }
  }

  @override
  T? get value => _value;

  void set(T? value) {
    _value = value;
    _isLoaded = true;
  }

  Future<T?> fetch() async {
    if (_isLoaded) {
      return _value;
    }
    final localKeyValue = _parent.toDatumMap()[localKey];
    if (localKeyValue == null) {
      return null;
    }
    final manager = getRelatedManager();
    final related = await manager.read(localKeyValue, userId: _parent.userId);
    _value = related;
    _isLoaded = true;
    return related;
  }

  @override
  DatumManager<T> getRelatedManager() {
    return Datum.manager<T>();
  }
}

class ManyToMany<T extends DatumEntityBase> extends Relation<T> {
  final DatumEntityBase pivotEntity;

  final String thisForeignKey;

  final String otherForeignKey;

  final String thisLocalKey;

  final String otherLocalKey;

  List<T>? _value;

  bool _isLoaded = false;

  ManyToMany(
    super._parent,
    this.pivotEntity,
    this.thisForeignKey,
    this.otherForeignKey, {
    this.thisLocalKey = 'id',
    this.otherLocalKey = 'id',
    List<T>? value,
  }) : _value = value {
    if (value != null) {
      _isLoaded = true;
    }
  }

  @override
  List<T>? get value => _value;

  void set(List<T>? value) {
    _value = value;

    _isLoaded = true;
  }

  Future<List<T>?> fetch() async {
    if (_isLoaded) {
      return _value;
    }

    final thisLocalKeyValue = _parent.toDatumMap()[thisLocalKey];
    if (thisLocalKeyValue == null) {
      return [];
    }

    // Get the manager for the pivot entity
    final pivotManager = Datum.managerByType(pivotEntity.runtimeType);

    // Query the pivot entity to find related pivot entities
    final pivotEntities = await pivotManager.query(
      DatumQuery(filters: [Filter(thisForeignKey, FilterOperator.equals, thisLocalKeyValue)]),
      source: DataSource.local,
      userId: _parent.userId,
    );

    // Extract the foreign keys of the related entities from the pivot entities
    final otherForeignKeys = pivotEntities.map((e) => e.toDatumMap()[otherForeignKey]).nonNulls.toList();

    if (otherForeignKeys.isEmpty) {
      _value = [];
      _isLoaded = true;
      return _value;
    }

    // Get the manager for the target entity type
    final relatedManager = getRelatedManager();

    // Query the target entity manager to get the related entities
    final related = await relatedManager.query(
      DatumQuery(filters: [Filter('id', FilterOperator.isIn, otherForeignKeys)]),
      source: DataSource.local,
      userId: _parent.userId,
    );

    _value = related;
    _isLoaded = true;
    return related;
  }

  @override
  DatumManager<T> getRelatedManager() {
    return Datum.manager<T>();
  }
}

/// An extension of [DatumEntity] that includes support for defining relationships.
///
/// ### Understanding Relationships
///
/// The key difference between `BelongsTo`, `HasOne`, and `HasMany` lies in
/// **which entity holds the foreign key**.
///
/// | Aspect                | `BelongsTo`                                     | `HasOne` / `HasMany`                                |
/// | :-------------------- | :---------------------------------------------- | :-------------------------------------------------- |
/// | **Who has the key?**  | **This entity** has the foreign key.            | The **other entity** has the foreign key.           |
/// | **Relationship Role** | The "child" or "dependent" side.                | The "parent" or "owner" side.                       |
/// | **Example**           | A `Post` **belongs to** a `User`.               | A `User` **has one** `Profile` or **has many** `Posts`. |
/// | **Code (`Post`)**     | `relations => {'author': BelongsTo('userId')}`  | (Defined in the `User` class)                       |
/// | **Code (`User`)**     | (Defined in the `Post` class)                   | `relations => {'profile': HasOne('userId')}`        |
///
/// #### `BelongsTo`
/// Use this when the current entity's table contains the foreign key that
/// points to the parent.
///
/// ```dart
/// // In a Post entity:
/// class Post extends RelationalDatumEntity {
///   final String userId; // Foreign key
///   @override
///   Map<String, Relation> get relations => {'author': BelongsTo<User>(this, 'userId')};
/// }
/// ```
///
/// #### `HasOne` / `HasMany`
/// Use these when the *other* entity's table contains the foreign key that
/// points back to this one.
///
/// ```dart
/// // In a User entity:
/// class User extends RelationalDatumEntity {
///   @override
///   Map<String, Relation> get relations => {
///     'profile': HasOne<Profile>(this, 'userId'), // A Profile has a `userId` field
///     'posts': HasMany<Post>(this, 'userId'),   // A Post has a `userId` field
///   };
/// }
/// ```
///
/// ---
///
/// Entities that have relationships with other syncable entities should extend this
/// class instead of [DatumEntity] directly.
abstract class RelationalDatumEntity extends DatumEntity with RelationalDatumEntityMixin {
  /// Creates a `const` [RelationalDatumEntity].
  const RelationalDatumEntity();

  /// Indicates whether this entity supports relationships. Always `true` for this class.
  @override
  bool get isRelational => true;

  /// A map defining all relationships for this entity.
  ///
  /// The key is a descriptive name for the relation, and the value is an
  /// instance of a [Relation] subclass (`BelongsTo`, `HasMany`, `ManyToMany`).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, Relation> get relations => {
  ///   'author': BelongsTo<User>(this, 'userId'),
  /// };
  /// ```
  @override
  Map<String, Relation> get relations => {};

  /// Converts the entity to a `Map<String, dynamic>` for persistence.
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
  RelationalDatumEntity copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  });

  /// Computes the **difference** between the current entity state and an
  /// [oldVersion] of the entity.
  ///
  /// Returns a **`Map<String, dynamic>`** containing only the fields that have
  /// changed, with their new values.
  /// Returns `null` if the entities are identical (no changes detected).
  @override
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);
}

/// A mixin that provides relational functionality for Datum entities.
///
/// Use this mixin when you want to compose Datum's relational capabilities
/// into your own base classes, allowing for a clean and maintainable architecture
/// without extending [RelationalDatumEntity].
///
/// **Important:** Use either [DatumEntityMixin] OR [RelationalDatumEntityMixin],
/// not both. [RelationalDatumEntityMixin] provides all the functionality of
/// [DatumEntityMixin] plus relational capabilities.
///
/// ```dart
/// class MyEntity with RelationalDatumEntityMixin {
///   @override
///   final String id;
///   @override
///   final String userId;
///   @override
///   final DateTime modifiedAt;
///   @override
///   final DateTime createdAt;
///   @override
///   final int version;
///   @override
///   final bool isDeleted;
///
///   // Your custom fields...
///
///   @override
///   Map<String, Relation> get relations => {
///     'author': BelongsTo<User>(this, 'userId'),
///   };
///
///   @override
///   Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
///     // Implementation...
///   }
///
///   @override
///   DatumEntityBase copyWith({DateTime? modifiedAt, int? version, bool? isDeleted}) {
///     // Implementation...
///   }
///
///   @override
///   Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion) {
///     // Implementation...
///   }
/// }
/// ```
mixin RelationalDatumEntityMixin implements Equatable {
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

  /// Computes the **difference** between the current entity state and an
  /// [oldVersion] of the entity.
  Map<String, dynamic>? diff(covariant DatumEntityBase oldVersion);

  /// Indicates whether this entity supports relationships. Always `true` for this mixin.
  bool get isRelational => true;

  /// A map defining all relationships for this entity.
  ///
  /// The key is a descriptive name for the relation, and the value is an
  /// instance of a [Relation] subclass (`BelongsTo`, `HasMany`, `ManyToMany`).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, Relation> get relations => {
  ///   'author': BelongsTo<User>(this, 'userId'),
  /// };
  /// ```
  Map<String, Relation> get relations => {};

  /// Provides the list of properties to be used by the [Equatable] mixin
  /// for value equality checks.
  @override
  List<Object?> get props => [id, userId, modifiedAt, createdAt, version, isDeleted];
}
