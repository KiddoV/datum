---
title: Quick Start
---


## Installation

Add Datum to your Dart or Flutter project:

### Add to pubspec.yaml
```bash
flutter pub add datum
```
### Or for pure Dart projects

```bash
dart pub add datum
```

## Define Your First Entity

Create a simple entity by extending `DatumEntity`:

```dart
import 'package:datum/datum.dart';

class Task extends DatumEntity {
  @override
  final String id;
  @override
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  @override
  final DateTime createdAt;
  @override
  final DateTime modifiedAt;
  @override
  final bool isDeleted;
  @override
  final int version;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    required this.modifiedAt,
    this.isDeleted = false,
    this.version = 1,
  });

  @override
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isDeleted,
    int? version,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
    );
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'version': version,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      modifiedAt: DateTime.parse(map['modifiedAt'] as String),
      isDeleted: map['isDeleted'] as bool? ?? false,
      version: map['version'] as int? ?? 1,
    );
  }
}
```

## Create Adapters

Implement local and remote adapters for your entity:

```dart
// Local adapter (using Hive as example)
class HiveTaskAdapter extends LocalAdapter<Task> {
  final Box<Task> _box;

  HiveTaskAdapter(this._box);

  @override
  Future<void> create(Task item) async {
    await _box.put(item.id, item);
  }

  @override
  Future<Task?> read(String id, {String? userId}) async {
    return _box.get(id);
  }

  @override
  Future<List<Task>> readAll({String? userId}) async {
    return _box.values.where((task) => task.userId == userId).toList();
  }

  @override
  Future<void> update(Task item) async {
    await _box.put(item.id, item);
  }

  @override
  Future<bool> delete(String id, {String? userId}) async {
    await _box.delete(id);
    return true;
  }

  // ... implement other required methods
}

// Remote adapter (REST API example)
class RestTaskAdapter extends RemoteAdapter<Task> {
  final Dio _dio;

  RestTaskAdapter(this._dio);

  @override
  Future<void> create(Task item) async {
    await _dio.post('/tasks', data: item.toDatumMap(target: MapTarget.remote));
  }

  @override
  Future<List<Task>> readAll({String? userId, DatumSyncScope? scope}) async {
    final response = await _dio.get('/tasks', queryParameters: {'userId': userId});
    return (response.data as List)
        .map((json) => Task.fromMap(json))
        .toList();
  }

  // ... implement other required methods
}
```

## Initialize Datum

Set up Datum in your app:

```dart
import 'package:datum/datum.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (or your local storage)
  await Hive.initFlutter();
  final taskBox = await Hive.openBox<Task>('tasks');

  // Initialize Datum
  final datum = await Datum.initialize(
    config: const DatumConfig(),
    connectivityChecker: ConnectivityChecker(), // Implement this
    registrations: [
      DatumRegistration<Task>(
        localAdapter: HiveTaskAdapter(taskBox),
        remoteAdapter: RestTaskAdapter(Dio()),
      ),
    ],
  );

  runApp(MyApp());
}
```

## Use Datum in Your App

Now you can use Datum for data operations:

```dart
class TaskList extends StatefulWidget {
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  late Stream<List<Task>> _tasksStream;

  @override
  void initState() {
    super.initState();
    // Watch for task changes
    _tasksStream = Datum.watchAll<Task>(userId: 'current-user-id') ?? Stream.empty();
  }

  Future<void> _addTask(String title) async {
    final task = Task(
      id: Uuid().v4(),
      userId: 'current-user-id',
      title: title,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    await Datum.create(task);
    // Changes will automatically sync and update the UI via the stream
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final task = snapshot.data![index];
            return ListTile(
              title: Text(task.title),
              trailing: Checkbox(
                value: task.isCompleted,
                onChanged: (value) async {
                  await Datum.update(task.copyWith(isCompleted: value));
                },
              ),
            );
          },
        );
      },
    );
  }
}
```

## Next Steps

- **[Changelog](changelog)**: See what's new in the latest version
- **[Complete Entity Definition](guides/entity_define)**: Learn about relational entities and advanced patterns
- **[Adapter Implementation](guides/local_adapter_implement)**: Deep dive into adapter patterns
- **[Sync Patterns](guides/sync_patterns)**: Master synchronization strategies
- **[Advanced Features](guides/advanced_sync)**: Production-ready synchronization features

This quick start gets you up and running with basic Datum functionality. As you build more complex features, explore the other guides for advanced patterns and best practices.
