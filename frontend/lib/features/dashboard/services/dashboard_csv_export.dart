import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';

import 'csv_download_stub.dart'
    if (dart.library.js_interop) 'csv_download_web.dart'
    if (dart.library.io) 'csv_download_native.dart' as download;

/// Export CSV des chiffres **affichés** par le dashboard (données API de la
/// période), à ne pas confondre avec `features/export` (CRI de la base locale).
///
/// Format tableur français : séparateur `;`, décimales à la virgule, UTF-8 avec
/// BOM (sinon Excel lit les accents en Windows-1252).
class DashboardCsvExport {
  static final _date = DateFormat('dd/MM/yyyy');

  static String _cell(Object? value) {
    if (value == null) return '';
    final text = value is double
        ? value.toStringAsFixed(1).replaceAll('.', ',')
        : value is DateTime
            ? _date.format(value)
            : value.toString();
    final needsQuotes = text.contains(RegExp('[;"\\n\\r]'));
    return needsQuotes ? '"${text.replaceAll('"', '""')}"' : text;
  }

  static String _table(List<String> header, Iterable<List<Object?>> rows) {
    return [
      header.map(_cell).join(';'),
      ...rows.map((row) => row.map(_cell).join(';')),
    ].join('\r\n');
  }

  static String sites(List<SiteStats> sites) => _table(
        [
          'Site', 'Client', 'Ville', 'Interventions', 'Services', 'Projets',
          'Résolues', 'Non résolues', 'Récurrences', 'Taux de récurrence (%)',
          'Durée moyenne (min)', 'Techniciens', 'Catégorie principale',
          'Dernière intervention',
        ],
        sites.map((s) => [
              s.siteNom, s.clientNom, s.ville, s.totalInterventions,
              s.totalServices, s.totalProjets, s.totalResolu, s.totalNonResolu,
              s.totalRecurrenceRequise, s.tauxRecurrence, s.dureeMoyenneMinutes,
              s.techniciensDistincts, s.topCategorie, s.derniereIntervention,
            ]),
      );

  static String technicians(List<TechnicianDetailedStats> technicians) => _table(
        [
          'Technicien', 'Interventions', 'Services', 'Projets', 'Résolues',
          'Non résolues', 'Récurrences', 'Heures', 'Durée moyenne (min)',
          'Sites', 'Clients', 'Dernière intervention',
        ],
        technicians.map((t) => [
              t.nomComplet, t.totalInterventions, t.totalServices,
              t.totalProjets, t.totalResolu, t.totalNonResolu,
              t.totalRecurrenceRequise, t.totalHeures, t.dureeMoyenneMinutes,
              t.sitesDistincts, t.clientsDistincts, t.derniereIntervention,
            ]),
      );

  /// Octets du fichier : BOM UTF-8 + contenu.
  static Uint8List encode(String csv) =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);

  /// Télécharge (web) ou enregistre (mobile) le fichier ; renvoie son nom ou son chemin.
  static Future<String> deliver(String csv, String filename) =>
      download.deliverCsv(encode(csv), filename);
}
