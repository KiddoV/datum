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

Enhanced logging utility for Datum's internal operations with structured logging, performance monitoring, and sampling capabilities.

**Configuration:**
- `enabled`: Whether logging is active (default: true)
- `colors`: Whether to use colored output (default: true)
- `minimumLevel`: Minimum log level to output (default: LogLevel.info)
- `samplers`: Map of category-specific sampling strategies
- `enablePerformanceLogging`: Whether to log performance metrics (default: false)
- `performanceThreshold`: Minimum duration to log performance (default: 100ms)

**Log Levels:**
- `trace`: Most detailed level, typically disabled in production
- `debug`: Detailed debugging information
- `info`: General information about system operation
- `warn`: Warning about potentially harmful situations
- `error`: Error conditions that don't stop the application
- `fatal`: Severe error conditions that may stop the application

**Structured Logging:**
```dart
final logger = DatumLogger();

// Basic logging
logger.info('Operation completed successfully');
logger.error('Failed to sync data', stackTrace);

// Structured logging with metadata
logger.log(LogEntry(
  timestamp: DateTime.now(),
  level: LogLevel.info,
  message: 'User login',
  category: 'auth',
  metadata: {'userId': '123', 'method': 'email'},
));

// Performance logging
logger.logPerformance(
  operation: 'sync_user_data',
  duration: Duration(milliseconds: 250),
  metadata: {'userId': '123', 'items': 50},
);

// Sync-specific logging
logger.logSync(
  level: LogLevel.info,
  message: 'Sync completed',
  userId: '123',
  itemCount: 25,
  metadata: {'conflicts': 2},
);
```

**Sampling Strategies:**
```dart
// Rate limiting sampler
final rateLimiter = RateLimitingSampler(
  window: Duration(minutes: 1),
  maxLogsPerWindow: 10,
);

// Count-based sampler (log every Nth occurrence)
final countSampler = CountBasedSampler(sampleRate: 100);

// Configure logger with samplers
final logger = DatumLogger(
  minimumLevel: LogLevel.debug,
  samplers: {
    'performance': rateLimiter,  // Limit performance logs
    'sync': countSampler,        // Sample sync logs
  },
  enablePerformanceLogging: true,
  performanceThreshold: Duration(milliseconds: 50),
);
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
