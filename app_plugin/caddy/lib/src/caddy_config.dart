import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The format of a Caddy configuration text.
enum ConfigFormat { caddyfile, json }

/// A text-based Caddy configuration that stores the raw config content
/// and its format (Caddyfile or JSON).
///
/// This replaces the old structured [CaddyConfig] model. Users edit
/// Caddyfile or JSON directly; the Go bridge handles Caddyfile→JSON
/// conversion via Caddy's built-in adapter.
class CaddyTextConfig extends Equatable {
  const CaddyTextConfig({
    this.text = '',
    this.format = ConfigFormat.caddyfile,
  });

  /// The raw configuration text (Caddyfile or JSON).
  final String text;

  /// Whether this config is in Caddyfile or JSON format.
  final ConfigFormat format;

  bool get isEmpty => text.trim().isEmpty;

  factory CaddyTextConfig.fromJson(Map<String, dynamic> json) {
    return CaddyTextConfig(
      text: json['text'] as String? ?? '',
      format: ConfigFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => ConfigFormat.caddyfile,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'format': format.name,
      };

  CaddyTextConfig copyWith({String? text, ConfigFormat? format}) {
    return CaddyTextConfig(
      text: text ?? this.text,
      format: format ?? this.format,
    );
  }

  @override
  List<Object?> get props => [text, format];
}

/// Built-in Caddyfile presets for common server configurations.
class CaddyConfigPresets {
  CaddyConfigPresets._();

  static CaddyTextConfig staticFileServer() => const CaddyTextConfig(
        text: ':8080\n'
            '\n'
            'root * /var/www/html\n'
            'file_server\n',
      );

  static CaddyTextConfig reverseProxy() => const CaddyTextConfig(
        text: ':8080\n'
            '\n'
            'reverse_proxy localhost:3000\n',
      );

  static CaddyTextConfig spaServer() => const CaddyTextConfig(
        text: ':8080\n'
            '\n'
            'root * /var/www/html\n'
            'try_files {path} /index.html\n'
            'file_server\n',
      );

  static CaddyTextConfig apiGateway() => const CaddyTextConfig(
        text: ':8080\n'
            '\n'
            'handle /api/* {\n'
            '\treverse_proxy localhost:3000\n'
            '}\n'
            '\n'
            'handle {\n'
            '\troot * /var/www/html\n'
            '\tfile_server\n'
            '}\n',
      );

  static CaddyTextConfig httpsWithDns() => const CaddyTextConfig(
        text: 'example.com {\n'
            '\ttls {\n'
            '\t\tdns cloudflare {env.CF_API_TOKEN}\n'
            '\t}\n'
            '\n'
            '\troot * /var/www/html\n'
            '\tfile_server\n'
            '}\n',
      );

  static CaddyTextConfig httpsWithS3() => const CaddyTextConfig(
        text: '{\n'
            '\tstorage s3 {\n'
            '\t\tbucket my-caddy-storage\n'
            '\t}\n'
            '}\n'
            '\n'
            'example.com {\n'
            '\ttls {\n'
            '\t\tdns cloudflare {env.CF_API_TOKEN}\n'
            '\t}\n'
            '\n'
            '\troot * /var/www/html\n'
            '\tfile_server\n'
            '}\n',
      );

  /// Validates config text. For JSON, checks JSON syntax.
  /// For Caddyfile, basic non-empty check (real validation happens
  /// via the Go adapter).
  static String? validate(CaddyTextConfig config) {
    if (config.isEmpty) return 'Configuration is empty';

    if (config.format == ConfigFormat.json) {
      try {
        jsonDecode(config.text);
        return null;
      } on FormatException catch (e) {
        return 'Invalid JSON: ${e.message}';
      }
    }

    // Caddyfile validation happens server-side via adaptCaddyfile
    return null;
  }
}
