## 1.0.1 (Unreleased)

- Refactored: Migrated from string-based type checking to `TypeChecker` for robust type handling.
- Added: `DatumConverter` support for custom field serialization/deserialization.
- Updated: `DatumField` annotation now accepts a `converter` parameter.
- Fixed: Improved handling of `Color`, `Offset`, `Duration`, `DateTime`, `Uri`, `BigInt` types.
- Enhanced `@DatumIgnore` annotation with optional flags:
  - `copyWith`: exclude from copyWith generation
  - `equality`: exclude from equality generation
  - `fromMap`: exclude from deserialization
  - `toMap`: exclude from serialization
- Updated: `ManyToMany` now supports passing `Type` for pivot entity instead of instance in generated code.


## 1.0.0

- Initial version.
