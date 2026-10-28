import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_models.dart';
import '../../auth/data/auth_providers.dart';
import 'participant.dart';
import 'participants_api.dart';

class ParticipantsRepository {
  const ParticipantsRepository(this._api);
  final ParticipantsApi _api;
  Future<ApiPage<Participant>> list(String eventId, int page) =>
      _api.list(eventId, page, 20);
  Future<ParticipantDetails> details(String eventId, String userId) async =>
      (await _api.details(eventId, userId)).data;
}

final participantsRepositoryProvider = Provider<ParticipantsRepository>(
  (ref) =>
      ParticipantsRepository(ParticipantsApi(ref.watch(authorizedDioProvider))),
);
final participantDetailsProvider = FutureProvider.autoDispose
    .family<ParticipantDetails, ({String eventId, String userId})>(
      (ref, ids) => ref
          .watch(participantsRepositoryProvider)
          .details(ids.eventId, ids.userId),
    );
