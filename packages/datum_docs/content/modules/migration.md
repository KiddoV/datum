---
title: Migration Module
---

The Migration module handles database schema and data migrations when upgrading between different versions of your Datum entities.

## Overview

Migrations are essential when you need to modify your entity structure, add new fields, or transform existing data. Datum provides a robust migration system that works across both local and remote adapters.

## Key Components

### Migration

Abstract base class for implementing schema migrations.

**Required Properties:**
- `version`: Target schema version (integer)
- `description`: Human-readable description of the migration

**Required Methods:**
- `execute(Map<String, dynamic> data)`: Transforms individual data records
- `rollback(Map<String, dynamic> data)`: Reverses the migration (optional)

### MigrationExecutor

Handles the execution of migrations in the correct order.

**Key Methods:**
- `executeMigrations(List<Migration> migrations, int targetVersion)`: Runs migrations to target version
- `rollbackMigration(Migration migration)`: Reverses a specific migration

## Creating Migrations

### Basic Migration Structure

```dart
class AddPriorityToTasksMigration extends Migration {
  @override
  int get version => 2;

  @override
  String get description => 'Add priority field to Task entities';

  @override
  Map<String, dynamic> execute(Map<String, dynamic> data) {
    // Add priority field with default value
    return {
      ...data,
      'priority': data['priority'] ?? 3, // Default medium priority
    };
  }

  @override
  Map<String, dynamic> rollback(Map<String, dynamic> data) {
    // Remove priority field
    final result = Map<String, dynamic>.from(data);
    result.remove('priority');
    return result;
  }
}
```

### Complex Data Transformations

```dart
class RenameFieldMigration extends Migration {
  @override
  int get version => 3;

  @override
  String get description => 'Rename "description" field to "content"';

  @override
  Map<String, dynamic> execute(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Rename field if it exists
    if (result.containsKey('description')) {
      result['content'] = result['description'];
      result.remove('description');
    }

    return result;
  }

  @override
  Map<String, dynamic> rollback(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Reverse the rename
    if (result.containsKey('content')) {
      result['description'] = result['content'];
      result.remove('content');
    }

    return result;
  }
}
```

### Data Type Conversions

```dart
class ConvertStatusToEnumMigration extends Migration {
  @override
  int get version => 4;

  @override
  String get description => 'Convert status string to integer enum values';

  @override
  Map<String, dynamic> execute(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convert string status to integer
    if (result['status'] is String) {
      switch (result['status']) {
        case 'pending':
          result['status'] = 0;
          break;
        case 'in_progress':
          result['status'] = 1;
          break;
        case 'completed':
          result['status'] = 2;
          break;
        default:
          result['status'] = 0; // Default to pending
      }
    }

    return result;
  }

  @override
  Map<String, dynamic> rollback(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    // Convert back to string
    if (result['status'] is int) {
      switch (result['status']) {
        case 0:
          result['status'] = 'pending';
          break;
        case 1:
          result['status'] = 'in_progress';
          break;
        case 2:
          result['status'] = 'completed';
          break;
        default:
          result['status'] = 'pending';
      }
    }

    return result;
  }
}
```

## Configuring Migrations

### In DatumConfig

```dart
final config = DatumConfig(
  schemaVersion: 4, // Current schema version
  migrations: [
    AddPriorityToTasksMigration(),
    RenameFieldMigration(),
    ConvertStatusToEnumMigration(),
  ],
);
```

### Migration Execution Order

Migrations are executed in version order automatically. The system:

1. Checks current stored schema version
2. Identifies migrations needed to reach target version
3. Executes migrations in ascending version order
4. Updates stored schema version

## Migration Lifecycle

### Automatic Execution

Migrations run automatically during Datum initialization if the stored schema version is lower than the configured version.

```dart
// Migrations run automatically during initialization
await Datum.initialize(
  config: DatumConfig(
    schemaVersion: 4,
    migrations: [/* migration list */],
  ),
  // ... other config
);
```

