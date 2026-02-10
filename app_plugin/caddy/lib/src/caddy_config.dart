import 'dart:convert';

import 'package:equatable/equatable.dart';

class CaddyConfig extends Equatable {
  const CaddyConfig({
    this.listenAddress = 'localhost:2015',
    this.routes = const [],
    this.rawJson,
  });

  final String listenAddress;
  final List<CaddyRoute> routes;
  final String? rawJson;

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

    return CaddyConfig(listenAddress: listenAddress, routes: routesList);
  }

  Map<String, dynamic> toJson() {
    if (rawJson != null) {
      return jsonDecode(rawJson!) as Map<String, dynamic>;
    }

    final host = listenAddress.split(':').first;
    final port = listenAddress.split(':').last;

    return {
      'apps': {
        'http': {
          'servers': {
            'srv0': {
              'listen': [':$port'],
              'routes': routes.map((r) => r.toJson(host)).toList(),
            },
          },
        },
      },
    };
  }

  String toJsonString() => jsonEncode(toJson());

  CaddyConfig copyWith({
    String? listenAddress,
    List<CaddyRoute>? routes,
    String? rawJson,
  }) {
    return CaddyConfig(
      listenAddress: listenAddress ?? this.listenAddress,
      routes: routes ?? this.routes,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  @override
  List<Object?> get props => [listenAddress, routes, rawJson];
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
