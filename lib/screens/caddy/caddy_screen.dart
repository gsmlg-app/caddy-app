import 'dart:async';

import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:caddy_app/destination.dart';
import 'package:caddy_app/screens/caddy/caddy_config_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_log_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_secrets_screen.dart';

class CaddyScreen extends StatelessWidget {
  static const name = 'Caddy';
  static const path = '/caddy';

  const CaddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        title: Text(context.l10n.caddyTitle),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: (context) => SafeArea(
        child: BlocBuilder<CaddyBloc, CaddyState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusCard(state: state),
                  const SizedBox(height: 16),
                  _ActionButtons(state: state),
                  if (state.isRunning) ...[
                    const SizedBox(height: 16),
                    _MetricsCard(state: state),
                  ],
                  const SizedBox(height: 16),
                  _ConfigSummary(state: state),
                  const SizedBox(height: 16),
                  _AdminApiCard(state: state),
                  const SizedBox(height: 16),
                  _NavigationLinks(state: state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusCard extends StatefulWidget {
  const _StatusCard({required this.state});

  final CaddyState state;

  @override
  State<_StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<_StatusCard> {
  Timer? _uptimeTimer;

  @override
  void initState() {
    super.initState();
    _startTimerIfRunning();
  }

  @override
  void didUpdateWidget(_StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isRunning != widget.state.isRunning) {
      _startTimerIfRunning();
    }
  }

  void _startTimerIfRunning() {
    _uptimeTimer?.cancel();
    if (widget.state.isRunning) {
      _uptimeTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {}),
      );
    }
  }

  @override
  void dispose() {
    _uptimeTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final (color, icon, label) = switch (state.status) {
      CaddyRunning() => (
        Colors.green,
        Icons.check_circle,
        context.l10n.caddyRunning,
      ),
      CaddyStopped() => (
        Colors.red,
        Icons.stop_circle,
        context.l10n.caddyStopped,
      ),
      CaddyError(message: final msg) => (
        Colors.amber,
        Icons.error,
        '${context.l10n.caddyError}: $msg',
      ),
      CaddyLoading() => (
        Colors.blue,
        Icons.hourglass_top,
        context.l10n.loading,
      ),
    };

    final startedAt = state.startedAt;
    final uptime = startedAt != null
        ? DateTime.now().difference(startedAt)
        : null;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: color),
                  ),
                  if (state.isRunning)
                    Text(
                      context.l10n.caddyListenAddress(
                        state.config.listenAddress,
                      ),
                    ),
                  if (uptime != null)
                    Text(
                      context.l10n.caddyUptime(_formatDuration(uptime)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CaddyBloc>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.isStopped || state.hasError)
          FilledButton.icon(
            onPressed: () => bloc.add(CaddyStart(state.config)),
            icon: const Icon(Icons.play_arrow),
            label: Text(context.l10n.caddyStart),
          ),
        if (state.isRunning) ...[
          FilledButton.icon(
            onPressed: () => bloc.add(const CaddyStop()),
            icon: const Icon(Icons.stop),
            label: Text(context.l10n.caddyStop),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => bloc.add(CaddyReload(state.config)),
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.caddyReload),
          ),
        ],
        if (state.isLoading) const CircularProgressIndicator(),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.caddyMetrics,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.http,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(context.l10n.caddyRequestsServed),
                const Spacer(),
                Text(
                  context.l10n.caddyRequestCount(state.requestCount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigSummary extends StatelessWidget {
  const _ConfigSummary({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.caddyConfig,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${context.l10n.caddyListenAddress('')}${state.config.listenAddress}',
            ),
            Text('Routes: ${state.config.routes.length}'),
          ],
        ),
      ),
    );
  }
}

class _AdminApiCard extends StatelessWidget {
  const _AdminApiCard({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(context.l10n.caddyAdminApi),
        subtitle: Text(
          state.adminEnabled
              ? context.l10n.caddyAdminApiEnabled('localhost:2019')
              : context.l10n.caddyAdminApiDisabled,
        ),
        secondary: Icon(
          Icons.admin_panel_settings,
          color: state.adminEnabled
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        value: state.adminEnabled,
        onChanged: (_) {
          context.read<CaddyBloc>().add(const CaddyToggleAdmin());
        },
      ),
    );
  }
}

class _NavigationLinks extends StatelessWidget {
  const _NavigationLinks({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(context.l10n.caddyConfig),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(CaddyConfigScreen.name),
        ),
        ListTile(
          leading: const Icon(Icons.article),
          title: Text(context.l10n.caddyLogs),
          trailing: Badge(
            label: Text('${state.logs.length}'),
            child: const Icon(Icons.chevron_right),
          ),
          onTap: () => context.goNamed(CaddyLogScreen.name),
        ),
        ListTile(
          leading: const Icon(Icons.key),
          title: Text(context.l10n.caddySecrets),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(CaddySecretsScreen.name),
        ),
      ],
    );
  }
}
