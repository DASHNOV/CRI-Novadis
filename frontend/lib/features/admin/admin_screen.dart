import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/services/user_api_service.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';

const String _appVersion = '1.0.0';

class AdminScreen extends HookConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final storage = ref.watch(storageServiceProvider);
    final role = ref.watch(userRoleProvider);
    final nameFuture = useMemoized(() => storage.getUserName(), [storage]);
    final nameSnap = useFuture(nameFuture);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    Future<void> handleLogout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(storageServiceProvider).clearTokens();
        if (context.mounted) {
          context.go(AppRouter.login);
        }
      }
    }

    void showAbout() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text('À propos'),
          content: const Text(
            'Novadis CRI v$_appVersion\n\n'
            'Application de gestion des comptes rendus d\'intervention.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ContentContainer(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.space20),
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Compte, apparence et préférences',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _AccountCard(
              name: nameSnap.data ?? 'Utilisateur',
              role: UserRole.fromString(role)?.label ?? role ?? '',
            ),
            const SizedBox(height: AppTheme.space24),

            // La signature enregistrée sert à signer ses propres CRI : inutile
            // sans droit de création (superviseur).
            if (ref.watch(permissionsProvider).hasPermission(Permission.criCreate)) ...[
              const _SectionLabel('Signature'),
              const SizedBox(height: AppTheme.space12),
              const _SavedSignatureSection(),
              const SizedBox(height: AppTheme.space24),
            ],

            const _SectionLabel('Apparence'),
            const SizedBox(height: AppTheme.space12),
            _SettingsGroup(
              children: [
                _ThemeToggleTile(
                  isDark: isDark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setMode(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space24),

            const _SectionLabel('Application'),
            const SizedBox(height: AppTheme.space12),
            _SettingsGroup(
              children: [
                _ActionListTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppTheme.primaryContent,
                  title: 'À propos',
                  subtitle: 'Version $_appVersion',
                  onTap: showAbout,
                ),
                _Divider(),
                _ActionListTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.error,
                  title: 'Se déconnecter',
                  subtitle: 'Fermer la session sur cet appareil',
                  destructive: true,
                  onTap: handleLogout,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space32),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final String role;

  const _AccountCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final displayRole = role.isEmpty ? '—' : role;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryContent,
                  AppTheme.primaryContent.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    displayRole,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryContent,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textTertiary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppTheme.space16,
      endIndent: AppTheme.space16,
      color: AppTheme.border.withValues(alpha: 0.5),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ThemeToggleTile({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final icon = isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded;
    final color = isDark ? AppTheme.accent : AppTheme.warning;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode sombre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Activé' : 'Désactivé',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primaryContent,
          ),
        ],
      ),
    );
  }
}

class _SavedSignatureSection extends ConsumerWidget {
  const _SavedSignatureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sigAsync = ref.watch(savedSignatureProvider);

    return _SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ma signature',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  sigAsync.when(
                    data: (sig) => TextButton.icon(
                      onPressed: () => _showSignatureDialog(context, ref, sig),
                      icon: Icon(sig != null ? Icons.edit : Icons.add, size: 16),
                      label: Text(sig != null ? 'Modifier' : 'Ajouter'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => TextButton.icon(
                      onPressed: () => _showSignatureDialog(context, ref, null),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space8),
              sigAsync.when(
                data: (sig) => sig != null
                    ? _buildPreview(sig)
                    : _buildEmpty(),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => _buildEmpty(),
              ),
              if (sigAsync.valueOrNull != null) ...[
                const SizedBox(height: AppTheme.space8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Supprimer la signature'),
                          content: const Text(
                              'Voulez-vous vraiment supprimer votre signature enregistrée ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.error),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(savedSignatureProvider.notifier)
                            .setSignature(null);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Signature supprimée')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(String base64) {
    try {
      final bytes = base64Decode(base64);
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd - 1),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      );
    } catch (_) {
      return _buildEmpty();
    }
  }

  Widget _buildEmpty() {
    return Container(
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          'Aucune signature enregistrée',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _showSignatureDialog(BuildContext context, WidgetRef ref, String? current) {
    final controller = SignatureController(
      penStrokeWidth: 3.0,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        controller: controller,
        onSave: (base64) async {
          await ref.read(savedSignatureProvider.notifier).setSignature(base64);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signature enregistrée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    ).whenComplete(() => controller.dispose());
  }
}

enum _SignatureMode { draw, import }

class _SignatureDialog extends StatefulWidget {
  final SignatureController controller;
  final Future<void> Function(String base64) onSave;

  const _SignatureDialog({required this.controller, required this.onSave});

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  bool _isSaving = false;
  _SignatureMode _mode = _SignatureMode.draw;
  Uint8List? _importedBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _importedBytes = bytes);
  }

  Future<void> _save() async {
    Uint8List? bytes;

    if (_mode == _SignatureMode.draw) {
      if (widget.controller.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez dessiner votre signature'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      bytes = await widget.controller.toPngBytes();
    } else {
      if (_importedBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une image'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      bytes = _importedBytes;
    }

    if (bytes == null) return;
    setState(() => _isSaving = true);
    try {
      final base64 = base64Encode(bytes);
      if (!mounted) return;
      await widget.onSave(base64);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width - 32,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ma signature', style: theme.textTheme.titleLarge),
                IconButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Toggle Dessiner / Importer
            SegmentedButton<_SignatureMode>(
              segments: const [
                ButtonSegment(
                  value: _SignatureMode.draw,
                  icon: Icon(Icons.draw_outlined, size: 16),
                  label: Text('Dessiner'),
                ),
                ButtonSegment(
                  value: _SignatureMode.import,
                  icon: Icon(Icons.upload_file_outlined, size: 16),
                  label: Text('Importer'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _isSaving
                  ? null
                  : (s) => setState(() => _mode = s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 16),

            // Contenu selon le mode
            if (_mode == _SignatureMode.draw) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Signature(
                    controller: widget.controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dessinez votre signature ci-dessus',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ] else ...[
              GestureDetector(
                onTap: _isSaving ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _importedBytes != null
                        ? Colors.white
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _importedBytes != null
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: _importedBytes != null ? 2 : 1,
                    ),
                  ),
                  child: _importedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(
                            _importedBytes!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              size: 40,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyer pour choisir une image',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PNG, JPG — fond blanc recommandé',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              if (_importedBytes != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _importedBytes = null),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Changer'),
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Boutons bas
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_mode == _SignatureMode.draw)
                  TextButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () => widget.controller.clear(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Effacer'),
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: destructive ? AppTheme.error : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
