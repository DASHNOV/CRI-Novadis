import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/features/history/widgets/sync_failure_notice.dart';
import 'package:novadis_cri/services/sync_service.dart';

/// Carte CRI unique, partagée par « Mes CRI » (technicien) et « Tous les CRI »
/// (admin). Avant, chaque écran avait sa copie et les fonctionnalités
/// divergeaient (poubelle des brouillons absente côté technicien) : toute
/// évolution de la carte se fait ici.
///
/// Les droits restent décidés par l'écran appelant : ouverture de la fiche
/// détail ([onOpenDetails]) et suppression d'un CRI serveur ([onDeleteRemote],
/// `null` → pas de bouton).
class CriCard extends ConsumerWidget {
  final Map<String, dynamic> cri;

  /// Affiche la ligne « technicien » (vue admin, CRI de tous les techniciens).
  final bool showTechnician;
  final VoidCallback onOpenDetails;
  final VoidCallback onEditPending;
  final VoidCallback onDeleteDraft;
  final VoidCallback? onDeleteRemote;

  const CriCard({
    super.key,
    required this.cri,
    required this.onOpenDetails,
    required this.onEditPending,
    required this.onDeleteDraft,
    this.onDeleteRemote,
    this.showTechnician = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientName = cri['clientName'] ?? 'Client inconnu';
    final category = cri['category'] ?? '';
    final interventionType = cri['interventionType'] ?? '';
    final createdAt = cri['createdAt'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.tryParse(cri['createdAt']) ?? DateTime.now())
        : '';
    final hasSigned = cri['clientSignature'] != null;
    final isDraft = cri['_isDraft'] == true;
    final isPending = cri['_isPending'] == true;
    // Refus serveur définitif sur ce CRI, s'il y en a un : le badge « Non
    // synchronisé » laisserait croire à une simple attente de réseau.
    final syncFailure = ref.watch(syncFailuresProvider)[cri['id']?.toString()];
    final canDeleteRemote = !isDraft && !isPending && onDeleteRemote != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          hoverColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
          onTap: () {
            if (isDraft) {
              final type = cri['_criType'] ?? 'service';
              context.push('/cri/edit/${cri['id']}?type=$type');
              return;
            }
            onOpenDetails();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Client + Status badge + actions
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _CriStatusBadge(
                      hasSigned: hasSigned,
                      isDraft: isDraft,
                      isPending: isPending,
                      syncFailure: syncFailure,
                      onEdit: onEditPending,
                    ),
                    // Correction d'un CRI resté en local : c'est le seul moyen
                    // de débloquer une synchronisation refusée pour son contenu.
                    if (isPending)
                      _CardAction(
                        icon: Icons.edit_outlined,
                        color: syncFailure != null
                            ? AppTheme.error
                            : AppTheme.primaryContent,
                        tooltip: 'Modifier et renvoyer',
                        onPressed: onEditPending,
                      ),
                    // Un CRI soumis non synchronisé n'a pas de poubelle : il
                    // n'existe pas encore côté serveur, le supprimer perdrait
                    // l'intervention.
                    if (isDraft)
                      _CardAction(
                        icon: Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        tooltip: 'Supprimer le brouillon',
                        onPressed: onDeleteDraft,
                      )
                    else if (canDeleteRemote)
                      _CardAction(
                        icon: Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        tooltip: 'Supprimer le CRI',
                        onPressed: onDeleteRemote!,
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),

                // Row 2: Type + Category + Date
                Row(
                  children: [
                    Icon(Icons.build_rounded,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        '$interventionType • $category',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),

                // Row 3: Technician name
                if (showTechnician) ...[
                  const SizedBox(height: AppTheme.space4),
                  _TechnicianLine(cri: cri),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Construit le [CriModel] attendu par la fiche détail à partir d'une ligne de
/// liste (locale ou serveur).
CriModel criModelFromMap(Map<String, dynamic> cri) {
  final clientName = cri['clientName'] ?? 'Client inconnu';
  return CriModel(
    id: cri['id'].toString(),
    client: clientName,
    site: cri['clientSite'] ?? clientName,
    typeIntervention: cri['interventionType'] ?? '',
    description: cri['workDescription'] ?? '',
    date: cri['interventionDate'] != null
        ? DateTime.tryParse(cri['interventionDate']) ?? DateTime.now()
        : DateTime.now(),
    createdAt: cri['createdAt'] != null
        ? DateTime.tryParse(cri['createdAt']) ?? DateTime.now()
        : DateTime.now(),
  );
}

/// Supprime un brouillon après confirmation : base locale **et** copie serveur.
/// `saveDraft()` pousse le brouillon sur le serveur dès qu'il y a du réseau —
/// une suppression purement locale le laissait dans « Brouillons à compléter »
/// de l'accueil (alimenté par le serveur) et dans les compteurs.
///
/// Renvoie `true` si le brouillon a été supprimé (l'appelant recharge sa liste).
Future<bool> deleteCriDraft(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> cri,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Supprimer le brouillon'),
      content: const Text(
          'Ce brouillon sera définitivement supprimé. Cette action est irréversible.'),
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
  if (confirmed != true) return false;

  final id = cri['id'].toString();
  final db = ref.read(appDatabaseProvider);
  if ((cri['_criType'] ?? 'service') == 'projet') {
    await db.deleteCriProjet(id);
  } else {
    await db.deleteCriService(id);
  }

  // Best-effort : hors ligne la copie serveur (si elle existe) survit, mais
  // le brouillon local est bien parti — ne pas bloquer la suppression.
  try {
    await ref.read(criRemoteRepositoryProvider).deleteCri(id);
  } catch (e) {
    debugPrint('Suppression serveur du brouillon $id échouée: $e');
  }
  return true;
}

class _CardAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _CardAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space4),
      child: SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 18, color: color),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _TechnicianLine extends StatelessWidget {
  final Map<String, dynamic> cri;

  const _TechnicianLine({required this.cri});

  @override
  Widget build(BuildContext context) {
    final techFullName =
        '${cri['technicianFirstName'] ?? ''} ${cri['technicianLastName'] ?? ''}'
            .trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(
            techFullName.isNotEmpty ? techFullName[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryContent,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space4),
        Text(
          techFullName.isNotEmpty ? techFullName : 'Non assigné',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryContent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CriStatusBadge extends ConsumerWidget {
  final bool hasSigned;
  final bool isDraft;
  final bool isPending;
  final String? syncFailure;
  final VoidCallback onEdit;

  const _CriStatusBadge({
    required this.hasSigned,
    required this.isDraft,
    required this.isPending,
    required this.syncFailure,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color color;
    final Color bgColor;
    final String label;
    final IconData iconData;
    if (isPending && syncFailure != null) {
      color = AppTheme.error;
      bgColor = AppTheme.errorLight;
      label = 'Sync. refusée';
      iconData = Icons.sync_problem_rounded;
    } else if (isPending) {
      color = AppTheme.info;
      bgColor = AppTheme.infoLight;
      label = 'Non synchronisé';
      iconData = Icons.cloud_off_rounded;
    } else if (isDraft) {
      color = const Color(0xFF92400E);
      bgColor = AppTheme.warningLight.withValues(alpha: 0.7);
      label = 'Brouillon';
      iconData = Icons.edit_note_rounded;
    } else if (hasSigned) {
      color = AppTheme.success;
      bgColor = AppTheme.successLight;
      label = 'Signé';
      iconData = Icons.check_circle_rounded;
    } else {
      color = AppTheme.warning;
      bgColor = AppTheme.warningLight;
      label = 'En attente';
      iconData = Icons.pending_rounded;
    }

    // Badge cliquable quand il signale un refus serveur, pour en donner le motif.
    return GestureDetector(
      onTap: syncFailure == null
          ? null
          : () => showSyncFailureDialog(context, ref,
              reason: syncFailure!, onEdit: onEdit),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (syncFailure != null) ...[
              const SizedBox(width: 3),
              Icon(Icons.info_outline_rounded, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
