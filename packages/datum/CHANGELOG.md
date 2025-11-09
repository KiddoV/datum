# Unreleased

## 🗑️ Breaking Changes

- **core**: Removed deprecated `pause()` and `resume()` methods from `DatumManager` and `Datum` classes
  - These methods were deprecated in favor of `unsubscribeFromRemoteChanges()` and `resubscribeToRemoteChanges()`
  - Update your code to use the new method names for remote change subscription management

## ✨ Core Library Features

### Entity & Model System
- **feat(datum)**: enhance entity definition with interface and mixin
  - introduce DatumEntityInterface for flexible entity implementations
  - add DatumEntityMixin for simplified entity creation
  - update all adapters and engine classes to use DatumEntityInterface
  - improve relational entity support with interface and mixin

- **feat(datum)**: enhance entity mixins and relational detection
  - migrate Plan to use RelationalDatumEntityMixin
  - make Task extend DatumEntity and use DatumEntityMixin
  - add isRelational getter to Task
  - update tests to reflect mixin changes
  - improve relational status detection for mixin entities

### Sync Engine & Data Synchronization
- **feat**: add initial sync handling on user authentication
  - Implement waiting for initial sync completion when user signs in
  - Clear sync metadata to force fresh data fetch from server
  - Add sync status listener to track sync state
  - Update auth listener to handle sign-in events asynchronously
  - Resume sync and perform pull-then-push with full sync options on login
  - This ensures data consistency by fetching the latest remote data upon authentication, preventing stale local data issues

- **feat(datum)**: enhance sync engine with metadata comparison and device tracking
  - add sync metadata comparison to skip sync if no changes are detected
  - fetch local and remote metadata and compare data hash and entity counts
  - skip sync if metadata matches and there are no pending local operations
  - add device tracking to sync metadata
  - track device id and last sync time for each device
  - update sync metadata with device information
  - add new sync statuses to enum
  - add isSyncing/isLastSyncSuccessful flags
  - add migrations
  - add migration for schema version 0 to 1
  - add forceFullSync option
  - add forceFullSync option to bypass metadata comparison and force a full sync
  - refactor sync engine to handle errors and events more robustly
  - wrap errors in SyncExceptionWithEvents to transport events back to the manager
  - handle manager disposal during sync to prevent event processing after disposal
  - improve error handling and logging for sync failures
  - add related entities support
  - add syncScope to the remoteAdapter

- **feat(datum)**: enhance auto-sync and initial data fetching
  - add auto-sync on login and app start
  - improve sync execution strategy
  - enhance logging and error handling

- **feat(datum)**: add startAutoSync method to Datum class
  - introduce startAutoSync method to start auto-sync across managers
  - refactor auto-sync management in DatumManager

### Configuration & Options
- **feat(core)**: add default sync options and remote metadata
  - 【DatumConfig】Add defaultSyncOptions to DatumConfig for default sync settings
  - Allows specifying default sync options in DatumConfig
  - Options are merged with those passed to individual sync calls
  - 【DatumManager】Implement sync option merging in DatumManager
  - Implement _mergeSyncOptions to merge provided and default options
  - Provided options take precedence over defaults
  - 【DatumManager】Add getRemoteSyncMetadata method to DatumManager
  - Fetches sync metadata from the remote server for the specified entity type
  - 【DatumCore】Add getRemoteSyncMetadata method to DatumCore
  - For easier access of remote sync metadata
  - 【Tests】Add tests for default sync options and merging
  - Add tests to verify default sync options and merging behavior
  - 【Docs】Update documentation to reflect the new sync metadata and options

### Logging & Monitoring
- **feat(datum)**: enhance CustomDatumLogger with advanced logging features
  - add support for minimum log levels, sampling rules, performance logging, and synchronous logging to improve flexibility, reduce log noise, and enable performance monitoring

## ♻️ Refactors

- **refactor(datum)**: enhance entity definition with interface and mixin
  - introduce DatumEntityInterface for flexible entity implementations
  - add DatumEntityMixin for simplified entity creation
  - update all adapters and engine classes to use DatumEntityInterface
  - improve relational entity support with interface and mixin

- **refactor(datum)**: enhance entity mixins and relational detection
  - migrate Plan to use RelationalDatumEntityMixin
  - make Task extend DatumEntity and use DatumEntityMixin
  - add isRelational getter to Task
  - update tests to reflect mixin changes
  - improve relational status detection for mixin entities

