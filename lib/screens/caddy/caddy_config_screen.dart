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

  void _saveConfig() {
    final bloc = context.read<CaddyBloc>();
    final CaddyConfig config;

    if (_tabController.index == 0) {
      config = CaddyConfig(
        listenAddress: _listenController.text,
        routes: bloc.state.config.routes,
      );
    } else {
      config = CaddyConfig(rawJson: _rawJsonController.text);
    }

    bloc.add(CaddyUpdateConfig(config));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          TextButton(
            onPressed: _saveConfig,
            child: Text(context.l10n.caddySave),
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
            Text(
              'Routes (${state.config.routes.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (state.config.routes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No routes configured'),
                ),
              ),
            ...state.config.routes.map(
              (route) => Card(
                child: ListTile(
                  title: Text(route.path),
                  subtitle: Text(switch (route.handler) {
                    StaticFileHandler(root: final root) =>
                      'Static Files: $root',
                    ReverseProxyHandler(upstreams: final upstreams) =>
                      'Reverse Proxy: ${upstreams.join(', ')}',
                  }),
                ),
              ),
            ),
          ],
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
