import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/map_site.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_stats_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Couleur d'un site : gris sans activité sur la période ; sinon vert < 10 %
/// de retours, orange jusqu'à 20 %, rouge au-delà (seuil des alertes).
Color siteColor(MapSite site) {
  final stats = site.stats;
  if (stats == null) return inactiveSiteColor;
  return recurrenceColor(stats.tauxRecurrence);
}

const inactiveSiteColor = Color(0xFF9CA3AF);

Color recurrenceColor(double tauxRecurrence) {
  if (tauxRecurrence > kRecurrenceAlertThreshold) return AppTheme.error;
  if (tauxRecurrence >= 10) return AppTheme.warning;
  return AppTheme.success;
}

/// Ouvre l'itinéraire Google Maps (application sur mobile, onglet sur le web).
Future<void> openDirections(BuildContext context, MapSite site) async {
  final opened = await launchUrl(site.directionsUri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
    );
  }
}

/// Légende de la carte.
class SiteMapLegend extends StatelessWidget {
  const SiteMapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ],
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Taux de retour',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          item(AppTheme.success, '< 10 %'),
          item(AppTheme.warning, '10 – 20 %'),
          item(AppTheme.error, '> 20 %'),
          item(inactiveSiteColor, 'Sans CRI sur la période'),
          const Text('Taille : nombre de CRI', style: TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}

/// Fiche du site sélectionné : activité, adresse, « Itinéraire », « Voir le site ».
class SelectedSiteCard extends StatelessWidget {
  final MapSite site;
  final VoidCallback onClose;

  /// `null` : pas de page site (périmètre personnel, ou site sans activité).
  final VoidCallback? onOpen;

  const SelectedSiteCard({
    super.key,
    required this.site,
    required this.onClose,
    this.onOpen,
  });

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 12, color: AppTheme.textTertiary);
    final stats = site.stats;
    final address = site.addressLine;

    return Material(
      elevation: 4,
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    site.name,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  if (stats?.clientNom != null) Text(stats!.clientNom!, style: muted),
                  if (address != null) Text(address, style: muted),
                  const SizedBox(height: 4),
                  Text(
                    stats == null
                        ? 'Aucun CRI sur la période'
                        : '${stats.totalInterventions} CRI · retours ${stats.tauxRecurrence.toStringAsFixed(0)} %'
                            '${stats.derniereIntervention != null ? ' · dernière le ${_date(stats.derniereIntervention!)}' : ''}',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  if (site.fromCri)
                    Text(
                      site.isApproximate
                          ? 'Position approximative : commune saisie dans le CRI'
                          : 'Position d\'après l\'adresse saisie dans le CRI',
                      style: muted,
                    )
                  else if (site.isApproximate)
                    Text('Position approximative (centre de la commune)', style: muted),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: () => openDirections(context, site),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Itinéraire'),
                ),
                if (onOpen != null)
                  TextButton(onPressed: onOpen, child: const Text('Voir le site')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Fermer',
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
