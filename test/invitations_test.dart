import 'dart:async';

import 'package:corevent_work_app/features/invitations/data/invitation.dart';
import 'package:corevent_work_app/features/invitations/data/invitations_repository.dart';
import 'package:corevent_work_app/features/invitations/presentation/invitation_decision_view_model.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockInvitationsRepository extends Mock implements InvitationsRepository {}

void main() {
  test(
    'aceite usa permissão retornada pela API e bloqueia repetição',
    () async {
      final repo = MockInvitationsRepository();
      when(() => repo.accept('invite')).thenAnswer(
        (_) async => const StaffMembership(
          id: 'membership',
          accessLevel: StaffAccess.readonly,
        ),
      );
      final model = InvitationDecisionViewModel(repo, 'invite');
      addTearDown(model.dispose);
      expect(await model.decide(accept: true), isTrue);
      expect(model.accepted?.accessLevel, StaffAccess.readonly);
      expect(model.busy, isFalse);
      expect(await model.decide(accept: true), isFalse);
      verify(() => repo.accept('invite')).called(1);
    },
  );
  test('não envia duas decisões enquanto a primeira está pendente', () async {
    final repo = MockInvitationsRepository();
    final pending = Completer<StaffMembership>();
    when(() => repo.accept('invite')).thenAnswer((_) => pending.future);
    final model = InvitationDecisionViewModel(repo, 'invite');
    addTearDown(model.dispose);
    final operation = model.decide(accept: true);
    expect(model.busy, isTrue);
    expect(await model.decide(accept: false), isFalse);
    verifyNever(() => repo.reject(any()));
    pending.complete(
      const StaffMembership(id: 'membership', accessLevel: StaffAccess.checkin),
    );
    expect(await operation, isTrue);
  });
  test('falha no aceite mantém convite e permite tentar novamente', () async {
    final repo = MockInvitationsRepository();
    when(() => repo.accept('invite')).thenThrow(StateError('offline'));
    final model = InvitationDecisionViewModel(repo, 'invite');
    addTearDown(model.dispose);
    expect(await model.decide(accept: true), isFalse);
    expect(model.error, isNotNull);
    expect(model.busy, isFalse);
    expect(model.accepted, isNull);
    when(() => repo.accept('invite')).thenAnswer(
      (_) async => const StaffMembership(
        id: 'membership',
        accessLevel: StaffAccess.checkin,
      ),
    );
    expect(await model.decide(accept: true), isTrue);
    expect(model.error, isNull);
  });
  test('recusar usa a operação correta sem criar vínculo', () async {
    final repo = MockInvitationsRepository();
    when(() => repo.reject('invite')).thenAnswer((_) async {});
    final model = InvitationDecisionViewModel(repo, 'invite');
    addTearDown(model.dispose);
    expect(await model.decide(accept: false), isTrue);
    expect(model.accepted, isNull);
    verifyNever(() => repo.accept(any()));
  });
}
