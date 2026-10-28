import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_models.dart';
import '../../../core/presentation/paged_view_model.dart';
import '../data/participant.dart';
import '../data/participants_repository.dart';

class ParticipantsViewModel extends PagedViewModel<Participant> {
  ParticipantsViewModel(this.repository, this.eventId);
  final ParticipantsRepository repository;
  final String eventId;
  @override
  Future<ApiPage<Participant>> fetch(int page) =>
      repository.list(eventId, page);
  @override
  String identity(Participant value) => value.id;
}

final participantsViewModelProvider = Provider.autoDispose
    .family<ParticipantsViewModel, String>((ref, eventId) {
      final model = ParticipantsViewModel(
        ref.watch(participantsRepositoryProvider),
        eventId,
      );
      ref.onDispose(model.dispose);
      return model;
    });
