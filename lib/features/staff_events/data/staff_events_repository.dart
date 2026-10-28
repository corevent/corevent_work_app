import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_models.dart';
import '../../auth/data/auth_providers.dart';
import 'staff_event.dart';
import 'staff_events_api.dart';

class StaffEventsRepository {
  const StaffEventsRepository(this._api);
  final StaffEventsApi _api;
  Future<ApiPage<StaffEvent>> list({
    int page = 1,
    StaffEventStatus status = StaffEventStatus.opened,
    String? search,
  }) => _api.list(page, 20, status.name, search);
  Future<StaffEvent> details(String id) async => (await _api.details(id)).data;

  // Detail endpoints do not return the caller's accessLevel. Resolve it from
  // actual accepted memberships, including events on later pages.
  Future<StaffEvent> membership(String id) async {
    for (final status in StaffEventStatus.values) {
      var page = 1;
      while (true) {
        final result = await _api.list(page, 100, status.name, null);
        for (final event in result.data) {
          if (event.id == id) return event;
        }
        if (!result.meta.hasMore) break;
        page++;
      }
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/api/events/my/staff'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/api/events/my/staff'),
        statusCode: 403,
      ),
    );
  }
}

final staffEventsRepositoryProvider = Provider<StaffEventsRepository>(
  (ref) =>
      StaffEventsRepository(StaffEventsApi(ref.watch(authorizedDioProvider))),
);
final eventAccessProvider = FutureProvider.autoDispose
    .family<StaffEvent, String>(
      (ref, id) => ref.watch(staffEventsRepositoryProvider).membership(id),
    );
final eventDetailsProvider = FutureProvider.autoDispose
    .family<StaffEvent, String>(
      (ref, id) => ref.watch(staffEventsRepositoryProvider).details(id),
    );
