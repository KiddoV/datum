---
title: Health Module
---
The Health module provides comprehensive monitoring and diagnostics for the Datum system's operational status.

## Overview

Health monitoring is crucial for maintaining reliable data synchronization. The Health module tracks the status of all adapters, managers, and sync operations to ensure the system is functioning properly.

## Key Components

### DatumHealth

Represents the health status of a Datum component.

**Properties:**
- `status`: Current health status (`healthy`, `degraded`, `unhealthy`)
- `message`: Human-readable status description
- `timestamp`: When the health check was performed
- `details`: Additional diagnostic information (Map<String, dynamic>)

### HealthStatus Enum

Defines the possible health states:

- `healthy`: Component is functioning normally
- `degraded`: Component has issues but can still operate
- `unhealthy`: Component is not functioning properly

## Health Monitoring

### Manager Health

Each DatumManager provides health monitoring:

```dart
// Check health of a specific manager
final taskHealth = await Datum.manager<Task>().checkHealth();

// Get current health status
final currentHealth = Datum.manager<Task>().currentStatus.health;

// Watch health changes reactively
final healthStream = Datum.manager<Task>().health;
healthStream.listen((health) {
  switch (health.status) {
    case HealthStatus.healthy:
      print('Tasks manager is healthy');
      break;
    case HealthStatus.degraded:
      print('Tasks manager is degraded: ${health.message}');
      break;
    case HealthStatus.unhealthy:
      print('Tasks manager is unhealthy: ${health.message}');
      break;
  }
});
```

### Global Health Monitoring

Monitor health across all managers:

```dart
// Get health status of all managers
final allHealths = await Datum.instance.allHealths.first;

allHealths.forEach((entityType, health) {
  print('${entityType}: ${health.status} - ${health.message}');
});

// Watch global health changes
Datum.instance.allHealths.listen((healthMap) {
  final unhealthyCount = healthMap.values
      .where((health) => health.status == HealthStatus.unhealthy)
      .length;

  if (unhealthyCount > 0) {
    print('Warning: $unhealthyCount managers are unhealthy');
  }
});
```

## Health Checks

### Automatic Health Checks

Health checks run automatically during:

- Manager initialization
- Sync operations
- Periodic intervals (configurable)
- Manual health check requests

### Manual Health Checks

Trigger health checks manually:

```dart
// Check health of all managers
final results = await Future.wait([
  Datum.manager<Task>().checkHealth(),
  Datum.manager<User>().checkHealth(),
  Datum.manager<Post>().checkHealth(),
]);

// Check if any manager is unhealthy
final hasUnhealthy = results.any((health) => health.status == HealthStatus.unhealthy);
```

### Adapter Health

Adapters implement their own health checks:

```dart
// Local adapter health
final localHealth = await taskManager.localAdapter.checkHealth();

// Remote adapter health
final remoteHealth = await taskManager.remoteAdapter.checkHealth();
```

## Health Diagnostics

### Health Details

Health checks provide detailed diagnostic information:

```dart
final health = await Datum.manager<Task>().checkHealth();

print('Status: ${health.status}');
print('Message: ${health.message}');
print('Timestamp: ${health.timestamp}');

// Access detailed diagnostics
final details = health.details;
if (details != null) {
  print('Connection status: ${details['connection']}');
  print('Last sync: ${details['lastSyncTime']}');
  print('Pending operations: ${details['pendingCount']}');
  print('Storage size: ${details['storageSize']} bytes');
}
```

### Common Health Issues

**Local Adapter Issues:**
- Database connection failures
- Storage quota exceeded
- File system permissions
- Corruption detection

**Remote Adapter Issues:**
- Network connectivity problems
- Authentication failures
- API rate limiting
- Service unavailability

**Sync Issues:**
- Long-running sync operations
- High conflict rates
- Large pending operation queues
- Memory pressure

## Health-Based Actions

### Automatic Recovery

Configure automatic recovery actions:

```dart
final config = DatumConfig(
  // Automatic recovery settings
  errorRecoveryStrategy: DatumErrorRecoveryStrategy(
    maxRetries: 3,
    backoffStrategy: ExponentialBackoffStrategy(),
  ),

  // Health check intervals
  healthCheckInterval: Duration(minutes: 5),
);
```

### Manual Recovery

Implement manual recovery logic:

```dart
Future<void> recoverFromHealthIssues() async {
  final allHealths = await Datum.instance.allHealths.first;

  for (final entry in allHealths.entries) {
    final entityType = entry.key;
    final health = entry.value;

    if (health.status == HealthStatus.unhealthy) {
      print('Attempting to recover ${entityType}...');

      // Try to reinitialize the manager
      try {
        final manager = Datum.managerByType(entityType);
        await manager.dispose();
        // Reinitialize logic here
        print('Recovered ${entityType}');
      } catch (e) {
        print('Failed to recover ${entityType}: $e');
      }
    }
  }
}
```

