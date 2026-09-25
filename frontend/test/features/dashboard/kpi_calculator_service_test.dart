import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/services/kpi_calculator_service.dart';

/// Minuit, [daysAgo] jours avant aujourd'hui : les dates d'intervention sont
/// saisies à la journée.
DateTime _day(int daysAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo);
}

CriServiceModel _service(
  DateTime date, {
  ResolutionStatus status = ResolutionStatus.resolu,
  String site = 'SiteA',
  String tech = 'Alice',
  int minutes = 60,
}) {
  return CriServiceModel(
    id: 'S-${date.toIso8601String()}-$site-$tech-${status.name}',
    interventionDate: date,
    startTime: date,
    endTime: date,
    ticketNumber: 'T1',
    clientName: 'Client',
    site: site,
    requestType: ServiceRequestType.depannage,
    requestDescription: '',
    actionsPerformed: '',
    interventionDurationMinutes: minutes,
    resolutionStatus: status,
    technicianNames: [tech],
    createdAt: date,
  );
}

CriProjetModel _projet(
  DateTime date, {
  ProjectStatus status = ProjectStatus.termine,
  String tech = 'Alice',
}) {
  return CriProjetModel(
    id: 'P-${date.toIso8601String()}-${status.name}',
    interventionDate: date,
    startTime: date,
    endTime: date,
    clientName: 'Client',
    site: 'SiteB',
    projectName: 'Projet',
    projectNumber: 'P1',
    projectPhase: ProjectPhase.installation,
    interventionType: ProjetInterventionType.formation,
    workDescription: '',
    projectStatus: status,
    technicianNames: [tech],
    createdAt: date,
  );
}

void main() {
  final calc = KpiCalculatorService();

  group('DashboardPeriod', () {
    test('le premier jour de la période est inclus, la veille exclue', () {
      const period = DashboardPeriod.week;
      expect(period.contains(_day(6)), isTrue); // aujourd'hui + 6 jours
      expect(period.contains(_day(7)), isFalse);
      expect(period.contains(_day(0)), isTrue);
      expect(period.contains(_day(-1)), isFalse); // demain
    });

    test('« Jour » couvre la journée entière, dès minuit', () {
      expect(DashboardPeriod.day.contains(_day(0)), isTrue);
      expect(DashboardPeriod.day.contains(_day(1)), isFalse);
    });

    test('la période précédente est contiguë et de même durée', () {
      const period = DashboardPeriod.week;
      expect(period.previousContains(_day(7)), isTrue);
      expect(period.previousContains(_day(13)), isTrue);
      expect(period.previousContains(_day(14)), isFalse);
      expect(period.previousContains(_day(6)), isFalse);
    });
  });

  group('KPIs du dashboard', () {
    final services = [
      _service(_day(0)),
      _service(_day(2), status: ResolutionStatus.nonResolu),
      _service(_day(3), status: ResolutionStatus.partiellementResolu),
      _service(_day(40)), // hors période : ne doit compter nulle part
      _service(_day(45), status: ResolutionStatus.nonResolu),
    ];
    final projets = [
      _projet(_day(1)),
      _projet(_day(4), status: ProjectStatus.enCours),
      _projet(_day(60)),
    ];
    const period = DashboardPeriod.week;

    test('réalisées et non terminées sont filtrées sur la période', () {
      final total = calc.calculateTotalInterventions(services, projets, period);
      final realized =
          calc.calculateRealizedInterventions(services, projets, period);
      expect(total, 5);
      expect(realized, 2); // service résolu + projet terminé
    });

    test('le taux de réalisation = réalisées / total', () {
      expect(
        calc.calculateCompletionRate(services, projets, period),
        closeTo(40, 0.001),
      );
    });

    test('la durée moyenne ignore les durées non saisies', () {
      final withZero = [
        _service(_day(0), minutes: 60),
        _service(_day(1), minutes: 0),
      ];
      expect(calc.calculateAverageDuration(withZero, [], period), 60);
    });
  });

  group('Évolution', () {
    test('suit la période et compte une intervention datée de minuit', () {
      final data = calc.calculateTimeEvolution(
        [_service(_day(0)), _service(_day(29)), _service(_day(30))],
        [],
        DashboardPeriod.month,
      );
      expect(data, hasLength(30));
      expect(data.first.date, _day(29));
      expect(data.first.count, 1);
      expect(data.last.date, _day(0));
      expect(data.last.count, 1);
      expect(data.fold<int>(0, (a, e) => a + e.count), 2);
    });

    test('« Jour » affiche au moins 7 jours', () {
      final data = calc.calculateTimeEvolution([], [], DashboardPeriod.day);
      expect(data, hasLength(7));
    });
  });

  group('Charge hebdomadaire', () {
    test('compte les interventions (services et projets) de la semaine en cours', () {
      final curve = calc.calculateWorkloadCurve(
        [_service(_day(0), minutes: 90), _service(_day(0), tech: 'Bob')],
        [_projet(_day(0))],
        'Alice',
      );
      expect(curve, hasLength(8));
      expect(curve.last.interventionCount, 2);
      expect(curve.last.totalHours, 1.5);
    });
  });
}
