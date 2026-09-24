import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/api_exception.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';

/// Nombre de CRI soumis en attente de synchronisation serveur.
/// Mis à jour par [SyncService] après chaque passe de synchronisation.
final pendingCriCountProvider = StateProvider<int>((ref) => 0);

/// Compteur incrémenté à chaque passe ayant réellement synchronisé au moins
/// un CRI. Les écrans d'historique l'écoutent pour se recharger : ils vivent
/// dans un `IndexedStack` (leur `initState` ne rejoue pas au changement
/// d'onglet), sans quoi un CRI passé « synced » en arrière-plan garde son
/// badge « Non synchronisé » jusqu'au prochain pull-to-refresh.
final syncTickProvider = StateProvider<int>((ref) => 0);

/// Motif du refus serveur, par identifiant de CRI, pour les seuls échecs
/// **définitifs** (cf. [ApiException.isPermanent]).
///
/// Un CRI refusé pour son contenu — champ hors format, droits insuffisants —
/// restait « Non synchronisé » indéfiniment sans que personne ne sache
/// pourquoi : le motif ne partait qu'en `debugPrint`. Les cartes d'historique
/// observent cette table pour l'afficher. Volontairement en mémoire : le motif
/// est une conséquence de la dernière tentative, pas un état à persister — il
/// est reconstitué à la passe suivante, dès l'ouverture de l'app.
final syncFailuresProvider =
    StateProvider<Map<String, String>>((ref) => const {});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(appDatabaseProvider),
    ref.read(criRemoteRepositoryProvider),
    ref,
  );
});

/// Resynchronise les CRI soumis restés en local (syncStatus 'pending')
/// vers le serveur — au démarrage de l'app et au retour de la connectivité.
///
/// Un CRI soumis sur site sans réseau est sauvegardé localement avec
/// syncStatus 'pending' ; sans ce service, il n'apparaissait jamais dans
/// « Tous les CRI » ni « Mes Documents ».
class SyncService with WidgetsBindingObserver {
  final AppDatabase _db;
  final CriRemoteRepository _remote;
  final Ref _ref;

  /// Intervalle de relance tant qu'il reste des CRI en attente. Un événement
  /// de connectivité n'est qu'une promesse : l'interface est up, la route ou
  /// le DNS pas encore. Sans relance, une passe tombée à ce moment-là laissait
  /// le CRI « pending » jusqu'au prochain redémarrage de l'app.
  static const _retryInterval = Duration(minutes: 2);

  /// Délai laissé au réseau pour devenir réellement utilisable après un
  /// événement « connecté ».
  static const _connectivityGrace = Duration(seconds: 3);

  bool _started = false;
  bool _syncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;

  /// Passes consécutives où tout a échoué. Sert de recul exponentiel sur la
  /// relance périodique : un CRI refusé durablement par le serveur (validation)
  /// ne doit pas repartir toutes les deux minutes avec ses signatures et ses
  /// photos — c'est de la data et de la batterie pour rien.
  int _consecutiveFailures = 0;
  int _ticksSinceLastAttempt = 0;
  static const _maxBackoffTicks = 16; // 2 min × 16 ≈ 32 min

  SyncService(this._db, this._remote, this._ref);

