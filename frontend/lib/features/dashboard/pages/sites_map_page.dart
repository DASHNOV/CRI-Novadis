import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/features/dashboard/widgets/sites_map_panel.dart';

/// Carte plein écran de tous les sites (recherche, fiche, « Itinéraire »).
/// La même carte est intégrée à l'accueil technicien.
class SitesMapPage extends ConsumerWidget {
  const SitesMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Carte des sites'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppTheme.space12),
        child: SitesMapPanel(),
      ),
    );
  }
}
