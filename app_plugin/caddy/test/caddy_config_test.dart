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
        CaddyConfigPresets.httpsWithDns(),
        CaddyConfigPresets.httpsWithS3(),
      ];

      for (final preset in presets) {
        expect(CaddyConfigPresets.validate(preset), isNull);
      }
    });

    test('httpsWithDns creates config with TLS enabled', () {
      final config = CaddyConfigPresets.httpsWithDns();
      expect(config.tls.enabled, isTrue);
      expect(config.tls.domain, 'example.com');
      expect(config.tls.dnsProvider, DnsProvider.cloudflare);
      expect(config.listenAddress, ':443');
    });
  });

  group('CaddyTlsConfig', () {
    test('default values', () {
      const tls = CaddyTlsConfig();
      expect(tls.enabled, isFalse);
      expect(tls.domain, isEmpty);
      expect(tls.dnsProvider, DnsProvider.none);
    });

    test('fromJson creates config correctly', () {
      final tls = CaddyTlsConfig.fromJson({
        'enabled': true,
        'domain': 'example.com',
        'dnsProvider': 'cloudflare',
      });
      expect(tls.enabled, isTrue);
      expect(tls.domain, 'example.com');
      expect(tls.dnsProvider, DnsProvider.cloudflare);
    });

    test('fromJson with unknown provider defaults to none', () {
      final tls = CaddyTlsConfig.fromJson({
        'enabled': true,
        'dnsProvider': 'unknown_provider',
      });
      expect(tls.dnsProvider, DnsProvider.none);
    });

    test('toJson round-trips correctly', () {
      const original = CaddyTlsConfig(
        enabled: true,
        domain: 'test.com',
        dnsProvider: DnsProvider.route53,
      );
      final restored = CaddyTlsConfig.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('copyWith preserves unchanged fields', () {
      const tls = CaddyTlsConfig(
        enabled: true,
        domain: 'test.com',
        dnsProvider: DnsProvider.cloudflare,
      );
      final updated = tls.copyWith(domain: 'new.com');
      expect(updated.enabled, isTrue);
      expect(updated.domain, 'new.com');
      expect(updated.dnsProvider, DnsProvider.cloudflare);
    });
  });

  group('CaddyStorageConfig', () {
    test('default values', () {
      const s3 = CaddyStorageConfig();
      expect(s3.enabled, isFalse);
      expect(s3.endpoint, isEmpty);
      expect(s3.bucket, isEmpty);
      expect(s3.region, isEmpty);
      expect(s3.prefix, 'caddy/');
    });

    test('fromJson creates config correctly', () {
      final s3 = CaddyStorageConfig.fromJson({
        'enabled': true,
        'endpoint': 's3.amazonaws.com',
        'bucket': 'my-bucket',
        'region': 'us-east-1',
        'prefix': 'certs/',
      });
      expect(s3.enabled, isTrue);
      expect(s3.endpoint, 's3.amazonaws.com');
      expect(s3.bucket, 'my-bucket');
      expect(s3.region, 'us-east-1');
      expect(s3.prefix, 'certs/');
    });

    test('toJson round-trips correctly', () {
      const original = CaddyStorageConfig(
        enabled: true,
        endpoint: 's3.eu-west-1.amazonaws.com',
        bucket: 'test-bucket',
        region: 'eu-west-1',
        prefix: 'caddy/',
      );
      final restored = CaddyStorageConfig.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('copyWith preserves unchanged fields', () {
      const s3 = CaddyStorageConfig(
        enabled: true,
        bucket: 'bucket',
        region: 'us-east-1',
      );
      final updated = s3.copyWith(bucket: 'new-bucket');
      expect(updated.enabled, isTrue);
      expect(updated.bucket, 'new-bucket');
      expect(updated.region, 'us-east-1');
    });
  });

  group('CaddyConfig TLS/S3 integration', () {
    test('toJson includes TLS automation when enabled with DNS provider', () {
      const config = CaddyConfig(
        listenAddress: ':443',
        tls: CaddyTlsConfig(
          enabled: true,
          domain: 'example.com',
          dnsProvider: DnsProvider.cloudflare,
        ),
      );

      final json = config.toJson();
      final tls = json['apps']['tls'] as Map<String, dynamic>;
      expect(tls, isNotNull);
      final policies = tls['automation']['policies'] as List;
      expect(policies, hasLength(1));
      final policy = policies.first as Map<String, dynamic>;
      expect(policy['subjects'], ['example.com']);
      final issuer =
          (policy['issuers'] as List).first as Map<String, dynamic>;
      expect(issuer['module'], 'acme');
      final provider = issuer['challenges']['dns']['provider']
          as Map<String, dynamic>;
      expect(provider['name'], 'cloudflare');
      expect(provider['api_token'], '{env.CF_API_TOKEN}');
    });

    test('toJson includes Route53 credentials for route53 provider', () {
      const config = CaddyConfig(
        listenAddress: ':443',
        tls: CaddyTlsConfig(
          enabled: true,
          dnsProvider: DnsProvider.route53,
        ),
      );

      final json = config.toJson();
      final policies =
          json['apps']['tls']['automation']['policies'] as List;
      final issuer = (policies.first as Map)['issuers'][0] as Map;
      final provider = issuer['challenges']['dns']['provider'] as Map;
      expect(provider['name'], 'route53');
      expect(provider['access_key_id'], '{env.AWS_ACCESS_KEY_ID}');
      expect(
        provider['secret_access_key'],
        '{env.AWS_SECRET_ACCESS_KEY}',
      );
    });

    test('toJson includes DuckDNS token for duckdns provider', () {
      const config = CaddyConfig(
        listenAddress: ':443',
        tls: CaddyTlsConfig(
          enabled: true,
          dnsProvider: DnsProvider.duckdns,
        ),
      );

      final json = config.toJson();
      final policies =
          json['apps']['tls']['automation']['policies'] as List;
      final issuer = (policies.first as Map)['issuers'][0] as Map;
      final provider = issuer['challenges']['dns']['provider'] as Map;
      expect(provider['name'], 'duckdns');
      expect(provider['api_token'], '{env.DUCKDNS_TOKEN}');
    });

    test('toJson excludes TLS when disabled', () {
      const config = CaddyConfig(
        listenAddress: ':443',
        tls: CaddyTlsConfig(enabled: false),
      );

      final json = config.toJson();
      expect((json['apps'] as Map).containsKey('tls'), isFalse);
    });

    test('toJson excludes TLS when provider is none', () {
      const config = CaddyConfig(
        listenAddress: ':443',
        tls: CaddyTlsConfig(
          enabled: true,
          dnsProvider: DnsProvider.none,
        ),
      );

      final json = config.toJson();
      expect((json['apps'] as Map).containsKey('tls'), isFalse);
    });

    test('toJson includes S3 storage when enabled', () {
      const config = CaddyConfig(
        listenAddress: 'localhost:8080',
        storage: CaddyStorageConfig(
          enabled: true,
          endpoint: 's3.amazonaws.com',
          bucket: 'my-bucket',
          region: 'us-east-1',
          prefix: 'caddy/',
        ),
      );

      final json = config.toJson();
      final storage = json['storage'] as Map<String, dynamic>;
      expect(storage['module'], 's3');
      expect(storage['host'], 's3.amazonaws.com');
      expect(storage['bucket'], 'my-bucket');
      expect(storage['region'], 'us-east-1');
      expect(storage['prefix'], 'caddy/');
    });

    test('toJson excludes S3 storage when disabled', () {
      const config = CaddyConfig(
        listenAddress: 'localhost:8080',
        storage: CaddyStorageConfig(enabled: false, bucket: 'bucket'),
      );

      final json = config.toJson();
      expect(json.containsKey('storage'), isFalse);
    });

    test('toJson excludes S3 storage when bucket is empty', () {
      const config = CaddyConfig(
        listenAddress: 'localhost:8080',
        storage: CaddyStorageConfig(enabled: true),
      );

      final json = config.toJson();
      expect(json.containsKey('storage'), isFalse);
    });

    test('toStorageJson includes TLS and storage', () {
      const config = CaddyConfig(
        listenAddress: 'localhost:8080',
        tls: CaddyTlsConfig(
          enabled: true,
          domain: 'test.com',
          dnsProvider: DnsProvider.cloudflare,
        ),
        storage: CaddyStorageConfig(
          enabled: true,
          bucket: 'test-bucket',
        ),
      );

      final json = config.toStorageJson();
      expect(json.containsKey('tls'), isTrue);
      expect(json.containsKey('storage'), isTrue);
      expect(json['tls']['enabled'], isTrue);
      expect(json['storage']['enabled'], isTrue);
    });

    test('fromJson restores TLS and storage', () {
      const original = CaddyConfig(
        listenAddress: 'localhost:8080',
        tls: CaddyTlsConfig(
          enabled: true,
          domain: 'test.com',
          dnsProvider: DnsProvider.route53,
        ),
        storage: CaddyStorageConfig(
          enabled: true,
          endpoint: 's3.example.com',
          bucket: 'bucket',
          region: 'eu-west-1',
        ),
      );

      final restored = CaddyConfig.fromJson(original.toStorageJson());
      expect(restored.tls, equals(original.tls));
      expect(restored.storage, equals(original.storage));
    });

    test('httpsWithS3 preset includes both TLS and S3', () {
      final config = CaddyConfigPresets.httpsWithS3();
      expect(config.tls.enabled, isTrue);
      expect(config.tls.domain, 'example.com');
      expect(config.tls.dnsProvider, DnsProvider.cloudflare);
      expect(config.storage.enabled, isTrue);
      expect(config.storage.bucket, 'my-caddy-storage');
      final json = config.toJson();
      expect((json['apps'] as Map).containsKey('tls'), isTrue);
      expect(json.containsKey('storage'), isTrue);
    });

    test('equatable includes TLS and storage in comparison', () {
      const config1 = CaddyConfig(
        tls: CaddyTlsConfig(enabled: true),
      );
      const config2 = CaddyConfig(
        tls: CaddyTlsConfig(enabled: false),
      );
      expect(config1, isNot(equals(config2)));
    });
  });
}
