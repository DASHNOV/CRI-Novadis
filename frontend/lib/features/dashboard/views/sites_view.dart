import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:novadis_cri/features/dashboard/models/map_site.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/views/general_view.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/searchable_sorted_list.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_stats_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map.dart';
import 'package:novadis_cri/models/site_location.dart';
import 'package:novadis_cri/models/site_stats.dart';

enum _SitesDisplay { list, map }

/// Onglet « Sites » : liste filtrable ou carte. Sur grand écran, la carte
/// s'affiche à côté de la liste et un clic sur une carte de site la centre.
class SitesView extends ConsumerStatefulWidget {
  final StatsQuery query;
  final bool isGlobal;

  const SitesView({super.key, required this.query, required this.isGlobal});

  static final Map<String, Comparator<SiteStats>> sorts = {
    'Nombre de CRI': (a, b) => b.totalInterventions.compareTo(a.totalInterventions),
    'Taux de récurrence': (a, b) => b.tauxRecurrence.compareTo(a.tauxRecurrence),
    'Durée moyenne': (a, b) =>
        (b.dureeMoyenneMinutes ?? -1).compareTo(a.dureeMoyenneMinutes ?? -1),
    'Dernière intervention': (a, b) => (b.derniereIntervention ?? DateTime(0))
        .compareTo(a.derniereIntervention ?? DateTime(0)),
    'Nom (A → Z)': (a, b) =>
        a.siteNom.toLowerCase().compareTo(b.siteNom.toLowerCase()),
  };

  @override
  ConsumerState<SitesView> createState() => _SitesViewState();
}

class _SitesViewState extends ConsumerState<SitesView> {
  _SitesDisplay _display = _SitesDisplay.list;
  MapSite? _selected;
  List<MapSite> _mapSites = const [];

  /// Clic dans la liste (vue côte à côte) : sélectionne le site sur la carte.
  void _focus(SiteStats site) {
    final point = _mapSites.where((m) => m.stats == site).firstOrNull;
    setState(() => _selected = point);
  }

  void _open(SiteStats site) => openSiteDashboard(context, site);

  @override
  Widget build(BuildContext context) {
    final query = widget.query;
    final isGlobal = widget.isGlobal;
    final sitesAsync = ref.watch(siteStatsProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Statistiques par site',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            SegmentedButton<_SitesDisplay>(
              segments: const [
                ButtonSegment(
                  value: _SitesDisplay.list,
                  icon: Icon(Icons.view_list_rounded),
                  label: Text('Liste'),
                ),
                ButtonSegment(
                  value: _SitesDisplay.map,
                  icon: Icon(Icons.map_rounded),
                  label: Text('Carte'),
                ),
              ],
              selected: {_display},
              // Sans la coche, « Carte » tient sur une ligne.
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _display = s.first),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        if (_display == _SitesDisplay.list) ...[
          TopSitesChart(query: query),
          const SizedBox(height: AppTheme.space16),
          if (isGlobal) ...[
            RequestTypesPie(query: query),
            const SizedBox(height: AppTheme.space16),
          ],
        ],
        sitesAsync.when(
          data: (sites) => _display == _SitesDisplay.list
              ? _list(sites, onTap: isGlobal ? _open : null)
              : _mapLayout(context, sites),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(siteStatsProvider(query)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _list(List<SiteStats> sites, {ValueChanged<SiteStats>? onTap}) {
    return SearchableSortedList<SiteStats>(
      items: sites,
      searchHint: 'Rechercher un site, un client, une ville…',
      searchText: (s) => '${s.siteNom} ${s.clientNom ?? ''} ${s.ville ?? ''}',
      sorts: SitesView.sorts,
      emptyMessage: 'Aucun site sur cette période',
      itemBuilder: (site) => SiteStatsCard(
        key: ValueKey(site.siteNom),
        site: site,
        onTap: onTap == null ? null : () => onTap(site),
      ),
    );
  }

  Widget _mapLayout(BuildContext context, List<SiteStats> sites) {
    return ref.watch(sitesMapProvider).when(
          data: (referentiel) => _mapWithList(context, sites, referentiel.sites, referentiel.nonLocalises),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => DashboardCard(
            child: DashboardErrorView(
              error: e,
              onRetry: () => ref.invalidate(sitesMapProvider),
            ),
          ),
        );
  }

  Widget _mapWithList(
    BuildContext context,
    List<SiteStats> sites,
    List<SiteLocation> referentiel,
    int referentielNonLocalises,
  ) {
    _mapSites = buildMapSites(sites, referentiel);
    final placed = _mapSites.map((m) => m.stats).whereType<SiteStats>().toSet();
    final unlocated = sites.where((s) => !placed.contains(s)).toList();

    final map = SizedBox(
      height: 560,
      child: SitesMap(
        sites: _mapSites,
        selected: _selected,
        onSelect: (site) => setState(() => _selected = site),
        onOpenSite: widget.isGlobal ? (site) => _open(site.stats!) : null,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= Responsive.tablet;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (unlocated.isNotEmpty || referentielNonLocalises > 0) ...[
              _UnlocatedSites(sites: unlocated, referentielNonLocalises: referentielNonLocalises),
              const SizedBox(height: AppTheme.space12),
            ],
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: map),
                  const SizedBox(width: AppTheme.space16),
                  // Liste : un clic sélectionne le site sur la carte.
                  Expanded(flex: 2, child: _list(sites, onTap: _focus)),
                ],
              )
            else
              map,
          ],
        );
      },
    );
  }
}

/// Sites absents de la carte : saisie libre (pas de site référencé), adresse
/// non géocodée ou résultat trop incertain.
class _UnlocatedSites extends StatelessWidget {
  final List<SiteStats> sites;

  /// Sites du référentiel sans coordonnées (avec ou sans activité).
  final int referentielNonLocalises;

  const _UnlocatedSites({required this.sites, required this.referentielNonLocalises});

  @override
  Widget build(BuildContext context) {
    final n = sites.length;
    final title = [
      if (n > 0) '$n site${n > 1 ? 's' : ''} actif${n > 1 ? 's' : ''} non localisé${n > 1 ? 's' : ''}',
      if (referentielNonLocalises > 0)
        '$referentielNonLocalises site${referentielNonLocalises > 1 ? 's' : ''} du référentiel sans coordonnées',
    ].join(' · ');
    return DashboardCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.location_off_outlined, color: AppTheme.warning),
          title: Text(
            title,
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
          subtitle: Text(
            'Adresse absente, non reconnue, ou pas encore géocodée '
            '(POST /api/sites/geocode, puis à chaque import des sites).',
            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
          ),
          children: sites
              .map((s) => ListTile(
                    dense: true,
                    title: Text(s.siteNom),
                    subtitle: Text(
                      [
                        if (s.clientNom != null) s.clientNom!,
                        if (s.ville != null) s.ville!,
                        s.siteID == null ? 'hors référentiel' : 'n° ${s.siteID}',
                      ].join(' · '),
                    ),
                    trailing: Text('${s.totalInterventions} CRI'),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
