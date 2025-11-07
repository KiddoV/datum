---
title: 🔄 Migration Troubleshooting
description: Debug and resolve Datum migration issues.
---

Handle schema changes, data transformations, and version upgrades in Datum.

## Schema Migration Failures

### Issue: Migration execution errors

**Symptoms:** App crashes during startup with migration errors

**Common Causes:**
- Invalid data transformation logic
- Missing null checks in migration code
- Schema version conflicts between local and remote

**Debugging Steps:**
```dart
// Enable detailed migration logging
final config = DatumConfig(
  logger: DatumLogger(
    enabled: true,
    level: LogLevel.debug,
  ),
);

// Check current schema version
final currentVersion = await localAdapter.getSchemaVersion();
print('Current schema version: $currentVersion');

// Verify migration path
final targetVersion = 3; // Your target version
if (currentVersion < targetVersion) {
  print('Migration needed from v$currentVersion to v$targetVersion');
}
```

**Migration Implementation:**
```dart
class Migration1To2 implements Migration {
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> data) async {
    // Always validate input data
    if (data == null) {
      throw MigrationException('Migration data cannot be null');
    }

    // Create a copy to avoid modifying original
    final migratedData = Map<String, dynamic>.from(data);

    // Safe field transformations
    if (migratedData.containsKey('oldFieldName')) {
      migratedData['newFieldName'] = migratedData['oldFieldName'];
      migratedData.remove('oldFieldName');
    }

    // Add default values for new required fields
    migratedData['newRequiredField'] ??= 'defaultValue';

    return migratedData;
  }

  @override
  Future<Map<String, dynamic>> rollback(Map<String, dynamic> data) async {
    // Implement rollback logic
    final rolledBackData = Map<String, dynamic>.from(data);

    if (rolledBackData.containsKey('newFieldName')) {
      rolledBackData['oldFieldName'] = rolledBackData['newFieldName'];
      rolledBackData.remove('newFieldName');
    }

    rolledBackData.remove('newRequiredField');
    return rolledBackData;
  }
}
```

### Issue: Data loss during migration

**Symptoms:** Data disappears after migration

**Prevention Strategies:**
```dart
// Always backup before migration
class MigrationManager {
  static Future<void> safeMigrate(
    LocalAdapter adapter,
    List<Migration> migrations,
  ) async {
    // Create backup
    final backup = await adapter.createBackup();
    print('Backup created: ${backup.path}');

    try {
      // Run migrations
      for (final migration in migrations) {
        await adapter.runMigration(migration);
        print('Migration ${migration.runtimeType} completed');
      }
    } catch (e) {
      // Restore from backup on failure
      await adapter.restoreFromBackup(backup);
      print('Migration failed, restored from backup');
      rethrow;
    }
  }
}
```

## Version Compatibility Issues

### Issue: Local and remote schema mismatch

**Symptoms:** Sync fails with schema incompatibility errors

**Resolution Steps:**
```dart
// Check schema versions
final localVersion = await localAdapter.getSchemaVersion();
final remoteVersion = await remoteAdapter.getSchemaVersion();

if (localVersion != remoteVersion) {
  print('Schema mismatch: local=$localVersion, remote=$remoteVersion');

  // Handle version differences
  if (localVersion < remoteVersion) {
    // Local is behind, update local schema
    await runMigrations(localAdapter, remoteVersion);
  } else {
    // Remote is behind, this might require server update
    throw Exception('Remote schema is outdated');
  }
}
```

### Issue: Breaking changes in entity definitions

**Symptoms:** Serialization/deserialization errors after entity changes

**Entity Evolution Strategies:**
```dart
class BackwardCompatibleTask extends DatumEntity {
  // Keep old field names for backward compatibility
  @deprecated
  String? get oldFieldName => newFieldName;

  // Add new fields with defaults
  String? newFieldName;

  // Custom serialization handling
  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    final map = super.toDatumMap(target: target);

    // Handle field name changes
    if (target == MapTarget.remote && oldFieldName != null) {
      map['legacyFieldName'] = oldFieldName;
    }

    return map;
  }

  factory BackwardCompatibleTask.fromMap(Map<String, dynamic> map) {
    // Handle both old and new field names
    final fieldValue = map['newFieldName'] ?? map['oldFieldName'];

    return BackwardCompatibleTask(
      newFieldName: fieldValue,
      // ... other fields
    );
  }
}
```

## Data Transformation Issues

### Issue: Complex data restructuring

**Symptoms:** Migration logic becomes too complex

**Advanced Migration Patterns:**
```dart
class ComplexMigration2To3 implements Migration {
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> data) async {
    final migratedData = Map<String, dynamic>.from(data);

    // Handle nested object restructuring
    if (migratedData['nestedObject'] is Map) {
      final nested = migratedData['nestedObject'] as Map<String, dynamic>;

      // Flatten nested structure
      migratedData['flattenedField'] = nested['deepField'];
      migratedData.remove('nestedObject');
    }

    // Handle array transformations
    if (migratedData['tags'] is List) {
      final tags = migratedData['tags'] as List;
      migratedData['tagObjects'] = tags.map((tag) => {
        'name': tag,
        'created': DateTime.now().toIso8601String(),
      }).toList();
    }

    return migratedData;
  }
}
```

