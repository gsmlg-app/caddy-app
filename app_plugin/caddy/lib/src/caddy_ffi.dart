import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

typedef _StartCaddyC = Pointer<Utf8> Function(Pointer<Utf8> configJSON);
typedef _StartCaddyDart = Pointer<Utf8> Function(Pointer<Utf8> configJSON);

typedef _StopCaddyC = Pointer<Utf8> Function();
typedef _StopCaddyDart = Pointer<Utf8> Function();

typedef _ReloadCaddyC = Pointer<Utf8> Function(Pointer<Utf8> configJSON);
typedef _ReloadCaddyDart = Pointer<Utf8> Function(Pointer<Utf8> configJSON);

typedef _GetCaddyStatusC = Pointer<Utf8> Function();
typedef _GetCaddyStatusDart = Pointer<Utf8> Function();

typedef _SetEnvironmentC = Pointer<Utf8> Function(Pointer<Utf8> envJSON);
typedef _SetEnvironmentDart = Pointer<Utf8> Function(Pointer<Utf8> envJSON);

/// Runs the given FFI [action] in a separate isolate so the main (UI)
/// isolate is never blocked by potentially long-running Go calls such as
/// `caddy.Load()`.
///
/// The [action] receives the library path and must open the library itself
/// because [DynamicLibrary] instances are not sendable across isolates.
Future<String> _runInIsolate(String Function(String libPath) action) {
  return Isolate.run(() => action(_libraryPath()));
}

String _libraryPath() {
  if (Platform.isLinux) return 'libcaddy_bridge.so';
  if (Platform.isMacOS) return 'libcaddy_bridge.dylib';
  throw UnsupportedError(
    'CaddyFfi is not supported on ${Platform.operatingSystem}',
  );
}

class CaddyFfi {
  CaddyFfi() {
    // Eagerly validate that the library can be loaded on the main isolate.
    DynamicLibrary.open(_libraryPath());
  }

  Future<String> start(String configJSON) {
    return _runInIsolate((libPath) {
      final lib = DynamicLibrary.open(libPath);
      final startCaddy =
          lib.lookupFunction<_StartCaddyC, _StartCaddyDart>('StartCaddy');
      final configPtr = configJSON.toNativeUtf8();
      try {
        final resultPtr = startCaddy(configPtr);
        final result = resultPtr.toDartString();
        calloc.free(resultPtr);
        return result;
      } finally {
        calloc.free(configPtr);
      }
    });
  }

  Future<String> stop() {
    return _runInIsolate((libPath) {
      final lib = DynamicLibrary.open(libPath);
      final stopCaddy =
          lib.lookupFunction<_StopCaddyC, _StopCaddyDart>('StopCaddy');
      final resultPtr = stopCaddy();
      final result = resultPtr.toDartString();
      calloc.free(resultPtr);
      return result;
    });
  }

  Future<String> reload(String configJSON) {
    return _runInIsolate((libPath) {
      final lib = DynamicLibrary.open(libPath);
      final reloadCaddy =
          lib.lookupFunction<_ReloadCaddyC, _ReloadCaddyDart>('ReloadCaddy');
      final configPtr = configJSON.toNativeUtf8();
      try {
        final resultPtr = reloadCaddy(configPtr);
        final result = resultPtr.toDartString();
        calloc.free(resultPtr);
        return result;
      } finally {
        calloc.free(configPtr);
      }
    });
  }

  Future<String> status() {
    return _runInIsolate((libPath) {
      final lib = DynamicLibrary.open(libPath);
      final getCaddyStatus =
          lib.lookupFunction<_GetCaddyStatusC, _GetCaddyStatusDart>(
            'GetCaddyStatus',
          );
      final resultPtr = getCaddyStatus();
      final result = resultPtr.toDartString();
      calloc.free(resultPtr);
      return result;
    });
  }

  Future<String> setEnvironment(String envJSON) {
    return _runInIsolate((libPath) {
      final lib = DynamicLibrary.open(libPath);
      final setEnv =
          lib.lookupFunction<_SetEnvironmentC, _SetEnvironmentDart>(
            'SetEnvironment',
          );
      final envPtr = envJSON.toNativeUtf8();
      try {
        final resultPtr = setEnv(envPtr);
        final result = resultPtr.toDartString();
        calloc.free(resultPtr);
        return result;
      } finally {
        calloc.free(envPtr);
      }
    });
  }
}
