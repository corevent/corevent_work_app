import 'package:dio/dio.dart';

import '../data/checkin_api.dart';

enum CheckinFailure {
  alreadyUsed,
  wrongEvent,
  cancelled,
  unpaid,
  invalid,
  connection,
  unavailable,
  accessRevoked,
  sessionExpired,
  rateLimited,
}

class CheckinOutcome {
  const CheckinOutcome.success(this.record) : failure = null;
  const CheckinOutcome.failure(this.failure) : record = null;
  final CheckinRecord? record;
  final CheckinFailure? failure;
  bool get success => record != null;
  bool get canRetry => const [
    CheckinFailure.connection,
    CheckinFailure.unavailable,
    CheckinFailure.rateLimited,
  ].contains(failure);
  bool get blocksScanner => const [
    CheckinFailure.accessRevoked,
    CheckinFailure.sessionExpired,
  ].contains(failure);
  bool get autoResume => !canRetry && !blocksScanner;
  String get title => switch (failure) {
    null => 'Check-in confirmado',
    CheckinFailure.alreadyUsed => 'Ingresso já utilizado',
    CheckinFailure.wrongEvent => 'Ingresso de outro evento',
    CheckinFailure.cancelled => 'Ingresso cancelado',
    CheckinFailure.unpaid => 'Pagamento não confirmado',
    CheckinFailure.invalid => 'Ingresso não aceito',
    CheckinFailure.connection => 'Entrada não confirmada',
    CheckinFailure.unavailable => 'Não foi possível validar',
    CheckinFailure.accessRevoked => 'Seu acesso mudou',
    CheckinFailure.sessionExpired => 'Sua sessão expirou',
    CheckinFailure.rateLimited => 'Aguarde um momento',
  };
  String get description => switch (failure) {
    null => 'Entrada registrada com sucesso.',
    CheckinFailure.alreadyUsed => 'Este ingresso já teve o check-in realizado. Não foi registrada uma nova entrada.',
    CheckinFailure.wrongEvent => 'Este QR Code não pertence ao evento selecionado. Peça o ingresso correto.',
    CheckinFailure.cancelled =>
      'Este ingresso foi cancelado. A entrada não foi registrada.',
    CheckinFailure.unpaid => 'O pedido ainda não tem pagamento confirmado. A entrada não foi registrada.',
    CheckinFailure.invalid => 'O código está inválido ou o ingresso não está disponível para este evento.',
    CheckinFailure.connection => 'A conexão foi interrompida antes da confirmação. Não libere a entrada sem consultar o resultado. Se tentar novamente e a primeira solicitação já tiver sido concluída, o ingresso aparecerá como utilizado.',
    CheckinFailure.unavailable => 'Não foi possível obter uma confirmação do serviço. Consulte o ingresso antes de liberar a entrada.',
    CheckinFailure.accessRevoked => 'Você não tem mais permissão para credenciar neste evento. O atendimento foi interrompido.',
    CheckinFailure.sessionExpired =>
      'Entre novamente para continuar o atendimento.',
    CheckinFailure.rateLimited => 'Há muitas tentativas de leitura. Aguarde um pouco antes de tentar novamente.',
  };
}

bool isValidQrToken(String value) =>
    RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(value);

CheckinOutcome checkinFailure(Object error) {
  if (error is! DioException) {
    return const CheckinOutcome.failure(CheckinFailure.unavailable);
  }
  final code = error.response?.statusCode;
  if (code == null) {
    return const CheckinOutcome.failure(CheckinFailure.connection);
  }
  if (code == 401) {
    return const CheckinOutcome.failure(CheckinFailure.sessionExpired);
  }
  if (code == 403) {
    return const CheckinOutcome.failure(CheckinFailure.accessRevoked);
  }
  if (code == 409) {
    return const CheckinOutcome.failure(CheckinFailure.alreadyUsed);
  }
  if (code == 404) return const CheckinOutcome.failure(CheckinFailure.invalid);
  if (code == 429) {
    return const CheckinOutcome.failure(CheckinFailure.rateLimited);
  }
  if (code == 400) {
    final data = error.response?.data;
    final Object? message = data is Map<String, dynamic>
        ? data['message']
        : null;
    final text =
        (message is List ? message.join(' ') : message?.toString() ?? '')
            .toLowerCase();
    if (text.contains('does not belong') ||
        text.contains('outro evento') ||
        text.contains('não pertence')) {
      return const CheckinOutcome.failure(CheckinFailure.wrongEvent);
    }
    if (text.contains('cancel')) {
      return const CheckinOutcome.failure(CheckinFailure.cancelled);
    }
    if (text.contains('not paid') ||
        text.contains('unpaid') ||
        text.contains('não pago')) {
      return const CheckinOutcome.failure(CheckinFailure.unpaid);
    }
    return const CheckinOutcome.failure(CheckinFailure.invalid);
  }
  return const CheckinOutcome.failure(CheckinFailure.unavailable);
}
