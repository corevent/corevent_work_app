import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_models.dart';
import '../../../core/presentation/paged_view_model.dart';
import '../data/staff_event.dart';
import '../data/staff_events_repository.dart';

class EventsViewModel extends PagedViewModel<StaffEvent> {
  EventsViewModel(this._repository);
  final StaffEventsRepository _repository;
  StaffEventStatus status = StaffEventStatus.opened;
  @override
  Future<ApiPage<StaffEvent>> fetch(int page) =>
      _repository.list(page: page, status: status);
  @override
  String identity(StaffEvent value) => value.id;
  Future<void> selectStatus(StaffEventStatus value) async {
    if (status == value) return;
    status = value;
    state = const PagedState<StaffEvent>();
    await load();
  }
}

final eventsViewModelProvider = Provider.autoDispose<EventsViewModel>((ref) {
  final model = EventsViewModel(ref.watch(staffEventsRepositoryProvider));
  ref.onDispose(model.dispose);
  return model;
});
