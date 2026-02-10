import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    _saveConfig();
    final bloc = context.read<CaddyBloc>();
    if (bloc.state.isRunning) {
      bloc.add(CaddyReload(bloc.state.config));
    }
  }

  void _loadPreset(CaddyConfig preset) {
    _listenController.text = preset.listenAddress;
    _rawJsonController.text = preset.rawJson ?? preset.toJsonString();
    context.read<CaddyBloc>().add(CaddyUpdateConfig(preset));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
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
                  onPressed: () => _showAddRouteDialog(context),
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
            ...state.config.routes.asMap().entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(entry.value.path),
                  subtitle: Text(switch (entry.value.handler) {
                    StaticFileHandler(root: final root) =>
                      'Static Files: $root',
                    ReverseProxyHandler(upstreams: final upstreams) =>
                      'Reverse Proxy: ${upstreams.join(', ')}',
                  }),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      final routes = [...state.config.routes]
                        ..removeAt(entry.key);
                      context.read<CaddyBloc>().add(
                        CaddyUpdateConfig(
                          state.config.copyWith(routes: routes),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddRouteDialog(BuildContext context) {
    final pathController = TextEditingController(text: '/*');
    final valueController = TextEditingController();
    var isStaticFile = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(dialogContext.l10n.caddyAddRoute),
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
                    final bloc = dialogContext.read<CaddyBloc>();
                    final handler = isStaticFile
                        ? StaticFileHandler(root: valueController.text)
                        : ReverseProxyHandler(upstreams: [valueController.text])
                              as CaddyHandler;
                    final route = CaddyRoute(
                      path: pathController.text,
                      handler: handler,
                    );
                    final routes = [...bloc.state.config.routes, route];
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

class _RawJsonEditor extends StatelessWidget {
  const _RawJsonEditor({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
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
