# Caddy App Development Guide

## Overview

Caddy App is a Flutter application for running and managing the Caddy web server. This guide explains the implementation architecture for contributors.

## Implementation Status

### Go Bridge Layer (Implemented)

The Go bridge (`go/caddy_bridge/`) provides native Caddy integration:

- **Desktop** (Linux/macOS): cgo shared library (`.so`/`.dylib`) loaded via `dart:ffi`
- **Mobile** (Android/iOS): gomobile library (`.aar`/`.xcframework`) via MethodChannel

C exports: `StartCaddy`, `StopCaddy`, `ReloadCaddy`, `GetCaddyStatus`, `SetEnvironment`

Custom Caddy modules compiled in via blank imports:
- `github.com/caddy-dns/cloudflare` — DNS challenge for Cloudflare
- `github.com/caddy-dns/route53` — DNS challenge for AWS Route 53
- `github.com/caddy-dns/duckdns` — DNS challenge for DuckDNS
- `github.com/ss098/certmagic-s3` — S3 certificate storage

### Platform Integration (Implemented)

- **Linux**: `CaddyFfi` loads `libcaddy_bridge.so`, CMakeLists bundles it
- **macOS**: `CaddyFfi` loads `libcaddy_bridge.dylib`, Xcode build phase copies it
- **Android**: `CaddyMethodHandler.kt` + `CaddyLogStream.kt` route to gomobile AAR
- **iOS**: xcframework build target ready (P2 priority)

### Core UI (Implemented)

- **Dashboard Screen** — Server status, metrics, start/stop/reload controls, uptime counter, request counter, admin API toggle, auto-restart toggle, keyboard shortcuts (Ctrl+S/Q/R)
- **Configuration Management** — Visual editor (listen address, routes, TLS, S3 storage), raw JSON editor, config presets, save/load/delete named configs, drag-and-drop route reordering, config diff dialog, import/export
- **Log Viewer** — Real-time log streaming, level filtering, text search, color-coded lines, auto-scroll, copy-to-clipboard (long press), export, 10K entry rolling buffer
- **Secrets Management** — Platform-native secure storage, add/update/delete secrets, injected as env vars at Caddy start (prefix `caddy_` → stripped)
- **Home Screen** — Server status card, quick actions grid

### State Management (BLoC Pattern)

`CaddyBloc` handles 18 event types: Start, Stop, Reload, StatusCheck, UpdateConfig, SaveConfig, LoadSavedConfig, LoadNamedConfig, DeleteSavedConfig, LogReceived, ClearLogs, SetLogFilter, SetLogSearch, ToggleAdmin, ToggleAutoRestart, LifecyclePause, LifecycleResume, Initialize

Sealed status types: `CaddyStopped`, `CaddyRunning`, `CaddyError`, `CaddyLoading`

### Data Layer

- **Database** — Drift (SQLite) for config persistence (`CaddyConfigs` table)
- **Secure Storage** — `SecureStorageVaultRepository` with namespace support
- **App Lifecycle** — Auto-pause on background, auto-restart on foreground, crash recovery

### Testing

- **Main App**: 196 widget tests covering all screens
- **CaddyBloc**: 51+ BLoC tests (state transitions, lifecycle, secrets, config persistence)
- **CaddyConfig**: 49+ model tests (serialization, presets, TLS, S3)
- **CaddyService**: 28+ service tests (start/stop/reload, FFI, MethodChannel)
- **CaddyMethodChannel**: 16 tests (method invocation, result handling)
- **Go Bridge**: 11 Go unit tests (status, environment, thread safety)
- **Other**: 250+ tests across theme, navigation, database, logging, provider, widgets

## Architecture

### Directory Structure

```
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Root MaterialApp with lifecycle observer
│   ├── router.dart                  # GoRouter configuration
│   ├── destination.dart             # Navigation destinations
│   └── screens/
│       ├── app/                     # Splash, error screens
│       ├── home/                    # Home dashboard
│       ├── caddy/                   # Server, config, logs, secrets
│       └── settings/                # Appearance, theme, app settings
│
├── go/caddy_bridge/
│   ├── bridge.go                    # Desktop FFI exports (cgo)
│   ├── bridge_mobile.go             # Mobile exports (gomobile)
│   ├── modules.go                   # Desktop Caddy module imports
│   ├── modules_mobile.go            # Mobile Caddy module imports
│   ├── bridge_test.go               # Go unit tests
│   └── Makefile                     # Build targets per platform
│
├── app_bloc/caddy/                  # CaddyBloc state management
├── app_plugin/caddy/                # CaddyService, CaddyConfig, CaddyFfi
├── app_lib/
│   ├── database/                    # Drift database
│   ├── locale/                      # L10n (English ARB)
│   ├── logging/                     # AppLogger
│   ├── provider/                    # MainProvider, AppBlocProvider
│   └── secure_storage/              # VaultRepository
└── Makefile                         # Root build orchestration
```

### Service Layer

```dart
class CaddyService {
  Future<CaddyStatus> start(CaddyConfig config, {
    bool adminEnabled, Map<String, String> environment});
  Future<CaddyStatus> stop();
  Future<CaddyStatus> reload(CaddyConfig config, {
    bool adminEnabled, Map<String, String> environment});
  Future<CaddyStatus> getStatus();
  Stream<String> get logStream;
}
```

Routes to `CaddyFfi` (desktop) or `CaddyMethodChannel` (mobile) based on platform.

### Secrets Injection

1. BLoC reads vault entries prefixed with `caddy_`
2. Strips prefix: `caddy_CF_API_TOKEN` → `CF_API_TOKEN`
3. Passes as environment map to `CaddyService.start()`
4. Service calls `SetEnvironment()` on native bridge before loading config
5. Caddy config references secrets via `{env.VARIABLE_NAME}` placeholders

### State Flow

1. **App Launch** → `CaddyInitialize` → detect orphaned instances, load saved configs
2. **User taps Start** → `CaddyStart` → inject secrets → `service.start()` → `CaddyRunning`
3. **Log streaming** → `service.logStream` → `CaddyLogReceived` → append to rolling buffer
4. **Config save** → `CaddySaveConfig` → persist to database via `AppDatabase`
5. **App backgrounded** → `CaddyLifecyclePause` → optionally stop Caddy
6. **App resumed** → `CaddyLifecycleResume` → optionally restart with saved config

## Build

```bash
# Full setup
make setup

# Build Go bridge
make bridge-linux    # Linux .so
make bridge-macos    # macOS .dylib
make bridge-android  # Android .aar
make bridge-test     # Run Go tests

# Build Flutter app (includes Go bridge)
make build-linux
make build-macos

# Quality checks
make test            # All Flutter/Dart tests
make analyze         # Static analysis
make ci              # analyze + test
```

## CI/CD

- **ci.yml** — Format check, analyze, test, Linux build (on push/PR)
- **go-bridge.yml** — Go vet, tests, multi-platform compilation (on go/ changes)
- **release.yml** — Manual release builds for all platforms
- **deploy.yml** — Store deployment (Play Store, TestFlight)

## Contributing

1. Read `CLAUDE.md` for project conventions
2. Use `/project-development` skill to choose the right workflow
3. Follow BLoC pattern for state management
4. Add tests for new features
5. Run `make ci` before submitting

## Resources

- [PRD](../PRD.md) — Product Requirements Document
- [CLAUDE.md](../CLAUDE.md) — Development conventions
- [Caddy Docs](https://caddyserver.com/docs/) — Official Caddy documentation
