---
title: Entity Define
---
First, you need to define your data models by extending either `DatumEntity` or `RelationalDatumEntity`. These classes provide the core structure for your entities, including properties like `id`, `userId`, `createdAt`, `modifiedAt`, `isDeleted`, and `version`.

## Entity Types

### DatumEntity (Non-Relational)

Use `DatumEntity` for entities that don't need relationships with other entities. This is the base class for simple data models.

### RelationalDatumEntity (Relational)

Use `RelationalDatumEntity` for entities that have relationships with other entities. This extends `DatumEntity` and adds support for defining and managing relationships.

## Next Steps

Now that you've defined your entities, you can:

1. **[Set up adapters](guides/local_adapter_implement)**: Implement local and remote adapters for your entities
2. **[Initialize Datum](guides/initialization)**: Configure and initialize the Datum system
3. **[Work with relationships](guides/relationships)**: Learn about defining and using entity relationships (if using `RelationalDatumEntity`)
4. **[Query data](guides/querying)**: Learn how to query and filter your data

## Example: Non-Relational Entity

Below is an example of a `Task` entity using `DatumEntity` (non-relational). Your entities will likely have more specific fields relevant to your application.

```dart
import 'package:datum/datum.dart';
import 'dart:convert'; // For json.encode and json.decode
import 'dart:math'; // For Random
import 'package:supabase_flutter/supabase_flutter.dart'; // Example for userId

class Task extends DatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final String title;

  final String? description;

  final bool isCompleted;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    // Determine if any field is being changed.
    final bool hasChanges = id != null ||
        userId != null ||
        title != null ||
        description != null ||
        isCompleted != null ||
        createdAt != null ||
        modifiedAt != null ||
        isDeleted != null;

    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      // Always update modifiedAt if there are changes.
      modifiedAt: (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      // If a version is explicitly passed, use it. Otherwise, increment if there are changes.
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntity oldVersion) {
    if (oldVersion is! Task) return toDatumMap();

    final diff = <String, dynamic>{};

    if (title != oldVersion.title) {
      diff['title'] = title;
    }
    if (description != oldVersion.description) {
      diff['description'] = description;
    }
    if (isCompleted != oldVersion.isCompleted) {
      diff['isCompleted'] = isCompleted;
    }
    if (isDeleted != oldVersion.isDeleted) {
      diff['isDeleted'] = isDeleted;
    }

    // Only include modification details if there are other changes
    if (diff.isNotEmpty) {
      diff['modifiedAt'] = modifiedAt.toIso8601String();
      diff['version'] = version;
    }

    return diff.isEmpty ? null : diff;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'isDeleted': isDeleted,
      'version': version,
    };

    if (target == MapTarget.remote) {
      map['createdAt'] = createdAt.toIso8601String();
      map['modifiedAt'] = modifiedAt.toIso8601String();
    } else {
      map['createdAt'] = createdAt.millisecondsSinceEpoch;
      map['modifiedAt'] = modifiedAt.millisecondsSinceEpoch;
    }
    return map;
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: (map['id'] ?? '') as String,
      userId: (map['userId'] ?? map['user_id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: map['description'] as String?,
      isCompleted: (map['isCompleted'] ?? map['is_completed'] ?? false) as bool,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      modifiedAt: _parseDate(map['modifiedAt'] ?? map['modified_at']),
      isDeleted: (map['isDeleted'] ?? map['is_deleted'] ?? false) as bool,
      version: (map['version'] ?? 1) as int,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Task create({required String title, String? description}) {
    final now = DateTime.now();
    // This is an example using Supabase for user ID. Adjust as per your auth solution.
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot create task: user is not logged in.');
    }
    return Task(
      id: '${now.millisecondsSinceEpoch}${Random().nextInt(9999)}',
      userId: userId,
      title: title,
      description: description,
      isCompleted: false,
      createdAt: now,
      modifiedAt: now,
    );
  }

  String toJson() => json.encode(toDatumMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Task(id: $id, userId: $userId, title: $title, description: $description, isCompleted: $isCompleted, createdAt: $createdAt, modifiedAt: $modifiedAt, isDeleted: $isDeleted, version: $version)';
  }

  @override
  bool operator ==(covariant Task other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.isCompleted == isCompleted &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.modifiedAt == modifiedAt &&
        other.isDeleted == isDeleted &&
        other.version == version;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        isCompleted.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        modifiedAt.hashCode ^
        isDeleted.hashCode ^
        version.hashCode;
  }
}
```

