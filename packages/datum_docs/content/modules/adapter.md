# Adapter Module

The Adapter module in Datum is responsible for handling data interactions with various sources, both local and remote. It provides a standardized interface for fetching, storing, and synchronizing data, abstracting away the underlying storage mechanisms.

## Key Components

### LocalAdapter<T>

The `LocalAdapter<T>` abstract class defines the interface for local storage operations. It provides methods for CRUD operations, reactive streams, querying, and synchronization support.

#### Core Methods

**Initialization & Lifecycle:**
- `initialize()`: Initializes the local storage (e.g., opens databases/boxes)
- `dispose()`: Cleans up resources (e.g., closes database connections)
- `checkHealth()`: Performs health checks on the adapter

**CRUD Operations:**
- `create(T entity)`: Creates a new entity
- `read(String id, {String? userId})`: Reads a single entity by ID
- `readAll({String? userId})`: Reads all entities
- `update(T entity)`: Updates an existing entity
- `patch({required String id, required Map<String, dynamic> delta, String? userId})`: Applies partial updates
- `delete(String id, {String? userId})`: Deletes an entity

**Reactive Streams:**
- `changeStream()`: Stream of changes occurring in local storage
- `watchAll({String? userId, bool includeInitialData = true})`: Watches all items with reactive updates
- `watchById(String id, {String? userId})`: Watches a single item by ID
- `watchAllPaginated(PaginationConfig config, {String? userId})`: Watches paginated results
- `watchQuery(DatumQuery query, {String? userId})`: Watches query results
- `watchStorageSize({String? userId})`: Watches storage size changes

**Querying:**
- `query(DatumQuery query, {String? userId})`: Executes one-time queries
- `readAllPaginated(PaginationConfig config, {String? userId})`: Reads paginated results
- `readByIds(List<String> ids, {required String userId})`: Reads multiple entities by IDs

**Synchronization Support:**
- `getPendingOperations(String userId)`: Gets pending sync operations
- `addPendingOperation(String userId, DatumSyncOperation<T> operation)`: Adds operations to sync queue
- `removePendingOperation(String operationId)`: Removes completed operations
- `getSyncMetadata(String userId)`: Retrieves sync state metadata
- `updateSyncMetadata(DatumSyncMetadata metadata, String userId)`: Updates sync metadata

**Migration & Schema:**
- `getStoredSchemaVersion()`: Gets current schema version
- `setStoredSchemaVersion(int version)`: Sets schema version
- `getAllRawData({String? userId})`: Gets raw data for migrations
- `overwriteAllRawData(List<Map<String, dynamic>> data, {String? userId})`: Overwrites data during migrations
- `transaction<R>(Future<R> Function() action)`: Executes operations in a transaction

**Utility:**
- `getStorageSize({String? userId})`: Gets storage size in bytes
- `clearUserData(String userId)`: Clears all data for a user
- `clear()`: Clears all data
- `getAllUserIds()`: Gets all user IDs with stored data

### RemoteAdapter<T>

The `RemoteAdapter<T>` abstract class defines the interface for remote storage operations, typically cloud services or REST APIs.

#### Core Methods

**Initialization & Lifecycle:**
- `initialize()`: Initializes the remote service (e.g., authentication, listeners)
- `dispose()`: Cleans up resources
- `checkHealth()`: Performs health checks
- `isConnected()`: Checks if remote service is reachable

**CRUD Operations:**
- `create(T entity)`: Creates entity on remote
- `read(String id, {String? userId})`: Reads entity from remote
- `readAll({String? userId, DatumSyncScope? scope})`: Reads all entities with optional scope
- `update(T entity)`: Updates entity on remote
- `patch({required String id, required Map<String, dynamic> delta, String? userId})`: Partial updates
- `delete(String id, {String? userId})`: Deletes entity from remote

**Reactive Streams:**
- `changeStream`: Stream of remote changes
- `watchAll({String? userId, DatumSyncScope? scope})`: Watches all remote items
- `watchById(String id, {String? userId})`: Watches single remote item
- `watchQuery(DatumQuery query, {String? userId})`: Watches remote query results

**Querying:**
- `query(DatumQuery query, {String? userId})`: Executes remote queries

**Synchronization Support:**
- `getSyncMetadata(String userId)`: Gets remote sync metadata
- `updateSyncMetadata(DatumSyncMetadata metadata, String userId)`: Updates remote sync metadata

**Change Stream Management:**
- `unsubscribeFromChanges()`: Stops listening to remote changes
- `resubscribeToChanges()`: Resumes listening to remote changes

## Adapter Health Status

Both adapters implement health checking through the `AdapterHealthStatus` enum:
- `healthy`: Adapter is functioning normally
- `degraded`: Adapter has issues but can still operate
- `unhealthy`: Adapter is not functioning properly
