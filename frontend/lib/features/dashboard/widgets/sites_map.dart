import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/map_site.dart';
import 'package:novadis_cri/features/dashboard/services/google_maps_config.dart';
import 'package:novadis_cri/features/dashboard/widgets/google_sites_map.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_map_overlays.dart';

export 'site_map_overlays.dart' show recurrenceColor, siteColor;

/// Diamètre d'un marqueur : surface proportionnelle au nombre de CRI, bornée.
double markerDiameter(int interventions, int maxInterventions) {
  const min = 16.0, max = 44.0;
  if (maxInterventions <= 0) return min;
  final ratio = math.sqrt(interventions / maxInterventions);
  return min + (max - min) * ratio.clamp(0, 1);
}

/// Site sans CRI sur la période : petit point gris.
const double inactiveMarkerDiameter = 12;

double diameterOf(MapSite site, int maxInterventions) => site.stats == null
    ? inactiveMarkerDiameter
    : markerDiameter(site.stats!.totalInterventions, maxInterventions);

/// Carte des sites : Google Maps si une clé est fournie au build
/// ([GoogleMapsConfig]), sinon Plan IGN. Même légende, même fiche (avec
/// « Itinéraire ») dans les deux cas.
class SitesMap extends StatelessWidget {
  final List<MapSite> sites;
  final MapSite? selected;
  final ValueChanged<MapSite?> onSelect;

  /// Ouvre la page du site ; `null` : pas de bouton (périmètre personnel).
  final ValueChanged<MapSite>? onOpenSite;

  const SitesMap({
    super.key,
    required this.sites,
    required this.selected,
    required this.onSelect,
    this.onOpenSite,
  });

  @override
  Widget build(BuildContext context) {
    final ign = IgnSitesMap(
      sites: sites,
      selected: selected,
      onSelect: onSelect,
      onOpenSite: onOpenSite,
    );
    if (!GoogleMapsConfig.isConfigured) return ign;

    return FutureBuilder<void>(
      future: GoogleMapsConfig.ensureLoaded(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ign; // SDK injoignable : repli IGN
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return GoogleSitesMap(
          sites: sites,
          selected: selected,
          onSelect: onSelect,
          onOpenSite: onOpenSite,
        );
      },
    );
  }
}

/// Carte Plan IGN (Géoplateforme) : repli sans clé Google Maps.
class IgnSitesMap extends StatefulWidget {
  final List<MapSite> sites;
  final MapSite? selected;
  final ValueChanged<MapSite?> onSelect;
  final ValueChanged<MapSite>? onOpenSite;

  const IgnSitesMap({
    super.key,
    required this.sites,
    required this.selected,
    required this.onSelect,
    this.onOpenSite,
  });

  @override
  State<IgnSitesMap> createState() => _IgnSitesMapState();
}

class _IgnSitesMapState extends State<IgnSitesMap> {
  static const _planIgn = 'https://data.geopf.fr/wmts?SERVICE=WMTS&REQUEST=GetTile'
      '&VERSION=1.0.0&LAYER=GEOGRAPHICALGRIDSYSTEMS.PLANIGNV2&STYLE=normal'
      '&TILEMATRIXSET=PM&FORMAT=image/png&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}';

  final _controller = MapController();

  @override
  void didUpdateWidget(IgnSitesMap old) {
    super.didUpdateWidget(old);
    final site = widget.selected;
    if (site != null && site != old.selected) {
      try {
        _controller.move(
          LatLng(site.latitude, site.longitude),
          math.max(_controller.camera.zoom, 12),
        );
      } catch (_) {
        // Carte pas encore affichée : la sélection suffit.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sites = widget.sites;
    final maxCount = sites.fold<int>(0, (m, s) => math.max(m, s.stats?.totalInterventions ?? 0));
    // Sites actifs dessinés en dernier : au-dessus des sites gris.
    final ordered = [
      ...sites.where((s) => s.stats == null),
      ...sites.where((s) => s.stats != null),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: const LatLng(46.6, 2.4),
              initialZoom: 5.3,
              initialCameraFit: sites.length >= 2
                  ? CameraFit.coordinates(
                      coordinates: sites.map((s) => LatLng(s.latitude, s.longitude)).toList(),
                      padding: const EdgeInsets.all(48),
                      maxZoom: 13,
                    )
                  : null,
              minZoom: 3,
              maxZoom: 18,
              onTap: (_, __) => widget.onSelect(null),
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
                  markers: ordered.map((site) {
                    final diameter = diameterOf(site, maxCount);
                    return Marker(
                      key: ValueKey('${site.name}@${site.latitude},${site.longitude}'),
                      point: LatLng(site.latitude, site.longitude),
                      width: diameter,
                      height: diameter,
                      child: _SiteMarker(
                        site: site,
                        selected: site == widget.selected,
                        onTap: () => widget.onSelect(site),
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
          const Positioned(top: 8, left: 8, child: SiteMapLegend()),
          if (widget.selected != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 32,
              child: SelectedSiteCard(
                site: widget.selected!,
                onClose: () => widget.onSelect(null),
                onOpen: widget.onOpenSite == null || widget.selected!.stats == null
                    ? null
                    : () => widget.onOpenSite!(widget.selected!),
              ),
            ),
        ],
      ),
    );
  }
}

class _SiteMarker extends StatelessWidget {
  final MapSite site;
  final bool selected;
  final VoidCallback onTap;

  const _SiteMarker({required this.site, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stats = site.stats;
    return Tooltip(
      message: stats == null ? site.name : '${site.name} — ${stats.totalInterventions} CRI',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: siteColor(site).withValues(alpha: 0.85),
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
