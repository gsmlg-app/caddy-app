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

class _CaddyConfigScreenState extends State<CaddyConfigScreen> {
  late final TextEditingController _textController;
  late ConfigFormat _format;

  @override
  void initState() {
    super.initState();
    final config = context.read<CaddyBloc>().state.config;
    _textController = TextEditingController(text: config.text);
    _format = config.format;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  CaddyTextConfig _buildConfig() {
    return CaddyTextConfig(text: _textController.text, format: _format);
  }

  void _syncFromBloc(CaddyTextConfig config) {
    _textController.text = config.text;
    setState(() => _format = config.format);
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
    CaddyTextConfig currentConfig,
    CaddyTextConfig newConfig,
  ) {
    final currentText = currentConfig.text;
    final newText = newConfig.text;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.caddyConfigDiffTitle),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: currentText == newText
                ? Center(
                    child: Text(
                      dialogContext.l10n.caddyConfigDiffNoChanges,
                      style: Theme.of(dialogContext).textTheme.bodyLarge,
                    ),
                  )
                : _ConfigDiffView(
                    currentText: currentText,
                    newText: newText,
                    currentLabel: dialogContext.l10n.caddyConfigDiffCurrent,
                    newLabel: dialogContext.l10n.caddyConfigDiffNew,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.cancel),
            ),
            if (currentText != newText)
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

