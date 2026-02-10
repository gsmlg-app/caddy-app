import 'dart:convert';

import 'package:equatable/equatable.dart';

/// DNS provider types supported by the embedded Caddy modules.
enum DnsProvider { none, cloudflare, route53, duckdns }

/// TLS configuration for automatic HTTPS.
class CaddyTlsConfig extends Equatable {
  const CaddyTlsConfig({
    this.enabled = false,
    this.domain = '',
    this.dnsProvider = DnsProvider.none,
  });

  final bool enabled;
  final String domain;
  final DnsProvider dnsProvider;

  factory CaddyTlsConfig.fromJson(Map<String, dynamic> json) {
    return CaddyTlsConfig(
      enabled: json['enabled'] as bool? ?? false,
      domain: json['domain'] as String? ?? '',
      dnsProvider: DnsProvider.values.firstWhere(
        (e) => e.name == json['dnsProvider'],
        orElse: () => DnsProvider.none,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'domain': domain,
    'dnsProvider': dnsProvider.name,
  };

  CaddyTlsConfig copyWith({
    bool? enabled,
    String? domain,
    DnsProvider? dnsProvider,
  }) {
    return CaddyTlsConfig(
      enabled: enabled ?? this.enabled,
      domain: domain ?? this.domain,
      dnsProvider: dnsProvider ?? this.dnsProvider,
    );
  }

  @override
  List<Object?> get props => [enabled, domain, dnsProvider];
}

/// S3-compatible storage configuration for Caddy certificate persistence.
class CaddyStorageConfig extends Equatable {
  const CaddyStorageConfig({
    this.enabled = false,
    this.endpoint = '',
    this.bucket = '',
    this.region = '',
    this.prefix = 'caddy/',
  });

  final bool enabled;
  final String endpoint;
  final String bucket;
  final String region;
  final String prefix;

  factory CaddyStorageConfig.fromJson(Map<String, dynamic> json) {
    return CaddyStorageConfig(
      enabled: json['enabled'] as bool? ?? false,
      endpoint: json['endpoint'] as String? ?? '',
      bucket: json['bucket'] as String? ?? '',
      region: json['region'] as String? ?? '',
      prefix: json['prefix'] as String? ?? 'caddy/',
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'endpoint': endpoint,
    'bucket': bucket,
    'region': region,
    'prefix': prefix,
  };

  CaddyStorageConfig copyWith({
    bool? enabled,
    String? endpoint,
    String? bucket,
    String? region,
    String? prefix,
  }) {
    return CaddyStorageConfig(
      enabled: enabled ?? this.enabled,
      endpoint: endpoint ?? this.endpoint,
      bucket: bucket ?? this.bucket,
      region: region ?? this.region,
      prefix: prefix ?? this.prefix,
    );
  }

  @override
  List<Object?> get props => [enabled, endpoint, bucket, region, prefix];
}

class CaddyConfig extends Equatable {
  const CaddyConfig({
    this.listenAddress = 'localhost:2015',
    this.routes = const [],
    this.rawJson,
    this.tls = const CaddyTlsConfig(),
    this.storage = const CaddyStorageConfig(),
  });

  final String listenAddress;
  final List<CaddyRoute> routes;
  final String? rawJson;
  final CaddyTlsConfig tls;
  final CaddyStorageConfig storage;

  factory CaddyConfig.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('_rawJson')) {
      return CaddyConfig(rawJson: json['_rawJson'] as String);
    }

    final listenAddress = json['listenAddress'] as String? ?? 'localhost:2015';
    final routesList =
        (json['routes'] as List<dynamic>?)
            ?.map((r) => CaddyRoute.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];
    final tls = json['tls'] != null
        ? CaddyTlsConfig.fromJson(json['tls'] as Map<String, dynamic>)
        : const CaddyTlsConfig();
    final storage = json['storage'] != null
        ? CaddyStorageConfig.fromJson(json['storage'] as Map<String, dynamic>)
        : const CaddyStorageConfig();

    return CaddyConfig(
      listenAddress: listenAddress,
      routes: routesList,
      tls: tls,
      storage: storage,
    );
  }

  Map<String, dynamic> toJson() {
    if (rawJson != null) {
      return jsonDecode(rawJson!) as Map<String, dynamic>;
    }

    final host = listenAddress.split(':').first;
    final port = listenAddress.split(':').last;

    final apps = <String, dynamic>{
      'http': {
        'servers': {
          'srv0': {
            'listen': [':$port'],
            'routes': routes.map((r) => r.toJson(host)).toList(),
          },
        },
      },
    };

    // Add TLS automation policy if enabled
    if (tls.enabled && tls.dnsProvider != DnsProvider.none) {
      final providerConfig = switch (tls.dnsProvider) {
        DnsProvider.cloudflare => {
          'name': 'cloudflare',
          'api_token': '{env.CF_API_TOKEN}',
        },
        DnsProvider.route53 => {
          'name': 'route53',
          'access_key_id': '{env.AWS_ACCESS_KEY_ID}',
          'secret_access_key': '{env.AWS_SECRET_ACCESS_KEY}',
        },
        DnsProvider.duckdns => {
          'name': 'duckdns',
          'api_token': '{env.DUCKDNS_TOKEN}',
        },
        DnsProvider.none => <String, dynamic>{},
      };

      apps['tls'] = {
        'automation': {
          'policies': [
            {
              if (tls.domain.isNotEmpty) 'subjects': [tls.domain],
              'issuers': [
                {
                  'module': 'acme',
                  'challenges': {
                    'dns': {'provider': providerConfig},
                  },
                },
              ],
            },
          ],
        },
      };
    }

    final json = <String, dynamic>{'apps': apps};

    // Add S3 storage if enabled
    if (storage.enabled && storage.bucket.isNotEmpty) {
      json['storage'] = {
        'module': 's3',
        if (storage.endpoint.isNotEmpty) 'host': storage.endpoint,
        'bucket': storage.bucket,
        if (storage.region.isNotEmpty) 'region': storage.region,
        if (storage.prefix.isNotEmpty) 'prefix': storage.prefix,
      };
    }

    return json;
  }

  String toJsonString({bool adminEnabled = false}) {
    final json = toJson();
    if (adminEnabled) {
      json['admin'] = {'listen': 'localhost:2019'};
    } else {
      json['admin'] = {'disabled': true};
    }
    return jsonEncode(json);
  }

  Map<String, dynamic> toStorageJson() {
    if (rawJson != null) {
      return {'_rawJson': rawJson, 'listenAddress': listenAddress};
    }
    return {
      'listenAddress': listenAddress,
      'routes': routes
          .map((r) => {'path': r.path, 'handler': r.handler.toJson()})
          .toList(),
      'tls': tls.toJson(),
      'storage': storage.toJson(),
    };
  }

  CaddyConfig copyWith({
    String? listenAddress,
    List<CaddyRoute>? routes,
    String? rawJson,
    CaddyTlsConfig? tls,
    CaddyStorageConfig? storage,
  }) {
    return CaddyConfig(
      listenAddress: listenAddress ?? this.listenAddress,
      routes: routes ?? this.routes,
      rawJson: rawJson ?? this.rawJson,
      tls: tls ?? this.tls,
      storage: storage ?? this.storage,
    );
  }

  @override
  List<Object?> get props => [listenAddress, routes, rawJson, tls, storage];
}

class CaddyRoute extends Equatable {
  const CaddyRoute({required this.path, required this.handler});