## Example: Relational Entity

Below is an example of entities using `RelationalDatumEntity` to demonstrate relationships between `User`, `Post`, and `Comment` entities.

```dart
import 'package:datum/datum.dart';

// User entity with relationships
class User extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final String name;
  final String email;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const User({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Map<String, Relation> get relations => {
    'posts': HasMany<Post>(this, 'userId'),
    'profile': HasOne<Profile>(this, 'userId'),
  };

  @override
  User copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    final bool hasChanges = id != null || userId != null || name != null ||
        email != null || createdAt != null || modifiedAt != null ||
        isDeleted != null;

    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: hasChanges ? DateTime.now() : (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) {
    if (oldVersion is! User) return toDatumMap();

    final diff = <String, dynamic>{};
    if (name != oldVersion.name) diff['name'] = name;
    if (email != oldVersion.email) diff['email'] = email;
    if (isDeleted != oldVersion.isDeleted) diff['isDeleted'] = isDeleted;

    if (diff.isNotEmpty) {
      diff['modifiedAt'] = modifiedAt.toIso8601String();
      diff['version'] = version;
    }
    return diff.isEmpty ? null : diff;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'isDeleted': isDeleted,
      'version': version,
    };

    if (target == MapTarget.remote) {
      map['createdAt'] = createdAt.toIso8601String();
      map['modifiedAt'] = modifiedAt.toIso8601String();
    } else {
      map['createdAt'] = createdAt.millisecondsSinceEpoch;
      map['modifiedAt'] = modifiedAt.millisecondsSinceEpoch;
    }
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      modifiedAt: _parseDate(map['modifiedAt'] ?? map['modified_at']),
      isDeleted: (map['isDeleted'] ?? false) as bool,
      version: (map['version'] ?? 1) as int,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }
}

// Post entity with BelongsTo relationship
class Post extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId; // Foreign key to User

  final String title;
  final String content;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Map<String, Relation> get relations => {
    'author': BelongsTo<User>(this, 'userId'),
    'comments': HasMany<Comment>(this, 'postId'),
  };

  @override
  Post copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    final bool hasChanges = id != null || userId != null || title != null ||
        content != null || createdAt != null || modifiedAt != null ||
        isDeleted != null;

    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: hasChanges ? DateTime.now() : (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) {
    if (oldVersion is! Post) return toDatumMap();

    final diff = <String, dynamic>{};
    if (title != oldVersion.title) diff['title'] = title;
    if (content != oldVersion.content) diff['content'] = content;
    if (userId != oldVersion.userId) diff['userId'] = userId;
    if (isDeleted != oldVersion.isDeleted) diff['isDeleted'] = isDeleted;

    if (diff.isNotEmpty) {
      diff['modifiedAt'] = modifiedAt.toIso8601String();
      diff['version'] = version;
    }
    return diff.isEmpty ? null : diff;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'isDeleted': isDeleted,
      'version': version,
    };

    if (target == MapTarget.remote) {
      map['createdAt'] = createdAt.toIso8601String();
      map['modifiedAt'] = modifiedAt.toIso8601String();
    } else {
      map['createdAt'] = createdAt.millisecondsSinceEpoch;
      map['modifiedAt'] = modifiedAt.millisecondsSinceEpoch;
    }
    return map;
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      modifiedAt: _parseDate(map['modifiedAt'] ?? map['modified_at']),
      isDeleted: (map['isDeleted'] ?? false) as bool,
      version: (map['version'] ?? 1) as int,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }
}

// Comment entity with BelongsTo relationship
class Comment extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final String postId; // Foreign key to Post
  final String content;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Map<String, Relation> get relations => {
    'author': BelongsTo<User>(this, 'userId'),
    'post': BelongsTo<Post>(this, 'postId'),
  };

  @override
  Comment copyWith({
    String? id,
    String? userId,
    String? postId,
    String? content,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    final bool hasChanges = id != null || userId != null || postId != null ||
        content != null || createdAt != null || modifiedAt != null ||
        isDeleted != null;

    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: hasChanges ? DateTime.now() : (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) {
    if (oldVersion is! Comment) return toDatumMap();

    final diff = <String, dynamic>{};
    if (content != oldVersion.content) diff['content'] = content;
    if (postId != oldVersion.postId) diff['postId'] = postId;
    if (userId != oldVersion.userId) diff['userId'] = userId;
    if (isDeleted != oldVersion.isDeleted) diff['isDeleted'] = isDeleted;

    if (diff.isNotEmpty) {
      diff['modifiedAt'] = modifiedAt.toIso8601String();
      diff['version'] = version;
    }
    return diff.isEmpty ? null : diff;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = {
      'id': id,
      'userId': userId,
      'postId': postId,
      'content': content,
      'isDeleted': isDeleted,
      'version': version,
    };

    if (target == MapTarget.remote) {
      map['createdAt'] = createdAt.toIso8601String();
      map['modifiedAt'] = modifiedAt.toIso8601String();
    } else {
      map['createdAt'] = createdAt.millisecondsSinceEpoch;
      map['modifiedAt'] = modifiedAt.millisecondsSinceEpoch;
    }
    return map;
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      userId: map['userId'] as String,
      postId: map['postId'] as String,
      content: map['content'] as String,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      modifiedAt: _parseDate(map['modifiedAt'] ?? map['modified_at']),
      isDeleted: (map['isDeleted'] ?? false) as bool,
      version: (map['version'] ?? 1) as int,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }
}

// Profile entity for HasOne relationship
class Profile extends RelationalDatumEntity {
  @override
  final String id;

  @override
  final String userId; // Foreign key to User

  final String bio;
  final String avatarUrl;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final bool isDeleted;

  @override
  final int version;

  const Profile({
    required this.id,
    required this.userId,
    required this.bio,
    required this.avatarUrl,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Map<String, Relation> get relations => {
    'user': BelongsTo<User>(this, 'userId'),
  };

  @override
  Profile copyWith({
    String? id,
    String? userId,
    String? bio,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    final bool hasChanges = id != null || userId != null || bio != null ||
        avatarUrl != null || createdAt != null || modifiedAt != null ||
        isDeleted != null;

    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: hasChanges ? DateTime.now() : (modifiedAt ?? this.modifiedAt),
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? (hasChanges ? this.version + 1 : this.version),
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) {
    if (oldVersion is! Profile) return toDatumMap();

    final diff = <String, dynamic>{};
    if (bio != oldVersion.bio) diff['bio'] = bio;
    if (avatarUrl != oldVersion.avatarUrl) diff['avatarUrl'] = avatarUrl;
    if (userId != oldVersion.userId) diff['userId'] = userId;
    if (isDeleted != oldVersion.isDeleted) diff['isDeleted'] = isDeleted;

    if (diff.isNotEmpty) {
      diff['modifiedAt'] = modifiedAt.toIso8601String();
      diff['version'] = version;
    }
    return diff.isEmpty ? null : diff;
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = {
      'id': id,
      'userId': userId,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'isDeleted': isDeleted,
      'version': version,
    };

    if (target == MapTarget.remote) {
      map['createdAt'] = createdAt.toIso8601String();
      map['modifiedAt'] = modifiedAt.toIso8601String();
    } else {
      map['createdAt'] = createdAt.millisecondsSinceEpoch;
      map['modifiedAt'] = modifiedAt.millisecondsSinceEpoch;
    }
    return map;
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      userId: map['userId'] as String,
      bio: map['bio'] as String,
      avatarUrl: map['avatarUrl'] as String,
      createdAt: _parseDate(map['createdAt'] ?? map['created_at']),
      modifiedAt: _parseDate(map['modifiedAt'] ?? map['modified_at']),
      isDeleted: (map['isDeleted'] ?? false) as bool,
      version: (map['version'] ?? 1) as int,
    );
  }

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is int) return DateTime.fromMillisecondsSinceEpoch(dateValue);
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }
}
```

