import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_models.dart';
import '../../../core/presentation/paged_view_model.dart';
import '../data/invitation.dart';
import '../data/invitations_repository.dart';

class InvitationsViewModel extends PagedViewModel<Invitation> {
  InvitationsViewModel(this.repository);
  final InvitationsRepository repository;
  @override
  Future<ApiPage<Invitation>> fetch(int page) => repository.list(page);
  @override
  String identity(Invitation value) => value.id;
}

final invitationsViewModelProvider = Provider.autoDispose<InvitationsViewModel>(
  (ref) {
    final model = InvitationsViewModel(
      ref.watch(invitationsRepositoryProvider),
    );
    ref.onDispose(model.dispose);
    return model;
  },
);
