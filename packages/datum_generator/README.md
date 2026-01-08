# Datum Generator

A code generation package for the [Datum](https://pub.dev/packages/datum) framework that automatically generates boilerplate code for your Datum entities, including serialization, deserialization, diff tracking, and copy methods.

## Features

- **Automatic Serialization**: Generates `toDatumMap()` methods for converting entities to maps
- **Smart Deserialization**: Creates `fromMap()` factory constructors with type-safe parsing
- **Diff Tracking**: Automatically generates `diff()` methods to track changes between entity versions
- **Copy Methods**: Generates both `copyWith()` and `copyWithAll()` methods with automatic version incrementing
- **Equality & HashCode**: Creates `datumEquals()` and `datumHashCode` for proper equality comparisons
- **Type-Specific Handling**: Built-in support for `DateTime`, `Color`, `Offset`, `List<Offset>`, and other complex types
- **Custom Field Mapping**: Use annotations to customize field names and exclude fields from serialization
- **Snake Case Conversion**: Automatically converts camelCase field names to snake_case for database compatibility

## Getting Started

### 1. Add Dependencies

Add `datum_generator` as both a regular dependency (for annotations) and a dev dependency (for the builder):

```yaml
dependencies:
  datum: ^1.0.0
  datum_generator: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.0
  datum_generator: ^1.0.0
```

### 2. Run `pub get`

```bash
flutter pub get
```

## Usage

### Basic Example

1. **Annotate your entity class** with `@DatumSerializable`:

```dart
import 'package:datum/datum.dart';
import 'package:datum_generator/datum_generator.dart';

part 'user.g.dart';

@DatumSerializable(tableName: 'users')
class User extends DatumEntity {
  @override
  final String id;

  @override
  final String userId;

  final String name;
  final int age;
  final String email;

  @override
  final DateTime createdAt;

  @override
  final DateTime modifiedAt;

  @override
  final int version;

  @override
  final bool isDeleted;

  const User({
    required this.id,
    required this.userId,
    required this.name,
    required this.age,
    required this.email,
    required this.createdAt,
    required this.modifiedAt,
    this.version = 1,
    this.isDeleted = false,
  });

  @override
  Map<String, dynamic>? diff(covariant DatumEntityInterface oldVersion) {
    return datumDiff(oldVersion);
  }

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) {
    return datumToMap(target: target);
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return _$UserFromMap(map);
  }

  @override
  DatumEntity copyWith({
    DateTime? modifiedAt,
    int? version,
    bool? isDeleted,
  }) {
    return copyWithAll(
      modifiedAt: modifiedAt,
      version: version,
      isDeleted: isDeleted,
    );
  }

  @override
  bool operator ==(Object other) => other is User && datumEquals(other);

  @override
  int get hashCode => datumHashCode;
}
```

2. **Run the code generator**:

```bash
flutter pub run build_runner build
```

Or for continuous generation during development:

```bash
flutter pub run build_runner watch
```

This will generate a `user.g.dart` file with all the boilerplate code.

### Advanced Features

#### Custom Field Names

Use `@DatumField` to specify custom field names for database mapping:

```dart
@DatumSerializable()
class Product extends DatumEntity {
  final String id;

  @DatumField('product_name')
  final String name;

  @DatumField('unit_price')
  final double price;

  // ... other fields
}
```

#### Ignoring Fields

Use `@DatumIgnore()` to exclude fields from serialization:

```dart
@DatumSerializable()
class User extends DatumEntity {
  final String id;
  final String name;

  @DatumIgnore()
  final String temporaryToken; // Won't be serialized

  // ... other fields
}
```

#### Relational Entities

For entities with relationships, extend `RelationalDatumEntity`:

```dart
@DatumSerializable(tableName: 'paint_canvases')
class PaintCanvas extends RelationalDatumEntity {
  @override
  final String id;

  final String title;
  final int strokeCount;

  // ... other fields

  @override
  Map<String, Relation> get relations => {
    'strokes': HasMany<PaintStroke>(
      this,
      'canvasId',
      cascadeDeleteBehavior: CascadeDeleteBehavior.cascade,
    ),
  };
}
```

#### Complex Types

The generator handles complex types automatically:

```dart
@DatumSerializable()
class DrawingEntity extends DatumEntity {
  final Color color;              // Serialized as int (ARGB)
  final List<Offset> points;      // Serialized as List<Map> with x, y
  final double strokeWidth;       // Handled with proper type conversion

  // ... other fields
}
```

### Generated Methods

The generator creates the following extension methods on your class:

- **`datumToMap({MapTarget target})`**: Converts the entity to a map
  - `MapTarget.local`: Uses millisecondsSinceEpoch for dates
  - `MapTarget.remote`: Uses ISO8601 strings for dates

- **`datumDiff(DatumEntityInterface oldVersion)`**: Returns a map of changed fields

- **`copyWith({DateTime? modifiedAt, int? version, bool? isDeleted})`**: Creates a copy with updated metadata

- **`copyWithAll({...})`**: Creates a copy with any field updated, auto-incrementing version

- **`datumEquals(YourClass other)`**: Compares all fields for equality

- **`datumHashCode`**: Generates a hash code from all fields

And a top-level factory function:

- **`_$YourClassFromMap(Map<String, dynamic> map)`**: Creates an instance from a map

## Configuration

### build.yaml

The generator is pre-configured to work with the following directory structure:

```yaml
targets:
  $default:
    builders:
      datum_generator|datumBuilder:
        enabled: true
        generate_for:
          - lib/**
          - test/**
```

You can customize this in your package's `build.yaml` if needed.

## Best Practices

1. **Always include the part directive**: `part 'your_file.g.dart';`
2. **Use const constructors** when possible for better performance
3. **Implement `operator ==` and `hashCode`** using the generated methods
4. **Run the generator** after making changes to your entity classes
5. **Commit generated files** to version control for consistency

## Troubleshooting

### Generator not running?

Make sure you have:
- Added the `part` directive to your file
- Annotated your class with `@DatumSerializable`
- Run `flutter pub run build_runner build`

### Build errors?

Try cleaning the build cache:

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Type errors in generated code?

Ensure all fields have explicit types and are not using `var` or `dynamic`.

## Additional Information

For more information about the Datum framework, visit:
- [Datum Package](https://pub.dev/packages/datum)
- [GitHub Repository](https://github.com/yourusername/datum)

To report issues or contribute:
- [Issue Tracker](https://github.com/yourusername/datum/issues)
- [Contributing Guide](https://github.com/yourusername/datum/blob/main/CONTRIBUTING.md)