- **refactor(datum)**: improve sync engine with batch processing and performance monitoring
  - implement batch processing for remote sync to reduce memory usage
  - add performance monitoring with baselines and regression detection
  - enhance datum config with performance and logging options
  - introduce error boundaries for sync operations
  - improve logging with structured entries and sampling
  - add sync error handler for consistent error management

- **refactor(datum)**: improve sync and error handling
  - Improve concurrent operation handling by using AsyncQueue
  - Enhance error handling for sync operations
  - Improve performance and memory usage monitoring
  - Enhance auto-sync scheduling
  - Improve logging and metrics reporting

## 🐛 Bug Fixes

- **fix(sync_engine)**: correct return values and unused variables in sync engine tests
  - remove unused result variables from synchronize calls in tests
  - fix the return value of synchronize function
  - rename unused url variable to _

## 📖 Documentation

- **docs(docs)**: enhance documentation with Datum singleton API
  - add documentation for Datum singleton API with usage examples
  - add advanced synchronization patterns and features documentation
  - add troubleshooting guide for Datum issues
  - add documentation for migration issues
  - add documentation for adapter issues
  - add documentation for performance issues

# 0.0.13
- fixed type casting error in `initialize()` method in Datum


# 0.0.12

## ✨ Features

- **core**: Add stacktrace to DatumEither
  - The `Failure` class now includes an optional `StackTrace` property.
  - The `fold` method in `DatumEither` now passes the `StackTrace` to the `onFailure` callback.
  - The `onFailure` method now accepts a `StackTrace` parameter.
  - The `getError` method now returns a tuple containing the error value and the stack trace.

- **core**: Bring back getSuccess method
  - Added the `getSuccess` method back to the `DatumEither` class.
  - This method returns the success value if the `DatumEither` is a `Success`, otherwise it throws a `StateError`.

## ♻️ Refactors

- **core**: Remove isSuccess and isFailure methods
  - Removed the `isSuccess` and `isFailure` methods from the `DatumEither` class.

- **core**: Use switch statement instead of if statement
  - Refactor the `onSuccess`, `onFailure`, `getSuccess`, `getError`, `successOrNull`, and `errorOrNull` methods to use switch statement instead of if statement.

# 0.0.11

## ✨ Features

- **core**: introduce DatumEither for initialization result
  - Use DatumEither to handle potential errors during Datum initialization
  - Return Success or Failure based on the outcome of the initialization process
  - Update related code to handle the new DatumEither return type
  - Add DatumEither model for typing success or failure.

# 0.0.10

## ✨ Features

- **Batch Operations**: Added `createMany` and `updateMany` methods for performing batch create and update operations.
- **Lifecycle Management**: Implemented `DatumProviderWithLifecycle` widget to manage Datum's lifecycle based on app state.
- **Flexible Entity Implementation**: Introduced `DatumEntityMixin` and `RelationalDatumEntityMixin` to allow for more flexible entity implementation without requiring inheritance from a base class.
- **Schema Versioning**: Added `schemaVersion` property to `IsolatedHiveLocalAdapter` for easier schema migration.
- **Type Comparison**: Added a `sameTypes` method for type comparison.
- **Dependencies**: Added `equatable` dependency for easier object comparison.

## 🐛 Bug Fixes

- **Logging**: Removed unnecessary debug logs from `tasksStreamProvider`.
- **Initialization**: Ensured managers are initialized before `saveMany` operations.
- **Memory Leaks**: Improved stream handling in `SupabaseRemoteAdapter` to prevent memory leaks.
- **Error Handling**: Improved type safety and error handling in `fetchRelated` methods.

## ♻️ Refactors

- **Background Sync**: Enhanced `SupabaseRemoteAdapter` with `resubscribeToChanges` and `unsubscribeFromChanges` methods for better background sync and lifecycle management.
- **Entity Handling**: Updated `DatumEntityBase` and related classes for better sync and versioning.
- **Adapters**: Updated `HiveLocalAdapter` and `SupabaseRemoteAdapter` to use `DatumEntityBase` instead of `DatumEntity`.
- **Task Entity**: Refactored the `Task` entity to use `DatumEntityMixin`.
- **Sync Execution**: Updated the default sync execution strategy to `parallel`.
- **Data Serialization**: Enhanced data serialization for local and remote persistence.

## 📖 Documentation

- **Datum Class**: Enhanced `Datum` class documentation for clarity and improved usage examples.
- **Sync Options**: Enhanced `DatumSyncOptions` documentation for better clarity.
- **General**: Improved overall documentation for clarity.

## ✅ Tests

- **Background Sync**: Added tests for background sync functionality.

# 0.0.9

## ✨ Features