  final String path;
  final CaddyHandler handler;

  factory CaddyRoute.fromJson(Map<String, dynamic> json) {
    return CaddyRoute(
      path: json['path'] as String,
      handler: CaddyHandler.fromJson(json['handler'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson(String host) {
    return {
      'match': [
        {
          'host': [host],
          'path': [path],
        },
      ],
      'handle': [handler.toJson()],
    };
  }

  @override
  List<Object?> get props => [path, handler];
}

sealed class CaddyHandler extends Equatable {
  const CaddyHandler();

  factory CaddyHandler.fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'static_files' => StaticFileHandler(root: json['root'] as String),
      'reverse_proxy' => ReverseProxyHandler(
        upstreams: (json['upstreams'] as List<dynamic>).cast<String>(),
      ),
      _ => StaticFileHandler(root: json['root'] as String? ?? '.'),
    };
  }

  Map<String, dynamic> toJson();
}

final class StaticFileHandler extends CaddyHandler {
  const StaticFileHandler({required this.root});

  final String root;

  @override
  Map<String, dynamic> toJson() {
    return {'handler': 'file_server', 'root': root};
  }

  @override
  List<Object?> get props => [root];
}

final class ReverseProxyHandler extends CaddyHandler {
  const ReverseProxyHandler({required this.upstreams});

  final List<String> upstreams;

  @override
  Map<String, dynamic> toJson() {
    return {
      'handler': 'reverse_proxy',
      'upstreams': upstreams.map((u) => {'dial': u}).toList(),
    };
  }

  @override
  List<Object?> get props => [upstreams];
}

class CaddyConfigPresets {
  CaddyConfigPresets._();

  static CaddyConfig staticFileServer({
    String listenAddress = 'localhost:8080',
    String root = '/var/www/html',
  }) {
    return CaddyConfig(
      listenAddress: listenAddress,
      routes: [
        CaddyRoute(
          path: '/*',
          handler: StaticFileHandler(root: root),
        ),
      ],
    );
  }

  static CaddyConfig reverseProxy({
    String listenAddress = 'localhost:8080',
    String upstream = 'localhost:3000',
  }) {
    return CaddyConfig(
      listenAddress: listenAddress,
      routes: [
        CaddyRoute(
          path: '/*',
          handler: ReverseProxyHandler(upstreams: [upstream]),
        ),
      ],
    );
  }

  static CaddyConfig spaServer({
    String listenAddress = 'localhost:8080',
    String root = '/var/www/html',
  }) {
    return CaddyConfig(
      listenAddress: listenAddress,
      rawJson: jsonEncode({
        'apps': {
          'http': {
            'servers': {
              'srv0': {
                'listen': [':${listenAddress.split(':').last}'],
                'routes': [
                  {
                    'handle': [
                      {'handler': 'file_server', 'root': root},
                      {'handler': 'rewrite', 'uri': '/index.html'},
                    ],
                  },
                ],
              },
            },
          },
        },
      }),
    );
  }

  static CaddyConfig apiGateway({String listenAddress = 'localhost:8080'}) {
    return CaddyConfig(
      listenAddress: listenAddress,
      rawJson: jsonEncode({
        'apps': {
          'http': {
            'servers': {
              'srv0': {
                'listen': [':${listenAddress.split(':').last}'],
                'routes': [
                  {
                    'match': [
                      {
                        'path': ['/api/*'],
                      },
                    ],
                    'handle': [
                      {
                        'handler': 'reverse_proxy',
                        'upstreams': [
                          {'dial': 'localhost:3000'},
                        ],
                      },
                    ],
                  },
                  {
                    'handle': [
                      {'handler': 'file_server', 'root': '/var/www/html'},
                    ],
                  },
                ],
              },
            },
          },
        },
      }),
    );
  }

  /// Preset for HTTPS with DNS challenge.
  static CaddyConfig httpsWithDns({
    String listenAddress = ':443',
    String domain = 'example.com',
    DnsProvider dnsProvider = DnsProvider.cloudflare,
  }) {
    return CaddyConfig(
      listenAddress: listenAddress,
      tls: CaddyTlsConfig(
        enabled: true,
        domain: domain,
        dnsProvider: dnsProvider,
      ),
      routes: [
        const CaddyRoute(
          path: '/*',
          handler: StaticFileHandler(root: '/var/www/html'),
        ),
      ],
    );
  }

  static String? validate(CaddyConfig config) {
    try {
      config.toJson();
      if (config.rawJson != null) {
        jsonDecode(config.rawJson!);
      }
      return null;
    } on FormatException catch (e) {
      return 'Invalid JSON: ${e.message}';
    } catch (e) {
      return e.toString();
    }
  }
}
