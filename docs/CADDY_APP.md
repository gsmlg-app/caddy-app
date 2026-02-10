# Caddy App Development Guide

## Overview

Caddy App is a Flutter application for running and managing the Caddy web server. This guide explains the current implementation status and architecture for contributors.

## Implementation Status

### ✅ Implemented Features

#### Core UI (M1-M5)
- **Dashboard Screen** - Server status, metrics, and controls
  - Status indicator (running/stopped/error/loading)
  - Start/Stop/Reload buttons
  - Live uptime counter (HH:MM:SS format)
  - Request counter
  - Listen address display
  - Admin API toggle
  - Auto-restart on app resume toggle

- **Configuration Management** - Visual and raw JSON editors
  - Simple config form (listen address, routes, TLS, storage)
  - Raw JSON editor with syntax highlighting
  - Config validation before save/apply
  - Config presets (Static File, Reverse Proxy, SPA, API Gateway, HTTPS+DNS, HTTPS+S3)
  - Save/load named configurations (persisted to SQLite)
  - Delete saved configurations
  - Export config to file
  - Add/remove routes dialog

- **Log Viewer** - Real-time log streaming with filtering
  - Log level filtering (All/DEBUG/INFO/WARN/ERROR)
  - Search/filter logs by text query
  - Color-coded log lines by level
  - Auto-scroll with pause/resume
  - Copy logs to clipboard
  - Export logs to file
  - Clear log buffer
  - 10,000 entry rolling buffer

- **Secrets Management** - Secure credential storage
  - Store/retrieve secrets in platform-native secure storage
  - Android Keystore, iOS Keychain, libsecret (Linux), Keychain (macOS)
  - Add/update/delete secrets by key name
  - Secrets injected as environment variables at Caddy start

#### State Management
- **BLoC Pattern** - `CaddyBloc` for server lifecycle
  - Events: Start, Stop, Reload, StatusCheck, UpdateConfig, LogReceived, ClearLogs, ToggleAdmin, SetLogFilter, SetLogSearch, LifecyclePause, LifecycleResume, SaveConfig, LoadNamedConfig, DeleteSavedConfig, ToggleAutoRestart
  - States: CaddyStopped, CaddyRunning, CaddyError, CaddyLoading
  - Equatable for efficient rebuilds

#### Data Layer
- **Database** - Drift (SQLite) for persistent storage
  - `CaddyConfigs` table: id, name, configJson, adminEnabled, isActive, createdAt
  - Methods: getAllCaddyConfigs, getActiveCaddyConfig, upsertCaddyConfig, deleteCaddyConfig, setActiveCaddyConfig

- **Secure Storage** - `app_secure_storage` package
  - Platform-native encrypted storage
  - Key-value storage for API tokens and credentials

#### App Lifecycle
- **Auto-pause on background** - Optionally stops Caddy when app is paused
- **Auto-restart on foreground** - Configurable restart when app resumes
- **Crash recovery** - Detects orphaned Caddy instances on startup

#### Testing
- **Widget Tests** - 667 lines across 4 Caddy screen test files
- **BLoC Tests** - 30+ tests for state transitions
- **Database Tests** - Tests for CRUD operations
- **Accessibility** - Semantic labels for screen readers

### 🚧 Not Yet Implemented (Requires Native Go Layer)

The UI is fully functional but operates in **mock mode**. The following require Go/Caddy native integration:

#### Go Bridge Layer
- [ ] **Go shared library** (`caddy_bridge/`) with C exports
  - [ ] `startCaddy(configJSON)` - Launch Caddy with config
  - [ ] `stopCaddy()` - Graceful shutdown
  - [ ] `reloadCaddy(configJSON)` - Hot reload config
  - [ ] `getCaddyStatus()` - Get status JSON
  - [ ] Log streaming via platform channels

#### Platform Channels
- [ ] **Android** - MethodChannel + EventChannel integration
  - [ ] Load `.aar` from `gomobile bind`
  - [ ] JNI bindings in Kotlin

- [ ] **Linux** - dart:ffi integration
  - [ ] Load `.so` via DynamicLibrary
  - [ ] FFI bindings in Dart

- [ ] **iOS** - MethodChannel + EventChannel (P2 priority)
  - [ ] Load `.xcframework` from `gomobile bind`
  - [ ] Swift/Objective-C bindings

- [ ] **macOS** - dart:ffi integration (P1 priority)
  - [ ] Load `.dylib` via DynamicLibrary
  - [ ] FFI bindings in Dart

#### Caddy Modules (via xcaddy)
The Go library must be built with xcaddy to include:

- [ ] **DNS Providers** (for ACME DNS-01 challenges)
  - [ ] `github.com/caddy-dns/cloudflare`
  - [ ] `github.com/caddy-dns/route53`
  - [ ] `github.com/caddy-dns/duckdns`

- [ ] **S3 Storage** (for certificate persistence)
  - [ ] `github.com/ss098/certmagic-s3`

#### Security
- [ ] Environment variable injection for secrets
- [ ] Config validation using real Caddy binary
- [ ] Port conflict detection and user-facing messages

## Architecture

### Directory Structure

