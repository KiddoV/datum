# Datum Persistence Layer

This directory contains example implementations of the `DatumPersistence` interface.

## Overview

The persistence layer allows Datum to store sync metadata, configuration, and other data persistently. By default, Datum uses in-memory storage, but you can provide custom implementations for persistent storage.

## Built-in Implementations

### InMemoryDatumPersistence (Default)

The default implementation stores all data in memory. Data is lost when the app restarts.

```dart
// This is used by default - no setup needed
await Datum.initialize(
  config: DatumConfig(...),
  connectivityChecker: MyConnectivityChecker(),
  // persistence: InMemoryDatumPersistence(), // Used by default
  registrations: [...],
);
```

### HiveDatumPersistence (Example)

Hive-based persistent storage implementation using isolated boxes for better performance and isolation.

```dart
// Initialize Hive first
await Hive.initFlutter();

// Create and initialize the persistence layer
final persistence = HiveDatumPersistence();
await persistence.initialize();

// Use with Datum
await Datum.initialize(
  config: DatumConfig(...),
  connectivityChecker: MyConnectivityChecker(),
  persistence: persistence,
  registrations: [...],
);
```

## Custom Implementation

You can implement your own persistence layer by implementing the `DatumPersistence` interface:

```dart
class MyCustomPersistence implements DatumPersistence {
  @override
  Future<void> initialize() async {
    // Set up your storage
  }

  @override
  Future<void> saveSyncMetadata(String userId, DatumSyncMetadata metadata) async {
    // Implement sync metadata storage
  }

  // ... implement all other required methods

  @override
  Future<void> dispose() async {
    // Clean up resources
  }
}

// Use it
await Datum.initialize(
  config: DatumConfig(...),
  connectivityChecker: MyConnectivityChecker(),
  persistence: MyCustomPersistence(),
  registrations: [...],
);
```

## Features

- **Streaming Support**: All storage operations support reactive streams for real-time updates
- **User Isolation**: Automatic data isolation per user with `clearUserData()`
- **Storage Stats**: Get insights into storage usage with `getStorageStats()`
- **Type Safety**: Full type safety with Dart's type system
- **Thread Safe**: Designed for concurrent access patterns

## Migration

When switching persistence implementations, you may need to handle data migration manually, as each implementation uses its own storage format.
