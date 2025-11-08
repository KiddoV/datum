---




title: Query Module
---

The Query module provides powerful tools for filtering, sorting, and paginating data across Datum entities.

## Key Components

### DatumQuery

The main query class that defines filtering, sorting, and pagination parameters.

**Properties:**
- `filters`: List of `Filter` conditions to apply
- `sorting`: List of `SortDescriptor` for ordering results
- `limit`: Maximum number of results to return
- `offset`: Number of results to skip (for pagination)
- `logicalOperator`: `LogicalOperator.and` or `LogicalOperator.or` for combining filters
- `withRelated`: List of relationship names to eagerly load

### Filter

Represents a single filtering condition.

**Properties:**
- `field`: The field name to filter on
- `operator`: The `FilterOperator` to apply
- `value`: The value to compare against

### FilterOperator

Supported filtering operations:

**Equality:**
- `equals`: Exact match
- `notEquals`: Not equal to value

**Comparison:**
- `greaterThan`: Greater than value
- `lessThan`: Less than value
- `greaterThanOrEqual`: Greater than or equal to value
- `lessThanOrEqual`: Less than or equal to value

**String Matching:**
- `contains`: String contains substring
- `startsWith`: String starts with value
- `endsWith`: String ends with value

**Set Operations:**
- `isIn`: Value is in the provided list
- `isNotIn`: Value is not in the provided list

**Null Checks:**
- `isNull`: Field is null
- `isNotNull`: Field is not null

**Array Operations:**
- `arrayContains`: Array field contains the value

### SortDescriptor

Defines sorting criteria for query results.

**Properties:**
- `field`: Field name to sort by
- `direction`: `SortDirection.ascending` or `SortDirection.descending`

### DatumQueryBuilder

Fluent API for building complex queries programmatically.

**Key Methods:**
- `where(field, operator, value)`: Add a filter condition
- `whereGroup(builder)`: Create grouped conditions with AND/OR logic
- `orderBy(field, {descending})`: Add sorting criteria
- `limit(count)`: Set maximum results
- `offset(count)`: Set results to skip
- `withRelated(relations)`: Specify relationships to eager load
- `build()`: Create the final `DatumQuery`

**Example:**
```dart
final query = DatumQueryBuilder<Task>()
  .where('isCompleted', equals, false)
  .where('priority', greaterThan, 3)
  .orderBy('createdAt', descending: true)
  .limit(50)
  .withRelated(['assignee'])
  .build();
```

### LogicalOperator

Controls how multiple filters are combined:

- `and`: All filters must be true (default)
- `or`: At least one filter must be true

## Usage Examples

### Basic Filtering

```dart
// Find active users
final activeUsers = await Datum.manager<User>().query(
  DatumQuery(
    filters: [Filter('status', FilterOperator.equals, 'active')],
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

### Complex Queries

```dart
// Find high-priority tasks from last week
final urgentTasks = await Datum.manager<Task>().query(
  DatumQuery(
    filters: [
      Filter('priority', FilterOperator.greaterThan, 4),
      Filter('createdAt', FilterOperator.greaterThan, DateTime.now().subtract(Duration(days: 7))),
    ],
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
    limit: 20,
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

### Relationship Queries

```dart
// Load posts with authors
final postsWithAuthors = await Datum.manager<Post>().query(
  DatumQuery(
    withRelated: ['author'],
    sorting: [SortDescriptor('createdAt', SortDirection.descending)],
  ),
  source: DataSource.local,
  userId: 'user-123',
);
```

### Reactive Queries

```dart
// Watch for changes to a query
final urgentTasksStream = Datum.manager<Task>().watchQuery(
  DatumQuery(
    filters: [Filter('priority', FilterOperator.greaterThan, 4)],
  ),
  userId: 'user-123',
);
```

## Performance Considerations

### Indexing
Ensure your local adapters support indexing on frequently queried fields for optimal performance.

### Query Optimization
- Use specific filters to reduce result sets
- Leverage pagination to limit memory usage
- Use `withRelated` strategically to avoid N+1 queries
- Consider the performance impact of sorting large datasets

### Memory Management
- Large result sets consume memory; use pagination
- Prefer reactive queries (`watchQuery`) over polling
- Clean up streams when no longer needed

## Error Handling

Handle query-related errors appropriately:

```dart
try {
  final results = await Datum.manager<Task>().query(query, source: DataSource.local, userId: 'user-123');
} catch (e) {
  if (e is DatumException) {
    switch (e.code) {
      case 'query_syntax_error':
        // Handle invalid query syntax
        break;
      case 'unsupported_operator':
        // Handle unsupported filter operator
        break;
      default:
        // Handle other query errors
        break;
    }
  }
}
```

## Best Practices

1. **Use appropriate data sources**: Query local data for speed, remote data for freshness
2. **Implement pagination**: Always paginate large result sets
3. **Index queried fields**: Ensure adapters support indexing on filtered fields
4. **Use eager loading**: Leverage `withRelated` to prevent N+1 query issues
5. **Handle errors gracefully**: Implement comprehensive error handling
6. **Monitor performance**: Profile queries and optimize as needed
7. **Prefer reactive queries**: Use `watchQuery` for real-time data updates</content>
