import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/models/site_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_service_form_page.dart';

class FakeAppDatabase implements AppDatabase {
  @override
  Future<bool> updateCriService(dynamic entity) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCriRemoteRepository implements CriRemoteRepository {
  @override
  Future<List<String>> searchClients(String query) async => [];

  @override
  Future<List<SiteModel>> searchSitesFromDatabase(String query) async => [];

  @override
  Future<List<String>> getTechnicians() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorageService extends StorageService {
  @override
  Future<String?> getUserName() async => 'Testeur';
}

Finder _fieldByHint(String hint) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );

void main() {
  testWidgets(
    'Type de demande est vide par défaut et bloque la validation tant que rien n\'est sélectionné',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(FakeAppDatabase()),
            criRemoteRepositoryProvider.overrideWithValue(FakeCriRemoteRepository()),
            dioProvider.overrideWithValue(Dio()),
            storageServiceProvider.overrideWithValue(FakeStorageService()),
          ],
          child: const MaterialApp(home: CriServiceFormPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Étape 0 (Général) : les dates ont déjà une valeur par défaut -> "Suivant" direct
      await tester.tap(find.text('Suivant').hitTestable());
      await tester.pumpAndSettle();

      // Étape 1 (Client) : remplir les seuls champs obligatoires de l'étape
      await tester.enterText(_fieldByHint('Nom du client'), 'Client Test');
      await tester.pump();
      await tester.enterText(_fieldByHint('Ville'), 'Paris');
      await tester.pump();
      await tester.tap(find.text('Suivant').hitTestable());
      await tester.pumpAndSettle();

      // Étape 2 (Demande) : le champ "Type de demande" doit être vide par défaut,
      // pas de valeur pré-sélectionnée ("Dépannage" ou autre)
      for (final type in ServiceRequestType.values) {
        expect(find.text(type.label), findsNothing);
      }
      expect(find.text('Type de demande'), findsOneWidget); // hint affiché, rien sélectionné

      // Tenter de continuer sans rien choisir -> bloqué avec message d'erreur
      await tester.tap(find.text('Suivant').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Type de demande requis'), findsOneWidget);

      // Sélectionner une valeur dans le menu déroulant
      await tester.tap(find.byType(DropdownButton<ServiceRequestType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dépannage').last);
      await tester.pumpAndSettle();

      // Revalider : l'erreur sur ce champ précis doit disparaître
      await tester.tap(find.text('Suivant').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Type de demande requis'), findsNothing);
    },
  );
}
