import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/config/api_config.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/data/models/cri_photo_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/features/cri_form/widgets/photo_picker.dart';
import 'package:novadis_cri/services/stats_api_service.dart';

class CriDetailsDialog extends ConsumerStatefulWidget {
  final CriModel cri;

  /// Signature actuelle du CRI (null = en attente). Fournie quand le dialogue
  /// permet de basculer le statut manuellement.
  final String? initialClientSignature;

  /// Appelé après un toggle réussi pour permettre au parent de rafraîchir sa liste.
  final VoidCallback? onSignatureChanged;

  /// Autorise l'affichage du bouton de bascule de signature manuelle.
  /// Doit être `false` si l'utilisateur courant n'est pas propriétaire du CRI.
  final bool canToggleSignature;

  /// Autorise l'affichage du bouton de suppression.
  final bool canDelete;

  /// Appelé après une suppression réussie (avant fermeture du dialogue).
  final VoidCallback? onDeleted;

  /// Autorise l'affichage du bouton « Modifier ». Réservé au propriétaire du
  /// CRI, même une fois celui-ci soumis.
  final bool canEdit;

  /// Appelé quand l'utilisateur demande la modification du CRI.
  final VoidCallback? onEdit;

  const CriDetailsDialog({
    super.key,
    required this.cri,
    this.initialClientSignature,
    this.onSignatureChanged,
    this.canToggleSignature = false,
    this.canDelete = false,
    this.onDeleted,
    this.canEdit = false,
    this.onEdit,
  });

  @override
  ConsumerState<CriDetailsDialog> createState() => _CriDetailsDialogState();
}

class _CriDetailsDialogState extends ConsumerState<CriDetailsDialog> {
  late String? _clientSignature = widget.initialClientSignature;
  bool _isToggling = false;
  bool _isDeleting = false;
  List<CriPhotoModel> _photos = [];
  String? _authToken;

  /// CRI complet récupéré du serveur (CriServiceModel | CriProjetModel | null).
  /// Porte le motif + le travail effectué détaillés, absents de la liste.
  dynamic _detail;

  CriModel get cri => widget.cri;

  @override
  void initState() {
    super.initState();
    _loadPhotoData();
    _loadDetail();
  }

  Future<void> _loadPhotoData() async {
    final token = await ref.read(storageServiceProvider).getAccessToken();
    final photos = await ref.read(criRemoteRepositoryProvider).fetchCriPhotos(cri.id);
    if (mounted) setState(() { _authToken = token; _photos = photos; });
  }

  Future<void> _loadDetail() async {
    try {
      final detail =
          await ref.read(criRemoteRepositoryProvider).fetchCriById(cri.id);
      if (mounted && detail != null) setState(() => _detail = detail);
    } catch (_) {
      // CRI hors-ligne / introuvable : on garde le repli sur cri.description.
    }
  }

  bool get _isSigned => _clientSignature != null;

  Future<void> _handleToggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    final wasSigned = _isSigned;
    try {
      await ref.read(statsApiServiceProvider).toggleClientSignature(
            cri.id,
            setSigned: !wasSigned,
          );
      if (!mounted) return;
      setState(() {
        _clientSignature = wasSigned ? null : StatsApiService.manualValidationMarker;
        _isToggling = false;
      });
      widget.onSignatureChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasSigned ? 'CRI repassé en attente.' : 'CRI marqué comme signé.'),
          backgroundColor: wasSigned ? AppTheme.warning : AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isToggling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce CRI ?'),
        content: const Text(
          'Cette action est irréversible. Le CRI sera définitivement supprimé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await ref.read(criRemoteRepositoryProvider).deleteCri(cri.id);
      if (!mounted) return;
      widget.onDeleted?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Barre de saisie
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cri.client,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.canEdit)
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            color: AppTheme.primaryContent),
                        tooltip: 'Modifier',
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onEdit?.call();
                        },
                      ),
                    if (widget.canDelete)
                      _isDeleting
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                              onPressed: _handleDelete,
                              tooltip: 'Supprimer',
                            ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.canToggleSignature) ...[
                      _buildSignatureToggle(),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'DÉTAILS DE L\'INTERVENTION',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryContent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoTile(Icons.location_on_outlined, 'Site', cri.site),
                    _buildInfoTile(Icons.build_circle_outlined, 'Type', cri.typeIntervention),
                    _buildInfoTile(Icons.calendar_today_outlined, 'Date', DateFormat('dd/MM/yyyy').format(cri.date)),

                    const SizedBox(height: 16),
                    _buildDescriptionSection(),

                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildPhotosSection(),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignatureToggle() {
    final signed = _isSigned;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: signed
            ? AppTheme.success.withValues(alpha: 0.08)
            : AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: signed ? AppTheme.success : AppTheme.warning,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                signed ? Icons.check_circle : Icons.hourglass_empty,
                color: signed ? AppTheme.success : AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                signed ? 'CRI signé' : 'En attente de signature',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: signed ? AppTheme.success : AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isToggling ? null : _handleToggle,
              icon: _isToggling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(signed ? Icons.undo : Icons.check),
              label: Text(signed ? 'Repasser en attente' : 'Valider manuellement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: signed ? AppTheme.warning : AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bloc « Motif de l'intervention » (Service uniquement) + « Travail effectué ».
  /// Utilise le détail serveur si disponible, sinon repli sur cri.description.
  Widget _buildDescriptionSection() {
    String? motif;
    String workDone;
    final detail = _detail;
    if (detail is CriServiceModel) {
      motif = detail.requestDescription;
      workDone = detail.actionsPerformed;
    } else if (detail is CriProjetModel) {
      workDone = detail.workDescription;
    } else {
      workDone = cri.description;
    }

    Widget field(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          MarkdownBody(data: value.trim().isEmpty ? '—' : value),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (motif != null) ...[
            field('Motif de l\'intervention :', motif),
            const SizedBox(height: 16),
          ],
          field('Travail effectué :', workDone),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHOTOS (${_photos.length})',
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.primaryContent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final photo = _photos[index];
              final url = '${ApiConfig.baseUrl}/CRI/${cri.id}/photos/${photo.id}';
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoViewScreen(
                      photoPath: url,
                      isNetworkImage: true,
                      authToken: _authToken,
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    httpHeaders: _authToken != null
                        ? {'Authorization': 'Bearer $_authToken'}
                        : const {},
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 120,
                      height: 120,
                      color: AppTheme.surfaceVariant,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 120,
                      color: AppTheme.surfaceVariant,
                      child: Icon(Icons.broken_image, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
