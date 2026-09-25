import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_alerts_banner.dart';
import 'package:novadis_cri/models/dashboard_alerts.dart';

Map<String, dynamic> _intervention(String id) => {
      'id': id,
      'interventionType': 'Service',
      'category': 'Maintenance',
      'interventionDate': '2026-09-01T00:00:00',
      'technicianId': 't1',
      'technicienNom': 'Alice Martin',
      'siteNom': 'Site U',
      'clientNom': 'Client',
      'resolutionStatus': 'nonResolu',
    };

final _json = {
  'seuilRecurrence': 20.0,
  'minInterventionsSite': 3,
  'joursSansResolution': 14,
  'sitesRecurrence': [
    {'siteNom': 'Site R', 'clientNom': 'Client R', 'totalInterventions': 4, 'totalRecurrenceRequise': 2, 'tauxRecurrence': 50.0},
  ],
  'criNonResolusTotal': 3,
  'criNonResolus': [_intervention('a'), _intervention('b')],
  'escaladesTotal': 0,
  'escalades': <Map<String, dynamic>>[],
};

Widget _host(DashboardAlerts alerts) {
  const query = StatsQuery(periodDays: 30);
  return ProviderScope(
    overrides: [
      dashboardAlertsProvider(query).overrideWith((ref) async => alerts),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardAlertsBanner(query: query, isGlobal: true),
        ),
      ),
    ),
  );
}

void main() {
  test('DashboardAlerts.fromJson', () {
    final alerts = DashboardAlerts.fromJson(_json);
    expect(alerts.sitesRecurrence.single.tauxRecurrence, 50);
    expect(alerts.criNonResolus, hasLength(2));
    expect(alerts.isEmpty, isFalse);
  });

  testWidgets('une ligne par type d\'alerte, masquée à zéro, dépliable', (tester) async {
    await tester.pumpWidget(_host(DashboardAlerts.fromJson(_json)));
    await tester.pumpAndSettle();

    expect(find.text('1 site avec plus de 20 % de retours'), findsOneWidget);
    expect(find.text('3 services non résolus depuis plus de 14 jours'), findsOneWidget);
    expect(find.textContaining('escalade'), findsNothing);

    await tester.tap(find.text('3 services non résolus depuis plus de 14 jours'));
    await tester.pumpAndSettle();
    expect(find.text('… et 1 autre'), findsOneWidget);
  });

  testWidgets('rien à signaler', (tester) async {
    await tester.pumpWidget(_host(DashboardAlerts.fromJson({
      ..._json,
      'sitesRecurrence': <Map<String, dynamic>>[],
      'criNonResolusTotal': 0,
      'criNonResolus': <Map<String, dynamic>>[],
    })));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rien à signaler'), findsOneWidget);
  });
}
