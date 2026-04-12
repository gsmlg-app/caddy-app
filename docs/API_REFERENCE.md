# Caddy App API Reference

This document provides a comprehensive reference for all public APIs in the Caddy App project.

## Table of Contents

1. [CaddyService](#caddyservice)
2. [CaddyBloc](#caddybloc)
3. [CaddyConfig](#caddyconfig)
4. [CaddyStatus](#caddystatus)
5. [Database API](#database-api)
6. [Secrets Management](#secrets-management)
7. [Go Bridge FFI](#go-bridge-ffi)

---

## CaddyService

**Location:** `app_plugin/caddy/lib/src/caddy_service.dart`

The main service layer for interacting with the Caddy server. Automatically handles platform detection (FFI for desktop, MethodChannel for mobile).

### Singleton Access

```dart
final service = CaddyService.instance;
```

### Methods

#### start()

Starts the Caddy server with the given configuration.

```dart
Future<CaddyStatus> start(
  CaddyConfig config, {
  bool adminEnabled = false,
  Map<String, String> environment = const {},
})
```

**Parameters:**
- `config` - Caddy configuration (CaddyConfig)
- `adminEnabled` - Enable admin API on localhost:2019 (default: false)
- `environment` - Environment variables to inject (typically secrets)

**Returns:** CaddyStatus indicating success (CaddyRunning) or failure (CaddyError)

**Example:**
```dart
final status = await service.start(
  CaddyConfig.staticFileServer(root: '/var/www'),
  adminEnabled: true,
  environment: {'CF_API_TOKEN': 'abc123'},
);
```

#### stop()

Stops the running Caddy server.

```dart
Future<CaddyStatus> stop()
```

**Returns:** CaddyStopped or CaddyError

**Example:**
```dart
final status = await service.stop();
```

#### reload()

Hot-reloads Caddy configuration without downtime.

```dart
Future<CaddyStatus> reload(
  CaddyConfig config, {
  bool adminEnabled = false,
  Map<String, String> environment = const {},
})
```

**Parameters:** Same as `start()`

**Returns:** CaddyRunning or CaddyError

**Example:**
```dart
final status = await service.reload(updatedConfig);
```

#### getStatus()

Queries the current server status.

```dart
Future<CaddyStatus> getStatus()
```

**Returns:** CaddyRunning, CaddyStopped, or CaddyError

#### setEnvironment()

Sets environment variables (internal, called automatically by start/reload).

```dart
Future<String> setEnvironment(Map<String, String> env)
```

#### logStream

Real-time stream of log entries.

```dart
Stream<String> get logStream
```

**Example:**
```dart
service.logStream.listen((line) {
  print('Caddy log: $line');
});
```

#### dispose()

Cleanup method (internal, called by framework).

```dart
void dispose()
```

---

## CaddyBloc

**Location:** `app_bloc/caddy/lib/src/bloc.dart`

BLoC for managing Caddy server state with reactive updates.

### Access in Widget Tree

```dart
// Read current state
final state = context.read<CaddyBloc>().state;

// Watch for changes
final state = context.watch<CaddyBloc>().state;

// Send events
context.read<CaddyBloc>().add(CaddyStart(config));
```

### Events

#### Server Control Events

**CaddyStart**
```dart
CaddyStart(CaddyConfig config)
```
Starts the Caddy server. Automatically injects secrets from vault.

**CaddyStop**
```dart
CaddyStop()
```
Stops the running server.

**CaddyReload**
```dart
CaddyReload(CaddyConfig config)
```
Hot-reloads configuration.

**CaddyStatusCheck**
```dart
CaddyStatusCheck()
```
Queries current status from service.

**CaddyInitialize**
```dart
CaddyInitialize()
```
Initializes BLoC (detects orphaned instances, loads saved configs).

#### Configuration Events

**CaddyUpdateConfig**
```dart
CaddyUpdateConfig(CaddyConfig config)
```
Updates in-memory configuration without persisting.

**CaddySaveConfig**
```dart
CaddySaveConfig(String name)
```
Persists current configuration to database.

**CaddyLoadSavedConfig**
```dart
CaddyLoadSavedConfig()
```
Loads all saved configuration names from database.

**CaddyLoadNamedConfig**
```dart
CaddyLoadNamedConfig(String name)
```
Switches to a saved configuration by name.

**CaddyDeleteSavedConfig**
```dart
CaddyDeleteSavedConfig(String name)
```
Deletes a saved configuration.

#### Logging Events

**CaddyLogReceived**
```dart
CaddyLogReceived(String line)
```
Appends log line to buffer (max 10,000 entries).

**CaddyClearLogs**
```dart
CaddyClearLogs()
```
Clears log buffer.

**CaddySetLogFilter**
```dart
CaddySetLogFilter(CaddyLogLevel level)
```
Filters logs by level (all, debug, info, warn, error).

**CaddySetLogSearch**
```dart
CaddySetLogSearch(String query)
```
Filters logs by search query.

#### Lifecycle & Settings Events

**CaddyLifecyclePause**
```dart
CaddyLifecyclePause()
```
Called when app is backgrounded. Saves current config and stops server if running.

**CaddyLifecycleResume**
```dart
CaddyLifecycleResume()
```
Called when app is foregrounded. Auto-restarts if enabled.

**CaddyToggleAdmin**
```dart
CaddyToggleAdmin()
```
Toggles admin API on/off.

**CaddyToggleAutoRestart**
```dart
CaddyToggleAutoRestart()
```
Toggles auto-restart on resume.

### State Properties

```dart
class CaddyState {
  final CaddyStatus status;                // Current server status
  final CaddyConfig config;                // Active configuration
  final List<String> logs;                 // All log lines (max 10k)
  final List<String> filteredLogs;         // Filtered logs
  final bool adminEnabled;                 // Admin API toggle
  final CaddyLogLevel logFilter;           // Current log filter
  final String logSearchQuery;             // Search query
  final List<String> savedConfigNames;     // Saved config names
  final String? activeConfigName;          // Active config name
  final int requestCount;                  // Request counter
  final bool autoRestartOnResume;          // Auto-restart setting
  final DateTime? lastStatusCheck;         // Last status query time

  // Computed properties
  bool get isRunning => status is CaddyRunning;
  bool get isStopped => status is CaddyStopped;
  bool get hasError => status is CaddyError;
  bool get isLoading => status is CaddyLoading;
  DateTime? get startedAt => status is CaddyRunning
    ? (status as CaddyRunning).startedAt
    : null;
}
```

---

## CaddyConfig

**Location:** `app_plugin/caddy/lib/src/caddy_config.dart`

Configuration model for Caddy server with full JSON serialization.

### Constructor

```dart
const CaddyConfig({
  this.listenAddress = 'localhost:2015',
  this.routes = const [],
  this.rawJson,
  this.tls,
  this.storage,
})
```

### Properties

- `listenAddress` - Server bind address (e.g., `'localhost:2015'`, `':80'`)
- `routes` - List of CaddyRoute objects
- `rawJson` - Optional raw Caddy JSON config (overrides generated config)
- `tls` - TLS configuration (CaddyTlsConfig)
- `storage` - S3 storage configuration (CaddyStorageConfig)

### Methods

#### toJson()

Generates full Caddy JSON configuration.

```dart
Map<String, dynamic> toJson()
```

**Returns:** Complete Caddy JSON config with apps.http.servers structure.

#### toJsonString()

Generates JSON string with optional admin API.

```dart
String toJsonString({bool adminEnabled = false})
```

**Parameters:**
- `adminEnabled` - Include admin API config on localhost:2019

#### toStorageJson()

Generates lightweight JSON for database persistence.

```dart
Map<String, dynamic> toStorageJson()
```

#### fromStorageJson()

Factory constructor from database JSON.

```dart
factory CaddyConfig.fromStorageJson(Map<String, dynamic> json)
```

#### copyWith()

Creates a copy with updated fields.

```dart
CaddyConfig copyWith({
  String? listenAddress,
  List<CaddyRoute>? routes,
  String? rawJson,
  CaddyTlsConfig? tls,
  CaddyStorageConfig? storage,
})
```

### Built-in Presets

#### staticFileServer()

Static file server configuration.

```dart
factory CaddyConfig.staticFileServer({
  String root = '/var/www',
  String listenAddress = 'localhost:2015',
})
```

**Example:**
```dart
final config = CaddyConfig.staticFileServer(
  root: '/Users/me/public',
  listenAddress: ':8080',
);
```

#### reverseProxy()

Reverse proxy configuration.

```dart
factory CaddyConfig.reverseProxy({
  required List<String> upstreams,
  String listenAddress = 'localhost:2015',
})
```

**Example:**
```dart
final config = CaddyConfig.reverseProxy(
  upstreams: ['localhost:3000', 'localhost:3001'],
  listenAddress: ':80',
);
```

#### spaServer()

Single-page application server with fallback.

```dart
factory CaddyConfig.spaServer({
  String root = '/var/www',
  String listenAddress = 'localhost:2015',
})
```

#### apiGateway()

API gateway with mixed static and proxy routes.

```dart
factory CaddyConfig.apiGateway({
  required String staticRoot,
  required List<String> apiUpstreams,
  String listenAddress = 'localhost:2015',
})
```

**Example:**
```dart
final config = CaddyConfig.apiGateway(
  staticRoot: '/var/www',
  apiUpstreams: ['localhost:3000'],
  listenAddress: ':80',
);
```

#### httpsWithDns()

HTTPS with DNS challenge.

```dart
factory CaddyConfig.httpsWithDns({
  required String domain,
  required CaddyDnsProvider dnsProvider,
  required List<CaddyRoute> routes,
  String listenAddress = ':443',
})
```

**Example:**
```dart
final config = CaddyConfig.httpsWithDns(
  domain: 'example.com',
  dnsProvider: CaddyDnsProvider.cloudflare,
  routes: [
    CaddyRoute(
      path: '/*',
      handler: StaticFileHandler(root: '/var/www'),
    ),
  ],
);
// Requires secret: caddy_CF_API_TOKEN
```

#### httpsWithS3()

HTTPS with S3 certificate storage.

```dart
factory CaddyConfig.httpsWithS3({
  required String domain,
  required CaddyDnsProvider dnsProvider,
  required String s3Endpoint,
  required String s3Bucket,
  required List<CaddyRoute> routes,
  String s3Region = 'us-east-1',
  String s3Prefix = 'caddy/',
  String listenAddress = ':443',
})
```

**Example:**
```dart
final config = CaddyConfig.httpsWithS3(
  domain: 'example.com',
  dnsProvider: CaddyDnsProvider.cloudflare,
  s3Endpoint: 's3.amazonaws.com',
  s3Bucket: 'my-certs',
  routes: [...],
);
// Requires secrets:
// - caddy_CF_API_TOKEN
// - caddy_AWS_ACCESS_KEY_ID
// - caddy_AWS_SECRET_ACCESS_KEY
```

### Static Methods

#### validate()

Validates configuration before applying.

```dart
static String? validate(CaddyConfig config)
```

**Returns:** Error message if invalid, null if valid.

**Example:**
```dart
final error = CaddyConfigPresets.validate(config);
if (error != null) {
  print('Invalid config: $error');
}
```

---

## CaddyRoute

**Location:** `app_plugin/caddy/lib/src/caddy_config.dart`

Route definition for path-to-handler mapping.

### Constructor

```dart
const CaddyRoute({
  required this.path,
  required this.handler,
})
```

### Properties

- `path` - URL path pattern (e.g., `'/*'`, `'/api/*'`)
- `handler` - Route handler (CaddyHandler sealed type)

---

## CaddyHandler

**Location:** `app_plugin/caddy/lib/src/caddy_config.dart`

Sealed type for route handlers.

### StaticFileHandler

Serves static files from filesystem.

```dart
const StaticFileHandler({
  required this.root,
})
```

**Properties:**
- `root` - Filesystem path to serve

**Example:**
```dart
CaddyRoute(
  path: '/*',
  handler: StaticFileHandler(root: '/var/www/html'),
)
```

### ReverseProxyHandler

Proxies requests to upstream servers.

```dart
const ReverseProxyHandler({
  required this.upstreams,
})
```

**Properties:**
- `upstreams` - List of upstream addresses (e.g., `['localhost:3000']`)

**Example:**
```dart
CaddyRoute(
  path: '/api/*',
  handler: ReverseProxyHandler(
    upstreams: ['localhost:3000', 'localhost:3001'],
  ),
)
```

---

## CaddyTlsConfig

**Location:** `app_plugin/caddy/lib/src/caddy_config.dart`

TLS automation configuration.

### Constructor

```dart
const CaddyTlsConfig({
  required this.enabled,
  required this.domain,
  this.dnsProvider = CaddyDnsProvider.none,
})
```

### Properties

- `enabled` - Enable TLS automation
- `domain` - Domain for certificate
- `dnsProvider` - DNS provider for ACME challenge

### DNS Providers

```dart
enum CaddyDnsProvider {
  none,        // No DNS challenge
  cloudflare,  // Requires: CF_API_TOKEN
  route53,     // Requires: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
  duckdns,     // Requires: DUCKDNS_TOKEN
}
```

**Example:**
```dart
final tls = CaddyTlsConfig(
  enabled: true,
  domain: 'example.com',
  dnsProvider: CaddyDnsProvider.cloudflare,
);
```

---

## CaddyStorageConfig

**Location:** `app_plugin/caddy/lib/src/caddy_config.dart`

S3-compatible certificate storage.

### Constructor

```dart
const CaddyStorageConfig({
  required this.endpoint,
  required this.bucket,
  this.region = 'us-east-1',
  this.prefix = 'caddy/',
})
```

### Properties

- `endpoint` - S3 endpoint URL
- `bucket` - S3 bucket name
- `region` - AWS region
- `prefix` - Key prefix for certificates

**Example:**
```dart
final storage = CaddyStorageConfig(
  endpoint: 's3.amazonaws.com',
  bucket: 'my-certs',
  region: 'us-west-2',
  prefix: 'caddy/',
);
// Requires secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

---

## CaddyStatus

**Location:** `app_plugin/caddy/lib/src/caddy_service.dart`

Sealed status type for server state.

### CaddyStopped

Server is not running.

```dart
class CaddyStopped extends CaddyStatus {}
```

### CaddyRunning

Server is running with active configuration.

```dart
class CaddyRunning extends CaddyStatus {
  final CaddyConfig config;
  final DateTime startedAt;
}
```

### CaddyError

Server encountered an error.

```dart
class CaddyError extends CaddyStatus {
  final String message;
}
```

### CaddyLoading

Operation in progress.

```dart
class CaddyLoading extends CaddyStatus {}
```

**Example:**
```dart
final status = await service.getStatus();
switch (status) {
  case CaddyRunning(:final config, :final startedAt):
    print('Running since $startedAt');
  case CaddyStopped():
    print('Not running');
  case CaddyError(:final message):
    print('Error: $message');
  case CaddyLoading():
    print('Loading...');
}
```

---

## Database API

**Location:** `app_lib/database/lib/src/database.dart`

Drift database for configuration persistence.

### Access

```dart
// Via MainProvider
final db = context.read<AppDatabase>();
```

### Methods

#### getAllCaddyConfigs()

Lists all saved configurations.

```dart
Future<List<CaddyConfigData>> getAllCaddyConfigs()
```

#### getCaddyConfigByName()

Loads a specific configuration.

```dart
Future<CaddyConfigData?> getCaddyConfigByName(String name)
```

#### getActiveCaddyConfig()

Gets the marked-as-active configuration.

```dart
Future<CaddyConfigData?> getActiveCaddyConfig()
```

#### upsertCaddyConfig()

Inserts or updates a configuration.

```dart
Future<int> upsertCaddyConfig({
  required String name,
  required String configJson,
  required bool adminEnabled,
  required bool isActive,
})
```

#### setActiveCaddyConfig()

Atomically sets a configuration as active.

```dart
Future<void> setActiveCaddyConfig(String name)
```

#### deleteCaddyConfig()

Deletes a configuration.

```dart
Future<int> deleteCaddyConfig(String name)
```

#### watchAllCaddyConfigs()

Stream of all configurations for reactive UI.

```dart
Stream<List<CaddyConfigData>> watchAllCaddyConfigs()
```

---

## Secrets Management

**Location:** `app_lib/secure_storage/lib/src/vault_repository.dart`

Platform-native secure storage for secrets.

### Access

```dart
// Via MainProvider
final vault = context.read<SecureStorageVaultRepository>();
```

### Methods

#### read()

Reads a secret value.

```dart
Future<String?> read(String key)
```

#### write()

Writes a secret value.

```dart
Future<void> write(String key, String value)
```

#### delete()

Deletes a secret.

```dart
Future<void> delete(String key)
```

#### readAll()

Lists all keys and values.

```dart
Future<Map<String, String>> readAll()
```

### Secret Naming Convention

Secrets for Caddy must be prefixed with `caddy_`:

```dart
// User adds secret with key: CF_API_TOKEN
await vault.write('caddy_CF_API_TOKEN', 'abc123');

// BLoC reads vault and strips prefix before injecting:
// caddy_CF_API_TOKEN -> CF_API_TOKEN
// Caddy config references: {env.CF_API_TOKEN}
```

**Supported Secrets:**

| Secret Key | Used For | DNS Provider |
|------------|----------|--------------|
| `caddy_CF_API_TOKEN` | Cloudflare DNS challenge | cloudflare |
| `caddy_AWS_ACCESS_KEY_ID` | Route53 DNS challenge / S3 storage | route53 |
| `caddy_AWS_SECRET_ACCESS_KEY` | Route53 DNS challenge / S3 storage | route53 |
| `caddy_DUCKDNS_TOKEN` | DuckDNS DNS challenge | duckdns |

---

## Go Bridge FFI

**Location:** `go/caddy_bridge/`

Low-level FFI interface to Caddy Go library.

### Exported Functions

#### SetEnvironment()

Sets environment variables from JSON map.

```c
char* SetEnvironment(char* envJSON);
```

**Parameters:**
- `envJSON` - JSON string: `{"KEY": "value", ...}`

**Returns:** JSON result: `{"status": "success"}`

#### StartCaddy()

Starts Caddy with JSON configuration.

```c
char* StartCaddy(char* configJSON);
```

**Parameters:**
- `configJSON` - Full Caddy JSON config string

**Returns:** Status JSON: `{"status": "running"}` or `{"status": "error", "message": "..."}`

#### StopCaddy()

Stops the running Caddy instance.

```c
char* StopCaddy();
```

**Returns:** Status JSON: `{"status": "stopped"}`

#### ReloadCaddy()

Hot-reloads Caddy configuration.

```c
char* ReloadCaddy(char* configJSON);
```

**Parameters:**
- `configJSON` - Updated Caddy JSON config

**Returns:** Status JSON

#### GetCaddyStatus()

Queries current server status.

```c
char* GetCaddyStatus();
```

**Returns:** Status JSON: `{"status": "running"}` or `{"status": "stopped"}`

### Memory Management

⚠️ **Critical:** All returned C strings must be freed by the caller:

```dart
final resultPtr = _startCaddy(configPtr.cast());
final result = resultPtr.toDartString();
calloc.free(resultPtr); // REQUIRED to prevent memory leak
```

### Platform Detection

- **Linux/macOS**: Uses `dart:ffi` with `.so`/`.dylib` libraries
- **Android/iOS**: Uses MethodChannel with gomobile wrappers

---

## Error Handling

### Common Error Patterns

#### Port Already in Use

```dart
CaddyError(message: 'listen tcp :2015: bind: address already in use')
```

**Handling:**
```dart
if (state.hasError && state.status is CaddyError) {
  final error = (state.status as CaddyError).message;
  if (error.contains('address already in use')) {
    // Show dialog to change port
  }
}
```

#### Orphaned Instance

Automatically handled by `CaddyInitialize` event on app startup.

#### Configuration Validation

```dart
final error = CaddyConfigPresets.validate(config);
if (error != null) {
  // Show validation error
}
```

---

## Example Usage

### Complete Workflow Example

```dart
import 'package:app_bloc/caddy/caddy.dart';
import 'package:app_plugin/caddy/caddy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyCaddyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaddyBloc, CaddyState>(
      builder: (context, state) {
        return Column(
          children: [
            // Status display
            Text('Status: ${state.isRunning ? 'Running' : 'Stopped'}'),

            // Start button
            ElevatedButton(
              onPressed: state.isStopped
                ? () {
                    final config = CaddyConfig.staticFileServer(
                      root: '/var/www',
                      listenAddress: ':8080',
                    );
                    context.read<CaddyBloc>().add(CaddyStart(config));
                  }
                : null,
              child: Text('Start'),
            ),

            // Stop button
            ElevatedButton(
              onPressed: state.isRunning
                ? () => context.read<CaddyBloc>().add(CaddyStop())
                : null,
              child: Text('Stop'),
            ),

            // Logs
            Expanded(
              child: ListView.builder(
                itemCount: state.filteredLogs.length,
                itemBuilder: (context, index) {
                  return Text(state.filteredLogs[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## See Also

- [User Guide](USER_GUIDE.md) - End-user documentation
- [Architecture](CADDY_APP.md) - Implementation details
- [Caddy Documentation](https://caddyserver.com/docs/) - Official Caddy docs
