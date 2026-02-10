import 'dart:convert';

import 'package:caddy_service/caddy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaddyConfig', () {
    test('default config has correct listen address', () {
      const config = CaddyConfig();
      expect(config.listenAddress, 'localhost:2015');
      expect(config.routes, isEmpty);
      expect(config.rawJson, isNull);
    });

    test('toJson generates valid Caddy JSON with static file handler', () {
      const config = CaddyConfig(
        listenAddress: 'localhost:8080',
        routes: [
          CaddyRoute(
            path: '/*',
            handler: StaticFileHandler(root: '/var/www'),
          ),
        ],
      );

      final json = config.toJson();
      expect(json['apps']['http']['servers']['srv0']['listen'], [':8080']);

      final routes = json['apps']['http']['servers']['srv0']['routes'] as List;
      expect(routes, hasLength(1));
    });

    test('toJson generates valid Caddy JSON with reverse proxy handler', () {
      const config = CaddyConfig(
        listenAddress: 'localhost:443',
        routes: [
          CaddyRoute(
            path: '/api/*',
            handler: ReverseProxyHandler(upstreams: ['localhost:3000']),
          ),
        ],
      );

      final json = config.toJson();
      final routes = json['apps']['http']['servers']['srv0']['routes'] as List;
      final handle = (routes[0] as Map)['handle'] as List;
      expect((handle[0] as Map)['handler'], 'reverse_proxy');
    });

    test('rawJson bypasses structured config', () {
      final rawConfig = jsonEncode({
        'apps': {
          'http': {
            'servers': {
              'srv0': {
                'listen': [':9999'],
              },
            },
          },
        },
      });

      final config = CaddyConfig(rawJson: rawConfig);
      final json = config.toJson();
      expect(json['apps']['http']['servers']['srv0']['listen'], [':9999']);
    });

    test('fromJson round-trips with structured config', () {
      const original = CaddyConfig(
        listenAddress: 'localhost:8080',
        routes: [
          CaddyRoute(
            path: '/*',
            handler: StaticFileHandler(root: '/var/www'),
          ),
        ],
      );

      final json = {
        'listenAddress': 'localhost:8080',
        'routes': [
          {
            'path': '/*',
            'handler': {'type': 'static_files', 'root': '/var/www'},
          },
        ],
      };

      final restored = CaddyConfig.fromJson(json);
      expect(restored.listenAddress, original.listenAddress);
      expect(restored.routes.length, original.routes.length);
      expect(restored.routes.first.path, original.routes.first.path);
    });

    test('copyWith preserves unchanged fields', () {
      const config = CaddyConfig(listenAddress: 'localhost:8080');
      final updated = config.copyWith(listenAddress: 'localhost:9090');

      expect(updated.listenAddress, 'localhost:9090');
      expect(updated.routes, config.routes);
    });
  });

  group('CaddyHandler', () {
    test('StaticFileHandler fromJson', () {
      final handler = CaddyHandler.fromJson({
        'type': 'static_files',
        'root': '/var/www',
      });

      expect(handler, isA<StaticFileHandler>());
      expect((handler as StaticFileHandler).root, '/var/www');
    });

    test('ReverseProxyHandler fromJson', () {
      final handler = CaddyHandler.fromJson({
        'type': 'reverse_proxy',
        'upstreams': ['localhost:3000', 'localhost:3001'],
      });

      expect(handler, isA<ReverseProxyHandler>());
      expect((handler as ReverseProxyHandler).upstreams, [
        'localhost:3000',
        'localhost:3001',
      ]);
    });
  });
}
