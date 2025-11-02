<p align="center">
  <img src="https://zmozkivkhopoeutpnnum.supabase.co/storage/v1/object/public/images/datum_logo.png" alt="Datum Logo" width="200">
</p>

# **Datum Hive**


A Hive-based persistence layer for the Datum ecosystem, enabling efficient local data storage and synchronization for Flutter applications.

## Features

- Seamless integration with Datum for local data persistence.
- Leverages Hive's high performance and ease of use.
- Supports offline-first capabilities for Datum entities.
- Provides robust and reliable data storage.

## Getting started

### Prerequisites

Ensure you have the `datum` package integrated into your Flutter project.

### Installation

Add `datum_hive` to your `pubspec.yaml` file:

```yaml
dependencies:
  datum_hive: ^latest_version
```

Then, run `flutter pub get`.

## Usage

To integrate `datum_hive` with your Datum setup, you'll typically initialize Datum with `IsolatedHiveLocalAdapter` or `HiveLocalAdapter` for your entities.

First, define your Datum entity and a `fromMap` factory:

```dart
import 'package:datum/datum.dart';
import 'package:datum_hive/datum_hive.dart'; // For DatumHiveEntity
import 'package:hive_flutter/hive_flutter.dart'; // For Hive.initFlutter()

// Example Task entity
class Task extends DatumHiveEntity {
  Task(super.id, super.collection, {required this.title, required this.isComplete});

  final String title;
  final bool isComplete;

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      map['id'] as String,
      map['collection'] as String,
      title: map['title'] as String,
      isComplete: map['isComplete'] as bool,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(), // Include base DatumHiveEntity fields
      'title': title,
      'isComplete': isComplete,
    };
  }
}
```

Then, initialize Hive and Datum:

```dart
import 'package:datum/datum.dart';
import 'package:datum_hive/datum_hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:your_app/models/task.dart'; // Assuming Task is defined here
import 'package:your_app/services/connectivity_checker.dart'; // CustomConnectivityChecker
import 'package:your_app/services/datum_logger.dart'; // CustomDatumLogger
import 'package:your_app/observers/my_datum_observer.dart'; // MyDatumObserver
import 'package:your_app/remote_adapters/supabase_remote_adapter.dart'; // SupabaseRemoteAdapter

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Flutter apps
  await Hive.initFlutter(); // Initialize Hive

  // Example Datum configuration
  final config = DatumConfig(
    appName: 'MyAwesomeApp',
    // ... other configurations
  );

  final datum = await Datum.initialize(
    config: config,
    connectivityChecker: CustomConnectivityChecker(),
    logger: CustomDatumLogger(enabled: config.enableLogging),
    observers: [
      MyDatumObserver(),
    ],
    registrations: [
      DatumRegistration<Task>(
        // Use IsolatedHiveLocalAdapter for better performance in Flutter
        localAdapter: IsolatedHiveLocalAdapter<Task>(
          entityBoxName: "tasks", // Unique name for your Hive box
          fromMap: (map) => Task.fromMap(map),
          schemaVersion: 0, // Increment this when your entity schema changes
        ),
        // Or use HiveLocalAdapter if you don't need isolation
        // localAdapter: HiveLocalAdapter<Task>(
        //   entityBoxName: "tasks",
        //   fromMap: (map) => Task.fromMap(map),
        //   schemaVersion: 0,
        // ),
        remoteAdapter: SupabaseRemoteAdapter(
          tableName: 'tasks',
          fromMap: Task.fromMap,
        ),
      ),
      // Add more DatumRegistrations for other entities
    ],
  );

  // Now you can use Datum to interact with your data
  final task = Task('123', 'tasks', title: 'Buy groceries', isComplete: false);
  await datum.save(task);
  final fetchedTask = await datum.get<Task>('123', 'tasks');
  print(fetchedTask?.title);
}
```


## Additional information

For more information on Datum, visit the
[Datum documentation](https://datum.dev).
To contribute or report issues, please visit the [GitHub repository](https://github.com/Shreemanarjun/datum).
For issue tracking, please visit [GitHub issues](https://github.com/Shreemanarjun/datum/issues).
