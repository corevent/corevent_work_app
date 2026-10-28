import 'package:corevent_work_app/core/network/api_models.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_event.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_events_api.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_events_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventsApi extends Mock implements StaffEventsApi {}

final event = StaffEvent(
  id: 'event',
  title: 'Evento',
  startDate: DateTime(2026),
  endDate: DateTime(2027),
  accessLevel: StaffAccess.checkin,
);
ApiPage<StaffEvent> page(
  List<StaffEvent> items, {
  int current = 1,
  int pages = 1,
}) => ApiPage(
  data: items,
  meta: PageMeta(
    page: current,
    limit: 100,
    totalItems: items.length,
    totalPages: pages,
  ),
);

void main() {
  test('permissões desconhecidas usam menor privilégio', () {
    final json = <String, dynamic>{
      'id': 'event',
      'title': 'Evento',
      'startDate': '2026-01-01T00:00:00Z',
      'endDate': '2027-01-01T00:00:00Z',
      'accessLevel': 'organizer',
    };
    expect(StaffEvent.fromJson(json).accessLevel, StaffAccess.readonly);
    json.remove('accessLevel');
    expect(StaffEvent.fromJson(json).accessLevel, StaffAccess.readonly);
  });
  test('somente checkin permite credenciar', () {
    expect(StaffAccess.readonly.canCheckin, isFalse);
    expect(StaffAccess.checkin.canCheckin, isTrue);
  });
  test('resolve acesso em páginas posteriores', () async {
    final api = MockEventsApi();
    when(() => api.list(1, 100, 'opened', null))
        .thenAnswer((_) async => page([], pages: 2));
    when(() => api.list(2, 100, 'opened', null))
        .thenAnswer((_) async => page([event], current: 2, pages: 2));
    expect(
      (await StaffEventsRepository(api).membership('event')).accessLevel,
      StaffAccess.checkin,
    );
  });
  test('procura também eventos em andamento', () async {
    final api = MockEventsApi();
    when(() => api.list(1, 100, 'opened', null))
        .thenAnswer((_) async => page([]));
    when(() => api.list(1, 100, 'going', null))
        .thenAnswer((_) async => page([event]));
    expect((await StaffEventsRepository(api).membership('event')).id, 'event');
  });
  test('evento sem vínculo resulta em 403 sem usar detalhes públicos como autorização', () async {
    final api = MockEventsApi();
    when(() => api.list(any(), 100, any(), null))
        .thenAnswer((_) async => page([]));
    await expectLater(
      StaffEventsRepository(api).membership('missing'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          403,
        ),
      ),
    );
    verifyNever(() => api.details(any()));
  });
}
