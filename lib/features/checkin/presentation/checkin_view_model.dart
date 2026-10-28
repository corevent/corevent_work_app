import 'package:flutter/foundation.dart';

import '../data/checkin_repository.dart';
import '../domain/checkin_outcome.dart';

class CheckinViewModel extends ChangeNotifier {
  CheckinViewModel(this._repository, this.eventId, {DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final CheckinRepository _repository;
  final String eventId;
  final DateTime Function() _now;
  bool busy = false;
  bool _disposed = false;
  int _revision = 0;
  CheckinOutcome? outcome;
  String? _lastToken;
  DateTime? _lastRead;

  bool canScanToken(String token) =>
      !_disposed &&
      !busy &&
      outcome == null &&
      !(token == _lastToken &&
          _lastRead != null &&
          _now().difference(_lastRead!) < const Duration(seconds: 8));

  Future<void> scan(String token, {bool retry = false}) async {
    if (_disposed || busy || (!retry && !canScanToken(token))) return;
    if (retry && outcome?.canRetry != true) return;
    final revision = ++_revision;
    busy = true;
    outcome = null;
    _lastToken = token;
    _lastRead = _now();
    notifyListeners();
    final result = await _repository.submit(eventId, token);
    if (_disposed || revision != _revision) return;
    busy = false;
    outcome = result;
    notifyListeners();
  }

  Future<void> retry() async {
    if (_lastToken != null) await scan(_lastToken!, retry: true);
  }

  void next({bool manual = false}) {
    if (_disposed || busy || outcome?.blocksScanner == true) return;
    outcome = null;
    if (manual) {
      _lastToken = null;
      _lastRead = null;
    }
    notifyListeners();
  }

  void blockAccess() {
    if (_disposed) return;
    _revision++;
    busy = false;
    outcome = const CheckinOutcome.failure(CheckinFailure.accessRevoked);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
