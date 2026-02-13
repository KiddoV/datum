## 1.0.1

- Enhanced `@DatumIgnore` annotation with optional flags:
  - `copyWith`: exclude from copyWith generation
  - `equality`: exclude from equality generation
  - `fromMap`: exclude from deserialization
  - `toMap`: exclude from serialization
- Updated: `ManyToMany` now supports passing `Type` for pivot entity instead of instance in generated code.
## 1.0.0

- Initial version.
