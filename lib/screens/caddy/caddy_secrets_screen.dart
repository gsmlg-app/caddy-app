import 'package:app_locale/app_locale.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaddySecretsScreen extends StatefulWidget {
  static const name = 'Caddy Secrets';
  static const path = 'secrets';

  const CaddySecretsScreen({super.key});

  @override
  State<CaddySecretsScreen> createState() => _CaddySecretsScreenState();
}

class _CaddySecretsScreenState extends State<CaddySecretsScreen> {
  static const _prefix = 'caddy_';

  late final VaultRepository _vault;
  Map<String, String> _secrets = {};
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vault = context.read<VaultRepository>();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    final all = await _vault.readAll();
    final caddySecrets = <String, String>{};
    for (final entry in all.entries) {
      if (entry.key.startsWith(_prefix)) {
        caddySecrets[entry.key.substring(_prefix.length)] = entry.value;
      }
    }
    if (mounted) {
      setState(() {
        _secrets = caddySecrets;
        _loading = false;
      });
    }
  }

  Future<void> _saveSecret(String key, String value) async {
    await _vault.write(key: '$_prefix$key', value: value);
    await _loadSecrets();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.caddySecretSaved)));
    }
  }

  Future<void> _deleteSecret(String key) async {
    await _vault.delete(key: '$_prefix$key');
    await _loadSecrets();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.caddySecretDeleted)));
    }
  }

  void _showAddEditDialog({String? existingKey, String? existingValue}) {
    final keyController = TextEditingController(text: existingKey ?? '');
    final valueController = TextEditingController(text: existingValue ?? '');
    final isEditing = existingKey != null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEditing
                ? dialogContext.l10n.caddyEditSecret
                : dialogContext.l10n.caddyAddSecret,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing)
                TextField(
                  controller: keyController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.caddySecretKey,
                    hintText: 'CF_API_TOKEN',
                    border: const OutlineInputBorder(),
                  ),
                ),
              if (!isEditing) const SizedBox(height: 12),
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    existingKey,
                    style: Theme.of(dialogContext).textTheme.titleMedium,
                  ),
                ),
              TextField(
                controller: valueController,
                autofocus: isEditing,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: dialogContext.l10n.caddySecretValue,
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
                final key = isEditing ? existingKey : keyController.text.trim();
                final value = valueController.text.trim();
                if (key.isEmpty || value.isEmpty) return;
                _saveSecret(key, value);
                Navigator.of(dialogContext).pop();
              },
              child: Text(dialogContext.l10n.caddySave),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String key) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.caddyDeleteSecret),
          content: Text(dialogContext.l10n.caddySecretDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () {
                _deleteSecret(key);
                Navigator.of(dialogContext).pop();
              },
              child: Text(dialogContext.l10n.caddyDeleteSecret),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.caddySecretsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.l10n.caddyAddSecret,
            onPressed: _showAddEditDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _secrets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.key_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.caddyNoSecrets,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _showAddEditDialog,
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.caddyAddSecret),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  context.l10n.caddySecretsDesc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ..._secrets.entries.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.key),
                      title: Text(entry.key),
                      subtitle: const Text(
                        '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: context.l10n.caddyEditSecret,
                            onPressed: () => _showAddEditDialog(
                              existingKey: entry.key,
                              existingValue: entry.value,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: context.l10n.caddyDeleteSecret,
                            onPressed: () => _showDeleteConfirmation(entry.key),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Quick Add',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickAddChip(
                      label: context.l10n.caddySecretCfToken,
                      keyName: 'CF_API_TOKEN',
                      onTap: (key) => _showAddEditDialog(existingKey: key),
                      exists: _secrets.containsKey('CF_API_TOKEN'),
                    ),
                    _QuickAddChip(
                      label: context.l10n.caddySecretRoute53Key,
                      keyName: 'AWS_ACCESS_KEY_ID',
                      onTap: (key) => _showAddEditDialog(existingKey: key),
                      exists: _secrets.containsKey('AWS_ACCESS_KEY_ID'),
                    ),
                    _QuickAddChip(
                      label: context.l10n.caddySecretRoute53Secret,
                      keyName: 'AWS_SECRET_ACCESS_KEY',
                      onTap: (key) => _showAddEditDialog(existingKey: key),
                      exists: _secrets.containsKey('AWS_SECRET_ACCESS_KEY'),
                    ),
                    _QuickAddChip(
                      label: context.l10n.caddySecretDuckdnsToken,
                      keyName: 'DUCKDNS_TOKEN',
                      onTap: (key) => _showAddEditDialog(existingKey: key),
                      exists: _secrets.containsKey('DUCKDNS_TOKEN'),
                    ),
                    _QuickAddChip(
                      label: context.l10n.caddySecretS3AccessKey,
                      keyName: 'S3_ACCESS_KEY',
                      onTap: (key) => _showAddEditDialog(existingKey: key),
                      exists: _secrets.containsKey('S3_ACCESS_KEY'),
                    ),
                    _QuickAddChip(
                      label: context.l10n.caddySecretS3SecretKey,
                      keyName: 'S3_SECRET_KEY',
                      onTap: (key) => _showAddEditDialog(existingKey: key),
                      exists: _secrets.containsKey('S3_SECRET_KEY'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  const _QuickAddChip({
    required this.label,
    required this.keyName,
    required this.onTap,
    required this.exists,
  });

  final String label;
  final String keyName;
  final void Function(String key) onTap;
  final bool exists;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        exists ? Icons.check_circle : Icons.add_circle_outline,
        size: 18,
      ),
      label: Text(label),
      onPressed: () => onTap(keyName),
    );
  }
}
