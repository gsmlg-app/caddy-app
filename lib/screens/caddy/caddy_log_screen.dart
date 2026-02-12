import 'dart:io';

import 'package:app_locale/app_locale.dart';
import 'package:app_logging/app_logging.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

class CaddyLogScreen extends StatefulWidget {
  static const name = 'Caddy Logs';
  static const path = 'logs';

  const CaddyLogScreen({super.key});

  @override
  State<CaddyLogScreen> createState() => _CaddyLogScreenState();
}

class _CaddyLogScreenState extends State<CaddyLogScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _autoScroll = true;
  bool _showSearch = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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

  Color? _logLineColor(String line) {
    final upper = line.toUpperCase();
    if (upper.contains('ERROR') || upper.contains('"level":"error"')) {
      return Colors.red;
    }
    if (upper.contains('WARN') || upper.contains('"level":"warn"')) {
      return Colors.orange;
    }
    if (upper.contains('DEBUG') || upper.contains('"level":"debug"')) {
      return Colors.grey;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.caddyLogs),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            tooltip: context.l10n.caddyLogSearch,
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<CaddyBloc>().add(const CaddySetLogSearch(''));
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_autoScroll ? Icons.lock : Icons.lock_open),
            tooltip: context.l10n.caddyAutoScrollToggle,
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: context.l10n.caddyCopyLogs,
            onPressed: () {
              final logs = context.read<CaddyBloc>().state.filteredLogs.join(
                '\n',
              );
              Clipboard.setData(ClipboardData(text: logs));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.caddyLogsCopied)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: context.l10n.caddyExportLogs,
            onPressed: () async {
              final logs = context.read<CaddyBloc>().state.filteredLogs.join(
                '\n',
              );
              if (logs.isEmpty) return;
              try {
                final dir = await getApplicationDocumentsDirectory();
                final timestamp = DateTime.now()
                    .toIso8601String()
                    .replaceAll(':', '-')
                    .split('.')
                    .first;
                final file = File('${dir.path}/caddy-logs-$timestamp.txt');
                await file.writeAsString(logs);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.caddyLogsSaved(file.path)),
                    ),
                  );
                }
              } catch (e, stackTrace) {
                AppLogger().e('Failed to export logs', e, stackTrace);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.caddyLogsExportFailed)),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: context.l10n.caddyClearLogs,
            onPressed: () {
              context.read<CaddyBloc>().add(const CaddyClearLogs());
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showSearch ? 100 : 48),
          child: Column(
            children: [
              _LogLevelFilter(),
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.l10n.caddyLogSearch,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (query) {
                      context.read<CaddyBloc>().add(CaddySetLogSearch(query));
                    },
                  ),
                ),
            ],
          ),
        ),
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
          final logs = state.filteredLogs;

          if (logs.isEmpty) {
            return Center(
              child: Text(
                context.l10n.caddyNoLogs,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }

          return Column(
            children: [
              if (state.logs.length != logs.length ||
                  state.logSearchQuery.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Text(
                        '${logs.length} / ${state.logs.length} lines',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      if (state.logFilter != CaddyLogLevel.all)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(state.logFilter.name.toUpperCase()),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      if (state.logSearchQuery.isNotEmpty)
                        Chip(
                          label: Text('"${state.logSearchQuery}"'),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                          onDeleted: () {
                            _searchController.clear();
                            context.read<CaddyBloc>().add(
                              const CaddySetLogSearch(''),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: logs.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final line = logs[index];
                    final color = _logLineColor(line);
                    final searchQuery = state.logSearchQuery;
                    Widget lineWidget;
                    if (searchQuery.isNotEmpty) {
                      lineWidget = _HighlightedLogLine(
                        line: line,
                        query: searchQuery,
                        color: color,
                      );
                    } else {
                      lineWidget = Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: color,
                        ),
                      );
                    }
                    return GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: line));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.caddyLogLineCopied),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: lineWidget,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HighlightedLogLine extends StatelessWidget {
  const _HighlightedLogLine({
    required this.line,
    required this.query,
    this.color,
  });

  final String line;
  final String query;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: color,
    );
    final highlightStyle = style.copyWith(
      backgroundColor: Colors.yellow.withValues(alpha: 0.4),
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.bold,
    );

    final lowerLine = line.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (start < line.length) {
      final matchIndex = lowerLine.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: line.substring(start), style: style));
        break;
      }
      if (matchIndex > start) {
        spans.add(
          TextSpan(text: line.substring(start, matchIndex), style: style),
        );
      }
      spans.add(
        TextSpan(
          text: line.substring(matchIndex, matchIndex + query.length),
          style: highlightStyle,
        ),
      );
      start = matchIndex + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _LogLevelFilter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CaddyBloc, CaddyState>(
      buildWhen: (prev, curr) => prev.logFilter != curr.logFilter,
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: CaddyLogLevel.values.map((level) {
              final label = switch (level) {
                CaddyLogLevel.all => context.l10n.caddyLogLevelAll,
                CaddyLogLevel.debug => context.l10n.caddyLogLevelDebug,
                CaddyLogLevel.info => context.l10n.caddyLogLevelInfo,
                CaddyLogLevel.warn => context.l10n.caddyLogLevelWarn,
                CaddyLogLevel.error => context.l10n.caddyLogLevelError,
              };
              final selected = state.logFilter == level;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) {
                    context.read<CaddyBloc>().add(CaddySetLogFilter(level));
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
