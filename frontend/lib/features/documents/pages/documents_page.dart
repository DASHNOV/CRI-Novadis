import 'package:flutter/material.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import '../../export/models/exported_document_model.dart';
import '../../export/providers/export_providers.dart';
import '../widgets/export_options_sheet.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/empty_documents_state.dart';
import 'pdf_viewer_page.dart';

/// Page principale de l'inventaire des documents exportés (server-backed).
///
/// Admin : tous les documents de tous les utilisateurs.
/// Technicien : uniquement ses propres documents.
class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final selected = ref.watch(selectedServerDocumentsProvider);
    final hasSelection = selected.isNotEmpty;
    final showAllUsers = ref
        .watch(permissionsProvider)
        .hasPermission(Permission.documentsReadAll);

    final filter = ref.watch(serverDocumentsFilterProvider);
    final docsAsync = ref.watch(serverDocumentsProvider(filter));
    final query = ref.watch(serverSearchQueryProvider);
    final sortOption = ref.watch(serverSortProvider);
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ─── Toolbar ───
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space20,
                  AppTheme.space12,
                  AppTheme.space12,
                  AppTheme.space12,
                ),
                child: _isSearching
                    ? Row(
                        children: [
                          Expanded(
                            child: DocumentSearchBar(
                              onChanged: (q) => ref
                                  .read(serverSearchQueryProvider.notifier)
                                  .state = q,
                              onClose: () {
                                setState(() => _isSearching = false);
                                ref
                                    .read(serverSearchQueryProvider.notifier)
                                    .state = '';
                              },
                            ),
                          ),
                        ],
                      )
                    : isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _ToolbarIconButton(
                                    icon: Icons.arrow_back_rounded,
                                    tooltip: 'Retour',
                                    onPressed: () {
                                      ref
                                          .read(requestedMainTabProvider
                                              .notifier)
                                          .state = 'Accueil';
                                    },
                                  ),
                                  const SizedBox(width: AppTheme.space8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mes Documents',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (showAllUsers)
                                          Text(
                                            'Tous les exports — vue administrateur',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textTertiary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: _buildToolbarActions(
                                  hasSelection: hasSelection,
                                  filter: filter,
                                  sortOption: sortOption,
                                  selectedCount: selected.length,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mes Documents',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (showAllUsers)
                                      Text(
                                        'Tous les exports — vue administrateur',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ..._buildToolbarActions(
                                hasSelection: hasSelection,
                                filter: filter,
                                sortOption: sortOption,
                                selectedCount: selected.length,
                              ),
                            ],
                          ),
              ),
            ),
          ),

          // ─── Liste ───
          Expanded(
            child: ContentContainer(
              maxWidth: 1400,
              child: docsAsync.when(
                data: (docs) {
                  final filtered = _applyClientFilters(docs, query);
                  final sorted = _sortDocs(filtered, sortOption);

                  if (sorted.isEmpty) {
                    if (query.isNotEmpty) {
                      return const EmptySearchState();
                    }
                    return EmptyDocumentsState(
                      fileType: DocumentFileType.pdf,
                      onCreatePressed: _showExportOptions,
                    );
                  }

                  if (isMobile) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(serverDocumentsProvider);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sorted.length,
                        itemBuilder: (context, i) => _ServerDocumentCard(
                          doc: sorted[i],
                          showAllUsers: showAllUsers,
                          isSelected: selected.contains(sorted[i].id),
                          onTap: () => _openDocument(sorted[i]),
                          onOpen: () => _openDocument(sorted[i]),
                          onLongPress: () => _toggleSelection(sorted[i].id),
                          onDownload: () => _downloadDocument(sorted[i]),
                          onRename: () => _renameDocument(sorted[i]),
                          onDelete: () => _deleteDocument(sorted[i]),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(serverDocumentsProvider);
                    },
                    child: _DesktopDocumentTable(
                      docs: sorted,
                      showAllUsers: showAllUsers,
                      selected: selected,
                      onTap: _openDocument,
                      onOpen: _openDocument,
                      onLongPress: (doc) => _toggleSelection(doc.id),
                      onDownload: _downloadDocument,
                      onRename: _renameDocument,
                      onDelete: _deleteDocument,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(serverDocumentsProvider),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_documents',
        onPressed: _showExportOptions,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Nouveau',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  List<Widget> _buildToolbarActions({
    required bool hasSelection,
    required ServerDocumentsFilter filter,
    required DocumentSortOption sortOption,
    required int selectedCount,
  }) {
    if (hasSelection) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryContent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            '$selectedCount',
            style: TextStyle(
              color: AppTheme.primaryContent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        _ToolbarIconButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Supprimer',
          color: AppTheme.error,
          onPressed: _deleteSelected,
        ),
        _ToolbarIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Annuler',
          onPressed: () =>
              ref.read(selectedServerDocumentsProvider.notifier).state = {},
        ),
      ];
    }
    return [
      _ToolbarIconButton(
        icon: Icons.search_rounded,
        tooltip: 'Rechercher',
        onPressed: () => setState(() => _isSearching = true),
      ),
      const SizedBox(width: AppTheme.space4),
      _FileTypeFilterMenu(filter: filter),
      const SizedBox(width: AppTheme.space4),
      _SortMenu(current: sortOption),
      const SizedBox(width: AppTheme.space4),
      _ToolbarIconButton(
        icon: Icons.refresh_rounded,
        tooltip: 'Rafraîchir',
        onPressed: () => ref.invalidate(serverDocumentsProvider),
      ),
    ];
  }

  List<ServerExportedDocument> _applyClientFilters(
    List<ServerExportedDocument> docs,
    String query,
  ) {
    if (query.isEmpty) return docs;
    final q = query.toLowerCase();
    return docs.where((d) {
      return d.filename.toLowerCase().contains(q) ||
          (d.userName?.toLowerCase().contains(q) ?? false) ||
          (d.userEmail?.toLowerCase().contains(q) ?? false) ||
          d.exportType.toLowerCase().contains(q);
    }).toList();
  }

  List<ServerExportedDocument> _sortDocs(
    List<ServerExportedDocument> docs,
    DocumentSortOption option,
  ) {
    final sorted = List<ServerExportedDocument>.from(docs);
    switch (option) {
      case DocumentSortOption.newestFirst:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DocumentSortOption.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DocumentSortOption.nameAZ:
        sorted.sort((a, b) => a.filename.compareTo(b.filename));
        break;
      case DocumentSortOption.nameZA:
        sorted.sort((a, b) => b.filename.compareTo(a.filename));
        break;
      case DocumentSortOption.sizeAsc:
        sorted.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        break;
      case DocumentSortOption.sizeDesc:
        sorted.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
        break;
    }
    return sorted;
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => const ExportOptionsSheet(),
    );
  }

  void _toggleSelection(String id) {
    final current = ref.read(selectedServerDocumentsProvider);
    final next = Set<String>.from(current);
    next.contains(id) ? next.remove(id) : next.add(id);
    ref.read(selectedServerDocumentsProvider.notifier).state = next;
  }

  Future<void> _openDocument(ServerExportedDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final api = ref.read(exportedDocumentsApiServiceProvider);

    // PDF : viewer embarqué in-app sur toutes les plateformes (pdfx + pdf.js
    // sur web). xlsx : non prévisualisable -> opener système / téléchargement.
    final canEmbed = doc.fileType.toLowerCase() == 'pdf';

    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ouverture du document...')),
      );
      if (canEmbed) {
        final bytes = await api.downloadBytes(doc.id);
        if (bytes.isEmpty) throw Exception('Fichier vide');
        if (!mounted) return;
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => PdfViewerPage(bytes: bytes, title: doc.filename),
          ),
        );
      } else {
        await api.open(doc.id, doc.filename, doc.fileType);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur à l\'ouverture: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _downloadDocument(ServerExportedDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(exportedDocumentsApiServiceProvider);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );
      await api.download(doc.id, doc.filename);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Téléchargé: ${doc.filename}'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _renameDocument(ServerExportedDocument doc) async {
    final controller = TextEditingController(text: doc.filename);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer le document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nouveau nom'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim().isEmpty) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(exportedDocumentsApiServiceProvider).rename(doc.id, newName.trim());
      ref.invalidate(serverDocumentsProvider);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Document renommé')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _deleteDocument(ServerExportedDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${doc.filename}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(exportedDocumentsApiServiceProvider).delete(doc.id);
      ref.invalidate(serverDocumentsProvider);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Document supprimé')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _deleteSelected() async {
    final selected = ref.read(selectedServerDocumentsProvider);
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${selected.length} document(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final api = ref.read(exportedDocumentsApiServiceProvider);
    var ok = 0, fail = 0;
    for (final id in selected) {
      try {
        await api.delete(id);
        ok++;
      } catch (_) {
        fail++;
      }
    }
    ref.read(selectedServerDocumentsProvider.notifier).state = {};
    ref.invalidate(serverDocumentsProvider);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Supprimés: $ok${fail > 0 ? ', échecs: $fail' : ''}')),
    );
  }
}

