import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaddyLogScreen extends StatefulWidget {
  static const name = 'Caddy Logs';
  static const path = 'logs';

  const CaddyLogScreen({super.key});

  @override
  State<CaddyLogScreen> createState() => _CaddyLogScreenState();
}

class _CaddyLogScreenState extends State<CaddyLogScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.caddyLogs),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.lock : Icons.lock_open),
            tooltip: 'Auto-scroll',
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy logs',
            onPressed: () {
              final logs = context.read<CaddyBloc>().state.logs.join('\n');
              Clipboard.setData(ClipboardData(text: logs));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copied to clipboard')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear logs',
            onPressed: () {
              context.read<CaddyBloc>().add(const CaddyClearLogs());
            },
          ),
        ],
      ),
      body: BlocConsumer<CaddyBloc, CaddyState>(
        listenWhen: (prev, curr) =>
            prev.logs.length != curr.logs.length && _autoScroll,
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        },
        builder: (context, state) {
          if (state.logs.isEmpty) {
            return Center(
              child: Text(
                context.l10n.caddyNoLogs,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: state.logs.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return Text(
                state.logs[index],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              );
            },
          );
        },
      ),
    );
  }
}