### Core

- **Implement Sync Request Strategies**: Introduced a new system to control how concurrent calls to the `synchronize` method are handled, preventing race conditions and improving data consistency.
  - Added `DatumSyncRequestStrategy` as the base for defining execution behavior.
  - Implemented `SequentialRequestStrategy` to queue and process all `synchronize` calls in the order they are received. This is the new default behavior.
  - Implemented `SkipConcurrentStrategy` as an alternative strategy to ignore new `synchronize` calls if a sync is already in progress.
  - Added `syncRequestStrategy` to `DatumConfig` to allow global configuration of this behavior.
  - Added an `isSyncing` getter to `DatumSyncEngine` to check the current sync status.

## 🐛 Bug Fixes

### Build

- **Correct Conditional Imports**: Fixed conditional imports to ensure compatibility across both `dart:io` and `dart:html` environments.


## 0.0.8
- fix conditional import for web and io

## 0.0.7

### 🐛 Bug Fixes

- **🐛 Isolate Error Handling & Web Compatibility**:
  - Ensured errors during isolate operations are properly caught and sent back to the main thread.
  - Enhanced web compatibility by using `compute` function for isolate operations.
  - Removed unnecessary newline at end of file for consistency.
  - Removed unused import in `supabase_security_dialog.dart`.

## 0.0.6

### 🚀 Features

- **🚀 Isolate Sync Strategy**: Introduced a new `IsolateStrategy` that runs data synchronization in a background isolate for improved performance and UI responsiveness. This includes platform-specific runners for both mobile/desktop (`dart:io`) and web (`dart:html`) via conditional imports, ensuring broad platform support.
- **✨ Sealed Class Migration**: Migrated `DatumEntity` and `RelationalDatumEntity` to a `DatumEntityBase` sealed class for enhanced type safety and to remove the need for `sampleInstance`.
- **🚀 New Facade Methods**: Added a suite of new methods to the global `Datum` facade for easier data interaction:
  - **Reactive Watching**: `watchAll`, `watchById`, `watchQuery`, `watchRelated`.
  - **One-time Fetching**: `query`, `fetchRelated`.
  - **Data & Sync Management**: `getPendingCount`, `getPendingOperations`, `getStorageSize`, `watchStorageSize`, `getLastSyncResult`, `checkHealth`.
  - **Sync Control**: `pauseSync`, `resumeSync`.

### ✅ Tests

- **🧪 Enhanced Core Tests**: Added test cases for uninitialized state errors, `statusForUser`, `allHealths`, and relational method behavior. Introduced a `CustomManagerConfig` for easier mock manager injection in tests.

### ♻️ Refactors & 🧹 Chores

- **♻️ Isolate Helper Improvements**:
  - Replaced conditional imports with platform-specific implementations.
  - Removed `isolate_helper.dart` and `isolate_helper_unsupported.dart`.
  - Added `_isolate_helper_io.dart` for IO platforms.
  - Updated `_isolate_helper_web.dart` to use synchronous JSON encoding.
  - Updated `datum_sync_engine.dart` to use the new isolate helper.
  - Removed unused imports in `test.dart`, `adapter_test.dart`, `relational_data_test.dart`, `relational_data_integration_test.dart`, `mock_adapters.dart`, and `test_entity.dart`.
  - Updated `isolate_helper_test.dart` to use the new isolate helper.
- **🗑️ Removed `sampleInstance`**: The `sampleInstance` property on `LocalAdapter` is no longer needed due to the sealed class migration and has been removed.
- **🩺 Renamed `AdapterHealthStatus.ok`** to `AdapterHealthStatus.healthy` for better clarity.
- **📦 Refactored internal imports** to use the `datum` package consistently.
- **⚙️ Made `MigrationExecutor` generic** to improve type safety during migrations.
- **🗺️ Added `DataSource` enum** to explicitly specify the source for query operations.

## 0.0.5
- Add docs link



## 0.0.4

### Features

- Added support for funding and contributions.

### Documentation

- Added `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md`.
- Updated `README.md` with funding and contribution sections.
- Updated `README.md` to mention future support for multiple adapters for a single entity.

### Chores

- ✨ chore(analysis): apply linter and formatter rules
- enable recommended linter rules for code quality
- set formatter rules for consistent code style
- ignore non_constant_identifier_names error

## 0.0.3
- 📝 docs(readme): enhance architecture diagrams in README

- update architecture diagrams for better clarity
- improve image display using <p> tag for alignment


## 0.0.2
- Update readme to add images correctly


## 0.0.1
- Initial release 🎉
