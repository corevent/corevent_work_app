import 'dart:async';

import 'package:corevent_work_app/core/network/api_models.dart';
import 'package:corevent_work_app/features/checkin/data/checkin_api.dart';
import 'package:corevent_work_app/features/checkin/data/checkin_repository.dart';
import 'package:corevent_work_app/features/checkin/domain/checkin_outcome.dart';
import 'package:corevent_work_app/features/checkin/presentation/checkin_view_model.dart';
import 'package:corevent_work_app/features/participants/data/participant.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckinApi extends Mock implements CheckinApi {}

class MockCheckinRepository extends Mock implements CheckinRepository {}

DioException failure(int? code, {Object? message}) {
  final options = RequestOptions(path: '/api/events/event/checkin');
  return DioException(
    requestOptions: options,
    type: code == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: code == null
        ? null
        : Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: code,
            data: {'message': message},
          ),
  );
}

final record = CheckinRecord(
  ticketId: 'ticket',
  status: 'checked_in',
  checkinAt: DateTime.utc(2026, 10, 27, 18),
  user: const PersonSummary(id: 'user', name: 'Participante'),
  ticketType: const TicketType(id: 'type', name: 'Entrada'),
  checkedInBy: const PersonSummary(id: 'staff', name: 'Colaborador'),
);

void main() {
  setUpAll(() => registerFallbackValue(const CheckinRequest('token')));
  test('QR deve ter exatamente 64 caracteres hexadecimais', () {
    expect(isValidQrToken('a' * 64), isTrue);
    expect(isValidQrToken('A1' * 32), isTrue);
    expect(isValidQrToken('a' * 63), isFalse);
    expect(isValidQrToken('g' * 64), isFalse);
    expect(isValidQrToken('https://example.com/${'a' * 64}'), isFalse);
  });
  final errors = <({int? code, Object? message, CheckinFailure result})>[
    (code: 409, message: null, result: CheckinFailure.alreadyUsed),
    (code: 403, message: null, result: CheckinFailure.accessRevoked),
    (code: 401, message: null, result: CheckinFailure.sessionExpired),
    (code: 404, message: null, result: CheckinFailure.invalid),
    (
      code: 400,
      message: 'Ticket does not belong to this event.',
      result: CheckinFailure.wrongEvent,
    ),
    (
      code: 400,
      message: ['Ticket is cancelled.'],
      result: CheckinFailure.cancelled,
    ),
    (code: 400, message: 'Order is not paid.', result: CheckinFailure.unpaid),
    (code: 400, message: null, result: CheckinFailure.invalid),
    (code: 429, message: null, result: CheckinFailure.rateLimited),
    (code: 500, message: null, result: CheckinFailure.unavailable),
    (code: null, message: null, result: CheckinFailure.connection),
  ];
  for (final scenario in errors) {
    test('classifica ${scenario.code}: ${scenario.result.name}', () {
      expect(
        checkinFailure(failure(scenario.code, message: scenario.message))
            .failure,
        scenario.result,
      );
    });
  }
  test(
    'rede e serviço indisponível pausam o totem sem liberação automática',
    () {
      for (final kind in [
        CheckinFailure.connection,
        CheckinFailure.unavailable,
        CheckinFailure.rateLimited,
      ]) {
        final result = CheckinOutcome.failure(kind);
        expect(result.success, isFalse);
        expect(result.autoResume, isFalse);
        expect(result.canRetry, isTrue);
      }
    },
  );
  test('403 e sessão expirada interrompem scanner', () {
    for (final kind in [
      CheckinFailure.accessRevoked,
      CheckinFailure.sessionExpired,
    ]) {
      final result = CheckinOutcome.failure(kind);
      expect(result.blocksScanner, isTrue);
      expect(result.autoResume, isFalse);
      expect(result.canRetry, isFalse);
    }
  });
  test('QR inválido não chama a API', () async {
    final api = MockCheckinApi();
    final result = await CheckinRepository(api).submit('event', 'invalid');
    expect(result.failure, CheckinFailure.invalid);
    verifyNever(() => api.checkin(any(), any()));
  });
  test('check-in usa evento selecionado e token sem espaços', () async {
    final api = MockCheckinApi();
    when(() => api.checkin('event', any()))
        .thenAnswer((_) async => ApiObject(data: record));
    final result = await CheckinRepository(api)
        .submit('event', '  ${'a' * 64}  ');
    expect(result.success, isTrue);
    final request =
        verify(() => api.checkin('event', captureAny())).captured.single
            as CheckinRequest;
    expect(request.qrToken, 'a' * 64);
  });
  test('ViewModel processa uma leitura por vez e aguarda próximo', () async {
    final repository = MockCheckinRepository();
    final pending = Completer<CheckinOutcome>();
    when(() => repository.submit('event', 'a' * 64))
        .thenAnswer((_) => pending.future);
    final model = CheckinViewModel(repository, 'event');
    addTearDown(model.dispose);
    final first = model.scan('a' * 64);
    await model.scan('a' * 64);
    expect(model.busy, isTrue);
    verify(() => repository.submit('event', 'a' * 64)).called(1);
    pending.complete(CheckinOutcome.success(record));
    await first;
    await model.scan('b' * 64);
    verifyNever(() => repository.submit('event', 'b' * 64));
    expect(model.outcome?.success, isTrue);
  });
  test('falha de rede só repete após retry explícito', () async {
    final repository = MockCheckinRepository();
    var calls = 0;
    when(() => repository.submit('event', 'a' * 64)).thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const CheckinOutcome.failure(CheckinFailure.connection)
          : CheckinOutcome.success(record);
    });
    final model = CheckinViewModel(repository, 'event');
    addTearDown(model.dispose);
    await model.scan('a' * 64);
    expect(calls, 1);
    expect(model.outcome?.canRetry, isTrue);
    await model.retry();
    expect(calls, 2);
    expect(model.outcome?.success, isTrue);
  });
  test('dispose durante requisição ignora resposta tardia', () async {
    final repository = MockCheckinRepository();
    final pending = Completer<CheckinOutcome>();
    when(() => repository.submit(any(), any()))
        .thenAnswer((_) => pending.future);
    final model = CheckinViewModel(repository, 'event');
    final operation = model.scan('a' * 64);
    model.dispose();
    pending.complete(CheckinOutcome.success(record));
    await operation;
    expect(model.outcome, isNull);
  });
  test('totem ignora repetição imediata do mesmo código', () async {
    final repository = MockCheckinRepository();
    when(() => repository.submit(any(), any()))
        .thenAnswer((_) async => CheckinOutcome.success(record));
    final model = CheckinViewModel(
      repository,
      'event',
      now: () => DateTime(2026),
    );
    addTearDown(model.dispose);
    await model.scan('a' * 64);
    model.next();
    await model.scan('a' * 64);
    verify(() => repository.submit('event', 'a' * 64)).called(1);
  });
  test('revogação de acesso não é sobrescrita por resposta tardia', () async {
    final repository = MockCheckinRepository();
    final pending = Completer<CheckinOutcome>();
    when(() => repository.submit(any(), any()))
        .thenAnswer((_) => pending.future);
    final model = CheckinViewModel(repository, 'event');
    addTearDown(model.dispose);
    final operation = model.scan('a' * 64);
    model.blockAccess();
    pending.complete(CheckinOutcome.success(record));
    await operation;
    expect(model.outcome?.failure, CheckinFailure.accessRevoked);
    expect(model.busy, isFalse);
  });
}
