import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/models/dashboard_evolution.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/recent_intervention.dart';

void main() {
  group('StatsQuery', () {
    test('période seule → period', () {
      expect(const StatsQuery(periodDays: 30).toQueryParameters(), {'period': 30});
    });

    test('from / to priment sur la période, dates au format ISO', () {
      final query = StatsQuery(
        periodDays: 30,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        technicianId: 'abc',
        site: 'Site A',
      );
      expect(query.toQueryParameters(), {
        'from': '2026-09-01',
        'to': '2026-09-30',
        'technicienId': 'abc',
        'site': 'Site A',
      });
    });

    test('égalité par valeur (clé des providers family)', () {
      expect(
        const StatsQuery(periodDays: 7, site: 'X'),
        const StatsQuery(periodDays: 7, site: 'X'),
      );
      expect(
        const StatsQuery(periodDays: 7).copyWith(technicianId: 't1'),
        const StatsQuery(periodDays: 7, technicianId: 't1'),
      );
    });
  });

  test('DashboardEvolution.fromJson', () {
    final evolution = DashboardEvolution.fromJson({
      'granularity': 'week',
      'points': [
        {'debut': '2026-09-14T00:00:00', 'label': '14/09', 'total': 3, 'services': 2, 'projets': 1, 'resolu': 2},
      ],
    });
    expect(evolution.granularityLabel, 'par semaine');
    expect(evolution.points.single.total, 3);
    expect(evolution.points.single.debut, DateTime(2026, 9, 14));
  });

  group('RecentIntervention', () {
    Map<String, dynamic> json(String type, {String? resolution, String? project}) => {
          'id': 'id-1',
          'interventionType': type,
          'category': 'Maintenance',
          'interventionDate': '2026-09-20T00:00:00',
          'technicianId': 't1',
          'technicienNom': 'Alice Martin',
          'siteNom': 'Site A',
          'clientNom': 'Client',
          'resolutionStatus': resolution,
          'projectStatus': project,
          'dureeMinutes': 90,
        };

    test('service : libellé du statut de résolution, route « service »', () {
      final item = RecentIntervention.fromJson(json('Service', resolution: 'resolu'));
      expect(item.statusLabel, 'Résolu');
      expect(item.source, 'service');
      expect(item.typeLabel, 'Service');
    });

    test('projet : libellé du statut de projet, route « projet »', () {
      final item = RecentIntervention.fromJson(json('Project', project: 'termine'));
      expect(item.statusLabel, 'Terminé');
      expect(item.source, 'projet');
    });

    test('statut inconnu : valeur brute plutôt qu\'un faux libellé', () {
      final item = RecentIntervention.fromJson(json('Service', resolution: 'enAttente'));
      expect(item.statusLabel, 'enAttente');
    });
  });

  test('GlobalStats lit totalInterventions, sinon l\'ancien totalCeMois', () {
    expect(GlobalStats.fromJson({'totalInterventions': 5, 'totalCeMois': 5}).totalInterventions, 5);
    expect(GlobalStats.fromJson({'totalCeMois': 4}).totalInterventions, 4);
  });
}
