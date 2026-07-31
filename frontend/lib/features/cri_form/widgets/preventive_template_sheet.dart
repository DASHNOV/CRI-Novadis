import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/features/cri_form/data/preventive_maintenance_template.dart';

/// Ouvre la feuille de configuration du modèle « Maintenance préventive ».
///
/// Retourne le Markdown à insérer, ou `null` si l'utilisateur annule.
Future<String?> showPreventiveTemplateSheet(
  BuildContext context, {
  required List<ServiceSystemType> criSystems,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
    ),
    builder: (_) => _PreventiveTemplateSheet(criSystems: criSystems),
  );
}

class _PreventiveTemplateSheet extends StatefulWidget {
  final List<ServiceSystemType> criSystems;

  const _PreventiveTemplateSheet({required this.criSystems});

  @override
  State<_PreventiveTemplateSheet> createState() =>
      _PreventiveTemplateSheetState();
}

class _PreventiveTemplateSheetState extends State<_PreventiveTemplateSheet> {
  late PmTemplateSelection _selection;
  final Map<String, TextEditingController> _versionControllers = {};

  @override
  void initState() {
    super.initState();
    _selection = PmTemplateSelection.initial(widget.criSystems);
    for (final section in kPreventiveMaintenanceSections) {
      for (final item in section.items) {
        if (item.versionHint == null) continue;
        _versionControllers[item.id] = TextEditingController()
          ..addListener(() => _onVersionChanged(item.id));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _versionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onVersionChanged(String itemId) {
    final versions = Map<String, String>.from(_selection.versions);
    versions[itemId] = _versionControllers[itemId]?.text ?? '';
    setState(() => _selection = _selection.copyWith(versions: versions));
  }

  void _toggleItem(String itemId, bool checked) {
    final ids = Set<String>.from(_selection.checkedItemIds);
    if (checked) {
      ids.add(itemId);
    } else {
      ids.remove(itemId);
    }
    setState(() => _selection = _selection.copyWith(checkedItemIds: ids));
  }

  void _toggleSection(PmTemplateSection section, bool checked) {
    final ids = Set<String>.from(_selection.checkedItemIds);
    for (final item in section.items) {
      if (checked) {
        ids.add(item.id);
      } else {
        ids.remove(item.id);
      }
    }
    setState(() => _selection = _selection.copyWith(checkedItemIds: ids));
  }

  bool _sectionHasChecked(PmTemplateSection section) =>
      section.items.any((i) => _selection.checkedItemIds.contains(i.id));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    final preview = _selection.buildMarkdown();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              shrinkWrap: true,
              children: [
                for (final section in kPreventiveMaintenanceSections) ...[
                  _buildSection(section),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                _buildPreview(theme, preview),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildActions(preview),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modèle — Maintenance préventive',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Décochez ce qui n\'a pas été fait, complétez les versions.',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            tooltip: 'Annuler',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(PmTemplateSection section) {
    final allChecked =
        section.items.every((i) => _selection.checkedItemIds.contains(i.id));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: allChecked,
            tristate: false,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            onChanged: (v) => _toggleSection(section, v ?? false),
          ),
          if (section.needsVms && _sectionHasChecked(section)) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PmVmsOption.values.map((vms) {
                  return ChoiceChip(
                    label: Text(vms.label),
                    selected: _selection.vms == vms,
                    onSelected: (_) => setState(
                      () => _selection = _selection.copyWith(vms: vms),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          for (final item in section.items) ...[
            CheckboxListTile(
              value: _selection.checkedItemIds.contains(item.id),
              dense: true,
              contentPadding: const EdgeInsets.only(left: 12),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                item.render(vmsLabel: _selection.vms.label),
                style: const TextStyle(fontSize: 13),
              ),
              onChanged: (v) => _toggleItem(item.id, v ?? false),
            ),
            if (item.versionHint != null &&
                _selection.checkedItemIds.contains(item.id))
              Padding(
                padding: const EdgeInsets.fromLTRB(52, 0, 0, 8),
                child: TextField(
                  controller: _versionControllers[item.id],
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: item.versionHint,
                    prefixIcon: const Icon(Icons.numbers, size: 18),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, String preview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: MarkdownBody(
            data: preview.isEmpty ? '_Aucune ligne sélectionnée_' : preview,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(String preview) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: preview.isEmpty
                ? null
                : () => Navigator.pop(context, preview),
            icon: const Icon(Icons.playlist_add_check),
            label: const Text('Insérer'),
          ),
        ],
      ),
    );
  }
}
