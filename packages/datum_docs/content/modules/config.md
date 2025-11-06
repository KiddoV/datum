# Config Module

The Config module in Datum centralizes all configuration settings for the Datum ecosystem. It provides a structured way to define and access various parameters that control the behavior and integration of Datum components.

## Key Components

### DatumConfig<T>

The `DatumConfig<T>` class defines comprehensive configuration options for Datum managers and their behavior.

#### Core Configuration Options

**Synchronization Settings:**
- `autoSyncInterval`: Duration between automatic sync operations (default: 15 minutes)
- `autoStartSync`: Whether to automatically start sync for discovered users on initialization
- `syncTimeout`: Maximum duration for sync operations (default: 2 minutes)
- `defaultSyncDirection`: Default sync direction (pushThenPull, pullThenPush, pushOnly, pullOnly)

**Conflict Resolution:**
- `defaultConflictResolver`: Default resolver for sync conflicts (LastWriteWinsResolver by default)

**User Management:**
- `defaultUserSwitchStrategy`: Strategy for handling user switches (syncThenSwitch, clearAndFetch, promptIfUnsyncedData, keepLocal)
- `initialUserId`: User ID to target for initial auto-sync

**Logging & Debugging:**
- `enableLogging`: Whether to enable Datum's internal logging

**Schema & Migration:**
- `schemaVersion`: Current data schema version for migration purposes
- `migrations`: List of Migration classes to run when schema version increments

**Execution Strategies:**
- `syncExecutionStrategy`: Strategy for processing sync queue (SequentialStrategy by default)
- `syncRequestStrategy`: Strategy for handling concurrent sync requests

**Error Handling:**
- `errorRecoveryStrategy`: Strategy for error recovery and retries
- `onMigrationError`: Callback for handling migration failures

**Performance Tuning:**
- `remoteEventDebounceTime`: Duration to buffer remote change events (default: 50ms)
- `changeCacheDuration`: Duration to cache change IDs to prevent duplicates (default: 5 seconds)

#### SyncDirection Enum

Defines the order of operations during synchronization:
- `pushThenPull`: Push local changes first, then pull remote changes (default)
- `pullThenPush`: Pull remote changes first, then push local changes
- `pushOnly`: Only push local changes to remote
- `pullOnly`: Only pull remote changes to local

#### UserSwitchStrategy Enum

Defines how to handle switching between users:
- `syncThenSwitch`: Sync current user before switching
- `clearAndFetch`: Clear new user's local data and fetch from remote
- `promptIfUnsyncedData`: Fail if current user has unsynced operations
- `keepLocal`: Switch without modifying local data

#### Configuration Methods

- `DatumConfig.defaultConfig()`: Returns a configuration with sensible production defaults
- `copyWith({...})`: Creates a modified copy of the configuration

### Migration System

The config supports automatic schema migrations through the `Migration` abstract class and `MigrationExecutor`.

**Migration Interface:**
- `version`: Target schema version
- `description`: Human-readable description
- `execute(Map<String, dynamic> data)`: Transforms individual data records
- `rollback(Map<String, dynamic> data)`: Reverses the migration (optional)

### Error Recovery Strategy

The `DatumErrorRecoveryStrategy` configures retry behavior:
- `shouldRetry`: Function determining whether to retry on specific errors
- `maxRetries`: Maximum number of retry attempts
- `backoffStrategy`: Strategy for calculating retry delays (ExponentialBackoff, LinearBackoff, etc.)
