import 'package:flutter/services.dart';

class CaddyMethodChannel {
  CaddyMethodChannel()
    : _methodChannel = const MethodChannel('com.caddy_app/caddy'),
      _eventChannel = const EventChannel('com.caddy_app/caddy/logs');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Future<String> start(String configJSON) async {
    final result = await _methodChannel.invokeMethod<String>('start', {
      'config': configJSON,
    });
    return result ?? '';
  }

  Future<String> stop() async {
    final result = await _methodChannel.invokeMethod<String>('stop');
    return result ?? '';
  }

  Future<String> reload(String configJSON) async {
    final result = await _methodChannel.invokeMethod<String>('reload', {
      'config': configJSON,
    });
    return result ?? '';
  }

  Future<String> status() async {
    final result = await _methodChannel.invokeMethod<String>('status');
    return result ?? '';
  }

  Future<String> setEnvironment(String envJSON) async {
    final result = await _methodChannel.invokeMethod<String>('setEnvironment', {
      'env': envJSON,
    });
    return result ?? '';
  }

  Stream<String> get logStream {
    return _eventChannel.receiveBroadcastStream().map((event) => '$event');
  }
}
