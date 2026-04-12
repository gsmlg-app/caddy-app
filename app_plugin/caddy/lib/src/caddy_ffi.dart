import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

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

typedef _AdaptCaddyfileC = Pointer<Utf8> Function(Pointer<Utf8> caddyfileText);
typedef _AdaptCaddyfileDart = Pointer<Utf8> Function(
  Pointer<Utf8> caddyfileText,
);

/// Absolute path to the Caddy bridge shared library.
/// Resolved once from the executable location so it works in both the main
/// isolate and compute() isolates.
final String _resolvedLibPath = () {
  final String name;
  if (Platform.isLinux) {
    name = 'libcaddy_bridge.so';
  } else if (Platform.isMacOS) {
    name = 'libcaddy_bridge.dylib';
  } else {
    throw UnsupportedError(
      'CaddyFfi is not supported on ${Platform.operatingSystem}',
    );
  }
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return '$exeDir/lib/$name';
}();

// ---------------------------------------------------------------------------
// Top-level functions for compute().
//
// The Go shared library must be loaded on the main isolate FIRST (via the
// CaddyFfi constructor) so that the Go runtime fully initialises. Subsequent
// DynamicLibrary.open() calls in compute() isolates reuse the already-loaded
// library without re-running init(), avoiding a CGO deadlock.
// ---------------------------------------------------------------------------

String _doStart(String configJSON) {
  final lib = DynamicLibrary.open(_resolvedLibPath);
  final fn = lib.lookupFunction<_StartCaddyC, _StartCaddyDart>('StartCaddy');
  final ptr = configJSON.toNativeUtf8();
  try {
    final res = fn(ptr);
    final s = res.toDartString();
    calloc.free(res);
    return s;
  } finally {
    calloc.free(ptr);
  }
}

String _doStop(void _) {
  final lib = DynamicLibrary.open(_resolvedLibPath);
  final fn = lib.lookupFunction<_StopCaddyC, _StopCaddyDart>('StopCaddy');
  final res = fn();
  final s = res.toDartString();
  calloc.free(res);
  return s;
}

String _doReload(String configJSON) {
  final lib = DynamicLibrary.open(_resolvedLibPath);
  final fn =
      lib.lookupFunction<_ReloadCaddyC, _ReloadCaddyDart>('ReloadCaddy');
  final ptr = configJSON.toNativeUtf8();
  try {
    final res = fn(ptr);
    final s = res.toDartString();
    calloc.free(res);
    return s;
  } finally {
    calloc.free(ptr);
  }
}

String _doStatus(void _) {
  final lib = DynamicLibrary.open(_resolvedLibPath);
  final fn = lib
      .lookupFunction<_GetCaddyStatusC, _GetCaddyStatusDart>('GetCaddyStatus');
  final res = fn();
  final s = res.toDartString();
  calloc.free(res);
  return s;
}

String _doSetEnvironment(String envJSON) {
  final lib = DynamicLibrary.open(_resolvedLibPath);
  final fn = lib
      .lookupFunction<_SetEnvironmentC, _SetEnvironmentDart>('SetEnvironment');
  final ptr = envJSON.toNativeUtf8();
  try {
    final res = fn(ptr);
    final s = res.toDartString();
    calloc.free(res);
    return s;
  } finally {
    calloc.free(ptr);
  }
}

String _doAdaptCaddyfile(String caddyfileText) {
  final lib = DynamicLibrary.open(_resolvedLibPath);
  final fn = lib
      .lookupFunction<_AdaptCaddyfileC, _AdaptCaddyfileDart>('AdaptCaddyfile');
  final ptr = caddyfileText.toNativeUtf8();
  try {
    final res = fn(ptr);
    final s = res.toDartString();
    calloc.free(res);
    return s;
  } finally {
    calloc.free(ptr);
  }
}

class CaddyFfi {
  CaddyFfi() {
    // Load the library on the main isolate to trigger Go runtime init.
    // This must complete before any compute() call uses the library.
    DynamicLibrary.open(_resolvedLibPath);
  }

  Future<String> start(String configJSON) => compute(_doStart, configJSON);

  Future<String> stop() => compute(_doStop, null);

  Future<String> reload(String configJSON) => compute(_doReload, configJSON);

  Future<String> status() => compute(_doStatus, null);

  Future<String> setEnvironment(String envJSON) =>
      compute(_doSetEnvironment, envJSON);

  Future<String> adaptCaddyfile(String caddyfileText) =>
      compute(_doAdaptCaddyfile, caddyfileText);
}
