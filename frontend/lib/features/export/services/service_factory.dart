import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

import 'service_factory_stub.dart'
    if (dart.library.io) 'service_factory_native.dart'
    if (dart.library.js_interop) 'service_factory_web.dart'
    if (dart.library.html) 'service_factory_web.dart';

BasePdfGeneratorService getPdfService(AppDatabase db) => createPdfService(db);
BaseFileManagementService getFileService(AppDatabase db) => createFileManagementService(db);
