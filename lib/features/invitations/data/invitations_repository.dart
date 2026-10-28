import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_models.dart';
import '../../auth/data/auth_providers.dart';
import 'invitation.dart';
import 'invitations_api.dart';

class InvitationsRepository {
  const InvitationsRepository(this._api);
  final InvitationsApi _api;
  Future<ApiPage<Invitation>> list(int page) => _api.list(page, 20, 'pending');
  Future<StaffMembership> accept(String id) async =>
      (await _api.accept(id)).data;
  Future<void> reject(String id) => _api.reject(id);
}

final invitationsRepositoryProvider = Provider<InvitationsRepository>(
  (ref) =>
      InvitationsRepository(InvitationsApi(ref.watch(authorizedDioProvider))),
);
final pendingInvitationsProvider =
    FutureProvider.autoDispose<ApiPage<Invitation>>(
      (ref) => ref.watch(invitationsRepositoryProvider).list(1),
    );
