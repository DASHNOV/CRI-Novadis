import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/features/dashboard/models/map_site.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/searchable_sorted_list.dart';
import 'package:novadis_cri/features/dashboard/widgets/site_map_overlays.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map.dart';

/// Carte plein écran de tous les sites, pour aller sur site : recherche,
/// fiche et « Itinéraire ». En couleur, les sites où l'utilisateur est déjà
/// intervenu (tout son historique — ses propres CRI pour un technicien).
class SitesMapPage extends ConsumerStatefulWidget {
  const SitesMapPage({super.key});

  @override
  ConsumerState<SitesMapPage> createState() => _SitesMapPageState();
}

class _SitesMapPageState extends ConsumerState<SitesMapPage> {
  static const _history = StatsQuery.allTime();

  MapSite? _selected;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final referentielAsync = ref.watch(sitesMapProvider);
    // L'historique sert seulement à colorer : s'il échoue, la carte reste utile.
    final activity = ref.watch(siteStatsProvider(_history)).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Carte des sites'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: referentielAsync.when(
        data: (referentiel) {
          final sites = buildMapSites(activity, referentiel.sites);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space12,
                  AppTheme.space12,
                  AppTheme.space12,
                  AppTheme.space8,
                ),
                child: _SiteSearchField(
                  sites: sites,
                  onSelected: (site) => setState(() => _selected = site),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space12,
                    0,
                    AppTheme.space12,
                    AppTheme.space12,
                  ),
                  child: sites.isEmpty
                      ? Center(
                          child: Text(
                            'Aucun site localisé pour l\'instant.',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        )
                      : SitesMap(
                          sites: sites,
                          selected: _selected,
                          onSelect: (site) => setState(() => _selected = site),
                          labels: InactiveSiteLabels.neverVisited,
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: DashboardErrorView(
            error: e,
            onRetry: () => ref.invalidate(sitesMapProvider),
          ),
        ),
      ),
    );
  }
}

/// Recherche d'un site par nom, adresse ou ville (sans accents) ; la sélection
/// centre la carte et ouvre la fiche.
class _SiteSearchField extends StatelessWidget {
  final List<MapSite> sites;
  final ValueChanged<MapSite> onSelected;

  const _SiteSearchField({required this.sites, required this.onSelected});

  static String _searchText(MapSite s) => '${s.name} ${s.addressLine ?? ''}';

  @override
  Widget build(BuildContext context) {
    return Autocomplete<MapSite>(
      displayStringForOption: (site) => site.name,
      optionsBuilder: (value) {
        final needle = normalizeForSearch(value.text.trim());
        if (needle.isEmpty) return const Iterable<MapSite>.empty();
        return sites
            .where((s) => normalizeForSearch(_searchText(s)).contains(needle))
            .take(8);
      },
      onSelected: (site) {
        FocusScope.of(context).unfocus();
        onSelected(site);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(
          hintText: 'Rechercher un site, une ville…',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 18),
            tooltip: 'Effacer',
            onPressed: controller.clear,
          ),
          isDense: true,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
      optionsViewBuilder: (context, onOptionSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320, maxWidth: 520),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: options
                  .map((site) => ListTile(
                        dense: true,
                        leading: Icon(Icons.location_on_rounded, color: siteColor(site)),
                        title: Text(site.name),
                        subtitle: site.addressLine == null ? null : Text(site.addressLine!),
                        onTap: () => onOptionSelected(site),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
