import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:caddy_service/src/caddy_config.dart';
import 'package:caddy_service/src/caddy_ffi.dart';
import 'package:caddy_service/src/caddy_method_channel.dart';
import 'package:caddy_service/src/caddy_status.dart';
import 'package:flutter/foundation.dart';

class CaddyService {
  CaddyService._();

  @visibleForTesting
  CaddyService.forTesting();

  static CaddyService? _instance;

  static CaddyService get instance {
    _instance ??= CaddyService._();
    return _instance!;
  }

  CaddyFfi? _ffi;
  CaddyMethodChannel? _methodChannel;

  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  Stream<String> get logStream => _logController.stream;

  bool get _isDesktop => Platform.isLinux || Platform.isMacOS;

  void _ensureInitialized() {
    if (_isDesktop) {
      _ffi ??= CaddyFfi();
    } else {
      _methodChannel ??= CaddyMethodChannel();
      _methodChannel!.logStream.listen((line) => _logController.add(line));
    }
  }

  Future<CaddyStatus> start(
    CaddyConfig config, {
    bool adminEnabled = false,
  }) async {
    _ensureInitialized();
    final configJson = config.toJsonString(adminEnabled: adminEnabled);

    try {
      final String error;
      if (_isDesktop) {
        error = _ffi!.start(configJson);
      } else {
        error = await _methodChannel!.start(configJson);
      }

      if (error.isNotEmpty) {
        if (error.contains('address already in use') ||
            error.contains('bind:')) {
          return CaddyError(
            message: 'Port ${config.listenAddress} is already in use',
          );
        }
        return CaddyError(message: error);
      }

      return CaddyRunning(config: configJson, startedAt: DateTime.now());
    } catch (e) {
      return CaddyError(message: e.toString());
    }
  }

  Future<CaddyStatus> stop() async {
    _ensureInitialized();

    try {
      final String error;
      if (_isDesktop) {
        error = _ffi!.stop();
      } else {
        error = await _methodChannel!.stop();
      }

      if (error.isNotEmpty) {
        return CaddyError(message: error);
      }

      return const CaddyStopped();
    } catch (e) {
      return CaddyError(message: e.toString());
    }
  }

  Future<CaddyStatus> reload(
    CaddyConfig config, {
    bool adminEnabled = false,
  }) async {
    _ensureInitialized();
    final configJson = config.toJsonString(adminEnabled: adminEnabled);

    try {
      final String error;
      if (_isDesktop) {
        error = _ffi!.reload(configJson);
      } else {
        error = await _methodChannel!.reload(configJson);
      }

      if (error.isNotEmpty) {
        if (error.contains('address already in use') ||
            error.contains('bind:')) {
          return CaddyError(
            message: 'Port ${config.listenAddress} is already in use',
          );
        }
        return CaddyError(message: error);
      }

      return CaddyRunning(config: configJson, startedAt: DateTime.now());
    } catch (e) {
      return CaddyError(message: e.toString());
    }
  }

  Future<CaddyStatus> getStatus() async {
    _ensureInitialized();

    try {
      final String result;
      if (_isDesktop) {
        result = _ffi!.status();
      } else {
        result = await _methodChannel!.status();
      }

      final json = jsonDecode(result) as Map<String, dynamic>;
      final status = json['status'] as String?;

      if (status == 'running') {
        return CaddyRunning(config: '', startedAt: DateTime.now());
      }

      return const CaddyStopped();
    } catch (e) {
      return CaddyError(message: e.toString());
    }
  }

  Future<void> dispose() async {
    await _logController.close();
  }
}
