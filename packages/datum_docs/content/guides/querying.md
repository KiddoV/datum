---
title: Querying Data
---
This guide covers how to query and filter data in Datum using the powerful query API.

## Overview

Datum provides a comprehensive query system that allows you to filter, sort, and paginate data from both local and remote sources.

## Basic Queries

### Simple Filtering

```dart
// Find all completed tasks
final completedTasks = await Datum.manager<Task>().query(
  DatumQuery(
    filters: [Filter('isCompleted', FilterOperator.equals, true)],
  ),
  source: DataSource.local,
  userId: 'user-123',
);

// Find tasks created in the last week
final recentTasks = await Datum.manager<Task>().query(
  DatumQuery(
    filters: [Filter('createdAt', FilterOperator.greaterThan, DateTime.now().subtract(Duration(days: 7)))],
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

### Sorting

```dart
// Sort by creation date (newest first)
final sortedTasks = await Datum.manager<Task>().query(
  DatumQuery(
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
  ),
  source: DataSource.local,
  userId: 'user-123',
);

// Multiple sort criteria
final sortedPosts = await Datum.manager<Post>().query(
  DatumQuery(
    sorting: [
      SortDescriptor('isPinned', SortDirection.descending), // Pinned posts first
      SortDescriptor('createdAt', SortDirection.descending), // Then by date
    ],
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

### Pagination

```dart
// Get first 20 items
final firstPage = await Datum.manager<Task>().query(
  DatumQuery(
    limit: 20,
    offset: 0,
  ),
  source: DataSource.local,
  userId: 'user-123',
);

// Get next page
final secondPage = await Datum.manager<Task>().query(
  DatumQuery(
    limit: 20,
    offset: 20,
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

## Filter Operators

Datum supports various filter operators:

### Equality Operators
```dart
// Exact match
Filter('status', FilterOperator.equals, 'active')

// Not equal
Filter('status', FilterOperator.notEquals, 'deleted')
```

### Comparison Operators
```dart
// Numeric/date comparisons
Filter('priority', FilterOperator.greaterThan, 5)
Filter('createdAt', FilterOperator.lessThan, DateTime.now())
Filter('score', FilterOperator.greaterThanOrEqual, 80)
Filter('age', FilterOperator.lessThanOrEqual, 65)
```

### String Operators
```dart
// String matching
Filter('title', FilterOperator.contains, 'urgent')
Filter('email', FilterOperator.startsWith, 'admin')
Filter('filename', FilterOperator.endsWith, '.pdf')
```

### Set Operators
```dart
// Check if value is in a list
Filter('category', FilterOperator.isIn, ['work', 'personal', 'urgent'])

// Check if value is not in a list
Filter('status', FilterOperator.isNotIn, ['deleted', 'archived'])
```

### Null Checks
```dart
// Check for null values
Filter('description', FilterOperator.isNull, null)

// Check for non-null values
Filter('assignedTo', FilterOperator.isNotNull, null)
```

### Array Operators
```dart
// Check if array contains a value
Filter('tags', FilterOperator.arrayContains, 'important')
```

## Complex Queries

### Multiple Filters

```dart
// AND logic (default)
final complexQuery = DatumQuery(
  filters: [
    Filter('isCompleted', FilterOperator.equals, false),
    Filter('priority', FilterOperator.greaterThan, 3),
    Filter('createdAt', FilterOperator.greaterThan, DateTime.now().subtract(Duration(days: 7))),
  ],
  // logicalOperator: LogicalOperator.and, // Default
);

// OR logic
final orQuery = DatumQuery(
  filters: [
    Filter('status', FilterOperator.equals, 'urgent'),
    Filter('assignedTo', FilterOperator.equals, 'me'),
  ],
  logicalOperator: LogicalOperator.or,
);
```

### Combining with Sorting and Pagination

```dart
final complexQuery = await Datum.manager<Task>().query(
  DatumQuery(
    filters: [
      Filter('isCompleted', FilterOperator.equals, false),
      Filter('priority', FilterOperator.greaterThanOrEqual, 4),
    ],
    sorting: [
      SortDescriptor('priority', SortDirection.descending),
      SortDescriptor('createdAt', SortDirection.ascending),
    ],
    limit: 50,
    offset: 0,
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

## Query Builder

For more complex queries, use the fluent `DatumQueryBuilder` API:

```dart
final query = DatumQueryBuilder<Task>()
  .where('isCompleted', equals, false)
  .where('priority', greaterThan, 3)
  .where('createdAt', greaterThan, DateTime.now().subtract(Duration(days: 7)))
  .orderBy('priority', descending: true)
  .orderBy('createdAt', descending: false)
  .limit(50)
  .offset(0)
  .build();

// Execute the query
final results = await Datum.manager<Task>().query(query, source: DataSource.local, userId: 'user-123');
```

### Advanced Query Builder

```dart
final complexQuery = DatumQueryBuilder<Post>()
  // Multiple conditions with OR logic for some filters
  .whereGroup((builder) =>
    builder
      .where('status', equals, 'published')
      .or()
      .where('authorId', equals, 'my-user-id')
  )
  .where('createdAt', greaterThan, DateTime.now().subtract(Duration(days: 30)))
  .where('tags', arrayContains, 'featured')
  .orderBy('publishedAt', descending: true)
  .withRelated(['author', 'comments'])
  .limit(20)
  .build();
```

## Reactive Queries

Watch queries reactively for real-time updates:

```dart
// Watch a dynamic query
final urgentTasksStream = Datum.manager<Task>().watchQuery(
  DatumQuery(
    filters: [Filter('priority', FilterOperator.greaterThan, 4)],
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
  ),
  userId: 'user-123',
);

// Listen for changes
urgentTasksStream.listen((tasks) {
  print('Urgent tasks updated: ${tasks.length} tasks');
  // Update UI
});
```

## Relationship Queries

Query with related data using `withRelated`:

```dart
// Load posts with their authors
final postsWithAuthors = await Datum.manager<Post>().query(
  DatumQuery(
    withRelated: ['author'],
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
    limit: 20,
  ),
  source: DataSource.local,
  userId: 'user-123',
);

// Access related data
for (final post in postsWithAuthors) {
  final author = post.relations['author']?.value;
  print('Post: ${post.title} by ${author?.name}');
}
```

### Nested Relationships

```dart
// Load posts with authors and comments with their authors
final postsWithNestedRelations = await Datum.manager<Post>().query(
  DatumQuery(
    withRelated: ['author', 'comments.author'],
    filters: [Filter('createdAt', FilterOperator.greaterThan, DateTime.now().subtract(Duration(days: 7)))],
  ),
  source: DataSource.remote,
  userId: 'user-123',
);
```

## Data Sources

Queries can be executed against different data sources:

```dart
// Query local data only
final localResults = await Datum.manager<Task>().query(
  query,
  source: DataSource.local,
  userId: 'user-123',
);

// Query remote data only
final remoteResults = await Datum.manager<Task>().query(
  query,
  source: DataSource.remote,
  userId: 'user-123',
);

// Note: Some operations like relationships may not be available for remote-only queries
```

## Performance Considerations

### Indexing
For optimal query performance, ensure your local adapter supports indexing on frequently queried fields.

### Query Optimization
- Use specific filters rather than broad ones
- Limit result sets with pagination
- Use `withRelated` strategically to avoid N+1 queries
- Consider the cost of sorting large datasets

### Memory Usage
- Large result sets can consume significant memory
- Use pagination for large datasets
- Consider using `watchQuery` for reactive updates instead of polling

## Error Handling

Handle query errors appropriately:

```dart
try {
  final results = await Datum.manager<Task>().query(query, source: DataSource.local, userId: 'user-123');
} on DatumException catch (e) {
  switch (e.code) {
    case 'query_syntax_error':
      print('Invalid query syntax');
      break;
    case 'unsupported_operator':
      print('Filter operator not supported by adapter');
      break;
    case 'network_error':
      print('Failed to query remote data');
      break;
    default:
      print('Query failed: ${e.message}');
  }
}
```

## Best Practices

1. **Use appropriate data sources**: Query local for fast access, remote for fresh data
2. **Leverage pagination**: Always paginate large result sets
3. **Index frequently queried fields**: Ensure your adapters support indexing
4. **Use eager loading**: Use `withRelated` to avoid N+1 query problems
5. **Handle errors gracefully**: Implement proper error handling for all queries
6. **Consider performance**: Profile your queries and optimize as needed
7. **Use reactive queries**: Prefer `watchQuery` for dynamic, real-time data</content>
