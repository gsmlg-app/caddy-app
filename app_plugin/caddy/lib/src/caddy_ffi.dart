import 'dart:ffi';
import 'dart:io';

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

class CaddyFfi {
  CaddyFfi() : _lib = _loadLibrary();

  final DynamicLibrary _lib;

  late final _StartCaddyDart _startCaddy = _lib
      .lookupFunction<_StartCaddyC, _StartCaddyDart>('StartCaddy');

  late final _StopCaddyDart _stopCaddy = _lib
      .lookupFunction<_StopCaddyC, _StopCaddyDart>('StopCaddy');

  late final _ReloadCaddyDart _reloadCaddy = _lib
      .lookupFunction<_ReloadCaddyC, _ReloadCaddyDart>('ReloadCaddy');

  late final _GetCaddyStatusDart _getCaddyStatus = _lib
      .lookupFunction<_GetCaddyStatusC, _GetCaddyStatusDart>('GetCaddyStatus');

  late final _SetEnvironmentDart _setEnvironment = _lib
      .lookupFunction<_SetEnvironmentC, _SetEnvironmentDart>('SetEnvironment');

  static DynamicLibrary _loadLibrary() {
    if (Platform.isLinux) {
      return DynamicLibrary.open('libcaddy_bridge.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libcaddy_bridge.dylib');
    }
    throw UnsupportedError(
      'CaddyFfi is not supported on ${Platform.operatingSystem}',
    );
  }

  String start(String configJSON) {
    final configPtr = configJSON.toNativeUtf8();
    try {
      final resultPtr = _startCaddy(configPtr);
      final result = resultPtr.toDartString();
      calloc.free(resultPtr);
      return result;
    } finally {
      calloc.free(configPtr);
    }
  }

  String stop() {
    final resultPtr = _stopCaddy();
    final result = resultPtr.toDartString();
    calloc.free(resultPtr);
    return result;
  }

  String reload(String configJSON) {
    final configPtr = configJSON.toNativeUtf8();
    try {
      final resultPtr = _reloadCaddy(configPtr);
      final result = resultPtr.toDartString();
      calloc.free(resultPtr);
      return result;
    } finally {
      calloc.free(configPtr);
    }
  }

  String status() {
    final resultPtr = _getCaddyStatus();
    final result = resultPtr.toDartString();
    calloc.free(resultPtr);
    return result;
  }

  String setEnvironment(String envJSON) {
    final envPtr = envJSON.toNativeUtf8();
    try {
      final resultPtr = _setEnvironment(envPtr);
      final result = resultPtr.toDartString();
      calloc.free(resultPtr);
      return result;
    } finally {
      calloc.free(envPtr);
    }
  }
}
