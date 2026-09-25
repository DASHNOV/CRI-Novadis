import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_stats_widgets.dart';
import 'package:novadis_cri/models/site_stats.dart';

/// Couleur d'un site selon son taux de récurrence : vert < 10 %, orange jusqu'à
/// 20 %, rouge au-delà (seuil des alertes).
Color recurrenceColor(double tauxRecurrence) {
  if (tauxRecurrence > kRecurrenceAlertThreshold) return AppTheme.error;
  if (tauxRecurrence >= 10) return AppTheme.warning;
  return AppTheme.success;
}

/// Diamètre d'un marqueur : surface proportionnelle au nombre de CRI, bornée.
double markerDiameter(int interventions, int maxInterventions) {
  const min = 16.0, max = 44.0;
  if (maxInterventions <= 0) return min;
  final ratio = math.sqrt(interventions / maxInterventions);
  return min + (max - min) * ratio.clamp(0, 1);
}

/// Carte des sites de la période : fond Plan IGN (Géoplateforme), marqueurs
/// regroupés au dézoom, taille = volume, couleur = récurrence. Un clic
/// sélectionne le site ([onSelect]) ; la fiche s'affiche en bas de la carte.
class SitesMap extends StatelessWidget {
  final List<SiteStats> sites;
  final MapController mapController;
  final SiteStats? selected;
  final ValueChanged<SiteStats?> onSelect;

  /// Ouvre la page du site ; `null` : pas de bouton (périmètre personnel).
  final ValueChanged<SiteStats>? onOpenSite;

  const SitesMap({
    super.key,
    required this.sites,
    required this.mapController,
    required this.selected,
    required this.onSelect,
    this.onOpenSite,
  });

  static const _planIgn = 'https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile'
      '&VERSION=1.0.0&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&STYLE=normal'
      '&TILEMATRIXSET=PM&FORMAT=image/png&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}';

  static final _france = LatLng(46.6, 2.4);

  static LatLng pointOf(SiteStats site) => LatLng(site.latitude!, site.longitude!);

  @override
  Widget build(BuildContext context) {
    final located = sites.where((s) => s.hasLocation).toList();
    final maxCount = located.fold<int>(0, (m, s) => math.max(m, s.totalInterventions));

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _france,
              initialZoom: 5.3,
              initialCameraFit: located.length >= 2
                  ? CameraFit.coordinates(
                      coordinates: located.map(pointOf).toList(),
                      padding: const EdgeInsets.all(48),
                      maxZoom: 13,
                    )
                  : null,
              minZoom: 3,
              maxZoom: 18,
              onTap: (_, __) => onSelect(null),
            ),
            children: [
              TileLayer(
                urlTemplate: _planIgn,
                userAgentPackageName: 'fr.novadis.cri',
                maxNativeZoom: 18,
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 45,
                  size: const Size(40, 40),
                  markers: located.map((site) {
                    final diameter = markerDiameter(site.totalInterventions, maxCount);
                    return Marker(
                      key: ValueKey(site.siteNom),
                      point: pointOf(site),
                      width: diameter,
                      height: diameter,
                      child: _SiteMarker(
                        site: site,
                        selected: identical(site, selected) || site.siteNom == selected?.siteNom,
                        onTap: () => onSelect(site),
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) => _ClusterBadge(count: markers.length),
                ),
              ),
              RichAttributionWidget(
                attributions: [TextSourceAttribution('Plan IGN — Géoplateforme')],
              ),
            ],
          ),
          const Positioned(top: 8, left: 8, child: _Legend()),
          if (selected != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 32,
              child: _SelectedSiteCard(
                site: selected!,
                onClose: () => onSelect(null),
                onOpen: onOpenSite == null ? null : () => onOpenSite!(selected!),
              ),
            ),
        ],
      ),
    );
  }
}

class _SiteMarker extends StatelessWidget {
  final SiteStats site;
  final bool selected;
  final VoidCallback onTap;

  const _SiteMarker({required this.site, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = recurrenceColor(site.tauxRecurrence);
    return Tooltip(
      message: '${site.siteNom} — ${site.totalInterventions} CRI',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppTheme.textPrimary : Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

class _ClusterBadge extends StatelessWidget {
  final int count;
  const _ClusterBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taux de retour',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          item(AppTheme.success, '< 10 %'),
          item(AppTheme.warning, '10 – 20 %'),
          item(AppTheme.error, '> 20 %'),
          const Text('Taille : nombre de CRI', style: TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _SelectedSiteCard extends StatelessWidget {
  final SiteStats site;
  final VoidCallback onClose;
  final VoidCallback? onOpen;

  const _SelectedSiteCard({required this.site, required this.onClose, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(fontSize: 12, color: AppTheme.textTertiary);
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
                    site.siteNom,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (site.clientNom != null) Text(site.clientNom!, style: muted),
                  const SizedBox(height: 4),
                  Text(
                    '${site.totalInterventions} CRI · retours ${site.tauxRecurrence.toStringAsFixed(0)} %'
                    '${site.derniereIntervention != null ? ' · dernière le ${_date(site.derniereIntervention!)}' : ''}',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  if (site.isApproximateLocation)
                    Text('Position approximative (centre de la commune)', style: muted),
                ],
              ),
            ),
            if (onOpen != null)
              TextButton(onPressed: onOpen, child: const Text('Voir le site')),
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

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