```
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Root MaterialApp widget
│   ├── router.dart                  # GoRouter configuration
│   ├── destination.dart             # Navigation destinations
│   └── screens/
│       └── caddy/
│           ├── caddy_screen.dart           # Dashboard
│           ├── caddy_config_screen.dart    # Config editor
│           ├── caddy_log_screen.dart       # Log viewer
│           └── caddy_secrets_screen.dart   # Secrets manager
│
├── app_bloc/
│   └── caddy/
│       └── lib/
│           ├── caddy_bloc.dart      # Barrel export
│           └── src/
│               ├── bloc.dart        # CaddyBloc implementation
│               ├── event.dart       # CaddyEvent sealed class
│               └── state.dart       # CaddyState class
│
├── app_lib/
│   ├── database/                    # Drift database for config persistence
│   ├── locale/                      # L10n (English ARB files)
│   ├── logging/                     # AppLogger singleton
│   ├── provider/                    # MainProvider (repos + ThemeBloc)
│   └── secure_storage/              # SecureStorageVaultRepository
│
└── test/
    └── screens/caddy/               # 4 widget test files (667 lines)
```

### Service Layer (`caddy_service`)

The `caddy_service` package defines the interface between the UI and the native Caddy bridge:

```dart
abstract class CaddyService {
  Future<CaddyStatus> start(CaddyConfig config, {bool adminEnabled, Map<String, String> environment});
  Future<CaddyStatus> stop();
  Future<CaddyStatus> reload(CaddyConfig config, {bool adminEnabled, Map<String, String> environment});
  Future<CaddyStatus> getStatus();
  Stream<String> get logStream;
}
```

**Current Implementation**: `MockCaddyService` returns simulated responses.

**Future Implementation**: `PlatformCaddyService` will use MethodChannel (mobile) or FFI (desktop) to call the Go bridge.

### Data Models

#### `CaddyConfig` (from `caddy_service`)
```dart
class CaddyConfig {
  final String listenAddress;        // e.g., "localhost:2015"
  final List<CaddyRoute> routes;     // List of routes
  final CaddyTlsConfig? tls;         // TLS settings
  final CaddyStorageConfig? storage; // S3 storage config
  final String? rawJson;             // Raw JSON override
}
```

#### `CaddyStatus` (sealed union)
- `CaddyStopped()` - Server is not running
- `CaddyRunning(String config, DateTime startedAt)` - Server running with config
- `CaddyError(String message)` - Server encountered error
- `CaddyLoading()` - Transitioning state

#### `SavedCaddyConfig` (from `app_database`)
Database model for persisted configs:
```dart
@DataClassName('SavedCaddyConfig')
class CaddyConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get configJson => text()();
  BoolColumn get adminEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

### State Flow

1. **App Launch** → `CaddyBloc` initialized with `CaddyService`
2. **User taps "Start"** → `CaddyStart` event dispatched
3. **Bloc** → Calls `service.start(config)` → Emits `CaddyRunning` state
4. **UI** → Rebuilds with running status, shows Stop/Reload buttons
5. **Log streaming** → `service.logStream` → `CaddyLogReceived` events → Appended to `state.logs`
6. **Config save** → `CaddySaveConfig` event → Persists to database via `AppDatabase.upsertCaddyConfig`
7. **Config load** → `CaddyLoadNamedConfig` event → Reads from database → Updates `state.config`

### Testing Strategy

#### Widget Tests
- **Screen rendering** - Verify widgets appear
- **State-driven UI** - Mock BLoC states, verify UI updates
- **User interactions** - Tap buttons, verify events dispatched
- **Accessibility** - Semantic labels for screen readers

#### BLoC Tests (using `bloc_test`)
```dart
blocTest<CaddyBloc, CaddyState>(
  'CaddyStart transitions to running state',
  build: () => CaddyBloc(MockCaddyService()),
  act: (bloc) => bloc.add(CaddyStart(const CaddyConfig())),
  expect: () => [
    isA<CaddyState>().having((s) => s.status, 'status', isA<CaddyLoading>()),
    isA<CaddyState>().having((s) => s.status, 'status', isA<CaddyRunning>()),
  ],
);
```

#### Database Tests
- CRUD operations on `CaddyConfigs` table
- Active config detection
- Unique name constraint enforcement

## Next Steps for Contributors

### High Priority
1. **Implement Go Bridge** - Build `caddy_bridge/` with cgo/gomobile
2. **Platform Channel Integration** - Wire up Android and Linux first
3. **xcaddy Build** - Add DNS and S3 modules to Makefile

### Medium Priority
4. **Error Recovery** - Port-in-use detection, crash recovery UX
5. **Integration Tests** - Multi-screen flows, end-to-end scenarios
6. **Performance** - Profile log rendering, optimize large config editing

### Low Priority
7. **Background Service** - Android foreground service for persistent Caddy
8. **iOS Port** - Requires App Store policy review for web server apps
9. **Caddyfile Support** - Embed Caddyfile adapter for text-based config

## Development Commands

```bash
# Setup
melos bootstrap
mason get

# Run app (mockup mode)
flutter run

# Run tests
melos run test

# Analysis
melos run analyze

# Format
melos run format
```

## Contributing

1. Read `CLAUDE.md` for project conventions
2. Use `/project-development` skill to choose the right workflow
3. Follow BLoC pattern for state management
4. Add tests for new features
5. Update this guide when adding major features

## Resources

- [PRD](../PRD.md) - Product Requirements Document
- [CLAUDE.md](../CLAUDE.md) - Claude Code integration guide
- [Caddy Docs](https://caddyserver.com/docs/) - Official Caddy documentation
- [xcaddy](https://github.com/caddyserver/xcaddy) - Caddy module builder
