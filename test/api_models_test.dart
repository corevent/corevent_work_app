import 'package:corevent_work_app/core/network/api_models.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resposta vazia com currentPage vira pagina vazia sem erro', () {
    final result = ApiPage<StaffEvent>.fromJson({
      'data': <Object>[],
      'meta': {
        'currentPage': 1,
        'itemsPerPage': 20,
        'totalItems': 0,
        'totalPages': 0,
      },
    }, (value) => StaffEvent.fromJson(value! as Map<String, dynamic>));
    expect(result.data, isEmpty);
    expect(result.meta.page, 1);
    expect(result.meta.limit, 20);
    expect(result.meta.totalItems, 0);
    expect(result.meta.totalPages, 0);
    expect(result.meta.hasMore, isFalse);
  });
  test('aceita metadados reais com numeros serializados como texto', () {
    final meta = PageMeta.fromJson({
      'currentPage': '1',
      'itemsPerPage': '20',
      'totalItems': '30',
      'totalPages': '2',
    });
    expect(meta.page, 1);
    expect(meta.hasMore, isTrue);
  });
  test('metadados invalidos continuam sendo erro em vez de lista vazia', () {
    expect(
      () => PageMeta.fromJson({
        'currentPage': 1,
        'itemsPerPage': 20,
        'totalItems': null,
        'totalPages': 0,
      }),
      throwsFormatException,
    );
  });
}
