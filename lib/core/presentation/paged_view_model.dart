import 'package:flutter/foundation.dart';

import '../network/api_error.dart';
import '../network/api_models.dart';

@immutable
class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.loading = true,
    this.refreshing = false,
    this.loadingMore = false,
    this.error,
    this.actionError,
    this.meta,
    this.accessDenied = false,
  });
  final List<T> items;
  final bool loading;
  final bool refreshing;
  final bool loadingMore;
  final String? error;
  final String? actionError;
  final PageMeta? meta;
  final bool accessDenied;
  bool get hasMore => meta?.hasMore ?? false;
}

abstract class PagedViewModel<T> extends ChangeNotifier {
  PagedState<T> state = PagedState<T>();
  int _revision = 0;
  bool _disposed = false;
  Future<ApiPage<T>> fetch(int page);
  String identity(T value);

  Future<void> load({bool refresh = false}) async {
    if (_disposed) return;
    final revision = ++_revision;
    final previous = state.items;
    state = PagedState<T>(
      items: previous,
      loading: previous.isEmpty,
      refreshing: previous.isNotEmpty,
      meta: state.meta,
    );
    notifyListeners();
    try {
      final response = await fetch(1);
      if (_disposed || revision != _revision) return;
      final unique = <String, T>{
        for (final item in response.data) identity(item): item,
      };
      state = PagedState<T>(
        items: List.unmodifiable(unique.values),
        loading: false,
        meta: response.meta,
      );
    } catch (error) {
      if (_disposed || revision != _revision) return;
      state = PagedState<T>(
        items: previous,
        loading: false,
        meta: state.meta,
        error: previous.isEmpty ? apiErrorMessage(error) : null,
        actionError: previous.isNotEmpty ? apiErrorMessage(error) : null,
        accessDenied: isAccessDenied(error),
      );
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_disposed ||
        state.loading ||
        state.refreshing ||
        state.loadingMore ||
        !state.hasMore) {
      return;
    }
    final revision = _revision;
    final previous = state;
    state = PagedState<T>(
      items: previous.items,
      loading: false,
      loadingMore: true,
      meta: previous.meta,
    );
    notifyListeners();
    try {
      final response = await fetch(previous.meta!.page + 1);
      if (_disposed || revision != _revision) return;
      final merged = <String, T>{
        for (final item in [...previous.items, ...response.data])
          identity(item): item,
      };
      state = PagedState<T>(
        items: List.unmodifiable(merged.values),
        loading: false,
        meta: response.meta,
      );
    } catch (error) {
      if (_disposed || revision != _revision) return;
      state = PagedState<T>(
        items: previous.items,
        loading: false,
        meta: previous.meta,
        actionError: apiErrorMessage(error),
        accessDenied: isAccessDenied(error),
      );
    }
    notifyListeners();
  }

  void remove(String id) {
    if (_disposed) return;
    state = PagedState<T>(
      items: List.unmodifiable(
        state.items.where((item) => identity(item) != id),
      ),
      loading: false,
      meta: state.meta,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }
}