### Manual Execution

You can also execute migrations manually:

```dart
final executor = MigrationExecutor();
await executor.executeMigrations(
  migrations: myMigrations,
  targetVersion: 4,
);
```

## Error Handling

### Migration Failures

Handle migration errors gracefully:

```dart
try {
  await Datum.initialize(config: config, /* ... */);
} on MigrationException catch (e) {
  print('Migration failed: ${e.message}');
  print('Failed at version: ${e.failedVersion}');

  // Handle migration failure
  // Options: rollback, manual fix, or abort
}
```

### Rollback Strategy

Implement rollback for critical migrations:

```dart
class CriticalMigration extends Migration {
  @override
  Map<String, dynamic> rollback(Map<String, dynamic> data) {
    // Implement rollback logic
    return originalDataTransformation(data);
  }
}
```

## Best Practices

### Migration Design

1. **Make migrations idempotent**: They should be safe to run multiple times
2. **Test migrations thoroughly**: Test on sample data before production
3. **Keep migrations small**: One migration per logical change
4. **Document changes clearly**: Use descriptive migration descriptions
5. **Implement rollbacks**: Always provide rollback logic for critical migrations

### Data Safety

1. **Backup data first**: Always backup before running migrations
2. **Validate data**: Check data integrity after migration
3. **Handle edge cases**: Account for unexpected data formats
4. **Use transactions**: Ensure migrations are atomic where possible

### Version Management

1. **Increment versions sequentially**: Use consecutive integers
2. **Never skip versions**: Each version should represent a migration
3. **Document version changes**: Keep changelog of what each version changes
4. **Test version upgrades**: Test upgrades from multiple previous versions

### Performance Considerations

1. **Batch operations**: Process data in batches for large datasets
2. **Index optimization**: Consider indexing needs during migrations
3. **Memory management**: Be mindful of memory usage with large datasets
4. **Timeout handling**: Implement timeouts for long-running migrations

## Migration Examples

### Adding a New Field

```dart
class AddCreatedByMigration extends Migration {
  @override
  int get version => 5;

  @override
  String get description => 'Add createdBy field to track entity creators';

  @override
  Map<String, dynamic> execute(Map<String, dynamic> data) {
    return {
      ...data,
      'createdBy': data['userId'], // Default to current user
    };
  }
}
```

### Splitting Fields

```dart
class SplitNameFieldMigration extends Migration {
  @override
  int get version => 6;

  @override
  String get description => 'Split fullName into firstName and lastName';

  @override
  Map<String, dynamic> execute(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);

    if (result['fullName'] is String) {
      final parts = (result['fullName'] as String).split(' ');
      result['firstName'] = parts.isNotEmpty ? parts.first : '';
      result['lastName'] = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      result.remove('fullName');
    }

    return result;
  }
}
```

### Data Cleanup

```dart
class CleanupInvalidDataMigration extends Migration {
  @override
  int get version => 7;

  @override
  String get description => 'Remove entities with invalid data';

  @override
  Map<String, dynamic> execute(Map<String, dynamic> data) {
    // Return null to indicate this record should be removed
    if (data['status'] == 'invalid') {
      return null;
    }
    return data;
  }
}
```

## Troubleshooting

### Common Issues

1. **Migration fails mid-execution**: Implement proper rollback or recovery logic
2. **Data corruption**: Always backup before migrating
3. **Performance issues**: Optimize migrations for large datasets
4. **Version conflicts**: Ensure version numbers are unique and sequential

### Debugging Migrations

```dart
// Enable detailed logging
final config = DatumConfig(
  enableLogging: true,
  // ... other config
);

// Test migrations on sample data
final testData = [{'id': '1', 'name': 'Test'}];
final migratedData = migration.execute(testData.first);
print('Migration result: $migratedData');
```</content>
