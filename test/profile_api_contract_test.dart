import 'dart:typed_data';

import 'package:corevent_work_app/features/auth/data/auth_api.dart';
import 'package:corevent_work_app/features/profile/data/avatar_api.dart';
import 'package:corevent_work_app/features/profile/data/avatar_repository.dart';
import 'package:corevent_work_app/features/profile/data/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = <String, Object>{
    'id': 'user',
    'name': 'Ana Souza',
    'email': 'ana@example.com',
    'avatarUrl': 'https://storage.invalid/avatar.jpg',
  };
  test(
    'perfil e senha usam as mesmas rotas e campos do app principal',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.invalid'));
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: request,
                statusCode: 200,
                data: request.path == '/api/users'
                    ? {'data': user}
                    : {'message': 'Senha atualizada.'},
              ),
            );
          },
        ),
      );
      final repository = ProfileRepository(ProfileApi(dio));
      final profile = await repository.updateFields({
        'name': 'Ana Souza',
        'phoneNumber': null,
      });
      await repository.changePassword('Atual!123', 'Nova!1234');
      expect(profile.name, 'Ana Souza');
      expect(requests[0].method, 'PATCH');
      expect(requests[0].path, '/api/users');
      expect(requests[0].data, {'name': 'Ana Souza', 'phoneNumber': null});
      expect(requests[1].method, 'PATCH');
      expect(requests[1].path, '/api/users/pass');
      expect(requests[1].data, {
        'currentPassword': 'Atual!123',
        'newPassword': 'Nova!1234',
      });
    },
  );
  test('foto usa presign, PUT sem Bearer e confirmacao por key', () async {
    const signed =
        'https://storage.invalid/avatars/user/foto.jpg?signature=abc%2B123';
    final requests = <RequestOptions>[];
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.invalid',
        headers: {'Authorization': 'Bearer api-token'},
      ),
    );
    final uploadDio = Dio();
    addTearDown(() => dio.close(force: true));
    addTearDown(() => uploadDio.close(force: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: request,
              statusCode: 200,
              data: request.path == '/api/storage/presign'
                  ? {
                      'data': {
                        'uploadUrl': signed,
                        'key': 'avatars/user/foto.jpg',
                        'publicUrl': user['avatarUrl'],
                        'expiresIn': 600,
                      },
                    }
                  : {'data': user},
            ),
          );
        },
      ),
    );
    uploadDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          expect(request.method, 'PUT');
          expect(request.uri.toString(), signed);
          expect(request.headers['Authorization'], isNull);
          expect(request.contentType, 'image/jpeg');
          handler.resolve(
            Response<void>(requestOptions: request, statusCode: 200),
          );
        },
      ),
    );
    final repository = AvatarRepository(AvatarApi(dio), uploadDio);
    final key = await repository.upload(Uint8List.fromList([1, 2, 3]), (_) {});
    final profile = await repository.confirm(key);
    expect(profile.avatarUrl, user['avatarUrl']);
    expect(requests[0].method, 'POST');
    expect(requests[0].path, '/api/storage/presign');
    expect(requests[0].data, {
      'purpose': 'avatar',
      'contentType': 'image/jpeg',
    });
    expect(requests[2].method, 'PATCH');
    expect(requests[2].path, '/api/users/me/avatar');
    expect(requests[2].data, {'key': 'avatars/user/foto.jpg'});
  });
}