// ─── Tableau desktop ───
class _DesktopDocumentTable extends StatelessWidget {
  final List<ServerExportedDocument> docs;
  final bool showAllUsers;
  final Set<String> selected;
  final void Function(ServerExportedDocument) onTap;
  final void Function(ServerExportedDocument) onOpen;
  final void Function(ServerExportedDocument) onLongPress;
  final void Function(ServerExportedDocument) onDownload;
  final void Function(ServerExportedDocument) onRename;
  final void Function(ServerExportedDocument) onDelete;

  const _DesktopDocumentTable({
    required this.docs,
    required this.showAllUsers,
    required this.selected,
    required this.onTap,
    required this.onOpen,
    required this.onLongPress,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: docs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  flex: 5,
                  child: Text('Nom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiary)),
                ),
                SizedBox(
                  width: 90,
                  child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiary)),
                ),
                SizedBox(
                  width: 140,
                  child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiary)),
                ),
                SizedBox(
                  width: 70,
                  child: Text('Taille', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiary)),
                ),
                if (showAllUsers)
                  Expanded(
                    flex: 3,
                    child: Text('Utilisateur', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiary)),
                  ),
                const SizedBox(width: 40),
              ],
            ),
          );
        }

        final doc = docs[i - 1];
        final isSelected = selected.contains(doc.id);
        final iconData = doc.fileType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.grid_on_rounded;
        final iconColor = doc.fileType == 'pdf' ? AppTheme.error : AppTheme.success;

        return Material(
          color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            onTap: () => onTap(doc),
            onLongPress: () => onLongPress(doc),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: isSelected
                    ? Border.all(color: AppTheme.primaryContent.withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(iconData, color: iconColor, size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Text(
                      doc.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      doc.exportType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      dateFmt.format(doc.createdAt.toLocal()),
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      doc.formattedSize,
                      style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ),
                  if (showAllUsers)
                    Expanded(
                      flex: 3,
                      child: Text(
                        doc.userName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: AppTheme.textTertiary, size: 18),
                    onSelected: (value) {
                      switch (value) {
                        case 'open': onOpen(doc); break;
                        case 'download': onDownload(doc); break;
                        case 'rename': onRename(doc); break;
                        case 'delete': onDelete(doc); break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.open_in_new_rounded, size: 18), SizedBox(width: 8), Text('Ouvrir')])),
                      PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download_rounded, size: 18), SizedBox(width: 8), Text('Télécharger')])),
                      PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Renommer')])),
                      PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18), SizedBox(width: 8), Text('Supprimer')])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Card pour un document serveur ───
