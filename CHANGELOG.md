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
