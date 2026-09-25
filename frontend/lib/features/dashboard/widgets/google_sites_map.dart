import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/map_site.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_map_overlays.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map.dart' show diameterOf;
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Carte Google Maps des sites. Marqueurs ronds dessinés à la volée (le web
/// n'a pas de marqueurs colorés natifs), regroupés au dézoom.
///
/// Sur le web, la carte est un élément HTML : les widgets Flutter posés dessus
/// (légende, fiche) passent par [PointerInterceptor], sinon les clics
/// traversent jusqu'à la carte.
class GoogleSitesMap extends StatefulWidget {
  final List<MapSite> sites;
  final MapSite? selected;
  final ValueChanged<MapSite?> onSelect;
  final ValueChanged<MapSite>? onOpenSite;

  /// Libellés des sites sans activité (légende, fiche).
  final InactiveSiteLabels labels;

  const GoogleSitesMap({
    super.key,
    required this.sites,
    required this.selected,
    required this.onSelect,
    this.onOpenSite,
    this.labels = InactiveSiteLabels.period,
  });

  @override
  State<GoogleSitesMap> createState() => _GoogleSitesMapState();
}

class _GoogleSitesMapState extends State<GoogleSitesMap> {
  static const _france = CameraPosition(target: LatLng(46.6, 2.4), zoom: 5.3);
  static const _clusters = ClusterManagerId('sites');
  static final _clusterManager = ClusterManager(clusterManagerId: _clusters);

  GoogleMapController? _controller;

  /// Icônes déjà dessinées, par couleur, diamètre et sélection.
  final Map<String, BitmapDescriptor> _icons = {};

  @override
  void initState() {
    super.initState();
    _prepareIcons();
  }

  @override
  void didUpdateWidget(GoogleSitesMap old) {
    super.didUpdateWidget(old);
    _prepareIcons();
    final site = widget.selected;
    if (site != null && site != old.selected) _focus(site);
  }

  int get _maxCount =>
      widget.sites.fold<int>(0, (m, s) => math.max(m, s.stats?.totalInterventions ?? 0));

  static String _iconKey(Color color, double diameter, bool selected) =>
      '${color.toARGB32()}-${diameter.round()}-$selected';

  Future<void> _prepareIcons() async {
    final maxCount = _maxCount;
    final wanted = <String, (Color, double, bool)>{};
    for (final site in widget.sites) {
      final color = siteColor(site);
      final diameter = diameterOf(site, maxCount).roundToDouble();
      final selected = site == widget.selected;
      wanted[_iconKey(color, diameter, selected)] = (color, diameter, selected);
    }
    final missing = wanted.entries.where((e) => !_icons.containsKey(e.key)).toList();
    if (missing.isEmpty) return;
    for (final entry in missing) {
      final (color, diameter, selected) = entry.value;
      _icons[entry.key] = await circleIcon(color, diameter, selected: selected);
    }
    if (mounted) setState(() {});
  }

  Future<void> _focus(MapSite site) async {
    final controller = _controller;
    if (controller == null) return;
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(site.latitude, site.longitude), math.max(zoom, 12)),
    );
  }

  void _fitAll(GoogleMapController controller) {
    final sites = widget.sites;
    if (sites.length < 2) return;
    final lats = sites.map((s) => s.latitude);
    final lngs = sites.map((s) => s.longitude);
    controller.moveCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
        northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
      ),
      48,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _maxCount;
    final markers = widget.sites.map((site) {
      final selected = site == widget.selected;
      final icon = _icons[_iconKey(
            siteColor(site),
            diameterOf(site, maxCount).roundToDouble(),
            selected,
          )] ??
          BitmapDescriptor.defaultMarker;
      return Marker(
        markerId: MarkerId('${site.name}@${site.latitude},${site.longitude}'),
        position: LatLng(site.latitude, site.longitude),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        // Sites actifs au-dessus des sites gris, sélection au-dessus de tout.
        zIndexInt: selected ? 2 : (site.stats == null ? 0 : 1),
        clusterManagerId: _clusters,
        onTap: () => widget.onSelect(site),
      );
    }).toSet();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _france,
            markers: markers,
            clusterManagers: {_clusterManager},
            mapToolbarEnabled: false,
            onTap: (_) => widget.onSelect(null),
            onMapCreated: (controller) {
              _controller = controller;
              _fitAll(controller);
            },
          ),
          Positioned(
            top: 8,
            left: 8,
            child: PointerInterceptor(child: SiteMapLegend(labels: widget.labels)),
          ),
          if (widget.selected != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 24,
              child: PointerInterceptor(
                child: SelectedSiteCard(
                  site: widget.selected!,
                  onClose: () => widget.onSelect(null),
                  onOpen: widget.onOpenSite == null || widget.selected!.stats == null
                      ? null
                      : () => widget.onOpenSite!(widget.selected!),
                  labels: widget.labels,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rond coloré à bord blanc (noir si sélectionné), dessiné en 2x pour les
/// écrans haute densité.
Future<BitmapDescriptor> circleIcon(Color color, double diameter, {bool selected = false}) async {
  const ratio = 2.0;
  final size = diameter * ratio;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final center = Offset(size / 2, size / 2);
  final border = (selected ? 3 : 2) * ratio;
  canvas.drawCircle(center, size / 2, Paint()..color = selected ? Colors.black87 : Colors.white);
  canvas.drawCircle(center, size / 2 - border, Paint()..color = color.withValues(alpha: 0.9));
  final image = await recorder.endRecording().toImage(size.ceil(), size.ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    width: diameter,
    height: diameter,
  );
}