class _ServerDocumentCard extends StatelessWidget {
  final ServerExportedDocument doc;
  final bool showAllUsers;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ServerDocumentCard({
    required this.doc,
    required this.showAllUsers,
    required this.isSelected,
    required this.onTap,
    required this.onOpen,
    required this.onLongPress,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final iconData = doc.fileType == 'pdf'
        ? Icons.picture_as_pdf_rounded
        : Icons.grid_on_rounded;
    final iconColor = doc.fileType == 'pdf' ? AppTheme.error : AppTheme.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected
            ? AppTheme.primaryLight.withValues(alpha: 0.1)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryContent.withValues(alpha: 0.5)
                    : AppTheme.border.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Chip(label: doc.fileType.toUpperCase(), color: iconColor),
                          _Chip(label: doc.exportType, color: AppTheme.textTertiary),
                          Text(
                            dateFmt.format(doc.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                          Text(
                            doc.formattedSize,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      if (showAllUsers && doc.userName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 14, color: AppTheme.textTertiary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                doc.userName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (doc.userEmail != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '· ${doc.userEmail}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppTheme.textTertiary),
                  onSelected: (value) {
                    switch (value) {
                      case 'open':
                        onOpen();
                        break;
                      case 'download':
                        onDownload();
                        break;
                      case 'rename':
                        onRename();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(children: [
                        Icon(Icons.open_in_new_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Ouvrir'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(children: [
                        Icon(Icons.download_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Télécharger'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Renommer'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _FileTypeFilterMenu extends ConsumerWidget {
  final ServerDocumentsFilter filter;
  const _FileTypeFilterMenu({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String?>(
      icon: Icon(
        Icons.filter_list_rounded,
        size: 20,
        color: filter.fileType != null ? AppTheme.primaryContent : AppTheme.textSecondary,
      ),
      tooltip: 'Filtrer par type',
      onSelected: (value) {
        ref.read(serverDocumentsFilterProvider.notifier).state =
            ServerDocumentsFilter(fileType: value, exportType: filter.exportType);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: null, child: Text('Tous les types')),
        PopupMenuItem(value: 'pdf', child: Text('PDF uniquement')),
        PopupMenuItem(value: 'xlsx', child: Text('Excel uniquement')),
      ],
    );
  }
}

class _SortMenu extends ConsumerWidget {
  final DocumentSortOption current;
  const _SortMenu({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<DocumentSortOption>(
      icon: Icon(Icons.swap_vert_rounded, color: AppTheme.textSecondary, size: 20),
      tooltip: 'Trier',
      onSelected: (v) => ref.read(serverSortProvider.notifier).state = v,
      itemBuilder: (_) => DocumentSortOption.values
          .map((o) => PopupMenuItem(value: o, child: Text(o.label)))
          .toList(),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color ?? AppTheme.textSecondary,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: AppTheme.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
