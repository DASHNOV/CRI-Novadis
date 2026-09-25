import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/features/dashboard/models/stats_query.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/services/dashboard_csv_export.dart';
import 'package:novadis_cri/features/dashboard/views/general_view.dart';
import 'package:novadis_cri/features/dashboard/views/sites_view.dart';
import 'package:novadis_cri/features/dashboard/views/technicians_view.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_cards.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';

/// Page principale du Dashboard.
///
/// Un seul écran pour deux périmètres ([dashboardIsGlobalProvider]) : l'équipe
/// (Admin, Superviseur) ou ses propres CRI (Technicien). Toutes les données
/// viennent de l'API ; les blocs propres à l'équipe (répartitions, techniciens)
/// sont masqués en périmètre personnel.
class MainDashboardPage extends ConsumerWidget {
  const MainDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final query = ref.watch(dashboardQueryProvider);
    final isGlobal = ref.watch(dashboardIsGlobalProvider);
    var viewMode = ref.watch(dashboardViewModeProvider);
    // Onglet « Techniciens » mémorisé puis indisponible : retour à « Général ».
    if (!isGlobal && viewMode == DashboardViewMode.parTechnicien) {
      viewMode = DashboardViewMode.general;
    }
    final userName = ref.watch(userNameProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 1400,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                leading: isMobile
                    ? null
                    : Container(
                        margin: const EdgeInsets.only(left: AppTheme.space12),
                        child: Icon(
                          Icons.dashboard_rounded,
                          color: AppTheme.textPrimary,
                          size: 24,
                        ),
                      ),
                title: Text(
                  isGlobal ? 'Dashboard Global' : 'Mon activité',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                actions: [
                  _ExportButton(query: query, isGlobal: isGlobal),
                  const SizedBox(width: AppTheme.space4),
                  _ToolbarButton(
                    icon: Icons.refresh_rounded,
                    tooltip: 'Actualiser',
                    onPressed: () => ref.refreshDashboard(),
                  ),
                  const SizedBox(width: AppTheme.space8),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.responsiveHorizontalPadding(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      userName != null && userName.isNotEmpty
                          ? 'Bonjour $userName,'
                          : 'Bonjour,',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Vue d\'ensemble',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: DashboardPeriodFilter(),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    _ViewModeSelector(
                      currentMode: viewMode,
                      showTechnicians: isGlobal,
                      onModeChanged: (mode) =>
                          ref.read(dashboardViewModeProvider.notifier).setMode(mode),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    switch (viewMode) {
                      DashboardViewMode.parSite =>
                        SitesView(query: query, isGlobal: isGlobal),
                      DashboardViewMode.parTechnicien => TechniciansView(query: query),
                      DashboardViewMode.general =>
                        GeneralView(query: query, isGlobal: isGlobal),
                    },
                    const SizedBox(height: AppTheme.space24),
                  ]),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
      ),
    );
  }
}

enum _ExportKind { sites, technicians }

/// Export CSV des chiffres affichés pour la période.
class _ExportButton extends ConsumerWidget {
  final StatsQuery query;
  final bool isGlobal;

  const _ExportButton({required this.query, required this.isGlobal});

  String _fileTag() {
    final day = DateFormat('yyyyMMdd');
    if (query.from != null && query.to != null) {
      return '${day.format(query.from!)}-${day.format(query.to!)}';
    }
    return '${query.periodDays ?? 'tout'}j_${day.format(DateTime.now())}';
  }

  Future<void> _export(BuildContext context, WidgetRef ref, _ExportKind kind) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final String csv;
      final String name;
      switch (kind) {
        case _ExportKind.sites:
          csv = DashboardCsvExport.sites(await ref.read(siteStatsProvider(query).future));
          name = 'dashboard_sites_${_fileTag()}.csv';
        case _ExportKind.technicians:
          csv = DashboardCsvExport.technicians(
              await ref.read(technicianStatsProvider(query).future));
          name = 'dashboard_techniciens_${_fileTag()}.csv';
      }
      final delivered = await DashboardCsvExport.deliver(csv, name);
      messenger.showSnackBar(SnackBar(content: Text('Export CSV : $delivered')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Export impossible : ${DashboardErrorView.messageOf(e)}'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: PopupMenuButton<_ExportKind>(
        tooltip: 'Exporter (CSV)',
        icon: Icon(Icons.download_rounded, color: AppTheme.textSecondary, size: 20),
        onSelected: (kind) => _export(context, ref, kind),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _ExportKind.sites,
            child: Text('Sites de la période (CSV)'),
          ),
          if (isGlobal)
            const PopupMenuItem(
              value: _ExportKind.technicians,
              child: Text('Techniciens de la période (CSV)'),
            ),
        ],
      ),
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  final DashboardViewMode currentMode;
  final bool showTechnicians;
  final ValueChanged<DashboardViewMode> onModeChanged;

  const _ViewModeSelector({
    required this.currentMode,
    required this.showTechnicians,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildItem('Général', DashboardViewMode.general),
          _buildItem('Sites', DashboardViewMode.parSite),
          if (showTechnicians)
            _buildItem('Techniciens', DashboardViewMode.parTechnicien),
        ],
      ),
    );
  }

  Widget _buildItem(String label, DashboardViewMode mode) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryContent.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
