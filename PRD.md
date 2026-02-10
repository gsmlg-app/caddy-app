# PRD: Caddy App

## Overview

Caddy App is a cross-platform Flutter application that embeds the [Caddy web server](https://caddyserver.com/) as a native library, giving users a mobile and desktop interface to run, configure, and manage a fully functional Caddy server instance directly on their device.

## Problem

Running a local web server on mobile or desktop typically requires CLI access, manual configuration, and platform-specific tooling. There is no simple, cross-platform GUI for Caddy — one of the most popular modern web servers — that lets users spin up a server on-device for local development, file serving, reverse proxying, or edge networking scenarios.

## Solution

A Flutter app that embeds Caddy as a Go shared library, exposed via platform channels. Users get a native UI to start/stop Caddy, edit configuration, monitor status, and view logs — all without touching a terminal.

## Target Users

- Mobile developers needing a local HTTP server on-device for testing
- Power users serving static files or running reverse proxies on personal devices
- IoT / edge computing scenarios requiring an embedded web server
- Developers who want a GUI for Caddy configuration management

## Platforms

| Platform | Priority | Integration Method |
|----------|----------|--------------------|
| Android  | P0       | gomobile `.aar` via MethodChannel |
| Linux    | P0       | cgo `.so` via dart:ffi |
| macOS    | P1       | cgo `.dylib` via dart:ffi |
| iOS      | P2       | gomobile `.xcframework` via MethodChannel |

## Core Features

### 1. Server Lifecycle Management

Control the Caddy server instance running on the device.

- **Start** — Launch Caddy with a given JSON configuration
- **Stop** — Graceful shutdown of running instance
- **Reload** — Hot-reload configuration without full restart
- **Status** — Real-time status: running, stopped, error (with error detail)
- **Auto-lifecycle** — Stop Caddy when app is backgrounded/paused, optionally restart on resume (configurable)

### 2. Configuration Management

Create, edit, and persist Caddy configurations.

- **Visual config editor** — Form-based UI for common settings:
  - Listen address and port (default: `localhost:8080`)
  - Static file server with directory picker
  - Reverse proxy with upstream address
  - Basic route definitions
  - DNS provider selection + API credentials (for ACME DNS challenges)
  - S3 storage configuration (endpoint, bucket, credentials)
  - TLS / automatic HTTPS toggle
- **Raw JSON editor** — Full Caddy JSON config editing with syntax highlighting
- **Config presets** — Bundled templates for common use cases:
  - Static file server
  - Reverse proxy
  - SPA (Single Page Application) server
  - API gateway
  - HTTPS with DNS challenge (Cloudflare / Route53 / DuckDNS)
  - Full setup with S3 storage backend
- **Config persistence** — Save/load named configurations locally
- **Config validation** — Validate config before applying (surface Caddy errors in UI)

### 3. Log Viewer

Real-time log streaming from the embedded Caddy instance.

- Stream structured logs via EventChannel
- Log level filtering (DEBUG, INFO, WARN, ERROR)
- Auto-scroll with pause/resume
- Search/filter within logs
- Clear log buffer
- Optional: export logs to file

### 4. Server Dashboard

At-a-glance view of server state.

- Status indicator with color coding (green/red/yellow)
- Current listen address and port
- Active configuration summary
- Uptime counter
- Request counter (if available from Caddy metrics)

### 5. Admin API Access

Expose Caddy's built-in admin API for advanced users.

- Caddy admin endpoint available at `localhost:2019`
- UI toggle to enable/disable admin API
- Display admin API URL for use with external tools (curl, Postman)

### 6. Secrets Management

Secure storage for API credentials required by Caddy modules.

- Store DNS provider API tokens and S3 credentials in platform-native secure storage (Android Keystore, iOS Keychain, libsecret on Linux, macOS Keychain)
- Credentials UI: add, update, delete secrets by key name
- Secrets are never serialized into config JSON — injected as environment variables at Caddy start time
- Support for referencing secrets in config via `{env.VARIABLE_NAME}` placeholders (Caddy-native pattern)

## Architecture

### Go Layer (`go/caddy_bridge/`)

A thin Go module wrapping Caddy's programmatic API:

```
StartCaddy(configJSON string) → error
StopCaddy() → error
ReloadCaddy(configJSON string) → error
GetCaddyStatus() → string (JSON: {status, uptime, error})
```

Compiled per-platform via gomobile (mobile) or cgo (desktop). No business logic — lifecycle management only.

### Dart Layer (`app_plugin/caddy/`)

Melos package following the existing `app_plugin/*` convention:

- `CaddyService` — Singleton managing the platform bridge
- `CaddyConfig` — Dart model serializable to Caddy JSON config
- `CaddyState` — Sealed union: `Running | Stopped | Error(message)`
- `CaddyFfi` — FFI bindings for desktop platforms (alternative to MethodChannel)

### Platform Bridge

- **Mobile**: MethodChannel `com.caddy_app/caddy` + EventChannel `com.caddy_app/caddy_logs`
- **Desktop**: dart:ffi loading `.so` / `.dylib` directly

### State Management

BLoC pattern (consistent with existing `app_bloc/` in the template):

- `CaddyBloc` — manages server state transitions
- `CaddyLogBloc` — manages log stream buffering and filtering
- `CaddyConfigBloc` — manages config CRUD and validation

## Caddy Modules

The Go library is **not** built from stock Caddy. It uses [xcaddy](https://github.com/caddyserver/xcaddy) to produce a custom build with the following modules compiled in:

### Required Modules

| Module | Purpose |
|--------|---------|
| `github.com/caddy-dns/cloudflare` | DNS challenge provider for Cloudflare |
| `github.com/caddy-dns/route53` | DNS challenge provider for AWS Route 53 |
| `github.com/caddy-dns/duckdns` | DNS challenge provider for DuckDNS |
| `github.com/ss098/certmagic-s3` | Store TLS certificates and Caddy state in S3-compatible storage |

> Add or remove DNS providers as needed. The module list is defined in
> `go/caddy_bridge/main.go` via blank imports and in the xcaddy build command.

### Why These Modules

- **caddy-dns-\<provider\>**: Enables ACME DNS-01 challenges for automatic HTTPS on non-localhost domains. Critical for devices behind NAT or without port 80/443 access — the typical mobile/edge scenario.
- **certmagic-s3**: Caddy's default storage is the local filesystem. On mobile devices this is ephemeral and non-portable. S3 storage allows:
  - TLS certificates to persist across app reinstalls
  - Shared certificate state across multiple device instances
  - Backing up Caddy state to durable storage
  - Using any S3-compatible backend (AWS S3, MinIO, Cloudflare R2, etc.)

### Build Process

The Go library build uses xcaddy instead of plain `go build`:

```makefile
# go/caddy_bridge/Makefile
XCADDY := xcaddy build
MODULES := \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/caddy-dns/route53 \
  --with github.com/caddy-dns/duckdns \
  --with github.com/ss098/certmagic-s3

build:
	$(XCADDY) $(MODULES) --output ./caddy_bridge
```

For gomobile targets, xcaddy is used to generate a custom `main.go` with the module imports, which is then compiled via gomobile bind.

### Configuration Surface

The modules expose additional config that the UI must support:

**DNS Provider Config** (in visual config editor):
- Provider selection (Cloudflare / Route 53 / DuckDNS / ...)
- API token / credentials input (stored securely in platform keychain)
- Domain name for certificate issuance

**S3 Storage Config**:
- S3 endpoint URL (for non-AWS S3-compatible services)
- Bucket name
- Region
- Access key ID + secret (stored securely in platform keychain)
- Optional prefix/path within bucket

**Example Caddy JSON config with modules:**

```json
{
  "storage": {
    "module": "s3",
    "host": "s3.amazonaws.com",
    "bucket": "my-caddy-storage",
    "prefix": "caddy/"
  },
  "apps": {
    "tls": {
      "automation": {
        "policies": [{
          "issuers": [{
            "module": "acme",
            "challenges": {
              "dns": {
                "provider": {
                  "name": "cloudflare",
                  "api_token": "{env.CF_API_TOKEN}"
                }
              }
            }
          }]
        }]
      }
    },
    "http": {
      "servers": {
        "main": {
          "listen": [":443"],
          "routes": [...]
        }
      }
    }
  }
}
```

### Security Considerations for Modules

- DNS provider API tokens and S3 credentials must be stored in platform-native secure storage (Android Keystore / iOS Keychain / libsecret on Linux)
- Credentials are injected via environment variables at Caddy startup, never written to config files on disk
- The `CaddyConfig` Dart model separates secrets from config — secrets are resolved at start time only

## Non-Functional Requirements

### Security

- All Caddy listeners bind to `localhost` only by default
- Admin API disabled by default, user must explicitly enable
- No TLS certificate generation on mobile (unnecessary for localhost)
- Config files stored in app-private storage

### Performance

- Caddy startup time < 2 seconds
- Log viewer maintains rolling buffer (max 10,000 entries) to avoid memory pressure
- App lifecycle transitions (pause/resume) handled within 500ms

### Size

- Go/Caddy shared library with bundled modules adds approximately 25–40 MB to app size
- Document this clearly to users and in store listings

### Reliability

- Graceful handling of port-already-in-use errors with user-facing message
- Crash recovery: detect unclean Caddy shutdown and clean up on next launch
- Config validation before applying to prevent broken states

## Build & Distribution

### Build Pipeline

- Go library compiled via Makefile targets per platform
- Artifacts copied to platform directories before Flutter build
- Melos scripts for orchestration:
  - `caddy:build:android`, `caddy:build:ios`, `caddy:build:linux`, `caddy:build:macos`
  - `caddy:build:all`

### Development Environment

- Nix flake / devenv providing: Flutter, Go, gomobile, xcaddy, Android SDK + NDK
- Existing GitHub Actions workflows from template extended with Go build steps

## UI Wireframe (Conceptual)

```
┌─────────────────────────────┐
│  Caddy App            [⚙️]  │
├─────────────────────────────┤
│                             │
│   ● Server Running          │
│   localhost:8080             │
│   Uptime: 00:12:34          │
│                             │
│   [ ■ Stop Server ]         │
│                             │
├──────────┬──────────────────┤
│ Config   │ Logs      │ Admin│
├──────────┴──────────────────┤
│                             │
│ [2025-02-11 10:00:01] INFO  │
│   http server listening on  │
│   localhost:8080             │
│ [2025-02-11 10:00:05] INFO  │
│   GET / 200 12ms            │
│ [2025-02-11 10:00:06] INFO  │
│   GET /api 200 8ms          │
│                             │
└─────────────────────────────┘
```

## Milestones

### M1: Core Engine (MVP)

- Go library compiled for Android + Linux
- Start/Stop/Status via method channel
- Minimal UI: status + start/stop button
- Hardcoded config (static file server on localhost:8080)

### M2: Configuration

- Visual config editor (listen address, file server, reverse proxy)
- Raw JSON editor
- Config persistence (save/load)
- Config validation

### M3: Observability

- Log streaming via EventChannel
- Log viewer with filtering
- Dashboard with uptime and request metrics

### M4: Platform Expansion

- iOS support
- macOS support
- Admin API toggle
- Config presets/templates

### M5: Polish

- App lifecycle handling (background/foreground)
- Error recovery and edge cases
- Store listing preparation
- Documentation

## Open Questions

1. ~~**Caddy modules**~~ — **Decided**: Include custom modules via xcaddy build. See Caddy Modules section below.
2. **Background execution** — On Android, should we support running Caddy as a foreground service with persistent notification? This enables serving while the app is backgrounded.
3. **iOS App Store** — Apple may reject apps running a web server. Should iOS be scoped to local-only use cases (e.g., serving to a WebView) to improve review chances?
4. **Config format** — Support Caddyfile syntax in addition to JSON? Would require embedding Caddy's Caddyfile adapter, but is more user-friendly.
