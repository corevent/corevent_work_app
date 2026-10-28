import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../data/invitation.dart';
import '../data/invitations_repository.dart';

class InvitationDecisionViewModel extends ChangeNotifier {
  InvitationDecisionViewModel(this.repository, this.invitationId);
  final InvitationsRepository repository;
  final String invitationId;
  bool busy = false;
  bool _disposed = false;
  String? error;
  StaffMembership? accepted;
  Future<bool> decide({required bool accept}) async {
    if (busy || accepted != null) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (accept) {
        accepted = await repository.accept(invitationId);
      } else {
        await repository.reject(invitationId);
      }
      return true;
    } catch (cause) {
      if (!_disposed) error = apiErrorMessage(cause);
      return false;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
