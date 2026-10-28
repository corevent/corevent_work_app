import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/checkin_outcome.dart';
import 'checkin_api.dart';

class CheckinRepository {
  const CheckinRepository(this._api);
  final CheckinApi _api;
  Future<CheckinOutcome> submit(String eventId, String raw) async {
    final token = raw.trim();
    if (!isValidQrToken(token)) {
      return const CheckinOutcome.failure(CheckinFailure.invalid);
    }
    try {
      final record = (await _api.checkin(eventId, CheckinRequest(token))).data;
      if (record.status != 'checked_in') {
        return const CheckinOutcome.failure(CheckinFailure.unavailable);
      }
      return CheckinOutcome.success(record);
    } catch (error) {
      return checkinFailure(error);
    }
  }
}

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(CheckinApi(ref.watch(authorizedDioProvider))),
);