### Issue: Large dataset migration performance

**Symptoms:** Migration takes too long for large datasets

**Performance Optimization:**
```dart
class BatchedMigration implements Migration {
  static const batchSize = 100;

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> data) async {
    // For large migrations, process in batches
    final allRecords = await getAllRecords();
    final batches = <List<Map<String, dynamic>>>[];

    for (var i = 0; i < allRecords.length; i += batchSize) {
      final end = (i + batchSize < allRecords.length) ? i + batchSize : allRecords.length;
      batches.add(allRecords.sublist(i, end));
    }

    for (final batch in batches) {
      await processBatch(batch);
      // Allow UI to remain responsive
      await Future.delayed(Duration(milliseconds: 10));
    }

    return data; // Return original for single record migrations
  }
}
```

## Cross-Platform Migration Issues

### Issue: Platform-specific data incompatibility

**Symptoms:** Data works on one platform but fails on another

**Cross-Platform Solutions:**
```dart
class CrossPlatformMigration implements Migration {
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> data) async {
    final migratedData = Map<String, dynamic>.from(data);

    // Normalize platform-specific data
    migratedData['platform'] = await detectCurrentPlatform();

    // Handle file path differences
    if (migratedData['filePath'] is String) {
      migratedData['filePath'] = normalizeFilePath(migratedData['filePath']);
    }

    // Standardize date formats
    if (migratedData['createdAt'] is String) {
      migratedData['createdAt'] = standardizeDateFormat(migratedData['createdAt']);
    }

    return migratedData;
  }

  Future<String> detectCurrentPlatform() async {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
```

## Testing Migration Changes

### Migration Testing Framework

```dart
class MigrationTestSuite {
  static Future<void> testMigration(
    Migration migration,
    Map<String, dynamic> inputData,
    Map<String, dynamic> expectedOutput,
  ) async {
    // Test forward migration
    final migratedData = await migration.execute(inputData);
    expect(migratedData, equals(expectedOutput));

    // Test rollback
    final rolledBackData = await migration.rollback(migratedData);
    expect(rolledBackData, equals(inputData));
  }

  static Future<void> testLargeDatasetMigration(
    Migration migration,
    int recordCount,
  ) async {
    // Generate test data
    final testData = generateTestRecords(recordCount);

    final stopwatch = Stopwatch()..start();
    for (final record in testData) {
      await migration.execute(record);
    }
    stopwatch.stop();

    print('Migrated $recordCount records in ${stopwatch.elapsed.inSeconds}s');
    print('Average: ${(stopwatch.elapsed.inMilliseconds / recordCount).round()}ms per record');
  }
}
```

## Rollback and Recovery

### Issue: Failed migration recovery

**Symptoms:** Migration fails and app is left in broken state

**Recovery Strategies:**
```dart
class MigrationRecovery {
  static Future<void> recoverFromFailedMigration(
    LocalAdapter adapter,
    String backupPath,
  ) async {
    try {
      // Attempt to restore from backup
      await adapter.restoreFromBackup(backupPath);
      print('Successfully restored from backup');
    } catch (e) {
      // If backup fails, try emergency recovery
      await emergencyRecovery(adapter);
    }
  }

  static Future<void> emergencyRecovery(LocalAdapter adapter) async {
    // Clear corrupted data and start fresh
    await adapter.clearAllData();

    // Reinitialize with default state
    await adapter.initialize();

    print('Emergency recovery completed - data reset to defaults');
  }
}
```

## Best Practices

### 1. Test Migrations Thoroughly
```dart
// Always test migrations with real data
void main() {
  test('Migration preserves data integrity', () async {
    final testData = createTestData();
    final migration = Migration1To2();

    final migrated = await migration.execute(testData);
    final rolledBack = await migration.rollback(migrated);

    expect(rolledBack, equals(testData));
  });
}
```

### 2. Version Control Migrations
```dart
// Keep migrations in version control
// migrations/
//   v1_to_v2.dart
//   v2_to_v3.dart
//   v3_to_v4.dart

class MigrationRegistry {
  static final migrations = <String, Migration>{
    '1->2': Migration1To2(),
    '2->3': Migration2To3(),
    '3->4': Migration3To4(),
  };

  static List<Migration> getMigrationPath(int fromVersion, int toVersion) {
    final path = <Migration>[];
    for (var v = fromVersion; v < toVersion; v++) {
      final migrationKey = '$v->${v + 1}';
      final migration = migrations[migrationKey];
      if (migration != null) {
        path.add(migration);
      }
    }
    return path;
  }
}
```

### 3. Monitor Migration Performance
```dart
class MigrationMonitor {
  static Future<void> monitorMigration(
    Migration migration,
    Map<String, dynamic> data,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await migration.execute(data);
    stopwatch.stop();

    // Log performance metrics
    await logMigrationMetrics(
      migration.runtimeType.toString(),
      stopwatch.elapsed,
      data.length,
    );

    return result;
  }
}
```

---

*For more migration patterns, check the [Migration Module](../../modules/migration.md) documentation.*
