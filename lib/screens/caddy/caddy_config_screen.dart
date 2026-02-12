import 'dart:convert';
import 'dart:io';

import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

class CaddyConfigScreen extends StatefulWidget {
  static const name = 'Caddy Config';
  static const path = 'config';

  const CaddyConfigScreen({super.key});

  @override
  State<CaddyConfigScreen> createState() => _CaddyConfigScreenState();
}

class _CaddyConfigScreenState extends State<CaddyConfigScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _listenController;
  late final TextEditingController _rawJsonController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final config = context.read<CaddyBloc>().state.config;
    _listenController = TextEditingController(text: config.listenAddress);
    _rawJsonController = TextEditingController(
      text: config.rawJson ?? config.toJsonString(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listenController.dispose();
    _rawJsonController.dispose();
    super.dispose();
  }

  CaddyConfig _buildConfig() {
    final bloc = context.read<CaddyBloc>();
    if (_tabController.index == 0) {
      return CaddyConfig(
        listenAddress: _listenController.text,
        routes: bloc.state.config.routes,
        tls: bloc.state.config.tls,
        storage: bloc.state.config.storage,
      );
    } else {
      return CaddyConfig(rawJson: _rawJsonController.text);
    }
  }

  void _validateConfig() {
    final config = _buildConfig();
    final error = CaddyConfigPresets.validate(config);
    final messenger = ScaffoldMessenger.of(context);
    if (error == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.caddyConfigValid),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.caddyConfigInvalid(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _saveConfig() {
    final config = _buildConfig();
    final error = CaddyConfigPresets.validate(config);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.caddyConfigInvalid(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    context.read<CaddyBloc>().add(CaddyUpdateConfig(config));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
  }

  void _applyConfig() {
    final config = _buildConfig();
    final error = CaddyConfigPresets.validate(config);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.caddyConfigInvalid(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final bloc = context.read<CaddyBloc>();
    if (bloc.state.isRunning) {
      _showDiffDialog(context, bloc.state.config, config);
    } else {
      bloc.add(CaddyUpdateConfig(config));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
    }
  }

  void _showDiffDialog(
    BuildContext context,
    CaddyConfig currentConfig,
    CaddyConfig newConfig,
  ) {
    final currentJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(currentConfig.toJson());
    final newJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(newConfig.toJson());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.caddyConfigDiffTitle),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: currentJson == newJson
                ? Center(
                    child: Text(
                      dialogContext.l10n.caddyConfigDiffNoChanges,
                      style: Theme.of(dialogContext).textTheme.bodyLarge,
                    ),
                  )
                : _ConfigDiffView(
                    currentJson: currentJson,
                    newJson: newJson,
                    currentLabel: dialogContext.l10n.caddyConfigDiffCurrent,
                    newLabel: dialogContext.l10n.caddyConfigDiffNew,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.cancel),
            ),
            if (currentJson != newJson)
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<CaddyBloc>().add(CaddyUpdateConfig(newConfig));
                  context.read<CaddyBloc>().add(CaddyReload(newConfig));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
                },
                icon: const Icon(Icons.check),
                label: Text(dialogContext.l10n.caddyConfigDiffApply),
              ),
          ],
        );
      },
    );
  }

  void _loadPreset(CaddyConfig preset) {
    _listenController.text = preset.listenAddress;
    _rawJsonController.text = preset.rawJson ?? preset.toJsonString();
    context.read<CaddyBloc>().add(CaddyUpdateConfig(preset));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
  }

  void _copyConfig() {
    final config = _buildConfig();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(config.toJson());
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.caddyConfigCopied)));
  }

  Future<void> _exportConfig() async {
    final config = _buildConfig();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(config.toJson());
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/caddy-config-$timestamp.json');
      await file.writeAsString(jsonStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.caddyConfigExported(file.path))),
        );
      }
    } catch (e, stackTrace) {
      AppLogger().e('Failed to export config', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.caddyConfigExportFailed)),
        );
      }
    }
  }

  Future<void> _importConfig() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.caddyConfigImportFailed('Clipboard is empty'),
            ),
          ),
        );
      }
      return;
    }
    try {
      final json = jsonDecode(text) as Map<String, dynamic>;
      final config = CaddyConfig(rawJson: jsonEncode(json));
      if (!mounted) return;
      _listenController.text = config.listenAddress;
      _rawJsonController.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(json);
      context.read<CaddyBloc>().add(CaddyUpdateConfig(config));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.caddyConfigImported)));
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.caddyConfigImportFailed('Not valid JSON'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showSaveAsDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.caddySaveConfigAs),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: dialogContext.l10n.caddyConfigName,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                _saveConfig();
                context.read<CaddyBloc>().add(CaddySaveConfig(name));
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
              },
              child: Text(dialogContext.l10n.caddySave),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CaddyBloc, CaddyState>(
      listenWhen: (prev, curr) =>
          prev.activeConfigName != curr.activeConfigName,
      listener: (context, state) {
        _listenController.text = state.config.listenAddress;
        _rawJsonController.text =
            state.config.rawJson ?? state.config.toJsonString();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.caddyConfig),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: context.l10n.caddyConfigSimple),
              Tab(text: context.l10n.caddyConfigRaw),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.snippet_folder),
              tooltip: context.l10n.caddyConfigPresets,
              onSelected: (value) {
                final preset = switch (value) {
                  'static' => CaddyConfigPresets.staticFileServer(),
                  'proxy' => CaddyConfigPresets.reverseProxy(),
                  'spa' => CaddyConfigPresets.spaServer(),
                  'api' => CaddyConfigPresets.apiGateway(),
                  'https' => CaddyConfigPresets.httpsWithDns(),
                  's3' => CaddyConfigPresets.httpsWithS3(),
                  _ => null,
                };
                if (preset != null) _loadPreset(preset);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'static',
                  child: ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(context.l10n.caddyPresetStaticFile),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'proxy',
                  child: ListTile(
                    leading: const Icon(Icons.swap_horiz),
                    title: Text(context.l10n.caddyPresetReverseProxy),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'spa',
                  child: ListTile(
                    leading: const Icon(Icons.web),
                    title: Text(context.l10n.caddyPresetSpa),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'api',
                  child: ListTile(
                    leading: const Icon(Icons.api),
                    title: Text(context.l10n.caddyPresetApiGateway),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'https',
                  child: ListTile(
                    leading: const Icon(Icons.lock),
                    title: Text(context.l10n.caddyTlsSettings),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 's3',
                  child: ListTile(
                    leading: const Icon(Icons.cloud),
                    title: Text(context.l10n.caddyPresetS3Full),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _validateConfig,
              child: Text(context.l10n.caddyValidate),
            ),
            TextButton(
              onPressed: _saveConfig,
              child: Text(context.l10n.caddySave),
            ),
            IconButton(
              icon: const Icon(Icons.save_as),
              tooltip: context.l10n.caddySaveConfigAs,
              onPressed: _showSaveAsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: context.l10n.caddyConfigCopy,
              onPressed: _copyConfig,
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: context.l10n.caddyConfigExport,
              onPressed: _exportConfig,
            ),
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: context.l10n.caddyConfigImport,
              onPressed: _importConfig,
            ),
            BlocBuilder<CaddyBloc, CaddyState>(
              buildWhen: (prev, curr) =>
                  prev.savedConfigNames != curr.savedConfigNames,
              builder: (context, state) {
                if (state.savedConfigNames.isEmpty) {
                  return const SizedBox.shrink();
                }
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.bookmark),
                  tooltip: context.l10n.caddySavedConfigs,
                  onSelected: (name) {
                    context.read<CaddyBloc>().add(CaddyLoadNamedConfig(name));
                  },
                  itemBuilder: (context) => state.savedConfigNames
                      .map(
                        (name) => PopupMenuItem(
                          value: name,
                          child: ListTile(
                            leading: Icon(
                              name == state.activeConfigName
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                            title: Text(name),
                            contentPadding: EdgeInsets.zero,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () {
                                context.read<CaddyBloc>().add(
                                  CaddyDeleteSavedConfig(name),
                                );
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            TextButton(
              onPressed: _applyConfig,
              child: Text(context.l10n.caddyApply),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _SimpleConfigForm(listenController: _listenController),
            _RawJsonEditor(controller: _rawJsonController),
          ],
        ),
      ),
    );
  }
}

class _SimpleConfigForm extends StatelessWidget {
  const _SimpleConfigForm({required this.listenController});

  final TextEditingController listenController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaddyBloc, CaddyState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: listenController,
              decoration: InputDecoration(
                labelText: context.l10n.caddyListenAddress(''),
                hintText: 'localhost:2015',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Routes (${state.config.routes.length})',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: context.l10n.caddyAddRoute,
                  onPressed: () => _showRouteDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.config.routes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No routes configured'),
                ),
              ),
            if (state.config.routes.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.config.routes.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final routes = [...state.config.routes];
                  final route = routes.removeAt(oldIndex);
                  routes.insert(newIndex, route);
                  context.read<CaddyBloc>().add(
                    CaddyUpdateConfig(state.config.copyWith(routes: routes)),
                  );
                },
                itemBuilder: (_, index) {
                  final route = state.config.routes[index];
                  return Card(
                    key: ValueKey('route_$index'),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle),
                      ),
                      title: Text(route.path),
                      subtitle: Text(switch (route.handler) {
                        StaticFileHandler(root: final root) =>
                          'Static Files: $root',
                        ReverseProxyHandler(upstreams: final upstreams) =>
                          'Reverse Proxy: ${upstreams.join(', ')}',
                      }),
                      onTap: () => _showRouteDialog(
                        context,
                        editIndex: index,
                        existingRoute: route,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          final routes = [...state.config.routes]
                            ..removeAt(index);
                          context.read<CaddyBloc>().add(
                            CaddyUpdateConfig(
                              state.config.copyWith(routes: routes),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            _TlsSection(config: state.config),
            const SizedBox(height: 24),
            _S3StorageSection(config: state.config),
          ],
        );
      },
    );
  }

  void _showRouteDialog(
    BuildContext parentContext, {
    int? editIndex,
    CaddyRoute? existingRoute,
  }) {
    final isEditing = editIndex != null && existingRoute != null;
    final isStaticInitially =
        existingRoute == null || existingRoute.handler is StaticFileHandler;
    final initialValue = switch (existingRoute?.handler) {
      StaticFileHandler(root: final root) => root,
      ReverseProxyHandler(upstreams: final upstreams) => upstreams.join(', '),
      null => '',
    };

    final pathController = TextEditingController(
      text: existingRoute?.path ?? '/*',
    );
    final valueController = TextEditingController(text: initialValue);
    var isStaticFile = isStaticInitially;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? dialogContext.l10n.caddyEditRoute
                    : dialogContext.l10n.caddyAddRoute,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pathController,
                    decoration: InputDecoration(
                      labelText: dialogContext.l10n.caddyRoutePath,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(dialogContext.l10n.caddyStaticFiles),
                        icon: const Icon(Icons.folder),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(dialogContext.l10n.caddyReverseProxy),
                        icon: const Icon(Icons.swap_horiz),
                      ),
                    ],
                    selected: {isStaticFile},
                    onSelectionChanged: (v) {
                      setDialogState(() => isStaticFile = v.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: isStaticFile
                          ? dialogContext.l10n.caddyFileRoot
                          : dialogContext.l10n.caddyUpstreamAddress,
                      hintText: isStaticFile
                          ? '/var/www/html'
                          : 'localhost:3000',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dialogContext.l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    final bloc = parentContext.read<CaddyBloc>();
                    final handler = isStaticFile
                        ? StaticFileHandler(root: valueController.text)
                        : ReverseProxyHandler(upstreams: [valueController.text])
                              as CaddyHandler;
                    final route = CaddyRoute(
                      path: pathController.text,
                      handler: handler,
                    );
                    final routes = [...bloc.state.config.routes];
                    if (isEditing) {
                      routes[editIndex] = route;
                    } else {
                      routes.add(route);
                    }
                    bloc.add(
                      CaddyUpdateConfig(
                        bloc.state.config.copyWith(routes: routes),
                      ),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(dialogContext.l10n.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RawJsonEditor extends StatefulWidget {
  const _RawJsonEditor({required this.controller});

  final TextEditingController controller;

  @override
  State<_RawJsonEditor> createState() => _RawJsonEditorState();
}

class _RawJsonEditorState extends State<_RawJsonEditor> {
  late final _JsonHighlightController _highlightController;

  @override
  void initState() {
    super.initState();
    _highlightController = _JsonHighlightController(widget.controller.text);
    // Sync changes back to the parent controller.
    _highlightController.addListener(() {
      if (widget.controller.text != _highlightController.text) {
        widget.controller.text = _highlightController.text;
      }
    });
    widget.controller.addListener(_syncFromParent);
  }

  void _syncFromParent() {
    if (_highlightController.text != widget.controller.text) {
      _highlightController.text = widget.controller.text;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromParent);
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _highlightController,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

class _JsonHighlightController extends TextEditingController {
  _JsonHighlightController(String text) : super(text: text);

  static final _patterns = <_JsonPattern>[
    // Strings (keys and values)
    _JsonPattern(RegExp(r'"(?:[^"\\]|\\.)*"(?=\s*:)'), _TokenType.key),
    _JsonPattern(RegExp(r'"(?:[^"\\]|\\.)*"'), _TokenType.string),
    // Numbers
    _JsonPattern(
      RegExp(r'-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
      _TokenType.number,
    ),
    // Booleans and null
    _JsonPattern(RegExp(r'\b(?:true|false|null)\b'), _TokenType.keyword),
    // Braces and brackets
    _JsonPattern(RegExp(r'[{}[\]]'), _TokenType.punctuation),
  ];

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _JsonColors.from(isDark);
    final src = text;
    final spans = <TextSpan>[];
    var pos = 0;

    // Collect all matches sorted by position.
    final matches = <_Match>[];
    for (final pattern in _patterns) {
      for (final m in pattern.regex.allMatches(src)) {
        matches.add(_Match(m.start, m.end, pattern.type));
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    for (final m in matches) {
      if (m.start < pos) continue; // Skip overlapping matches.
      if (m.start > pos) {
        spans.add(TextSpan(text: src.substring(pos, m.start)));
      }
      spans.add(
        TextSpan(
          text: src.substring(m.start, m.end),
          style: TextStyle(color: colors.colorFor(m.type)),
        ),
      );
      pos = m.end;
    }
    if (pos < src.length) {
      spans.add(TextSpan(text: src.substring(pos)));
    }

    return TextSpan(style: style, children: spans);
  }
}

enum _TokenType { key, string, number, keyword, punctuation }

class _JsonPattern {
  const _JsonPattern(this.regex, this.type);
  final RegExp regex;
  final _TokenType type;
}

class _Match {
  const _Match(this.start, this.end, this.type);
  final int start;
  final int end;
  final _TokenType type;
}

class _JsonColors {
  const _JsonColors({
    required this.key,
    required this.string,
    required this.number,
    required this.keyword,
    required this.punctuation,
  });

  factory _JsonColors.from(bool isDark) {
    if (isDark) {
      return const _JsonColors(
        key: Color(0xFF9CDCFE),
        string: Color(0xFFCE9178),
        number: Color(0xFFB5CEA8),
        keyword: Color(0xFF569CD6),
        punctuation: Color(0xFFD4D4D4),
      );
    }
    return const _JsonColors(
      key: Color(0xFF0451A5),
      string: Color(0xFFA31515),
      number: Color(0xFF098658),
      keyword: Color(0xFF0000FF),
      punctuation: Color(0xFF000000),
    );
  }

  final Color key;
  final Color string;
  final Color number;
  final Color keyword;
  final Color punctuation;

  Color colorFor(_TokenType type) => switch (type) {
    _TokenType.key => key,
    _TokenType.string => string,
    _TokenType.number => number,
    _TokenType.keyword => keyword,
    _TokenType.punctuation => punctuation,
  };
}

class _TlsSection extends StatelessWidget {
  const _TlsSection({required this.config});

  final CaddyConfig config;

  @override
  Widget build(BuildContext context) {
    final tls = config.tls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.caddyTlsSettings,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(context.l10n.caddyTlsEnabled),
                secondary: Icon(
                  Icons.lock,
                  color: tls.enabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                value: tls.enabled,
                onChanged: (value) {
                  context.read<CaddyBloc>().add(
                    CaddyUpdateConfig(
                      config.copyWith(tls: tls.copyWith(enabled: value)),
                    ),
                  );
                },
              ),
              if (tls.enabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: context.l10n.caddyTlsDomain,
                      hintText: 'example.com',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: tls.domain),
                    onChanged: (value) {
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          config.copyWith(tls: tls.copyWith(domain: value)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<DnsProvider>(
                    initialValue: tls.dnsProvider,
                    decoration: InputDecoration(
                      labelText: context.l10n.caddyDnsProvider,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: DnsProvider.none,
                        child: Text(context.l10n.caddyDnsProviderNone),
                      ),
                      DropdownMenuItem(
                        value: DnsProvider.cloudflare,
                        child: Text(context.l10n.caddyDnsProviderCloudflare),
                      ),
                      DropdownMenuItem(
                        value: DnsProvider.route53,
                        child: Text(context.l10n.caddyDnsProviderRoute53),
                      ),
                      DropdownMenuItem(
                        value: DnsProvider.duckdns,
                        child: Text(context.l10n.caddyDnsProviderDuckdns),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          config.copyWith(
                            tls: tls.copyWith(dnsProvider: value),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigDiffView extends StatelessWidget {
  const _ConfigDiffView({
    required this.currentJson,
    required this.newJson,
    required this.currentLabel,
    required this.newLabel,
  });

  final String currentJson;
  final String newJson;
  final String currentLabel;
  final String newLabel;

  @override
  Widget build(BuildContext context) {
    final currentLines = currentJson.split('\n');
    final newLines = newJson.split('\n');
    final diffLines = _computeDiff(currentLines, newLines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _DiffLegendChip(
              color: Colors.red.withValues(alpha: 0.15),
              label: '- $currentLabel',
            ),
            const SizedBox(width: 12),
            _DiffLegendChip(
              color: Colors.green.withValues(alpha: 0.15),
              label: '+ $newLabel',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: diffLines.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final diff = diffLines[index];
                final (bg, prefix) = switch (diff.type) {
                  _DiffType.removed => (
                    Colors.red.withValues(alpha: 0.15),
                    '- ',
                  ),
                  _DiffType.added => (
                    Colors.green.withValues(alpha: 0.15),
                    '+ ',
                  ),
                  _DiffType.unchanged => (null as Color?, '  '),
                };
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    '$prefix${diff.text}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: diff.type == _DiffType.removed
                          ? Colors.red.shade700
                          : diff.type == _DiffType.added
                          ? Colors.green.shade700
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Simple line-based diff using longest common subsequence.
  static List<_DiffLine> _computeDiff(
    List<String> oldLines,
    List<String> newLines,
  ) {
    // Build LCS table
    final m = oldLines.length;
    final n = newLines.length;
    final lcs = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (oldLines[i - 1] == newLines[j - 1]) {
          lcs[i][j] = lcs[i - 1][j - 1] + 1;
        } else {
          lcs[i][j] = lcs[i - 1][j] > lcs[i][j - 1]
              ? lcs[i - 1][j]
              : lcs[i][j - 1];
        }
      }
    }

    // Backtrack to build diff
    final result = <_DiffLine>[];
    var i = m;
    var j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && oldLines[i - 1] == newLines[j - 1]) {
        result.add(_DiffLine(oldLines[i - 1], _DiffType.unchanged));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j])) {
        result.add(_DiffLine(newLines[j - 1], _DiffType.added));
        j--;
      } else {
        result.add(_DiffLine(oldLines[i - 1], _DiffType.removed));
        i--;
      }
    }

    return result.reversed.toList();
  }
}

class _DiffLegendChip extends StatelessWidget {
  const _DiffLegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

enum _DiffType { removed, added, unchanged }

class _DiffLine {
  const _DiffLine(this.text, this.type);
  final String text;
  final _DiffType type;
}

class _S3StorageSection extends StatelessWidget {
  const _S3StorageSection({required this.config});

  final CaddyConfig config;

  @override
  Widget build(BuildContext context) {
    final s3 = config.storage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.caddyS3Storage,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(context.l10n.caddyS3Enabled),
                secondary: Icon(
                  Icons.cloud,
                  color: s3.enabled
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                value: s3.enabled,
                onChanged: (value) {
                  context.read<CaddyBloc>().add(
                    CaddyUpdateConfig(
                      config.copyWith(storage: s3.copyWith(enabled: value)),
                    ),
                  );
                },
              ),
              if (s3.enabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: context.l10n.caddyS3Endpoint,
                      hintText: 's3.amazonaws.com',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: s3.endpoint),
                    onChanged: (value) {
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          config.copyWith(
                            storage: s3.copyWith(endpoint: value),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: context.l10n.caddyS3Bucket,
                      hintText: 'my-caddy-storage',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: s3.bucket),
                    onChanged: (value) {
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          config.copyWith(storage: s3.copyWith(bucket: value)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: context.l10n.caddyS3Region,
                      hintText: 'us-east-1',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: s3.region),
                    onChanged: (value) {
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          config.copyWith(storage: s3.copyWith(region: value)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: context.l10n.caddyS3Prefix,
                      hintText: 'caddy/',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: s3.prefix),
                    onChanged: (value) {
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          config.copyWith(storage: s3.copyWith(prefix: value)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
