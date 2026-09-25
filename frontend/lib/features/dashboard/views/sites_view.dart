import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/views/general_view.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/searchable_sorted_list.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_stats_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map.dart';
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
  final _mapController = MapController();
  SiteStats? _selected;

  void _focus(SiteStats site) {
    setState(() => _selected = site);
    if (!site.hasLocation) return;
    try {
      _mapController.move(SitesMap.pointOf(site), 13);
    } catch (_) {
      // Carte pas encore affichée (premier rendu) : la sélection suffit.
    }
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
    final map = SizedBox(
      height: 520,
      child: SitesMap(
        sites: sites,
        mapController: _mapController,
        selected: _selected,
        onSelect: (site) => setState(() => _selected = site),
        onOpenSite: widget.isGlobal ? _open : null,
      ),
    );
    final unlocated = sites.where((s) => !s.hasLocation).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= Responsive.tablet;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (unlocated.isNotEmpty) ...[
              _UnlocatedSites(sites: unlocated),
              const SizedBox(height: AppTheme.space12),
            ],
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: map),
                  const SizedBox(width: AppTheme.space16),
                  // Liste : un clic centre la carte ; « Voir le site » est sur la fiche.
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
  const _UnlocatedSites({required this.sites});

  @override
  Widget build(BuildContext context) {
    final n = sites.length;
    return DashboardCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Icons.location_off_outlined, color: AppTheme.warning),
          title: Text(
            '$n site${n > 1 ? 's' : ''} non localisé${n > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
          subtitle: Text(
            'Site saisi librement dans le CRI, ou adresse du référentiel à compléter / vérifier.',
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
