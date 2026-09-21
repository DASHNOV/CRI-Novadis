import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/services/sync_service.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/features/history/widgets/cri_details_dialog.dart';
import 'package:novadis_cri/features/history/widgets/sync_failure_notice.dart';

/// Historique global - tous les CRI de tous les techniciens (admin uniquement)
class GlobalHistoryScreen extends ConsumerStatefulWidget {
  const GlobalHistoryScreen({super.key});

  @override
  ConsumerState<GlobalHistoryScreen> createState() =>
      _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends ConsumerState<GlobalHistoryScreen> {
  String _selectedFilter = 'all';
  String? _selectedTechnicienId;
  String? _selectedClient;
  String? _selectedSite;
  String _sortBy = 'date_desc';
  bool _showFilters = false;
  List<Map<String, dynamic>> _cris = [];
  List<Map<String, dynamic>> _technicians = [];
  bool _isLoading = true;
  int _draftCount = 0;

  final List<_FilterOption> _statusFilters = [
    const _FilterOption(label: 'Tous', value: 'all'),
    const _FilterOption(label: 'Brouillons', value: 'drafts'),
    const _FilterOption(label: 'En attente', value: 'pending'),
    const _FilterOption(label: 'Signés', value: 'signed'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);

      // Filtre "Brouillons" : charge uniquement les brouillons locaux
      // (les brouillons ne remontent jamais au serveur).
      if (_selectedFilter == 'drafts') {
        final results = await Future.wait([
          _loadLocalDrafts(),
          statsService.getTechnicians(),
        ]);
        if (mounted) {
          final drafts = List<Map<String, dynamic>>.from(results[0] as List);
          setState(() {
            _cris = drafts;
            _draftCount = drafts.length;
            _technicians = List<Map<String, dynamic>>.from(results[1] as List);
            _isLoading = false;
          });
        }
        return;
      }

      // Tenter d'abord de repousser les CRI soumis hors ligne, pour qu'ils
      // apparaissent directement côté serveur si le réseau est revenu.
      try {
        await ref.read(syncServiceProvider).syncPendingCris();
      } catch (_) {}

      // Les CRI locaux (brouillons + soumis non synchronisés) se chargent
      // TOUJOURS, indépendamment du réseau : leur affichage ne doit jamais
      // dépendre de la réussite de l'appel serveur.
      final localDrafts = await _loadLocalDrafts();
      final localPendingAll = await _loadLocalPending();

      // Le serveur est best-effort : hors ligne, on affiche quand même les
      // CRI locaux pending au lieu de tomber dans le catch et tout perdre.
      var serverCris = <Map<String, dynamic>>[];
      var technicians = _technicians;
      var serverFailed = false;
      try {
        final results = await Future.wait([
          statsService.getAllCRIsWithTechnician(
            technicienId: _selectedTechnicienId,
            filter: _selectedFilter,
          ),
          statsService.getTechnicians(),
        ]);
        serverCris = List<Map<String, dynamic>>.from(results[0] as List);
        technicians = List<Map<String, dynamic>>.from(results[1] as List);
      } catch (e) {
        serverFailed = true;
        debugPrint(
            'Global history: serveur injoignable, affichage local uniquement: $e');
      }

      if (mounted) {
        // CRI soumis restés locaux (non synchronisés), absents du serveur
        final serverIds = serverCris.map((c) => c['id']?.toString()).toSet();
        final localPending = localPendingAll
            .where((c) => !serverIds.contains(c['id']?.toString()))
            .toList();

        setState(() {
          _cris = [...localPending, ...serverCris];
          _technicians = technicians;
          _draftCount = localDrafts.length;
          _isLoading = false;
        });

        if (serverFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Hors ligne : affichage des CRI enregistrés sur l\'appareil.'),
              backgroundColor: AppTheme.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading global history: $e\n$stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

  /// La colonne `technicianName` des lignes locales stocke la liste des
  /// techniciens encodée en JSON (ex. `["Rémy Denimal"]`). Cette méthode en
  /// extrait un nom d'affichage lisible.
  String _displayTechnicianName(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('[')) {
      try {
        final list = jsonDecode(s);
        if (list is List) {
          return list
              .map((e) => e?.toString().trim() ?? '')
              .where((e) => e.isNotEmpty)
              .join(', ');
        }
      } catch (_) {}
    }
    return s;
  }

  /// Charge les brouillons locaux (CRI Service + Projet). Les brouillons sont
  /// stockés uniquement sur l'appareil courant — un admin ne verra que ceux
  /// créés sur cette installation.
  Future<List<Map<String, dynamic>>> _loadLocalDrafts() async {
    final db = ref.read(appDatabaseProvider);
    
    List<CriService> services = [];
    try {
      services = await db.getAllCriService();
    } catch (e) {
      debugPrint('Error loading local service drafts: $e');
    }

    List<CriProjet> projets = [];
    try {
      projets = await db.getAllCriProjet();
    } catch (e) {
      debugPrint('Error loading local projet drafts: $e');
    }

    final drafts = <Map<String, dynamic>>[];

    for (final s in services.where((e) => e.isDraft)) {
      drafts.add({
        'id': s.id,
        '_isDraft': true,
        '_criType': 'service',
        'clientName': s.clientName,
        'clientSite': s.site,
        'siteNom': s.site,
        'category': s.requestType,
        'interventionType': s.requestType,
        'technicianFirstName': _displayTechnicianName(s.technicianName),
        'technicianLastName': '',
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
        'siteNom': p.site,
        'category': p.interventionType,
        'interventionType': p.interventionType,
        'technicianFirstName': _displayTechnicianName(p.technicianName),
        'technicianLastName': '',
        'createdAt': (p.updatedAt ?? p.createdAt).toIso8601String(),
        'clientSignature': p.clientSignature,
      });
    }

    return drafts;
  }

  /// Charge les CRI soumis restés en local (non synchronisés avec le serveur,
  /// ex. soumission sur site sans réseau). Ils sont visibles uniquement sur
  /// l'appareil où ils ont été créés, en attendant leur envoi automatique.
  Future<List<Map<String, dynamic>>> _loadLocalPending() async {
    final db = ref.read(appDatabaseProvider);

    List<CriService> services = [];
    try {
      services = await db.getAllCriService();
    } catch (e) {
      debugPrint('Error loading local pending services: $e');
    }

    List<CriProjet> projets = [];
    try {
      projets = await db.getAllCriProjet();
    } catch (e) {
      debugPrint('Error loading local pending projets: $e');
    }

    final pending = <Map<String, dynamic>>[];

    for (final s
        in services.where((e) => !e.isDraft && e.syncStatus == 'pending')) {
      pending.add({
        'id': s.id,
        '_isPending': true,
        '_criType': 'service',
        'clientName': s.clientName,
        'clientSite': s.site,
        'siteNom': s.site,
        'category': s.requestType,
        'interventionType': s.requestType,
        'workDescription': s.requestDescription,
        'interventionDate': s.interventionDate.toIso8601String(),
        'technicianFirstName': _displayTechnicianName(s.technicianName),
        'technicianLastName': '',
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
        'siteNom': p.site,
        'category': p.interventionType,
        'interventionType': p.interventionType,
        'workDescription': p.workDescription,
        'interventionDate': p.interventionDate.toIso8601String(),
        'technicianFirstName': _displayTechnicianName(p.technicianName),
        'technicianLastName': '',
        'createdAt': (p.updatedAt ?? p.createdAt).toIso8601String(),
        'clientSignature': p.clientSignature,
      });
    }

    return pending;
  }

  Future<void> _deleteRemoteCri(Map<String, dynamic> cri) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce CRI ?'),
        content: const Text(
            'Cette action est irréversible. Le CRI sera définitivement supprimé.'),
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
    try {
      await ref.read(criRemoteRepositoryProvider).deleteCri(cri['id'].toString());
      if (mounted) _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        );
      }
    }
  }

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
    final db = ref.read(appDatabaseProvider);
    final id = cri['id'].toString();
    final type = cri['_criType'] ?? 'service';
    if (type == 'projet') {
      await db.deleteCriProjet(cri['id']);
    } else {
      await db.deleteCriService(cri['id']);
    }

    // `saveDraft()` pousse aussi le brouillon côté serveur : sans cet appel il
    // y survit et continue d'alimenter les compteurs et l'accueil.
    try {
      await ref.read(criRemoteRepositoryProvider).deleteCri(id);
    } catch (e) {
      debugPrint('Suppression serveur du brouillon $id échouée: $e');
    }

    if (mounted) _loadData();
  }

  void _onStatusFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadData();
  }

  void _onTechnicienFilterChanged(String? techId) {
    setState(() => _selectedTechnicienId = techId);
    _loadData();
  }

  void _onClientFilterChanged(String? client) {
    setState(() => _selectedClient = client);
  }

  void _onSiteFilterChanged(String? site) {
    setState(() => _selectedSite = site);
  }

  String _siteOf(Map<String, dynamic> cri) =>
      ((cri['siteNom'] ?? cri['clientSite'] ?? '') as Object).toString();

  String _clientOf(Map<String, dynamic> cri) =>
      (cri['clientName'] ?? '').toString();

  List<String> get _distinctClients {
    final set = _cris.map(_clientOf).where((v) => v.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set;
  }

  List<String> get _distinctSites {
    final set = _cris.map(_siteOf).where((v) => v.isNotEmpty).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return set;
  }

  List<Map<String, dynamic>> get _sortedCris {
    final sorted = _cris.where((c) {
      if (_selectedClient != null && _clientOf(c) != _selectedClient) {
        return false;
      }
      if (_selectedSite != null && _siteOf(c) != _selectedSite) return false;
      return true;
    }).toList();
    sorted.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          final dateA =
              DateTime.tryParse(a['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              DateTime.tryParse(b['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateA.compareTo(dateB);
        case 'client_asc':
          final clientA = (a['clientName'] ?? '').toString().toLowerCase();
          final clientB = (b['clientName'] ?? '').toString().toLowerCase();
          return clientA.compareTo(clientB);
        case 'site_asc':
          final siteA = ((a['siteNom'] ?? a['clientSite'] ?? '') as Object)
              .toString()
              .toLowerCase();
          final siteB = ((b['siteNom'] ?? b['clientSite'] ?? '') as Object)
              .toString()
              .toLowerCase();
          return siteA.compareTo(siteB);
        case 'tech_asc':
          final techA = '${a['technicianFirstName']} ${a['technicianLastName']}'
              .toLowerCase();
          final techB = '${b['technicianFirstName']} ${b['technicianLastName']}'
              .toLowerCase();
          return techA.compareTo(techB);
        case 'date_desc':
        default:
          final dateA =
              DateTime.tryParse(a['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              DateTime.tryParse(b['createdAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
      }
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    // Idem historique personnel : recharger quand le SyncService a repoussé
    // des CRI en arrière-plan (l'écran vit dans un IndexedStack).
    ref.listen<int>(syncTickProvider, (_, __) {
      if (mounted) _loadData();
    });
    final sortedCris = _sortedCris;
    final total = sortedCris.length;
    final signed =
        sortedCris.where((c) => c['clientSignature'] != null).length;
    final pending = total - signed;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 1400,
          child: Column(
            children: [
              // Custom inline header (no AppBar)
              _buildHeader(total),

              // KPI Section
              if (!_isLoading && _cris.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16,
                    AppTheme.space8,
                    AppTheme.space16,
                    AppTheme.space8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          'Total',
                          total.toString(),
                          Icons.analytics_rounded,
                          AppTheme.primaryContent,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: _buildKpiCard(
                          'Signés',
                          signed.toString(),
                          Icons.check_circle_rounded,
                          AppTheme.success,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: _buildKpiCard(
                          'Attente',
                          pending.toString(),
                          Icons.pending_rounded,
                          AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),

              // Collapsible Filters
              _buildFiltersPanel(),

              // Status filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space4,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedFilter == filter.value;
                      final int count;
                      switch (filter.value) {
                        case 'all':
                          count = total;
                          break;
                        case 'signed':
                          count = signed;
                          break;
                        case 'drafts':
                          count = _draftCount;
                          break;
                        default:
                          count = pending;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.space8),
                        child: _buildStatusChip(
                          filter.label,
                          count,
                          isSelected,
                          () => _onStatusFilterChanged(filter.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.space8),

              // CRI List
              Expanded(
                child: _isLoading
                    ? _buildShimmerList()
                    : _cris.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.primaryContent,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth >= 1000) {
                                  return GridView.builder(
                                    padding: const EdgeInsets.all(
                                        AppTheme.space16),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: AppTheme.space16,
                                      mainAxisSpacing: AppTheme.space12,
                                      childAspectRatio: 2.5,
                                    ),
                                    itemCount: sortedCris.length,
                                    itemBuilder: (context, index) =>
                                        _buildGlobalCriCard(
                                            sortedCris[index]),
                                  );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(
                                      AppTheme.space16),
                                  itemCount: sortedCris.length,
                                  itemBuilder: (context, index) =>
                                      _buildGlobalCriCard(sortedCris[index]),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space16,
        AppTheme.space8,
        AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tous les CRI',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '$total CRI trouvé(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildHeaderAction(
            icon: _showFilters
                ? Icons.filter_list_off_rounded
                : Icons.filter_list_rounded,
            tooltip: 'Filtres',
            onPressed: () => setState(() => _showFilters = !_showFilters),
            isActive: _showFilters,
          ),
          _buildHeaderAction(
            icon: Icons.folder_outlined,
            tooltip: 'Documents',
            onPressed: () {
              ref.read(requestedMainTabProvider.notifier).state = 'Documents';
            },
          ),
          _buildHeaderAction(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualiser',
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: AppTheme.space4),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? AppTheme.primaryContent : AppTheme.textSecondary,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
        constraints: const BoxConstraints(
          minWidth: 38,
          minHeight: 38,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: Container(
        margin: const EdgeInsets.fromLTRB(
          AppTheme.space16,
          AppTheme.space8,
          AppTheme.space16,
          0,
        ),
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            // Technician searchable filter
            _SearchableFilterField(
              labelText: 'Filtrer par technicien',
              prefixIcon: Icons.person_search_rounded,
              allLabel: 'Tous les techniciens',
              selectedValue: _selectedTechnicienId,
              selectedDisplayLabel: _selectedTechnicienId != null
                  ? () {
                      final t = _technicians.firstWhere(
                        (t) => t['id']?.toString() == _selectedTechnicienId,
                        orElse: () => {},
                      );
                      return t.isEmpty
                          ? _selectedTechnicienId!
                          : '${t['firstName']} ${t['lastName']}';
                    }()
                  : null,
              items: _technicians.map((t) {
                final id = t['id']?.toString() ?? '';
                final firstName = t['firstName'] ?? '';
                final lastName = t['lastName'] ?? '';
                final role = t['role'] ?? '';
                return _FilterItem(
                    value: id, label: '$firstName $lastName ($role)');
              }).toList(),
              onChanged: _onTechnicienFilterChanged,
            ),
            const SizedBox(height: AppTheme.space8),

            // Client searchable filter
            _SearchableFilterField(
              labelText: 'Filtrer par client',
              prefixIcon: Icons.business_rounded,
              allLabel: 'Tous les clients',
              selectedValue: _distinctClients.contains(_selectedClient)
                  ? _selectedClient
                  : null,
              items: _distinctClients
                  .map((n) => _FilterItem(value: n, label: n))
                  .toList(),
              onChanged: _onClientFilterChanged,
            ),
            const SizedBox(height: AppTheme.space8),

            // Site searchable filter
            _SearchableFilterField(
              labelText: 'Filtrer par site',
              prefixIcon: Icons.location_on_rounded,
              allLabel: 'Tous les sites',
              selectedValue:
                  _distinctSites.contains(_selectedSite) ? _selectedSite : null,
              items: _distinctSites
                  .map((n) => _FilterItem(value: n, label: n))
                  .toList(),
              onChanged: _onSiteFilterChanged,
            ),
            const SizedBox(height: AppTheme.space8),

            // Sort dropdown
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: InputDecoration(
                labelText: 'Trier par',
                labelStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.sort_rounded,
                    color: AppTheme.textTertiary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(
                      color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                      BorderSide(color: AppTheme.primaryContent, width: 1.5),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'date_desc',
                  child: Text('Trier par...'),
                ),
                DropdownMenuItem(
                  value: 'date_asc',
                  child: Text('Date (ancien)'),
                ),
                DropdownMenuItem(
                  value: 'client_asc',
                  child: Text('Client (A-Z)'),
                ),
                DropdownMenuItem(
                  value: 'site_asc',
                  child: Text('Site (A-Z)'),
                ),
                DropdownMenuItem(
                  value: 'tech_asc',
                  child: Text('Technicien (A-Z)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _sortBy = val);
              },
            ),
          ],
        ),
      ),
      crossFadeState:
          _showFilters ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: AppTheme.animNormal,
      sizeCurve: Curves.easeOut,
    );
  }

  Widget _buildStatusChip(
      String label, int count, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryContent
                : AppTheme.border.withValues(alpha: 0.5),
          ),
          boxShadow: isSelected ? AppTheme.shadowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: AppTheme.space4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceVariant,
      highlightColor: AppTheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.space16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppTheme.space12),
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Aucun CRI trouvé',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Ajustez les filtres pour trouver des résultats',
            style: TextStyle(
              color: AppTheme.textTertiary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.space24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilter = 'all';
                _selectedTechnicienId = null;
                _selectedClient = null;
                _selectedSite = null;
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réinitialiser les filtres'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryContent,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space16,
                vertical: AppTheme.space8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: AppTheme.primaryContent.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCriCard(Map<String, dynamic> cri) {
    final clientName = cri['clientName'] ?? 'Client inconnu';
    final category = cri['category'] ?? '';
    final interventionType = cri['interventionType'] ?? '';
    final techFirstName = cri['technicianFirstName'] ?? '';
    final techLastName = cri['technicianLastName'] ?? '';
    final techFullName = '$techFirstName $techLastName'.trim();
    final createdAt = cri['createdAt'] != null
        ? DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(DateTime.tryParse(cri['createdAt']) ?? DateTime.now())
        : '';
    final hasSigned = cri['clientSignature'] != null;
    final isDraft = cri['_isDraft'] == true;
    final isPending = cri['_isPending'] == true;
    // Refus serveur définitif sur ce CRI, s'il y en a un.
    final syncFailure = ref.watch(syncFailuresProvider)[cri['id']?.toString()];

    final currentUserId = ref.read(userIdProvider);
    final criOwnerId = cri['technicianId']?.toString();
    final isAdmin = ref.read(permissionsProvider).hasPermission(Permission.deleteAnyCri);
    final canDeleteRemote = !isDraft &&
        !isPending &&
        (isAdmin ||
            (currentUserId != null &&
                criOwnerId != null &&
                currentUserId == criOwnerId));

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
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
            final currentUserId = ref.read(userIdProvider);
            final criOwnerId = cri['technicianId']?.toString();
            final canToggle = currentUserId != null &&
                criOwnerId != null &&
                currentUserId == criOwnerId;
            // Un CRI déjà soumis n'est modifiable que par son propriétaire.
            final canEdit = canToggle;

            final criModel = CriModel(
              id: cri['id'].toString(),
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
                canToggleSignature: canToggle,
                onSignatureChanged: _loadData,
                canDelete: canDeleteRemote,
                onDeleted: () {
                  if (mounted) _loadData();
                },
                canEdit: canEdit,
                onEdit: () {
                  // Type local (_criType) sinon dérivé du type serveur.
                  final type = cri['_criType'] ??
                      (interventionType == 'Project' ? 'projet' : 'service');
                  context
                      .push('/cri/edit/${cri['id']}?type=$type')
                      .then((_) {
                    if (mounted) _loadData();
                  });
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Client + Status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        clientName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildStatusBadge(hasSigned,
                        isDraft: isDraft,
                        isPending: isPending,
                        syncFailure: syncFailure),
                    if (isDraft) ...[
                      const SizedBox(width: AppTheme.space4),
                      SizedBox(
                        width: 30,
                        height: 30,
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
                    ] else if (canDeleteRemote) ...[
                      const SizedBox(width: AppTheme.space4),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppTheme.error,
                          ),
                          tooltip: 'Supprimer le CRI',
                          onPressed: () => _deleteRemoteCri(cri),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.space8),

                // Row 2: Type + Category + Date
                Row(
                  children: [
                    Icon(Icons.build_rounded,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        '$interventionType • $category',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppTheme.textTertiary),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space4),

                // Row 3: Technician name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        techFullName.isNotEmpty
                            ? techFullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryContent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Text(
                      techFullName.isNotEmpty ? techFullName : 'Non assigné',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryContent,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildStatusBadge(bool hasSigned,
      {bool isDraft = false,
      bool isPending = false,
      String? syncFailure}) {
    final Color color;
    final Color bgColor;
    final String label;
    final IconData iconData;
    if (isPending && syncFailure != null) {
      color = AppTheme.error;
      bgColor = AppTheme.errorLight;
      label = 'Sync. refusée';
      iconData = Icons.sync_problem_rounded;
    } else if (isPending) {
      color = AppTheme.info;
      bgColor = AppTheme.infoLight;
      label = 'Non synchronisé';
      iconData = Icons.cloud_off_rounded;
    } else if (isDraft) {
      color = const Color(0xFF92400E);
      bgColor = AppTheme.warningLight.withValues(alpha: 0.7);
      label = 'Brouillon';
      iconData = Icons.edit_note_rounded;
    } else if (hasSigned) {
      color = AppTheme.success;
      bgColor = AppTheme.successLight;
      label = 'Signé';
      iconData = Icons.check_circle_rounded;
    } else {
      color = AppTheme.warning;
      bgColor = AppTheme.warningLight;
      label = 'En attente';
      iconData = Icons.pending_rounded;
    }

    // Badge cliquable quand il signale un refus serveur, pour en donner le motif.
    return GestureDetector(
      onTap: syncFailure == null
          ? null
          : () => showSyncFailureDialog(context, ref, reason: syncFailure),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (syncFailure != null) ...[
              const SizedBox(width: 3),
              Icon(Icons.info_outline_rounded, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }

}

class _FilterOption {
  final String label;
  final String value;

  const _FilterOption({required this.label, required this.value});
}

class _FilterItem {
  final String value;
  final String label;
  const _FilterItem({required this.value, required this.label});
}

class _FilterResult {
  final String? value;
  const _FilterResult(this.value);
}

class _SearchableFilterField extends StatelessWidget {
  final String labelText;
  final IconData prefixIcon;
  final String allLabel;
  final String? selectedValue;
  final String? selectedDisplayLabel;
  final List<_FilterItem> items;
  final ValueChanged<String?> onChanged;

  const _SearchableFilterField({
    required this.labelText,
    required this.prefixIcon,
    required this.allLabel,
    required this.items,
    required this.onChanged,
    this.selectedValue,
    this.selectedDisplayLabel,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchBottomSheet(
        title: labelText,
        allLabel: allLabel,
        items: items,
        selectedValue: selectedValue,
      ),
    );
    if (result != null) onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedValue != null;
    final displayText =
        hasSelection ? (selectedDisplayLabel ?? selectedValue!) : null;

    return GestureDetector(
      onTap: () => _open(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          prefixIcon:
              Icon(prefixIcon, color: AppTheme.textTertiary, size: 20),
          suffixIcon: hasSelection
              ? GestureDetector(
                  onTap: () => onChanged(null),
                  child: Icon(Icons.clear_rounded,
                      color: AppTheme.textTertiary, size: 18),
                )
              : Icon(Icons.arrow_drop_down_rounded,
                  color: AppTheme.textTertiary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide:
                BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            borderSide:
                BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
          ),
          filled: true,
          fillColor: AppTheme.surfaceVariant.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space8,
          ),
          isDense: true,
        ),
        child: Text(
          displayText ?? allLabel,
          style: TextStyle(
            fontSize: 14,
            color: hasSelection ? AppTheme.textPrimary : AppTheme.textTertiary,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final String title;
  final String allLabel;
  final List<_FilterItem> items;
  final String? selectedValue;

  const _SearchBottomSheet({
    required this.title,
    required this.allLabel,
    required this.items,
    this.selectedValue,
  });

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  String _query = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_FilterItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items
        .where((i) => i.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusXl)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: AppTheme.space8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.space16, AppTheme.space12,
                    AppTheme.space16, AppTheme.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher...',
                        hintStyle:
                            TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppTheme.textTertiary, size: 20),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded,
                                    color: AppTheme.textTertiary, size: 18),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                              color: AppTheme.border.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                              color: AppTheme.border.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: BorderSide(
                              color: AppTheme.primaryContent, width: 1.5),
                        ),
                        filled: true,
                        fillColor:
                            AppTheme.surfaceVariant.withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space12,
                            vertical: AppTheme.space8),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ListTile(
                      leading: Icon(Icons.clear_all_rounded,
                          color: AppTheme.textTertiary, size: 20),
                      title: Text(widget.allLabel,
                          style: TextStyle(
                              color: widget.selectedValue == null
                                  ? AppTheme.primaryContent
                                  : AppTheme.textPrimary,
                              fontWeight: widget.selectedValue == null
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                      trailing: widget.selectedValue == null
                          ? Icon(Icons.check_rounded,
                              color: AppTheme.primaryContent, size: 18)
                          : null,
                      onTap: () =>
                          Navigator.pop(ctx, const _FilterResult(null)),
                    ),
                    ..._filtered.map((item) => ListTile(
                          title: Text(item.label,
                              style: TextStyle(
                                  color: widget.selectedValue == item.value
                                      ? AppTheme.primaryContent
                                      : AppTheme.textPrimary,
                                  fontWeight:
                                      widget.selectedValue == item.value
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                          trailing: widget.selectedValue == item.value
                              ? Icon(Icons.check_rounded,
                                  color: AppTheme.primaryContent, size: 18)
                              : null,
                          onTap: () =>
                              Navigator.pop(ctx, _FilterResult(item.value)),
                        )),
                    if (_filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.space24),
                        child: Center(
                          child: Text(
                            'Aucun résultat',
                            style: TextStyle(
                                color: AppTheme.textTertiary, fontSize: 14),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
