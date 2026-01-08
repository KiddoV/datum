# 🚀 Datum Improvements Roadmap

This document tracks planned improvements and future directions for the **Datum** framework.

## 1. Ecosystem & Concrete Adapters
- [ ] **First-Party Adapters**: Official packages for Hive, Isar, Drift (SQLite), and Supabase.
- [ ] **Web Support**: Enhanced adapters for IndexedDB/localStorage with better performance.

## 2. Relational Data Enhancements
- [x] **Eager Loading**: Support `withRelated` in `read()` and `readAll()` to solve N+1 query problems. ✅ **COMPLETE**
- [x] **Advanced Cascade Controls**: More granular deletion behaviors (e.g., `SetNull`) and visualization of delete plans. ✅ **COMPLETE**
- [x] **Transactional Relationships**: Atomic saves for entities and their pivot/related records. ✅ **COMPLETE**

## 3. Performance & scaling
- [x] **Batch Operations**: Support for batch push/pull in adapters and sync engine ✅ **COMPLETE** (Includes comprehensive test suite with 14 edge case scenarios and 100% pass rate)
- [x] **LRU Cache**: Size-limited caching in `DatumManager` to prevent memory bloat. ✅ **COMPLETE**
- [x] **Full Isolate Syncing**: Offloading the entire synchronizer to a background Isolate. ✅ **COMPLETE**

## 4. Advanced Sync Logic
- [x] **Conflict Resolution Strategies**: Initial support for CRDT-based merging implemented via `VectorClock` and `DatumEntityInterface.merge()`.
- [x] **Vector Clocks**: Implemented for complex multi-device conflict detection and causality tracking (moving beyond simple version numbers).

## 5. Developer Experience (DX) & Tooling
- [ ] **Code Generation**: Automate `toDatumMap`, `fromMap`, `diff`, and `copyWith` using `build_runner`.
- [ ] **CLI Migration Tools**: Manage schema migrations via command line.
- [ ] **Datum DevTools**: Inspector for local DB, sync queue, and conflict simulation.

## 6. Robustness & Security
- [ ] **Encryption at Rest**: Standardized field-level encryption.
- [ ] **Storage Pressure Handling**: Logic for handling low disk space.
- [ ] **Idempotency Keys**: Enhanced duplicate prevention in remote push.

## 7. Testing & Observability
- [ ] **OpenTelemetry**: Hooks for performance tracing and monitoring.
- [ ] **Mocking Utilities**: Ready-to-use mocks for common dependencies.
