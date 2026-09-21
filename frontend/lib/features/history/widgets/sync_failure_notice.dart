import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/services/sync_service.dart';

/// Détail d'un refus de synchronisation, partagé par les deux écrans
/// d'historique (personnel et global) — deux implémentations parallèles de la
/// même carte CRI, qu'il ne faut pas laisser diverger une fois de plus.
///
/// N'est proposé que pour un échec **définitif** : un CRI qui attend
/// simplement le réseau n'a pas de motif à montrer, il repartira tout seul.
///
/// [onEdit] ouvre le CRI dans le formulaire pour corriger la cause du refus.
/// Sans lui, le dialogue invitait à « corriger depuis le formulaire » sans
/// offrir le moindre chemin pour y arriver.
Future<void> showSyncFailureDialog(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
  VoidCallback? onEdit,
}) async {
  final action = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync_problem_rounded, color: AppTheme.error),
          SizedBox(width: AppTheme.space8),
          Expanded(child: Text('Synchronisation refusée')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le serveur a rejeté ce CRI. Il reste enregistré sur l\'appareil '
            'et ne sera pas perdu, mais il ne partira pas tant que la cause '
            'n\'est pas corrigée.',
          ),
          const SizedBox(height: AppTheme.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: AppTheme.errorLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              reason,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            onEdit != null
                ? 'Utilisez « Modifier » pour corriger le CRI et le '
                    'resoumettre, ou transmettez ce message au support si le '
                    'motif n\'est pas clair.'
                : 'Corrigez le CRI depuis le formulaire, ou transmettez ce '
                    'message au support si le motif n\'est pas clair.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'close'),
          child: const Text('Fermer'),
        ),
        if (onEdit != null)
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: const Text('Modifier'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'retry'),
          child: const Text('Réessayer'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;

  if (action == 'edit') {
    onEdit?.call();
    return;
  }
  if (action != 'retry') return;

  final synced = await ref.read(syncServiceProvider).retryNow();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(synced > 0
          ? 'CRI synchronisé.'
          : 'Le serveur refuse toujours ce CRI.'),
      backgroundColor: synced > 0 ? AppTheme.success : AppTheme.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
