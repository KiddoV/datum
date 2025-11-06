# Utils Module

The Utils module in Datum provides a collection of general-purpose utility functions and helpers that support various operations across the Datum ecosystem. These utilities aim to simplify common tasks and enhance code reusability.

## Key Components

### DatumConnectivityChecker

Abstract interface for checking network connectivity. Allows Datum to remain platform-agnostic by requiring users to provide concrete implementations.

**Interface Methods:**
- `isConnected`: Future<bool> - Checks if device is connected to network
- `onStatusChange`: Stream<bool> - Stream that emits connectivity status changes

**Example Implementation (Flutter):**
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class MyConnectivityChecker implements DatumConnectivityChecker {
  final _connectivity = Connectivity();

  @override
  Future<bool> get isConnected async =>
      !(await _connectivity.checkConnectivity()).contains(ConnectivityResult.none);

  @override
  Stream<bool> get onStatusChange => _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
}
```

### DatumLogger

Simple logging utility for Datum's internal operations and debugging.

**Configuration:**
- `enabled`: Whether logging is active (default: true)
- `colors`: Whether to use colored output (default: true)

**Methods:**
- `info(String message)`: Logs informational messages
- `debug(String message)`: Logs debug information
- `error(String message, [StackTrace? stackTrace])`: Logs errors with optional stack traces
- `warn(String message)`: Logs warning messages

**Usage:**
```dart
final logger = DatumLogger();
logger.info('Operation completed successfully');
logger.error('Failed to sync data', stackTrace);
```

### DurationFormatter

Utility for formatting time durations in human-readable formats.

**Key Methods:**
- `format(Duration duration)`: Formats duration to string (e.g., "2h 30m 45s")
- `formatCompact(Duration duration)`: Compact format (e.g., "2:30:45")
- `formatRelative(DateTime from, DateTime to)`: Relative time format (e.g., "3 minutes ago")

### HashGenerator

Generates hash values for data integrity verification and identification.

**Supported Algorithms:**
- MD5
- SHA-1
- SHA-256 (default)
- SHA-512

**Methods:**
- `generate(String input)`: Generates hash for string input
- `generateBytes(List<int> bytes)`: Generates hash for byte array
- `generateFile(String filePath)`: Generates hash for file contents

**Usage:**
```dart
final hashGen = HashGenerator();
final hash = hashGen.generate('my data');
// Use SHA-256 by default
```

### IsolateHelper

Utility for running computationally intensive operations in background isolates to prevent UI blocking.

**Key Methods:**
- `computeJsonEncode(Map<String, dynamic> data)`: Encodes JSON in background isolate
- `computeJsonDecode(String json)`: Decodes JSON in background isolate
- `computeHash(String data)`: Computes hash in background isolate
- `initialize()`: Initializes the isolate pool
- `dispose()`: Cleans up isolate resources

**Usage:**
```dart
final isolateHelper = IsolateHelper();
await isolateHelper.initialize();

// Encode large JSON payload without blocking UI
final encodedSize = await isolateHelper.computeJsonEncode(largeMap);
```