  /// Démarre la synchronisation automatique. Idempotent. Déclencheurs :
  /// - passe immédiate (ouverture de l'app, après login) ;
  /// - retour de connectivité (mobile — connectivity_plus ne gère pas le Web) ;
  /// - retour de l'app au premier plan (l'OS ne délivre pas les événements de
  ///   connectivité à une app en arrière-plan : le réseau revenu pendant que
  ///   le téléphone dormait n'était vu par personne) ;
  /// - relance périodique tant qu'il reste des CRI en attente.
  void start() {
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addObserver(this);

    // Passe initiale (à l'ouverture de l'app, après login)
    unawaited(syncPendingCris());

    if (!kIsWeb) {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final isOnline = !results.contains(ConnectivityResult.none);
        if (isOnline) {
          // Un changement de réseau invalide le diagnostic d'échec précédent.
          _resetBackoff();
          unawaited(Future.delayed(_connectivityGrace, syncPendingCris));
        }
      });
    }

    _retryTimer = Timer.periodic(_retryInterval, (_) {
      _ticksSinceLastAttempt++;
      final requiredTicks = _consecutiveFailures == 0
          ? 1
          : (1 << (_consecutiveFailures - 1)).clamp(1, _maxBackoffTicks);
      if (_ticksSinceLastAttempt < requiredTicks) return;
      _ticksSinceLastAttempt = 0;
      unawaited(_syncIfPending());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetBackoff();
      unawaited(_syncIfPending());
    }
  }

  void _resetBackoff() {
    _consecutiveFailures = 0;
    _ticksSinceLastAttempt = 0;
  }

  /// Relance immédiate demandée par l'utilisateur (bouton « Réessayer »).
  /// Court-circuite le recul exponentiel : si quelqu'un vient de corriger la
  /// cause du refus, il ne doit pas attendre la prochaine fenêtre.
  Future<int> retryNow() {
    _resetBackoff();
    return syncPendingCris();
  }

  /// Mémorise le motif d'un refus **définitif** pour l'afficher sur la carte
  /// du CRI. Un échec réseau efface au contraire un motif précédent : il ne
  /// dit rien du contenu, et laisser l'ancien message affiché induirait en
  /// erreur.
  void _recordFailure(String id, Object error) {
    final notifier = _ref.read(syncFailuresProvider.notifier);
    if (error is ApiException && error.isPermanent) {
      notifier.state = {...notifier.state, id: error.message};
    } else {
      _clearFailure(id);
    }
  }

  void _clearFailure(String id) {
    final notifier = _ref.read(syncFailuresProvider.notifier);
    if (!notifier.state.containsKey(id)) return;
    notifier.state = {...notifier.state}..remove(id);
  }

  /// Passe de synchronisation seulement s'il reste quelque chose à pousser —
  /// évite un appel réseau inutile toutes les deux minutes.
  Future<void> _syncIfPending() async {
    if (_syncing) return;
    final pending = await refreshPendingCount();
    if (pending == 0) return;
    await syncPendingCris();
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
  }

  /// Pousse vers le serveur tous les CRI soumis (non-brouillons) restés en
  /// 'pending'. Retourne le nombre de CRI synchronisés avec succès.
  Future<int> syncPendingCris() async {
    if (_syncing) return 0;
    _syncing = true;
    var synced = 0;
    var attempted = 0;
    try {
      final services = await _db.getAllCriService();
      for (final row in services.where(_needsSync)) {
        attempted++;
        try {
          final model = CriServiceModel.fromDb(row);
          await _remote.saveCriService(model);
          // Pas de try/catch : un envoi de photos en échec doit laisser le CRI
          // « pending » pour que SyncService le rejoue. L'ancien catch (_) {}
          // le marquait « synced » et les photos n'étaient jamais envoyées.
          // Rejouer est sans risque : le serveur ignore les photos déjà reçues.
          if (model.photos.isNotEmpty) {
            await _remote.uploadPhotos(model.id, model.photos);
          }
          await _db.updateCriService(
            model.copyWith(syncStatus: 'synced').toDb(),
          );
          _clearFailure(model.id);
          synced++;
        } catch (e) {
          debugPrint('Sync CRI Service ${row.id} échouée: $e');
          _recordFailure(row.id, e);
        }
      }

      final projets = await _db.getAllCriProjet();
      for (final row in projets.where(_needsSync)) {
        attempted++;
        try {
          final model = CriProjetModel.fromDb(row);
          await _remote.saveCriProjet(model);
          // Pas de try/catch : un envoi de photos en échec doit laisser le CRI
          // « pending » pour que SyncService le rejoue. L'ancien catch (_) {}
          // le marquait « synced » et les photos n'étaient jamais envoyées.
          // Rejouer est sans risque : le serveur ignore les photos déjà reçues.
          if (model.photos.isNotEmpty) {
            await _remote.uploadPhotos(model.id, model.photos);
          }
          await _db.updateCriProjet(
            model.copyWith(syncStatus: 'synced').toDb(),
          );
          _clearFailure(model.id);
          synced++;
        } catch (e) {
          debugPrint('Sync CRI Projet ${row.id} échouée: $e');
          _recordFailure(row.id, e);
        }
      }

      await refreshPendingCount();
    } finally {
      _syncing = false;
    }

    if (synced > 0) {
      _resetBackoff();
      // Prévient les écrans déjà construits qu'un badge « Non synchronisé »
      // vient de tomber — ils ne se rechargent pas tout seuls.
      _ref.read(syncTickProvider.notifier).state++;
    } else if (attempted > 0) {
      _consecutiveFailures++;
    }
    return synced;
  }

  bool _needsSync(dynamic row) => !row.isDraft && row.syncStatus == 'pending';

  /// Recompte les CRI soumis encore en attente et met à jour le provider.
  Future<int> refreshPendingCount() async {
    final services = await _db.getAllCriService();
    final projets = await _db.getAllCriProjet();
    final count =
        services.where(_needsSync).length + projets.where(_needsSync).length;
    _ref.read(pendingCriCountProvider.notifier).state = count;
    return count;
  }
}
