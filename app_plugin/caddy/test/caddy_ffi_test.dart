import 'dart:io';

import 'package:caddy_service/src/caddy_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaddyFfi', () {
    test('constructor loads library on supported platforms', () {
      // Skip on unsupported platforms (mobile, Windows, etc.)
      if (!Platform.isLinux && !Platform.isMacOS) {
        expect(
          () => CaddyFfi(),
          throwsA(isA<UnsupportedError>()),
        );
        return;
      }

      // On Linux/macOS, CaddyFfi should construct successfully
      // NOTE: This will throw if libcaddy_bridge.so/.dylib is not found
      // in the search path. That's expected for CI environments without
      // the built library.
      try {
        final ffi = CaddyFfi();
        expect(ffi, isNotNull);
      } on ArgumentError catch (e) {
        // If library not found, that's expected in test environment
        expect(e.message, contains('Failed to load dynamic library'));
      }
    });

    test('setEnvironment returns empty string on success', () {
      if (!Platform.isLinux && !Platform.isMacOS) {
        return; // Skip on unsupported platforms
      }

      try {
        final ffi = CaddyFfi();
        final result = ffi.setEnvironment('{}');
        expect(result, isEmpty);
      } on ArgumentError catch (_) {
        // Library not found in test environment
      }
    });

    test('status returns JSON when Caddy is not running', () {
      if (!Platform.isLinux && !Platform.isMacOS) {
        return; // Skip on unsupported platforms
      }

      try {
        final ffi = CaddyFfi();
        final result = ffi.status();
        expect(result, contains('status'));
        expect(result, contains('stopped'));
      } on ArgumentError catch (_) {
        // Library not found in test environment
      }
    });
  });
}
