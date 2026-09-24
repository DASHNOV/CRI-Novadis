# Plan — Refonte du dashboard

> Plan d'exécution à suivre étape par étape. Cocher chaque case une fois faite **et vérifiée**.
> Avant chaque étape : relire `docs/resolved-issues.md` (règle `CLAUDE.md`).
> Rédigé le 2026-09-24 — branches de travail : une par phase, depuis `dev`.

---

## 1. Objectif

Rendre le dashboard **juste** (chiffres cohérents avec la période), **rapide** (plus de téléchargement de tous les CRI), **plus utile** (tendances, alertes, carte des sites) et **maintenable** (découpage de `main_dashboard_page.dart`, suppression du code mort).

## 2. Décisions à valider

| Sujet | Proposition |
|---|---|
| Source des données | **API uniquement** pour toutes les vues (admin et technicien). Plus de calcul local à partir de `getAllCris()` |
| Périodes | Jour, 7 j, 30 j, trimestre, année, plage personnalisée |
| Tendances KPI | Comparaison avec la période précédente de même durée |
| Seuils récurrence | Vert < 10 %, orange 10–20 %, rouge > 20 % (seuil 20 % déjà utilisé) |
| Carte — géocodage | API Adresse / Géoplateforme IGN (gratuite, sans clé) |
| Carte — fond | Plan IGN (Géoplateforme). **Pas** les tuiles OSM publiques (interdites en production) |
| Carte — emplacement | Onglet **Sites**, bascule Liste / Carte ; côte à côte sur desktop |
| Route site | `/dashboard/site/:siteId` passe du **nom** au **`SiteID`** numérique |

## 3. Constats de départ

### Chiffres faux ou incohérents
- ⚠️ **« Réalisées » et « En cours » ignorent la période** (`dashboard_repository.dart:55-64`) alors que « Interventions » est filtré → on peut avoir plus de réalisées que d'interventions.
- ⚠️ **« Prévues » = toujours 0** : `plannedInterventions` n'est jamais renseigné dans `DashboardKpis`.
- ⚠️ **Courbe d'évolution figée sur 6 mois**, quel que soit le filtre (`kpi_calculator_service.dart:184`).
- ⚠️ **Bornes exclusives** : `isAfter(startDate)` exclut une intervention datée exactement du début de période (ex. 1er du mois à 00:00).
- ⚠️ **Page technicien avec valeurs inventées** : ponctualité fixée à 90 %, écart-type 0, radar de compétences vide, email fabriqué ; technicien identifié par son **nom**.
- **Vue admin mixte** : KPI / sites / répartitions viennent de l'API, mais évolution et interventions récentes sont calculées localement → incohérences possibles.
- **KPI admin « Interventions » lit `totalCeMois`** : à vérifier côté back qu'il respecte bien `period`.

### Performance
- ⚠️ **Tous les CRI téléchargés deux fois** par chargement : `_getAllServices` et `_getAllProjets` appellent chacun `getAllCris()`.
- Onglets Sites / Techniciens : toutes les cartes rendues d'un bloc (`Column`), sans liste paginée.

### Ergonomie
- `KpiCard` supporte `trendValue` et `previousCompletionRate` est calculé, mais aucune tendance n'est affichée.
- Périodes limitées à 1 / 7 / 30 jours glissants.
- Pas de recherche ni de tri dans Sites / Techniciens ; lignes « Top Sites » et « Répartition techniciens » non cliquables en vue admin.
- Erreurs affichées brutes (`Text('Erreur: $e')`), sans bouton « Réessayer ».
- Onglet (Général / Sites / Techniciens) non mémorisé ; double espacement (`main_dashboard_page.dart:143-145`) ; seuils responsive incohérents (640 px vs 1000 px).
- Export CSV (`dashboard_csv_service`) existant mais non branché sur le dashboard.

### Code
- `main_dashboard_page.dart` : 1 713 lignes, nombreux doublons (états de chargement, cartes site / technicien en version admin + technicien).
- Fichiers probablement orphelins (à confirmer via `[AUDIT_CLEAN]`) :
  - `features/dashboard/dashboard_screen.dart`
  - `features/dashboard/pages/technician_statistics_page.dart`
  - `features/dashboard/pages/site_details_page.dart`
  - `features/dashboard/widgets/type_distribution_chart_widget.dart`
  - `features/dashboard/widgets/top_sites_list_widget.dart`
  - providers `dashboardKpisProvider`, `timeEvolutionProvider`, `typeDistributionProvider`

### Données sites
- `Site` a `Adresse`, `Ville`, `CodePostal` — **aucune coordonnée GPS**.
- `SiteStatsDto` contient `SiteID`, `Ville` et toutes les stats utiles à la carte.
- Aucun paquet de carte dans `frontend/pubspec.yaml`.

---

## 4. Phases

### Phase 1 — Justesse des chiffres
Branche : `fix/dashboard-kpis`

- [ ] Filtrer « Réalisées » et « En cours » sur la période
- [ ] Renseigner « Prévues » ou retirer la carte si la notion n'existe pas côté données
- [ ] Bornes inclusives (`!isBefore(start)`) partout dans `kpi_calculator_service.dart`
- [ ] Courbe d'évolution : granularité selon la période (heure / jour / semaine / mois)
- [ ] Vérifier `totalCeMois` côté back et le renommer si besoin
- [ ] Page technicien : retirer les valeurs inventées (ponctualité, écart-type, radar, email) en attendant de vraies données ; identifier par ID
- [ ] Tests unitaires `KpiCalculatorService` sur les bornes et le filtrage par période

