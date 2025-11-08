## Cost and Licensing




Datum is **free and open-source**, released under the generous **MIT License**. You can use it in any personal or commercial project without any fees.

While the `datum` library itself is free, it is designed to connect to a backend service of your choice. Please be aware that you are responsible for any costs associated with the backend infrastructure you choose to use (e.g., Supabase, Firebase, self-hosted server costs).

If you find Datum useful and wish to support its continued development, you can do so through the [funding link](https://buymeacoffee.com/shreemanarjun) in the `pubspec.yaml`.

## Architectural Considerations

Using Datum requires adhering to a specific data model structure, which is a necessary trade-off for the powerful synchronization features it provides.

### 1. Mandatory Entity Fields

Any data model you want to synchronize with Datum must extend `DatumEntity`. This requires you to add several fields to your table schema:

-   `id (String)`: A unique identifier for each record.
-   `userId (String)`: The ID of the user who owns the data.
-   `createdAt (DateTime)`: Timestamp of when the record was created.
-   `modifiedAt (DateTime)`: Timestamp of the last modification, crucial for conflict resolution.
-   `version (int)`: A number that increments with each change, used for optimistic locking.
-   `isDeleted (bool)`: A flag for soft-deleting records, so deletions can be synced.

These fields are essential for tracking changes, resolving conflicts, and ensuring data integrity across devices.

### 2. Metadata Storage

Datum also requires a separate table or collection in your database (both local and remote) to store synchronization metadata, as represented by the `DatumSyncMetadata` class. This table stores comprehensive sync state information.

#### Backend Setup for DatumSyncMetadata

For your remote backend to work correctly with Datum, you need to create a `sync_metadata` table with the following structure:

**SQL (PostgreSQL/Supabase):**

```sql
CREATE TABLE sync_metadata (
  user_id TEXT PRIMARY KEY,
  last_sync_time TIMESTAMPTZ,
  last_successful_sync_time TIMESTAMPTZ,
  data_hash TEXT,
  device_id TEXT,
  devices JSONB DEFAULT '{}',
  custom_metadata JSONB,
  entity_counts JSONB DEFAULT '{}',
  sync_status TEXT NOT NULL DEFAULT 'neverSynced',
  sync_version INTEGER NOT NULL DEFAULT 1,
  server_timestamp TIMESTAMPTZ,
  conflict_count INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  retry_count INTEGER NOT NULL DEFAULT 0,
  sync_duration INTEGER
);

-- Enable RLS (Row Level Security) if using Supabase
ALTER TABLE sync_metadata ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to only access their own metadata
CREATE POLICY "Users can only access their own sync metadata"
ON sync_metadata FOR ALL USING (auth.uid()::text = user_id);
```

**Firestore (Firebase):**
```javascript
// Collection: sync_metadata
// Document ID: {userId}
// Fields:
{
  userId: "string", // (document ID)
  lastSyncTime: "Timestamp",
  lastSuccessfulSyncTime: "Timestamp",
  dataHash: "string",
  deviceId: "string",
  devices: { "deviceId": "Timestamp" },
  customMetadata: { "key": "any" },
  entityCounts: {
    "entityType": {
      count: 0,
      hash: "string",
      lastModified: "Timestamp",
      pendingChanges: 0
    }
  },
  syncStatus: "string", // 'neverSynced', 'syncing', 'synced', 'failed', 'pending', 'conflict'
  syncVersion: 1,
  serverTimestamp: "Timestamp",
  conflictCount: 0,
  errorMessage: "string",
  retryCount: 0,
  syncDuration: 0
}
```

```javascript
// Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /sync_metadata/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**MongoDB:**
```javascript
// Collection: sync_metadata
{
  _id: ObjectId(),
  userId: "String", // indexed, unique
  lastSyncTime: new Date(),
  lastSuccessfulSyncTime: new Date(),
  dataHash: "String",
  deviceId: "String",
  devices: {}, // { deviceId: Date }
  customMetadata: {},
  entityCounts: {}, // { entityType: { count, hash, lastModified, pendingChanges } }
  syncStatus: "String", // 'neverSynced', 'syncing', 'synced', 'failed', 'pending', 'conflict'
  syncVersion: 1,
  serverTimestamp: new Date(),
  conflictCount: 0,
  errorMessage: "String",
  retryCount: 0,
  syncDuration: 0
}
```

```javascript
// Create index
db.sync_metadata.createIndex({ userId: 1 }, { unique: true });
```

**MySQL:**
```sql
CREATE TABLE sync_metadata (
  user_id VARCHAR(255) PRIMARY KEY,
  last_sync_time DATETIME NULL,
  last_successful_sync_time DATETIME NULL,
  data_hash TEXT NULL,
  device_id VARCHAR(255) NULL,
  devices JSON DEFAULT ('{}'),
  custom_metadata JSON NULL,
  entity_counts JSON DEFAULT ('{}'),
  sync_status VARCHAR(20) NOT NULL DEFAULT 'neverSynced',
  sync_version INT NOT NULL DEFAULT 1,
  server_timestamp DATETIME NULL,
  conflict_count INT NOT NULL DEFAULT 0,
  error_message TEXT NULL,
  retry_count INT NOT NULL DEFAULT 0,
  sync_duration INT NULL,

  INDEX idx_user_id (user_id)
);
```

The metadata table must be accessible by your `RemoteAdapter` implementation, and the `user_id` field should match the user ID used throughout your Datum entities. This metadata is vital for the sync engine to operate efficiently and reliably.

### 3. Development and Maintenance Overhead

While Datum significantly reduces the boilerplate for synchronization, there is still a learning curve and ongoing development effort involved:

*   **Understanding Core Concepts**: Users need to grasp Datum's core concepts like `DatumEntity`, `Adapter` (Local and Remote), `DatumManager`, and conflict resolution strategies.
*   **Adapter Implementation**: You will need to implement custom `LocalAdapter` and `RemoteAdapter` classes to integrate Datum with your chosen local database and backend API. This involves writing code to map your entities to and from your database/API formats.
*   **Conflict Resolution Logic**: While Datum provides built-in strategies, complex applications may require custom conflict resolvers, which adds to development complexity.
*   **Schema Migrations**: As your data models evolve, you will need to manage schema migrations for both your local and remote databases, ensuring compatibility with Datum's requirements.

### 4. Performance and Storage Considerations

The architectural choices made for Datum, while enabling powerful features, can introduce some overhead:

*   **Storage Footprint**: The mandatory `DatumEntity` fields (`modifiedAt`, `version`, `isDeleted`) and the `DatumSyncMetadata` table add to the storage footprint of your application's data, both on the device and on the backend.
*   **Performance Impact**: While optimized, the additional logic for change tracking, conflict detection, and metadata management can introduce a slight performance overhead compared to direct, un-synced database operations. This is generally negligible for most applications but should be considered for extremely high-throughput or resource-constrained environments.
