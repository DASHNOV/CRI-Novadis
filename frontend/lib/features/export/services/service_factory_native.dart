import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// On utilise des imports conditionnels même dans le fichier "native" pour que le compilateur Web
// ne tente pas de résoudre les dépendances (path_provider, etc.) si elles sont supprimées du pubspec.yaml

// Note: Cette syntaxe d'import multiple conditionnel n'est pas standard pour l'instanciation.
// On va plutôt utiliser une approche plus directe en gardant les imports mais en s'assurant 
// que le script de build Vercel nettoie bien le tout.

// En fait, le problème vient souvent du fait que dart2js analyse TOUS les fichiers importés.
// Si on veut vraiment que ça marche, le fichier native ne doit PAS être importé du tout sur le web.
// C'est déjà ce que fait service_factory.dart.

// On revient à une version simple pour le moment, le nettoyage du pubspec.yaml devrait suffire.
import 'pdf_generator_native.dart';
import 'file_management_native.dart';

BasePdfGeneratorService createPdfService(AppDatabase db) => PdfGeneratorService(db);
BaseFileManagementService createFileManagementService(AppDatabase db) => FileManagementService(db);
