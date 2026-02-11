import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_artwork/app_artwork.dart';
import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:caddy_app/destination.dart';
import 'package:caddy_app/screens/caddy/caddy_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_config_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_log_screen.dart';
import 'package:caddy_app/screens/caddy/caddy_secrets_screen.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'Home Screen';
  static const path = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(const Key(HomeScreen.name), context),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      appBar: AppBar(
        title: Text(context.l10n.appName),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome header with Lottie animation
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Center(
                    child: LaddingPageLottie(width: 80, height: 80),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.l10n.welcomeHome,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 24),

            // Server status card
            const _ServerStatusCard(),

            const SizedBox(height: 16),

            // Quick actions grid
            Text(
              context.l10n.homeQuickActions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _QuickActionsGrid(),
          ],
        ),
      ),
    );
  }
}

class _ServerStatusCard extends StatelessWidget {
  const _ServerStatusCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaddyBloc, CaddyState>(
      builder: (context, state) {
        final isRunning = state.status is CaddyRunning;
        final isStopped = state.status is CaddyStopped;
        final isError = state.status is CaddyError;

        final (statusText, statusColor) = switch (state.status) {
          CaddyRunning() => (context.l10n.caddyRunning, Colors.green),
          CaddyError() => (
            context.l10n.caddyError,
            Theme.of(context).colorScheme.error,
          ),
          CaddyLoading() => (context.l10n.loading, Colors.blue),
          CaddyStopped() => (context.l10n.caddyStopped, Colors.grey),
        };

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dns, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.homeServerStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Chip(
                      label: Text(statusText),
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      side: BorderSide(color: statusColor),
                    ),
                  ],
                ),
                if (isRunning) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.caddyListenAddress(state.config.listenAddress),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${state.config.routes.length} ${context.l10n.caddyActiveRoutes.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (isStopped) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<CaddyBloc>().add(CaddyStart(state.config));
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(context.l10n.caddyStart),
                  ),
                ],
                if (isError) ...[
                  const SizedBox(height: 8),
                  Text(
                    (state.status as CaddyError).message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: [
        _QuickActionCard(
          icon: Icons.dns,
          label: context.l10n.homeGoToServer,
          onTap: () => context.goNamed(CaddyScreen.name),
        ),
        _QuickActionCard(
          icon: Icons.settings_applications,
          label: context.l10n.homeGoToConfig,
          onTap: () => context.goNamed(CaddyConfigScreen.name),
        ),
        _QuickActionCard(
          icon: Icons.article,
          label: context.l10n.homeGoToLogs,
          onTap: () => context.goNamed(CaddyLogScreen.name),
        ),
        _QuickActionCard(
          icon: Icons.vpn_key,
          label: context.l10n.homeGoToSecrets,
          onTap: () => context.goNamed(CaddySecretsScreen.name),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
