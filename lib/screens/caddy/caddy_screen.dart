import 'dart:async';

import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        child: BlocConsumer<CaddyBloc, CaddyState>(
          listenWhen: (prev, curr) => !prev.hasError && curr.hasError,
          listener: (context, state) {
            if (state.status case CaddyError(message: final msg)) {
              _showErrorRecoveryDialog(context, msg, state);
            }
          },
          builder: (context, state) {
            final bloc = context.read<CaddyBloc>();
            return CallbackShortcuts(
              bindings: {
                const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  control: true,
                ): () {
                  if (state.isStopped || state.hasError) {
                    bloc.add(CaddyStart(state.config));
                  }
                },
                const SingleActivator(
                  LogicalKeyboardKey.keyQ,
                  control: true,
                ): () {
                  if (state.isRunning) {
                    bloc.add(const CaddyStop());
                  }
                },
                const SingleActivator(
                  LogicalKeyboardKey.keyR,
                  control: true,
                ): () {
                  if (state.isRunning) {
                    bloc.add(CaddyReload(state.config));
                  }
                },
              },
              child: Focus(
                autofocus: true,
                child: SingleChildScrollView(
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
                      _AutoRestartCard(state: state),
                      const SizedBox(height: 16),
                      _NavigationLinks(state: state),
                      const SizedBox(height: 8),
                      _KeyboardShortcutsHint(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void _showErrorRecoveryDialog(
  BuildContext context,
  String errorMessage,
  CaddyState state,
) {
  final isPortInUse =
      errorMessage.contains('already in use') || errorMessage.contains('bind:');

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Icon(
          isPortInUse ? Icons.portable_wifi_off : Icons.error_outline,
          color: Theme.of(dialogContext).colorScheme.error,
          size: 48,
        ),
        title: Text(dialogContext.l10n.caddyErrorRecoveryTitle),
        content: Text(
          isPortInUse
              ? dialogContext.l10n.caddyErrorPortInUse
              : dialogContext.l10n.caddyErrorGeneric,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.caddyErrorDismiss),
          ),
          if (isPortInUse)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.goNamed(CaddyConfigScreen.name);
              },
              icon: const Icon(Icons.edit),
              label: Text(dialogContext.l10n.caddyErrorChangePort),
            ),
          if (!isPortInUse)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.goNamed(CaddyLogScreen.name);
              },
              icon: const Icon(Icons.article),
              label: Text(dialogContext.l10n.caddyErrorViewLogs),
            ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CaddyBloc>().add(CaddyStart(state.config));
            },
            icon: const Icon(Icons.refresh),
            label: Text(dialogContext.l10n.caddyErrorRetry),
          ),
        ],
      );
    },
  );
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

    final semanticLabel = [
      label,
      if (state.isRunning)
        context.l10n.caddyListenAddress(state.config.listenAddress),
      if (uptime != null) context.l10n.caddyUptime(_formatDuration(uptime)),
    ].join('. ');

    return Semantics(
      label: semanticLabel,
      child: Card(
        color: color.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: color, size: 40)),
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

  int get _errorLogCount =>
      state.logs.where((l) => l.toUpperCase().contains('ERROR')).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;

    return Semantics(
      label:
          '${context.l10n.caddyMetrics}. ${context.l10n.caddyRequestsServed}: ${state.requestCount}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.caddyMetrics,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                icon: Icons.http,
                iconColor: primary,
                label: context.l10n.caddyRequestsServed,
                value: context.l10n.caddyRequestCount(state.requestCount),
                valueColor: primary,
              ),
              const SizedBox(height: 8),
              _MetricRow(
                icon: Icons.alt_route,
                iconColor: primary,
                label: context.l10n.caddyActiveRoutes,
                value: context.l10n.caddyRouteCount(state.config.routes.length),
                valueColor: primary,
              ),
              const SizedBox(height: 8),
              _MetricRow(
                icon: Icons.error_outline,
                iconColor: _errorLogCount > 0 ? errorColor : primary,
                label: context.l10n.caddyLogErrors,
                value: context.l10n.caddyErrorCount(_errorLogCount),
                valueColor: _errorLogCount > 0 ? errorColor : primary,
              ),
              const SizedBox(height: 8),
              _MetricRow(
                icon: Icons.admin_panel_settings,
                iconColor: primary,
                label: context.l10n.caddyAdminApiStatus,
                value: state.adminEnabled
                    ? context.l10n.caddyEnabled
                    : context.l10n.caddyDisabled,
                valueColor: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _ConfigSummary extends StatelessWidget {
  const _ConfigSummary({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    final semanticLabel =
        '${context.l10n.caddyConfig}. '
        '${context.l10n.caddyListenAddress(state.config.listenAddress)}. '
        'Routes: ${state.config.routes.length}';

    return Semantics(
      label: semanticLabel,
      child: Card(
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

class _AutoRestartCard extends StatelessWidget {
  const _AutoRestartCard({required this.state});

  final CaddyState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(context.l10n.caddyAutoRestart),
        subtitle: Text(
          state.autoRestartOnResume
              ? context.l10n.caddyAutoRestartEnabled
              : context.l10n.caddyAutoRestartDisabled,
        ),
        secondary: Icon(
          Icons.restart_alt,
          color: state.autoRestartOnResume
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        value: state.autoRestartOnResume,
        onChanged: (_) {
          context.read<CaddyBloc>().add(const CaddyToggleAutoRestart());
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

class _KeyboardShortcutsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.caddyShortcutsTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _ShortcutChip(
                  shortcut: 'Ctrl+S',
                  label: context.l10n.caddyShortcutStart,
                ),
                _ShortcutChip(
                  shortcut: 'Ctrl+Q',
                  label: context.l10n.caddyShortcutStop,
                ),
                _ShortcutChip(
                  shortcut: 'Ctrl+R',
                  label: context.l10n.caddyShortcutReload,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.shortcut, required this.label});

  final String shortcut;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            shortcut,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
