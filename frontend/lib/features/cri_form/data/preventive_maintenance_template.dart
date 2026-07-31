import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

/// Modèle « Maintenance préventive » pour le champ « Travail effectué » du
/// CRI Service.
///
/// Les interventions de maintenance préventive reprennent toujours les mêmes
/// vérifications : on propose donc une liste à cocher plutôt qu'un texte figé,
/// les seules variables étant le logiciel vidéo utilisé et les numéros de
/// version/licence.
///
/// Les données sont volontairement en dur (aucun stockage en base) : le modèle
/// ne produit qu'une chaîne Markdown insérée dans `actionsPerformed`.

/// Une ligne du modèle (une puce dans le texte généré).
class PmTemplateItem {
  final String id;
  final String label;

  /// Si non nul, une saisie libre (numéro de version / licence) est proposée
  /// et vient compléter la ligne entre parenthèses.
  final String? versionHint;

  const PmTemplateItem({
    required this.id,
    required this.label,
    this.versionHint,
  });

  /// Ligne finale, `{vms}` remplacé et version accolée si renseignée.
  String render({required String vmsLabel, String version = ''}) {
    final text = label.replaceAll('{vms}', vmsLabel);
    final v = version.trim();
    if (versionHint == null || v.isEmpty) return text;
    return '$text ($v)';
  }
}

/// Un bloc du modèle, pré-coché selon les types de système du CRI.
class PmTemplateSection {
  final String id;
  final String title;
  final List<PmTemplateItem> items;

  /// Types de système qui déclenchent le pré-cochage du bloc.
  /// Vide = bloc commun, toujours pré-coché.
  final List<ServiceSystemType> systems;

  /// Bloc dont les libellés dépendent du logiciel vidéo choisi.
  final bool needsVms;

  const PmTemplateSection({
    required this.id,
    required this.title,
    required this.items,
    this.systems = const [],
    this.needsVms = false,
  });

  bool isDefaultChecked(List<ServiceSystemType> criSystems) {
    if (systems.isEmpty) return true;
    return systems.any(criSystems.contains);
  }
}

/// Logiciels vidéo rencontrés sur le parc.
enum PmVmsOption {
  qvms('QVMS'),
  ocularis('Ocularis'),
  milestone('Milestone XProtect'),
  octave('Octave VMS');

  final String label;
  const PmVmsOption(this.label);
}

/// Définition du modèle.
const List<PmTemplateSection> kPreventiveMaintenanceSections = [
  PmTemplateSection(
    id: 'commun',
    title: 'Base commune',
    items: [
      PmTemplateItem(
        id: 'commun_backup',
        label: 'Sauvegarde de la base de données',
      ),
      PmTemplateItem(
        id: 'commun_serveurs',
        label: 'Vérification des serveurs et postes clients',
      ),
      PmTemplateItem(
        id: 'commun_sql',
        label: 'Vérification et nettoyage de la base de données SQL',
      ),
    ],
  ),
  PmTemplateSection(
    id: 'amadeus',
    title: 'Contrôle d\'accès — Amadeus8',
    systems: [
      ServiceSystemType.controleAcces,
      ServiceSystemType.intrusion,
      ServiceSystemType.hypervision,
    ],
    items: [
      PmTemplateItem(
        id: 'amadeus_check',
        label:
            'Vérification du logiciel Amadeus8 (UTL, communication, processus, '
            'tâches planifiées, rapports, événements et alarmes, plans, '
            'asservissements)',
      ),
      PmTemplateItem(
        id: 'amadeus_update',
        label: 'Mise à jour de la licence et de la version Amadeus8',
        versionHint: 'Version Amadeus8 (ex. 1.160.004)',
      ),
    ],
  ),
  PmTemplateSection(
    id: 'video',
    title: 'Vidéo',
    systems: [ServiceSystemType.video],
    needsVms: true,
    items: [
      PmTemplateItem(
        id: 'video_check',
        label:
            'Vérification du logiciel {vms} (caméras, enregistrements, durée '
            'de rétention, détection de mouvement, export)',
      ),
      PmTemplateItem(
        id: 'video_update',
        label: 'Mise à jour de la licence et des patches {vms}',
        versionHint: 'Version / licence (ex. 7.5_21, 2026 R1)',
      ),
    ],
  ),
];

/// État de la sélection dans la feuille de configuration du modèle.
class PmTemplateSelection {
  final Set<String> checkedItemIds;
  final PmVmsOption vms;
  final Map<String, String> versions;

  const PmTemplateSelection({
    required this.checkedItemIds,
    this.vms = PmVmsOption.qvms,
    this.versions = const {},
  });

  /// Sélection initiale : blocs pré-cochés selon les types de système du CRI.
  factory PmTemplateSelection.initial(List<ServiceSystemType> criSystems) {
    final checked = <String>{};
    for (final section in kPreventiveMaintenanceSections) {
      if (!section.isDefaultChecked(criSystems)) continue;
      for (final item in section.items) {
        checked.add(item.id);
      }
    }
    return PmTemplateSelection(checkedItemIds: checked);
  }

  PmTemplateSelection copyWith({
    Set<String>? checkedItemIds,
    PmVmsOption? vms,
    Map<String, String>? versions,
  }) {
    return PmTemplateSelection(
      checkedItemIds: checkedItemIds ?? this.checkedItemIds,
      vms: vms ?? this.vms,
      versions: versions ?? this.versions,
    );
  }

  bool get isEmpty => checkedItemIds.isEmpty;

  /// Texte Markdown généré : une puce par vérification cochée.
  String buildMarkdown() {
    final lines = <String>[];
    for (final section in kPreventiveMaintenanceSections) {
      for (final item in section.items) {
        if (!checkedItemIds.contains(item.id)) continue;
        lines.add(
          '- ${item.render(vmsLabel: vms.label, version: versions[item.id] ?? '')}',
        );
      }
    }
    return lines.join('\n');
  }
}
