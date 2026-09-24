import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/config/app_router.dart';

/// Étape 2.5 du plan de remédiation : garde d'authentification du routeur.
void main() {
  String? guard(String url, {bool authenticated = false}) {
    final uri = Uri.parse(url);
    return AppRouter.authRedirect(
      location: uri.path,
      uri: uri,
      isAuthenticated: authenticated,
    );
  }

  group('AppRouter.authRedirect — sans jeton', () {
    test('une route protégée renvoie vers la connexion en gardant la destination',
        () {
      final target = Uri.parse(guard('/admin')!);
      expect(target.path, AppRouter.login);
      expect(target.queryParameters['from'], '/admin');
    });

    test('la destination conserve ses paramètres', () {
      final target = Uri.parse(guard('/history?site=Lyon')!);
      expect(target.queryParameters['from'], '/history?site=Lyon');
    });

    test('toutes les routes non publiques sont gardées', () {
      for (final route in [
        AppRouter.dashboard,
        AppRouter.documents,
        '/cri/new/service',
        '/cri/edit/42?type=projet',
        '/dashboard/site/7',
      ]) {
        expect(Uri.parse(guard(route)!).path, AppRouter.login, reason: route);
      }
    });

    test("l'accueil renvoie vers la connexion sans paramètre superflu", () {
      expect(guard(AppRouter.home), AppRouter.login);
    });

    test('connexion et vérification OTP restent accessibles', () {
      expect(guard(AppRouter.login), isNull);
      expect(guard('${AppRouter.verifyOtp}?email=a@b.fr'), isNull);
    });
  });

  test('avec jeton, aucune redirection', () {
    expect(guard('/admin', authenticated: true), isNull);
  });

  group('AppRouter.afterLogin', () {
    test('retourne à la destination interne demandée', () {
      expect(AppRouter.afterLogin('/history?site=Lyon'), '/history?site=Lyon');
    });

    test("retombe sur l'accueil sans destination", () {
      expect(AppRouter.afterLogin(null), AppRouter.home);
      expect(AppRouter.afterLogin(''), AppRouter.home);
    });

    test('refuse toute destination externe (redirection ouverte)', () {
      for (final from in [
        'https://evil.example',
        '//evil.example/admin',
        'javascript:alert(1)',
        'evil.example',
      ]) {
        expect(AppRouter.afterLogin(from), AppRouter.home, reason: from);
      }
    });

    test("ne renvoie pas vers l'écran de connexion lui-même", () {
      expect(AppRouter.afterLogin(AppRouter.login), AppRouter.home);
      expect(AppRouter.afterLogin('${AppRouter.verifyOtp}?email=x'), AppRouter.home);
    });
  });
}
