import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/network/api_exception.dart';

DioException _dioError({int? status, dynamic data}) {
  final options = RequestOptions(path: '/CRI');
  return DioException(
    requestOptions: options,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
  );
}

void main() {
  group('ApiException.isPermanent', () {
    test('un échec réseau sans réponse est réessayable', () {
      expect(ApiException.fromDio(_dioError()).isPermanent, isFalse);
    });

    test('un refus de validation (400) est définitif', () {
      expect(ApiException.fromDio(_dioError(status: 400)).isPermanent, isTrue);
    });

    test('un refus de droits (403) est définitif', () {
      expect(ApiException.fromDio(_dioError(status: 403)).isPermanent, isTrue);
    });

    test('un 401 reste réessayable — le jeton est rafraîchi par Dio', () {
      expect(ApiException.fromDio(_dioError(status: 401)).isPermanent, isFalse);
    });

    test('temporisation (408) et limitation de débit (429) sont réessayables',
        () {
      expect(ApiException.fromDio(_dioError(status: 408)).isPermanent, isFalse);
      expect(ApiException.fromDio(_dioError(status: 429)).isPermanent, isFalse);
    });

    test('une erreur serveur (500) est réessayable', () {
      expect(ApiException.fromDio(_dioError(status: 500)).isPermanent, isFalse);
    });
  });

  group('ApiException.fromDio — message', () {
    test('préfère le message métier renvoyé par l\'API', () {
      final e = ApiException.fromDio(
        _dioError(status: 400, data: {'message': 'Statut de CRI invalide'}),
      );
      expect(e.message, 'Statut de CRI invalide');
      expect('$e', 'Statut de CRI invalide');
      expect(e.statusCode, 400);
    });

    test('un 403 sans message annonce un manque de droits, pas un code HTTP',
        () {
      final e = ApiException.fromDio(_dioError(status: 403, data: ''));
      expect(e.message, contains('droits'));
      expect(e.statusCode, 403);
    });

    test("un 403 porteur d'un message métier le conserve", () {
      final e = ApiException.fromDio(
        _dioError(status: 403, data: {'message': "CRI d'un autre technicien"}),
      );
      expect(e.message, "CRI d'un autre technicien");
    });

    test('retombe sur le code HTTP quand le corps ne porte pas de message', () {
      final e = ApiException.fromDio(_dioError(status: 413, data: 'nope'));
      expect(e.message, contains('413'));
      expect(e.isPermanent, isTrue);
    });

    test('détaille les erreurs de validation ASP.NET par champ', () {
      final e = ApiException.fromDio(_dioError(status: 400, data: {
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': {
          'ClientPhone': ['The field ClientPhone must be a string with a maximum length of 20.'],
          'ClientName': ['The ClientName field is required.'],
        },
      }));
      expect(e.message, contains('ClientPhone'));
      expect(e.message, contains('maximum length of 20'));
      expect(e.message, contains('ClientName'));
      expect(e.isPermanent, isTrue);
    });

    test('retombe sur le titre quand ProblemDetails ne detaille aucun champ', () {
      final e = ApiException.fromDio(_dioError(status: 400, data: {
        'title': 'Requête malformée',
        'status': 400,
      }));
      expect(e.message, 'Requête malformée');
    });

    test('le message métier prime sur les erreurs de validation', () {
      final e = ApiException.fromDio(_dioError(status: 400, data: {
        'message': 'Statut de CRI invalide',
        'errors': {'Status': ['nope']},
      }));
      expect(e.message, 'Statut de CRI invalide');
    });

    test('ignore un message vide', () {
      final e = ApiException.fromDio(
        _dioError(status: 400, data: {'message': '   '}),
      );
      expect(e.message, contains('400'));
    });
  });
}