  void _loadPreset(CaddyTextConfig preset) {
    _syncFromBloc(preset);
    context.read<CaddyBloc>().add(CaddyUpdateConfig(preset));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.success)));
  }

  void _copyConfig() {
    Clipboard.setData(ClipboardData(text: _textController.text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.caddyConfigCopied)));
  }

  Future<void> _exportConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final ext = _format == ConfigFormat.caddyfile ? 'Caddyfile' : 'json';
      final file = File('${dir.path}/caddy-config-$timestamp.$ext');
      await file.writeAsString(_textController.text);
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

    // Detect format: if it parses as JSON, treat as JSON; otherwise Caddyfile
    ConfigFormat detectedFormat;
    try {
      jsonDecode(text);
      detectedFormat = ConfigFormat.json;
    } on FormatException {
      detectedFormat = ConfigFormat.caddyfile;
    }

    final config = CaddyTextConfig(text: text, format: detectedFormat);
    if (!mounted) return;
    _syncFromBloc(config);
    context.read<CaddyBloc>().add(CaddyUpdateConfig(config));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.caddyConfigImported)));
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

  Future<void> _switchFormat(ConfigFormat newFormat) async {
    if (newFormat == _format) return;

    if (_format == ConfigFormat.caddyfile && newFormat == ConfigFormat.json) {
      // Convert Caddyfile → JSON via Go bridge
      final service = CaddyService.instance;
      final result = await service.adaptCaddyfile(_textController.text);

      // Check for adapter error
      try {
        final parsed = jsonDecode(result) as Map<String, dynamic>;
        if (parsed.containsKey('error')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Adapt error: ${parsed['error']}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
        // Format the JSON nicely
        _textController.text = const JsonEncoder.withIndent(
          '  ',
        ).convert(parsed);
      } on FormatException {
        // Result is raw JSON, use as-is
        _textController.text = result;
      }

      setState(() => _format = newFormat);
    } else if (_format == ConfigFormat.json &&
        newFormat == ConfigFormat.caddyfile) {
      // JSON → Caddyfile is not supported by Caddy
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Converting JSON to Caddyfile is not supported. '
              'Please rewrite the config in Caddyfile format manually.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CaddyBloc, CaddyState>(
      listenWhen: (prev, curr) =>
          prev.activeConfigName != curr.activeConfigName,
      listener: (context, state) {
        if (state.activeConfigName != null) {
          _syncFromBloc(state.config);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Config'),
          actions: [
            // Format toggle
            SegmentedButton<ConfigFormat>(
              segments: const [
                ButtonSegment(
                  value: ConfigFormat.caddyfile,
                  label: Text('Caddyfile'),
                ),
                ButtonSegment(
                  value: ConfigFormat.json,
                  label: Text('JSON'),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (selected) {
                _switchFormat(selected.first);
              },
            ),
            const SizedBox(width: 8),
            // Presets
            PopupMenuButton<CaddyTextConfig>(
              icon: const Icon(Icons.auto_awesome),
              tooltip: context.l10n.caddyConfigPresets,
              onSelected: _loadPreset,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: CaddyConfigPresets.staticFileServer(),
                  child: Text(context.l10n.caddyPresetStaticFile),
                ),
                PopupMenuItem(
                  value: CaddyConfigPresets.reverseProxy(),
                  child: Text(context.l10n.caddyPresetReverseProxy),
                ),
                PopupMenuItem(
                  value: CaddyConfigPresets.spaServer(),
                  child: Text(context.l10n.caddyPresetSpa),
                ),
                PopupMenuItem(
                  value: CaddyConfigPresets.apiGateway(),
                  child: Text(context.l10n.caddyPresetApiGateway),
                ),
                PopupMenuItem(
                  value: CaddyConfigPresets.httpsWithDns(),
                  child: Text(context.l10n.caddyPresetHttpsDns),
                ),
                PopupMenuItem(
                  value: CaddyConfigPresets.httpsWithS3(),
                  child: Text(context.l10n.caddyPresetS3Full),
                ),
              ],
            ),
            // Validate
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: context.l10n.caddyValidate,
              onPressed: _validateConfig,
            ),
            // Save
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: context.l10n.caddySave,
              onPressed: _saveConfig,
            ),
            // Save As
            IconButton(
              icon: const Icon(Icons.save_as),
              tooltip: context.l10n.caddySaveConfigAs,
              onPressed: _showSaveAsDialog,
            ),
            // Copy
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: context.l10n.caddyConfigCopy,
              onPressed: _copyConfig,
            ),
            // Export
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: context.l10n.caddyConfigExport,
              onPressed: _exportConfig,
            ),
            // Import
            IconButton(
              icon: const Icon(Icons.file_upload),
              tooltip: context.l10n.caddyConfigImport,
              onPressed: _importConfig,
            ),
            // Saved configs
            BlocBuilder<CaddyBloc, CaddyState>(
              buildWhen: (prev, curr) =>
                  prev.savedConfigNames != curr.savedConfigNames ||
                  prev.activeConfigName != curr.activeConfigName,
              builder: (context, state) {
                if (state.savedConfigNames.isEmpty) {
                  return const SizedBox.shrink();
                }
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.bookmark),
                  tooltip: context.l10n.caddySavedConfigs,
                  itemBuilder: (context) {
                    return state.savedConfigNames.map((name) {
                      return PopupMenuItem(
                        value: name,
                        child: Row(
                          children: [
                            if (name == state.activeConfigName)
                              const Icon(Icons.check, size: 18),
                            if (name == state.activeConfigName)
                              const SizedBox(width: 8),
                            Expanded(child: Text(name)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () {
                                Navigator.of(context).pop();
                                context
                                    .read<CaddyBloc>()
                                    .add(CaddyDeleteSavedConfig(name));
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  onSelected: (name) {
                    context.read<CaddyBloc>().add(CaddyLoadNamedConfig(name));
                  },
                );
              },
            ),
            // Apply
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: context.l10n.caddyApply,
              onPressed: _applyConfig,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _textController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _format == ConfigFormat.caddyfile
                  ? ':8080\n\nreverse_proxy localhost:3000'
                  : '{"apps": {"http": {"servers": {}}}}',
              alignLabelWithHint: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Side-by-side diff view comparing two config texts.
class _ConfigDiffView extends StatelessWidget {
  const _ConfigDiffView({
    required this.currentText,
    required this.newText,
    required this.currentLabel,
    required this.newLabel,
  });

  final String currentText;
  final String newText;
  final String currentLabel;
  final String newLabel;

  @override
  Widget build(BuildContext context) {
    final currentLines = currentText.split('\n');
    final newLines = newText.split('\n');
    final maxLines =
        currentLines.length > newLines.length
            ? currentLines.length
            : newLines.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                currentLabel,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                newLabel,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: maxLines,
            itemBuilder: (context, index) {
              final oldLine =
                  index < currentLines.length ? currentLines[index] : '';
              final newLine =
                  index < newLines.length ? newLines[index] : '';
              final changed = oldLine != newLine;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      color: changed
                          ? Colors.red.withValues(alpha: 0.15)
                          : null,
                      child: Text(
                        oldLine,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      color: changed
                          ? Colors.green.withValues(alpha: 0.15)
                          : null,
                      child: Text(
                        newLine,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