## Health Metrics

### Performance Metrics

Track performance-related health metrics:

```dart
// Get detailed health with performance metrics
final health = await Datum.manager<Task>().checkHealth();

final details = health.details;
if (details != null) {
  final avgSyncTime = details['averageSyncDuration'];
  final syncSuccessRate = details['syncSuccessRate'];
  final storageUtilization = details['storageUtilizationPercent'];

  print('Avg sync time: ${avgSyncTime}ms');
  print('Success rate: ${(syncSuccessRate * 100).round()}%');
  print('Storage usage: ${storageUtilization}%');
}
```

### Trend Analysis

Monitor health trends over time:

```dart
class HealthMonitor {
  final List<DatumHealth> _healthHistory = [];

  void recordHealth(DatumHealth health) {
    _healthHistory.add(health);

    // Keep only recent history
    if (_healthHistory.length > 100) {
      _healthHistory.removeAt(0);
    }

    // Analyze trends
    final recentHealth = _healthHistory.sublist(_healthHistory.length - 10);
    final unhealthyCount = recentHealth
        .where((h) => h.status == HealthStatus.unhealthy)
        .length;

    if (unhealthyCount > 5) {
      print('Warning: Health deteriorating');
    }
  }
}
```

## Health Alerts

### Alert Configuration

Set up health-based alerts:

```dart
class HealthAlertSystem {
  void setupAlerts() {
    // Monitor all managers
    Datum.instance.allHealths.listen((healthMap) {
      for (final entry in healthMap.entries) {
        final entityType = entry.key;
        final health = entry.value;

        if (health.status == HealthStatus.unhealthy) {
          sendAlert(
            title: '${entityType} Manager Unhealthy',
            message: health.message,
            details: health.details,
          );
        }
      }
    });
  }

  void sendAlert({
    required String title,
    required String message,
    Map<String, dynamic>? details,
  }) {
    // Send alert via email, Slack, etc.
    print('ALERT: $title - $message');
  }
}
```

### Alert Types

**Critical Alerts:**
- Complete system failure
- Data corruption detected
- Authentication failures

**Warning Alerts:**
- Degraded performance
- High error rates
- Storage capacity warnings

**Info Alerts:**
- Recovery actions taken
- Configuration changes
- Maintenance notifications

## Best Practices

### Health Check Design

1. **Make health checks fast**: Keep checks lightweight to avoid impacting performance
2. **Provide actionable information**: Include specific details for troubleshooting
3. **Use appropriate timeouts**: Don't let health checks hang indefinitely
4. **Check dependencies**: Verify all required services are accessible

### Monitoring Strategy

1. **Monitor continuously**: Set up ongoing health monitoring
2. **Alert on degradation**: Catch issues before they become critical
3. **Automate recovery**: Implement automatic recovery where possible
4. **Log health changes**: Maintain history for trend analysis

### Alert Management

1. **Avoid alert fatigue**: Only alert on actionable issues
2. **Escalate appropriately**: Different severity levels for different issues
3. **Include context**: Provide enough information to diagnose issues
4. **Test alerts**: Ensure alerts work and reach the right people

### Performance Impact

1. **Minimize overhead**: Health checks should not significantly impact performance
2. **Use sampling**: For high-frequency metrics, consider sampling
3. **Cache results**: Cache health check results when appropriate
4. **Async checks**: Run health checks asynchronously to avoid blocking

## Troubleshooting

### Common Health Issues

**Database Connection Issues:**
```dart
// Check local adapter health
final localHealth = await manager.localAdapter.checkHealth();
if (localHealth.status == HealthStatus.unhealthy) {
  // Try to reconnect or reinitialize
  await manager.dispose();
  await manager.initialize();
}
```

**Network Connectivity Issues:**
```dart
// Check remote adapter health
final remoteHealth = await manager.remoteAdapter.checkHealth();
if (remoteHealth.status == HealthStatus.unhealthy) {
  // Wait for connectivity to recover
  await connectivityChecker.onStatusChange
      .where((connected) => connected)
      .first;
}
```

**Sync Performance Issues:**
```dart
// Check for large pending queues
final pendingCount = await manager.getPendingCount('user-id');
if (pendingCount > 1000) {
  print('Warning: Large pending queue may cause performance issues');
}
```

### Health Check Debugging

```dart
// Enable detailed logging
final config = DatumConfig(
  enableLogging: true,
  // ... other config
);

// Manually run health checks with timing
final stopwatch = Stopwatch()..start();
final health = await manager.checkHealth();
stopwatch.stop();

print('Health check took ${stopwatch.elapsedMilliseconds}ms');
print('Health details: ${health.details}');
```</content>