### Phase 2 — Tout passer par l'API
Branche : `feat/dashboard-api`

- [ ] Back : endpoint évolution temporelle (`GET /api/global/stats/evolution?period=&granularity=`)
- [ ] Back : endpoint interventions récentes (`GET /api/global/stats/recent?limit=`)
- [ ] Back : stats du technicien connecté filtrées par période (vue non-admin)
- [ ] Back : paramètres `from` / `to` en plus de `period` (plage personnalisée)
- [ ] Front : remplacer `DashboardRepository` (calcul local) par des providers API
- [ ] Front : supprimer le double appel `getAllCris()`
- [ ] Mettre à jour `docs/api-summary.md`

### Phase 3 — Ergonomie
Branche : `feat/dashboard-ux`

- [ ] Tendances sur les KPI (vs période précédente)
- [ ] Nouvelles périodes : trimestre, année, plage personnalisée
- [ ] Recherche + tri (CRI, récurrence, heures) dans Sites et Techniciens
- [ ] Listes paginées / `SliverList` au lieu de `Column`
- [ ] Lignes admin cliquables vers les dashboards site / technicien
- [ ] Widget d'erreur commun avec bouton « Réessayer »
- [ ] Mémoriser l'onglet actif (comme la période)
- [ ] Bouton d'export CSV
- [ ] Seuils responsive unifiés via `Responsive`

### Phase 4 — Alertes
Branche : `feat/dashboard-alertes`

- [ ] Back : endpoint `GET /api/global/stats/alerts` :
  - sites avec récurrence > 20 %
  - CRI non résolus depuis plus de X jours (X configurable)
  - escalades niveau 2 sur la période
- [ ] Front : bandeau d'alertes en haut de la vue Général, chaque alerte cliquable

### Phase 5 — Carte des sites
Branche : `feat/sites-map`

**Backend**
- [ ] `Site` : `Latitude`, `Longitude` (`double?`), `GeocodageScore` (`double?`), `GeocodeLe` (`DateTime?`), `CoordonneesManuelles` (`bool`) + migration
- [ ] Service de géocodage (API Adresse / Géoplateforme) :
  - à la création / modification d'adresse d'un site (sauf si `CoordonneesManuelles`)
  - score < 0,5 → coordonnées non enregistrées, site marqué « à vérifier »
  - repli sur le centre de la commune si seule la ville est connue
- [ ] Endpoint admin `POST /api/sites/geocode` : rattrapage des sites existants (mode CSV groupé)
- [ ] Lancer le rattrapage sur la base de dev et mesurer le taux de réussite
- [ ] `SiteStatsDto` : ajouter `Latitude`, `Longitude`

**Frontend**
- [ ] Paquets : `flutter_map`, `latlong2`, `flutter_map_marker_cluster`
- [ ] `SitesMapWidget` :
  - fond Plan IGN
  - taille du marqueur = nombre de CRI sur la période
  - couleur = taux de récurrence (seuils §2)
  - regroupement des marqueurs au dézoom
  - clic → panneau : site, client, CRI, récurrence, dernière intervention, bouton « Voir le site »
- [ ] Onglet Sites : bascule Liste / Carte ; côte à côte sur desktop (clic liste → centrage carte)
- [ ] Bandeau « N sites non localisés » avec lien de correction
- [ ] Route `/dashboard/site/:siteId` basée sur `SiteID`

**Plus tard (optionnel)**
- [ ] Correction manuelle : déplacement du marqueur sur la fiche site (`CoordonneesManuelles = true`)

### Phase 6 — Nettoyage
Branche : `refactor/dashboard`

- [ ] Découper `main_dashboard_page.dart` en widgets (`admin_general_view`, `sites_view`, `technicians_view`, `section_card`, `async_card`)
- [ ] Un seul widget de carte site et un seul de carte technicien (fin des doublons admin / technicien)
- [ ] `[AUDIT_CLEAN]` puis suppression des fichiers orphelins validés
- [ ] Mettre à jour `docs/architecture.md` et `docs/conventions.md`

---

## 5. Ordre recommandé

1. **Phase 1** — des chiffres faux font plus de tort qu'un dashboard incomplet
2. **Phase 2** — prérequis des phases 3 à 5 (données serveur, plage personnalisée)
3. **Phase 5** étape back (géocodage) peut démarrer en parallèle : elle est indépendante et révèle vite la qualité des adresses
4. Phases 3, 4, puis 6

## 6. Risques

- **Qualité des adresses** : si beaucoup de sites n'ont que la ville, la carte sera précise à la commune seulement. Mesurer en phase 5 avant d'investir dans la correction manuelle.
- **Route site** : passer du nom à l'ID casse les liens existants vers `/dashboard/site/<nom>` → vérifier tous les `pushNamed('site-dashboard')`.
- **Fond de carte** : respecter les conditions d'utilisation de la Géoplateforme (attribution IGN obligatoire sur la carte).
