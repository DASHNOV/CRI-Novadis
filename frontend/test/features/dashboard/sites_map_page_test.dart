import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/pages/sites_map_page.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/models/site_location.dart';
import 'package:novadis_cri/models/site_stats.dart';

void main() {
  test('la carte des sites est ouverte à tout utilisateur connecté (techniciens)', () {
    expect(AppRouter.requiredPermission(AppRouter.sitesMap), isNull);
  });

  testWidgets('recherche d\'un site : la fiche s\'ouvre avec « Itinéraire »', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sitesMapProvider.overrideWith((ref) async => const SitesMapData(
              sites: [
                SiteLocation(numero: 1, nomDuSite: 'Agence Évry', ville: 'Évry', latitude: 48.63, longitude: 2.44),
                SiteLocation(numero: 2, nomDuSite: 'Dépôt Lille', ville: 'Lille', latitude: 50.63, longitude: 3.06),
              ],
              nonLocalises: 0,
            )),
        siteStatsProvider(const StatsQuery.allTime()).overrideWith((ref) async => const [
              SiteStats(siteID: 1, siteNom: 'Agence Évry', totalInterventions: 3),
            ]),
      ],
      child: const MaterialApp(home: SitesMapPage()),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'evry'); // sans accent
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Agence Évry'));
    await tester.pumpAndSettle();

    expect(find.text('Itinéraire'), findsOneWidget);
    expect(find.textContaining('3 CRI'), findsOneWidget);   // site déjà visité
    expect(find.text('Voir le site'), findsNothing);        // pas de page site ici
  });
}
