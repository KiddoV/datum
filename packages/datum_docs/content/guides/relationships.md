---
title: Working with Relationships
---

This guide covers how to work with relationships in Datum, including defining relationships, accessing related data, and performing queries with relationships.

## Overview

Datum supports four types of relationships between entities:

- **BelongsTo**: Current entity holds the foreign key pointing to another entity
- **HasMany**: Other entities hold the foreign key pointing to this entity (one-to-many)
- **HasOne**: Other entity holds the foreign key pointing to this entity (one-to-one)
- **ManyToMany**: Many-to-many relationship using a pivot/junction table

## Defining Relationships

There are two ways to define relationships in Datum:

1. **Automated (Recommended)**: Using `@HasManyRelation`, `@BelongsToRelation`, etc., annotations on placeholder fields in conjunction with `datum_generator`.
2. **Manual**: Overriding the `relations` getter in your `RelationalDatumEntity`.

### 1. Automated Approach (Recommended)

When using `datum_generator`, you can define relationships with annotations. The generator will automatically create the `datumRelations` map for you.

```dart
@DatumSerializable(generateMixin: true)
class User extends RelationalDatumEntity with _$UserMixin {
  // Annotation on a placeholder field
  @HasManyRelation<Post>('userId', cascadeDelete: 'cascade')
  final List<Post>? _posts = null;

  @override
  Map<String, Relation> get relations => datumRelations;

  // ... rest of implementation
}
```

For more details on this approach, see the **[Automated Relationship Generation Guide](guides/code_generation_relationships)**.

### 2. Manual Approach

If you prefer not to use code generation or need advanced custom logic, you must extend `RelationalDatumEntity` and override the `relations` getter:

```dart
class User extends RelationalDatumEntity {
  final String name;
  final String email;

  @override
  Map<String, Relation> get relations => {
    'posts': HasMany<Post>(this, 'userId'),
    'profile': HasOne<Profile>(this, 'userId'),
  };

  // ... rest of implementation
}

class Post extends RelationalDatumEntity {
  final String userId; // Foreign key
  final String title;
  final String content;

  @override
  Map<String, Relation> get relations => {
    'author': BelongsTo<User>(this, 'userId'),
    'comments': HasMany<Comment>(this, 'postId'),
  };

  // ... rest of implementation
}

class Comment extends RelationalDatumEntity {
  final String userId;
  final String postId; // Foreign key
  final String content;

  @override
  Map<String, Relation> get relations => {
    'author': BelongsTo<User>(this, 'userId'),
    'post': BelongsTo<Post>(this, 'postId'),
  };

  // ... rest of implementation
}

class Profile extends RelationalDatumEntity {
  final String userId; // Foreign key
  final String bio;
  final String avatarUrl;

  @override
  Map<String, Relation> get relations => {
    'user': BelongsTo<User>(this, 'userId'),
  };

  // ... rest of implementation
}
```

## Accessing Related Data

### Lazy Loading

Access related data on-demand using the `fetch()` method:

```dart
// Get a post with its author
final post = await Datum.manager<Post>().read('post-id', userId: userId);
final author = await post.relations['author']?.fetch();

// Get a user with their posts
final user = await Datum.manager<User>().read('user-id', userId: userId);
final posts = await user.relations['posts']?.fetch();
```

### Setting Relationship Values

You can set relationship values directly or update foreign keys:

```dart
// Set a relationship value directly
final authorRelation = post.relations['author'] as BelongsTo<User>;
authorRelation.set(someUser);

// Or update the foreign key directly
final updatedPost = post.copyWith(userId: newUserId);
```

## Eager Loading

Use queries with `withRelated` to load relationships efficiently in a single operation:

```dart
// Load posts with their authors
final postsWithAuthors = await Datum.manager<Post>().query(
  DatumQuery(withRelated: ['author']),
  source: DataSource.local,
  userId: userId,
);

// Load users with their posts and profiles
final usersWithRelations = await Datum.manager<User>().query(
  DatumQuery(withRelated: ['posts', 'profile']),
  source: DataSource.local,
  userId: userId,
);

// Nested relationships
final postsWithAuthorsAndComments = await Datum.manager<Post>().query(
  DatumQuery(withRelated: ['author', 'comments.author']),
  source: DataSource.local,
  userId: userId,
);
```

## Reactive Relationships

Watch relationships reactively for real-time updates:

```dart
// Watch a user's posts
final userPostsStream = Datum.instance.watchRelated<User, Post>(
  user,
  'posts',
);

// Watch a post's comments with their authors
final postCommentsStream = Datum.instance.watchRelated<Post, Comment>(
  post,
  'comments',
);
```

## Many-to-Many Relationships

For many-to-many relationships, you need a pivot entity:

```dart
class Student extends RelationalDatumEntity {
  final String name;

  @override
  Map<String, Relation> get relations => {
    'courses': ManyToMany<Course>(
      this,
      Enrollment(), // Pivot entity
      'studentId',  // Foreign key in pivot pointing to this entity
      'courseId',   // Foreign key in pivot pointing to related entity
    ),
  };

  // ... implementation
}

class Course extends RelationalDatumEntity {
  final String title;

  @override
  Map<String, Relation> get relations => {
    'students': ManyToMany<Student>(
      this,
      Enrollment(), // Same pivot entity
      'courseId',   // Foreign key in pivot pointing to this entity
      'studentId',  // Foreign key in pivot pointing to related entity
    ),
  };

  // ... implementation
}

// Pivot entity
class Enrollment extends DatumEntity {
  final String studentId;
  final String courseId;
  final String grade;

  // ... implementation
}
```

## Relationship Constraints

### Foreign Key Requirements

- **BelongsTo**: The foreign key field must exist in the current entity
- **HasMany/HasOne**: The foreign key field must exist in the related entity
- **ManyToMany**: Both foreign key fields must exist in the pivot entity

### Type Safety

All relationships are type-safe. The generic type parameter ensures you can only relate compatible entity types.

### Performance Considerations

- Use eager loading (`withRelated`) when you know you'll need related data
- Use lazy loading (`fetch()`) when related data is optional
- Consider the impact of deep relationship loading on performance

## Error Handling

Relationship operations can fail in several ways:

```dart
try {
  final author = await post.relations['author']?.fetch();
} on ArgumentError catch (e) {
  // Entity is not relational
  print('Entity does not support relationships: $e');
} catch (e) {
  // Other errors (network, database, etc.)
  print('Failed to fetch relationship: $e');
}
```

## Best Practices

1. **Choose the right relationship type**: Use the relationship that accurately represents your data model
2. **Use eager loading strategically**: Only eager load what you need to avoid performance issues
3. **Handle null relationships**: Always check if relationships exist before accessing them
4. **Keep foreign keys consistent**: Ensure foreign key field names follow a consistent naming convention
5. **Document your relationships**: Use clear, descriptive names for your relationship keys</content>
