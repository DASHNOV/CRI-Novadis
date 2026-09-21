import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/services/sync_service.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/features/history/widgets/cri_details_dialog.dart';
import 'package:novadis_cri/features/history/widgets/sync_failure_notice.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Historique personnel - uniquement les CRI du technicien connecte
class PersonalHistoryScreen extends ConsumerStatefulWidget {
  const PersonalHistoryScreen({super.key});

  @override
  ConsumerState<PersonalHistoryScreen> createState() =>
      _PersonalHistoryScreenState();
}

class _PersonalHistoryScreenState extends ConsumerState<PersonalHistoryScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _cris = [];
  bool _isLoading = true;
  int _pendingCount = 0;
  int _draftCount = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<_FilterOption> _filters = [
    const _FilterOption(label: 'Tous', value: 'all', icon: Icons.list_rounded),
    const _FilterOption(
        label: 'Brouillons',
        value: 'drafts',
        icon: Icons.edit_note_rounded),
    const _FilterOption(
        label: 'En attente', value: 'pending', icon: Icons.schedule_rounded),
    const _FilterOption(
        label: 'Signes', value: 'signed', icon: Icons.check_circle_rounded),
    const _FilterOption(
        label: 'En cours',
        value: 'in_progress',
        icon: Icons.play_circle_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadCRIs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCRIs() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> cris;
      if (_selectedFilter == 'drafts') {
        cris = await _loadLocalDrafts();
      } else {
        // Tenter d'abord de repousser les CRI soumis hors ligne
        try {
          await ref.read(syncServiceProvider).syncPendingCris();
        } catch (_) {}

        final statsService = ref.read(statsApiServiceProvider);

        // Serveur best-effort : hors ligne, on retombe sur les CRI locaux au
        // lieu de partir en erreur et de perdre l'affichage.
        var serverCris = <Map<String, dynamic>>[];
        var serverFailed = false;
        try {
          serverCris =
              await statsService.getPersonalCRIs(filter: _selectedFilter);
        } catch (e) {
          serverFailed = true;
          debugPrint(
              'Personal history: serveur injoignable, affichage local: $e');
        }

        // Ajouter les CRI soumis restés locaux (non synchronisés) en tête
        // de liste pour qu'ils restent visibles même sans réseau.
        if (_selectedFilter == 'all') {
          final serverIds = serverCris.map((c) => c['id']?.toString()).toSet();
          final localPending = (await _loadLocalPending())
              .where((c) => !serverIds.contains(c['id']?.toString()))
              .toList();
          cris = [...localPending, ...serverCris];

          // Dédup défensive par id : évite tout doublon résiduel entre
          // local (pending) et serveur en cas d'id normalisé différemment.
          final seenIds = <String>{};
          cris = cris.where((c) {
            final id = c['id']?.toString();
            if (id == null) return true;
            return seenIds.add(id);
          }).toList();
        } else {
          cris = serverCris;
        }

        if (serverFailed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Hors ligne : affichage des CRI enregistrés sur l\'appareil.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      }

      // Rafraîchir les compteurs (pending/draft) sur les filtres globaux.
      if (_selectedFilter == 'all') {
        _pendingCount = cris.where((c) => c['clientSignature'] == null).length;
        _draftCount = (await _loadLocalDrafts()).length;
      } else if (_selectedFilter == 'drafts') {
        _draftCount = cris.length;
      }

      if (mounted) {
        setState(() {
          _cris = cris;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  /// Charge les brouillons locaux (CRI Service + Projet) et les normalise au
  /// format attendu par la liste. La clé `_isDraft` permet à la carte de
  /// distinguer un brouillon d'un CRI soumis.
  Future<List<Map<String, dynamic>>> _loadLocalDrafts() async {
    final db = ref.read(appDatabaseProvider);
    final services = await db.getAllCriService();
    final projets = await db.getAllCriProjet();

    final drafts = <Map<String, dynamic>>[];

    for (final s in services.where((e) => e.isDraft)) {
      drafts.add({
        'id': s.id,
        '_isDraft': true,
        '_criType': 'service',
        'clientName': s.clientName,
        'clientSite': s.site,
        'category': s.requestType,
        'interventionType': s.requestType,
        'workDescription': s.requestDescription,
        'interventionDate': s.interventionDate.toIso8601String(),
        'createdAt': (s.updatedAt ?? s.createdAt).toIso8601String(),
        'clientSignature': s.clientSignature,
      });
    }

    for (final p in projets.where((e) => e.isDraft)) {
      drafts.add({
        'id': p.id,
        '_isDraft': true,
        '_criType': 'projet',
        'clientName': p.clientName,
        'clientSite': p.site,
        'category': p.interventionType,
        'interventionType': p.interventionType,
        'workDescription': p.workDescription,
        'interventionDate': p.interventionDate.toIso8601String(),
        'createdAt': (p.updatedAt ?? p.createdAt).toIso8601String(),
        'clientSignature': p.clientSignature,
      });
    }

    drafts.sort((a, b) => (b['createdAt'] as String)
        .compareTo(a['createdAt'] as String));
    return drafts;
  }

  /// Charge les CRI soumis restés en local (non synchronisés avec le serveur,
  /// ex. soumission sur site sans réseau). La clé `_isPending` permet à la
  /// carte d'afficher le badge « Non synchronisé ».
  Future<List<Map<String, dynamic>>> _loadLocalPending() async {
    final db = ref.read(appDatabaseProvider);
    final services = await db.getAllCriService();
    final projets = await db.getAllCriProjet();

    final pending = <Map<String, dynamic>>[];

    for (final s
        in services.where((e) => !e.isDraft && e.syncStatus == 'pending')) {
      pending.add({
        'id': s.id,
        '_isPending': true,
        '_criType': 'service',
        'clientName': s.clientName,
        'clientSite': s.site,
        'category': s.requestType,
        'interventionType': s.requestType,
        'workDescription': s.requestDescription,
        'interventionDate': s.interventionDate.toIso8601String(),
        'createdAt': (s.updatedAt ?? s.createdAt).toIso8601String(),
        'clientSignature': s.clientSignature,
      });
    }

    for (final p
        in projets.where((e) => !e.isDraft && e.syncStatus == 'pending')) {
      pending.add({
        'id': p.id,
        '_isPending': true,
        '_criType': 'projet',
        'clientName': p.clientName,
        'clientSite': p.site,
        'category': p.interventionType,
        'interventionType': p.interventionType,
        'workDescription': p.workDescription,
        'interventionDate': p.interventionDate.toIso8601String(),
        'createdAt': (p.updatedAt ?? p.createdAt).toIso8601String(),
        'clientSignature': p.clientSignature,
      });
    }

    pending.sort((a, b) =>
        (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return pending;
  }

  /// Supprime un brouillon : base locale **et** copie serveur. `saveDraft()`
  /// pousse le brouillon sur le serveur dès qu'il y a du réseau — une
  /// suppression purement locale le laissait dans « Brouillons à compléter »
  /// de l'accueil (alimenté par le serveur) et dans les compteurs.
  Future<void> _deleteDraft(Map<String, dynamic> cri) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le brouillon'),
        content: const Text(
            'Ce brouillon sera définitivement supprimé. Cette action est irréversible.'),
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
    if (confirmed != true || !mounted) return;

    final id = cri['id'].toString();
    final db = ref.read(appDatabaseProvider);
    if ((cri['_criType'] ?? 'service') == 'projet') {
      await db.deleteCriProjet(id);
    } else {
      await db.deleteCriService(id);
    }

    // Best-effort : hors ligne la copie serveur (si elle existe) survit, mais
    // le brouillon local est bien parti — ne pas bloquer la suppression.
    try {
      await ref.read(criRemoteRepositoryProvider).deleteCri(id);
    } catch (e) {
      debugPrint('Suppression serveur du brouillon $id échouée: $e');
    }

    if (mounted) _loadCRIs();
  }

  /// Ouvre un CRI soumis mais resté en local (« Non synchronisé » /
  /// « Sync. refusée ») dans le formulaire pour le corriger puis le
  /// resoumettre. Le CRI existe déjà en base locale : le formulaire le
  /// recharge par son id et `submit()` le repousse avec le contenu corrigé.
  ///
  /// Réservé aux CRI encore en attente : un CRI déjà accepté par le serveur
  /// passe par la fiche détail, qui applique les droits de propriété.
  void _editPendingCri(Map<String, dynamic> cri) {
    final type = cri['_criType'] ?? 'service';
    context.push('/cri/edit/${cri['id']}?type=$type').then((_) {
      if (mounted) _loadCRIs();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadCRIs();
  }

  List<Map<String, dynamic>> get _filteredCris {
    if (_searchQuery.isEmpty) return _cris;
    final query = _searchQuery.toLowerCase();
    return _cris.where((cri) {
      final clientName = (cri['clientName'] ?? '').toString().toLowerCase();
      final category = (cri['category'] ?? '').toString().toLowerCase();
      final type = (cri['interventionType'] ?? '').toString().toLowerCase();
      return clientName.contains(query) ||
          category.contains(query) ||
          type.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    // Un CRI repoussé en arrière-plan par le SyncService doit perdre son badge
    // « Non synchronisé » sans attendre un pull-to-refresh.
    ref.listen<int>(syncTickProvider, (_, __) {
      if (mounted) _loadCRIs();
    });
    final isDesktop = Responsive.isDesktopOrLarger(context);
    final filtered = _filteredCris;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ContentContainer(
        maxWidth: 1200,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Custom header ---
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? AppTheme.space32 : AppTheme.space16,
                AppTheme.space24,
                isDesktop ? AppTheme.space32 : AppTheme.space16,
                AppTheme.space4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes CRI',
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 26 : 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${filtered.length} compte${filtered.length > 1 ? 's' : ''} rendu${filtered.length > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderAction(
                    icon: Icons.folder_outlined,
                    tooltip: 'Mes Documents & Exports',
                    onTap: () {
                      ref.read(requestedMainTabProvider.notifier).state =
                          'Documents';
                    },
                  ),
                  const Gap(8),
                  _buildHeaderAction(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Actualiser',
                    onTap: _loadCRIs,
                  ),
                ],
              ),
            ),

            // --- Search bar + filter pills ---
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? AppTheme.space32 : AppTheme.space16,
                vertical: AppTheme.space12,
              ),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Rechercher par client, type, categorie...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textTertiary,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppTheme.textTertiary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 18, color: AppTheme.textTertiary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),

                  // Filter pills
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const Gap(8),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        return _buildFilterPill(filter);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Gap(4),

            // --- List ---
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadCRIs,
                          color: AppTheme.primaryContent,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop
                                  ? AppTheme.space32
                                  : AppTheme.space16,
                              vertical: AppTheme.space8,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildCriCard(
                              filtered[index],
                            )
                                .animate()
                                .fadeIn(
                                  duration: AppTheme.animNormal,
                                  delay: Duration(
                                      milliseconds: (index * 40).clamp(0, 400)),
                                )
                                .slideY(
                                  begin: 0.03,
                                  end: 0,
                                  duration: AppTheme.animNormal,
                                  delay: Duration(
                                      milliseconds: (index * 40).clamp(0, 400)),
                                ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 18, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(_FilterOption filter) {
    final isSelected = _selectedFilter == filter.value;
    final badgeCount = filter.value == 'pending'
        ? _pendingCount
        : filter.value == 'drafts'
            ? _draftCount
            : 0;
    final showBadge = badgeCount > 0;

    Color pillColor;
    Color pillTextColor;
    Color pillBorderColor;

    if (isSelected) {
      switch (filter.value) {
        case 'drafts':
          pillColor = AppTheme.warningLight.withValues(alpha: 0.7);
          pillTextColor = const Color(0xFF92400E);
          pillBorderColor = AppTheme.warning.withValues(alpha: 0.25);
          break;
        case 'pending':
          pillColor = AppTheme.warningLight;
          pillTextColor = const Color(0xFFB45309);
          pillBorderColor = AppTheme.warning.withValues(alpha: 0.3);
          break;
        case 'signed':
          pillColor = AppTheme.successLight;
          pillTextColor = const Color(0xFF065F46);
          pillBorderColor = AppTheme.success.withValues(alpha: 0.3);
          break;
        case 'in_progress':
          pillColor = AppTheme.infoLight;
          pillTextColor = const Color(0xFF1E40AF);
          pillBorderColor = AppTheme.info.withValues(alpha: 0.3);
          break;
        default:
          pillColor = AppTheme.primaryContent.withValues(alpha: 0.08);
          pillTextColor = AppTheme.primaryContent;
          pillBorderColor = AppTheme.primaryContent.withValues(alpha: 0.2);
      }
    } else {
      pillColor = AppTheme.surface;
      pillTextColor = AppTheme.textSecondary;
      pillBorderColor = AppTheme.border;
    }

    return GestureDetector(
      onTap: () => _onFilterChanged(filter.value),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        decoration: BoxDecoration(
          color: pillColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: pillBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(filter.icon, size: 15, color: pillTextColor),
            const Gap(6),
            Text(
              filter.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: pillTextColor,
              ),
            ),
            if (showBadge) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: filter.value == 'drafts'
                      ? AppTheme.warning
                      : AppTheme.error,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final isDesktop = Responsive.isDesktopOrLarger(context);
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.surface,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? AppTheme.space32 : AppTheme.space16,
          vertical: AppTheme.space8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 36,
              color: AppTheme.textTertiary,
            ),
          ),
          const Gap(20),
          Text(
            'Aucun CRI trouve',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(6),
          Text(
            _selectedFilter == 'all'
                ? 'Creez votre premier CRI'
                : 'Aucun CRI avec ce filtre',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.animNormal).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: AppTheme.animNormal,
        );
  }

  Widget _buildCriCard(Map<String, dynamic> cri) {
    final clientName = cri['clientName'] ?? 'Client inconnu';
    final category = cri['category'] ?? '';
    final interventionType = cri['interventionType'] ?? '';
    final isDraft = cri['_isDraft'] == true;
    final isPending = cri['_isPending'] == true;

    final createdAt = cri['createdAt'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.tryParse(cri['createdAt']) ?? DateTime.now())
        : '';
    final hasSigned = cri['clientSignature'] != null;

    // Refus serveur définitif sur ce CRI, s'il y en a un : le badge « Non
    // synchronisé » laisserait croire à une simple attente de réseau.
    final syncFailure = ref.watch(syncFailuresProvider)[cri['id']?.toString()];

    // Status badge config
    final String statusLabel;
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;
    if (isPending && syncFailure != null) {
      statusLabel = 'Sync. refusée';
      statusColor = AppTheme.error;
      statusBg = AppTheme.errorLight;
      statusIcon = Icons.sync_problem_rounded;
    } else if (isPending) {
      statusLabel = 'Non synchronisé';
      statusColor = AppTheme.info;
      statusBg = AppTheme.infoLight;
      statusIcon = Icons.cloud_off_rounded;
    } else if (isDraft) {
      statusLabel = 'Brouillon';
      statusColor = const Color(0xFF92400E);
      statusBg = AppTheme.warningLight.withValues(alpha: 0.7);
      statusIcon = Icons.edit_note_rounded;
    } else if (hasSigned) {
      statusLabel = 'Signe';
      statusColor = AppTheme.success;
      statusBg = AppTheme.successLight;
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusLabel = 'En attente';
      statusColor = AppTheme.warning;
      statusBg = AppTheme.warningLight;
      statusIcon = Icons.schedule_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          hoverColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
          onTap: () {
            if (isDraft) {
              final type = cri['_criType'] ?? 'service';
              context.push('/cri/edit/${cri['id']}?type=$type');
              return;
            }
            final criModel = CriModel(
              id: cri['id'],
              client: clientName,
              site: cri['clientSite'] ?? clientName,
              typeIntervention: interventionType,
              description: cri['workDescription'] ?? '',
              date: cri['interventionDate'] != null
                  ? DateTime.tryParse(cri['interventionDate']) ?? DateTime.now()
                  : DateTime.now(),
              createdAt: cri['createdAt'] != null
                  ? DateTime.tryParse(cri['createdAt']) ?? DateTime.now()
                  : DateTime.now(),
            );

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => CriDetailsDialog(
                cri: criModel,
                initialClientSignature: cri['clientSignature']?.toString(),
                onSignatureChanged: _loadCRIs,
                // Un CRI non synchronisé n'existe pas encore côté serveur
                canToggleSignature: !isPending,
                // ... mais il reste modifiable localement pour corriger ce qui
                // bloque sa synchronisation.
                canEdit: isPending,
                onEdit: () => _editPendingCri(cri),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                // Left content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clientName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status pill — cliquable quand elle signale un refus
                          // serveur, pour en donner le motif.
                          GestureDetector(
                            onTap: syncFailure == null
                                ? null
                                : () => showSyncFailureDialog(context, ref,
                                    reason: syncFailure,
                                    onEdit: () => _editPendingCri(cri)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 13, color: statusColor),
                                  const Gap(4),
                                  Text(
                                    statusLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                  if (syncFailure != null) ...[
                                    const Gap(3),
                                    Icon(Icons.info_outline_rounded,
                                        size: 12, color: statusColor),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          // Correction d'un CRI resté en local : c'est le
                          // seul moyen de débloquer une synchronisation
                          // refusée pour son contenu.
                          if (isPending) ...[
                            const Gap(4),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: syncFailure != null
                                      ? AppTheme.error
                                      : AppTheme.primaryContent,
                                ),
                                tooltip: 'Modifier et renvoyer',
                                onPressed: () => _editPendingCri(cri),
                              ),
                            ),
                          ],
                          // Suppression d'un brouillon — réservée aux
                          // brouillons : un CRI soumis non synchronisé n'existe
                          // pas encore côté serveur, le supprimer perdrait
                          // l'intervention.
                          if (isDraft) ...[
                            const Gap(4),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppTheme.error,
                                ),
                                tooltip: 'Supprimer le brouillon',
                                onPressed: () => _deleteDraft(cri),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Gap(8),
                      Row(
                        children: [
                          Icon(Icons.build_outlined,
                              size: 13, color: AppTheme.textTertiary),
                          const Gap(4),
                          Expanded(
                            child: Text(
                              '$interventionType  $category',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(12),
                          Icon(Icons.calendar_today_rounded,
                              size: 13, color: AppTheme.textTertiary),
                          const Gap(4),
                          Text(
                            createdAt,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textTertiary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                // View icon (hover-visible via InkWell)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  final String label;
  final String value;
  final IconData icon;

  const _FilterOption(
      {required this.label, required this.value, required this.icon});
}
