import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/services/dashboard_csv_export.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/searchable_sorted_list.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/site_stats.dart';

void main() {
  group('Export CSV', () {
    test('séparateur ;, décimale à la virgule, guillemets échappés, BOM', () {
      final csv = DashboardCsvExport.sites([
        SiteStats(
          siteNom: 'Site "Nord"; bât. A',
          clientNom: 'Client',
          totalInterventions: 3,
          tauxRecurrence: 33.3,
          derniereIntervention: DateTime(2026, 9, 20),
        ),
      ]);
      final lines = csv.split('\r\n');
      expect(lines, hasLength(2));
      expect(lines.first, startsWith('Site;Client;Ville;Interventions'));
      expect(lines[1], startsWith('"Site ""Nord""; bât. A";Client;;3;'));
      expect(lines[1], contains(';33,3;'));
      expect(lines[1], endsWith(';20/09/2026'));

      final bytes = DashboardCsvExport.encode(csv);
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(bytes.skip(3).toList()), csv);
    });
  });

  test('recherche insensible à la casse et aux accents', () {
    expect(normalizeForSearch('Évry Cœur'), 'evry coeur');
  });

  group('Tendances', () {
    test('variation en %, rien sans période précédente ou depuis zéro', () {
      expect(GlobalStats.trend(15, 10), 50);
      expect(GlobalStats.trend(5, 10), -50);
      expect(GlobalStats.trend(5, 0), isNull);
      expect(GlobalStats.trend(5, null), isNull);
    });

    test('lecture de periodePrecedente', () {
      final stats = GlobalStats.fromJson({
        'totalInterventions': 12,
        'periodePrecedente': {'totalInterventions': 8, 'totalResolu': 2, 'totalRecurrenceRequise': 1},
      });
      expect(stats.interventionsTrend, 50);
      expect(GlobalStats.fromJson({'totalInterventions': 3}).periodePrecedente, isNull);
    });
  });

  test('message d\'erreur sans le préfixe technique', () {
    expect(DashboardErrorView.messageOf('Session expirée.'), 'Session expirée.');
    expect(DashboardErrorView.messageOf(Exception('Hors ligne')), 'Hors ligne');
  });

  group('Période', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('préréglage → period ; personnalisée → from / to', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(selectedPeriodProvider.notifier).setPeriod(DashboardPeriod.quarter);
      expect(container.read(dashboardQueryProvider), const StatsQuery(periodDays: 90));

      await container.read(selectedPeriodProvider.notifier).setPeriod(DashboardPeriod.custom);
      // Sans plage choisie : repli sur 30 jours plutôt qu'une requête vide.
      expect(container.read(dashboardQueryProvider), const StatsQuery(periodDays: 30));

      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 3, 31));
      await container.read(customRangeProvider.notifier).setRange(range);
      expect(
        container.read(dashboardQueryProvider),
        StatsQuery(from: range.start, to: range.end),
      );
    });

    test('l\'onglet choisi est mémorisé', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(dashboardViewModeProvider.notifier).setMode(DashboardViewMode.parSite);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dashboard_view_mode'), 'parSite');
    });
  });

  group('SearchableSortedList', () {
    Widget host(List<int> items) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SearchableSortedList<int>(
                items: items,
                searchHint: 'Rechercher',
                searchText: (i) => 'Site $i',
                sorts: {
                  'Décroissant': (a, b) => b.compareTo(a),
                  'Croissant': (a, b) => a.compareTo(b),
                },
                pageSize: 3,
                itemBuilder: (i) => Text('Site $i', key: ValueKey(i)),
              ),
            ),
          ),
        );

    testWidgets('affiche par tranches, trie, filtre', (tester) async {
      await tester.pumpWidget(host([1, 2, 3, 4, 5]));

      expect(find.text('Site 5'), findsOneWidget); // tri par défaut : décroissant
      expect(find.text('Site 2'), findsNothing); // tranche de 3
      await tester.tap(find.textContaining('Afficher plus'));
      await tester.pump();
      expect(find.text('Site 1'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '4');
      await tester.pump();
      expect(find.text('Site 4'), findsOneWidget);
      expect(find.text('Site 5'), findsNothing);
      expect(find.text('1 résultat'), findsOneWidget);
    });
  });
}
