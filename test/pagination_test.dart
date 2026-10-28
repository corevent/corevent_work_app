import 'dart:async';

import 'package:corevent_work_app/core/network/api_models.dart';
import 'package:corevent_work_app/core/presentation/paged_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class Pages extends PagedViewModel<String> {
  Pages(this.loader);
  final Future<ApiPage<String>> Function(int) loader;
  @override
  Future<ApiPage<String>> fetch(int page) => loader(page);
  @override
  String identity(String value) => value;
}

ApiPage<String> page(List<String> items, int current, int total) => ApiPage(
  data: items,
  meta: PageMeta(
    page: current,
    limit: 20,
    totalItems: total * 20,
    totalPages: total,
  ),
);

void main() {
  test('paginação acrescenta sem duplicar', () async {
    final model = Pages(
      (n) async => n == 1 ? page(['a', 'b'], 1, 2) : page(['b', 'c'], 2, 2),
    );
    addTearDown(model.dispose);
    await model.load();
    await model.loadMore();
    expect(model.state.items, ['a', 'b', 'c']);
    expect(model.state.hasMore, isFalse);
  });
  test('atualização com erro preserva dados e sinaliza toast', () async {
    var calls = 0;
    final model = Pages((_) async {
      if (calls++ == 0) return page(['a'], 1, 1);
      throw StateError('offline');
    });
    addTearDown(model.dispose);
    await model.load();
    await model.load(refresh: true);
    expect(model.state.items, ['a']);
    expect(model.state.error, isNull);
    expect(model.state.actionError, isNotNull);
    expect(model.state.refreshing, isFalse);
  });
  test('ignora resposta antiga ao trocar filtro', () async {
    final first = Completer<ApiPage<String>>();
    var calls = 0;
    final model = Pages(
      (_) => calls++ == 0 ? first.future : Future.value(page(['new'], 1, 1)),
    );
    addTearDown(model.dispose);
    final stale = model.load();
    await model.load();
    first.complete(page(['old'], 1, 1));
    await stale;
    expect(model.state.items, ['new']);
  });
  test('erro ao carregar mais mantém página para nova tentativa', () async {
    var failed = false;
    final model = Pages((n) async {
      if (n == 2 && !failed) {
        failed = true;
        throw StateError('offline');
      }
      return page(n == 1 ? ['a'] : ['b'], n, 2);
    });
    addTearDown(model.dispose);
    await model.load();
    await model.loadMore();
    expect(model.state.items, ['a']);
    expect(model.state.meta?.page, 1);
    await model.loadMore();
    expect(model.state.items, ['a', 'b']);
  });
  test('dispose ignora requisições pendentes', () async {
    final result = Completer<ApiPage<String>>();
    final model = Pages((_) => result.future);
    final pending = model.load();
    model.dispose();
    result.complete(page(['a'], 1, 1));
    await pending;
    expect(model.state.items, isEmpty);
  });
}
