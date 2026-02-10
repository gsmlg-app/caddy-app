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

    test('toJsonString returns valid JSON string', () {
      const config = CaddyConfig(listenAddress: 'localhost:8080');
      final jsonString = config.toJsonString();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded.containsKey('apps'), isTrue);
    });

    test('toJsonString with adminEnabled includes admin listen', () {
      const config = CaddyConfig(listenAddress: 'localhost:8080');
      final jsonString = config.toJsonString(adminEnabled: true);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['admin']['listen'], 'localhost:2019');
    });

    test('toJsonString without admin disables admin endpoint', () {
      const config = CaddyConfig(listenAddress: 'localhost:8080');
      final jsonString = config.toJsonString();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(decoded['admin']['disabled'], isTrue);
    });

    test('fromJson with rawJson key', () {
      final json = {'_rawJson': '{"apps":{}}'};
      final config = CaddyConfig.fromJson(json);
      expect(config.rawJson, '{"apps":{}}');
    });

    test('equatable compares correctly', () {
      const config1 = CaddyConfig(listenAddress: 'localhost:8080');
      const config2 = CaddyConfig(listenAddress: 'localhost:8080');
      const config3 = CaddyConfig(listenAddress: 'localhost:9090');

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
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

    test('unknown type defaults to StaticFileHandler', () {
      final handler = CaddyHandler.fromJson({
        'type': 'unknown',
        'root': '/tmp',
      });

      expect(handler, isA<StaticFileHandler>());
      expect((handler as StaticFileHandler).root, '/tmp');
    });

    test('StaticFileHandler toJson', () {
      const handler = StaticFileHandler(root: '/var/www');
      final json = handler.toJson();
      expect(json['handler'], 'file_server');
      expect(json['root'], '/var/www');
    });

    test('ReverseProxyHandler toJson', () {
      const handler = ReverseProxyHandler(upstreams: ['localhost:3000']);
      final json = handler.toJson();
      expect(json['handler'], 'reverse_proxy');
      expect(json['upstreams'], [
        {'dial': 'localhost:3000'},
      ]);
    });
  });

  group('CaddyRoute', () {
    test('fromJson creates route correctly', () {
      final route = CaddyRoute.fromJson({
        'path': '/api/*',
        'handler': {
          'type': 'reverse_proxy',
          'upstreams': ['localhost:3000'],
        },
      });

      expect(route.path, '/api/*');
      expect(route.handler, isA<ReverseProxyHandler>());
    });

    test('toJson generates correct match and handle', () {
      const route = CaddyRoute(
        path: '/*',
        handler: StaticFileHandler(root: '/var/www'),
      );

      final json = route.toJson('localhost');
      expect(json['match'], [
        {
          'host': ['localhost'],
          'path': ['/*'],
        },
      ]);
      expect(json['handle'], hasLength(1));
    });

    test('equatable compares correctly', () {
      const route1 = CaddyRoute(
        path: '/*',
        handler: StaticFileHandler(root: '/var/www'),
      );
      const route2 = CaddyRoute(
        path: '/*',
        handler: StaticFileHandler(root: '/var/www'),
      );
      const route3 = CaddyRoute(
        path: '/api/*',
        handler: StaticFileHandler(root: '/var/www'),
      );

      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });
  });

  group('CaddyConfigPresets', () {
    test('staticFileServer creates valid config', () {
      final config = CaddyConfigPresets.staticFileServer();
      expect(config.listenAddress, 'localhost:8080');
      expect(config.routes, hasLength(1));
      expect(config.routes.first.handler, isA<StaticFileHandler>());
      expect(
        (config.routes.first.handler as StaticFileHandler).root,
        '/var/www/html',
      );
    });

    test('staticFileServer with custom params', () {
      final config = CaddyConfigPresets.staticFileServer(
        listenAddress: 'localhost:9090',
        root: '/home/user/site',
      );
      expect(config.listenAddress, 'localhost:9090');
      expect(
        (config.routes.first.handler as StaticFileHandler).root,
        '/home/user/site',
      );
    });

    test('reverseProxy creates valid config', () {
      final config = CaddyConfigPresets.reverseProxy();
      expect(config.listenAddress, 'localhost:8080');
      expect(config.routes, hasLength(1));
      expect(config.routes.first.handler, isA<ReverseProxyHandler>());
      expect(
        (config.routes.first.handler as ReverseProxyHandler).upstreams,
        ['localhost:3000'],
      );
    });

    test('reverseProxy with custom upstream', () {
      final config = CaddyConfigPresets.reverseProxy(
        upstream: 'localhost:4000',
      );
      expect(
        (config.routes.first.handler as ReverseProxyHandler).upstreams,
        ['localhost:4000'],
      );
    });

    test('spaServer creates config with rawJson', () {
      final config = CaddyConfigPresets.spaServer();
      expect(config.listenAddress, 'localhost:8080');
      expect(config.rawJson, isNotNull);

      final json = config.toJson();
      expect(json['apps']['http']['servers']['srv0']['listen'], [':8080']);
    });

    test('apiGateway creates config with rawJson', () {
      final config = CaddyConfigPresets.apiGateway();
      expect(config.listenAddress, 'localhost:8080');
      expect(config.rawJson, isNotNull);

      final json = config.toJson();
      final routes =
          json['apps']['http']['servers']['srv0']['routes'] as List;
      expect(routes, hasLength(2));
    });

    test('validate returns null for valid structured config', () {
      const config = CaddyConfig(listenAddress: 'localhost:8080');
      expect(CaddyConfigPresets.validate(config), isNull);
    });

    test('validate returns null for valid rawJson config', () {
      final config = CaddyConfig(rawJson: jsonEncode({'apps': {}}));
      expect(CaddyConfigPresets.validate(config), isNull);
    });

    test('validate returns error for invalid rawJson', () {
      const config = CaddyConfig(rawJson: '{invalid json}');
      final error = CaddyConfigPresets.validate(config);
      expect(error, isNotNull);
      expect(error, contains('Invalid JSON'));
    });

    test('validate returns error for malformed rawJson', () {
      const config = CaddyConfig(rawJson: 'not json at all');
      final error = CaddyConfigPresets.validate(config);
      expect(error, isNotNull);
    });

    test('all presets pass validation', () {
      final presets = [
        CaddyConfigPresets.staticFileServer(),
        CaddyConfigPresets.reverseProxy(),
        CaddyConfigPresets.spaServer(),
        CaddyConfigPresets.apiGateway(),
      ];

      for (final preset in presets) {
        expect(CaddyConfigPresets.validate(preset), isNull);
      }
    });
  });
}
