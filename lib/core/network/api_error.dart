import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Não foi possível conectar. Confira sua conexão e tente novamente.';
    }
    return switch (error.response?.statusCode) {
      401 => 'Sua sessão expirou. Entre novamente para continuar.',
      403 => 'Seu acesso a este evento mudou. Volte aos seus eventos.',
      404 => 'Esta informação não está mais disponível.',
      429 => 'Muitas tentativas. Aguarde um pouco e tente novamente.',
      _ => 'Não foi possível carregar os dados. Tente novamente.',
    };
  }
  return 'Não foi possível carregar os dados. Tente novamente.';
}

bool isAccessDenied(Object error) =>
    error is DioException && error.response?.statusCode == 403;
