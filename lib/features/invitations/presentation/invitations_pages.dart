import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/work_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../staff_events/data/staff_events_repository.dart';
import '../../staff_events/presentation/events_view_model.dart';
import '../data/invitation.dart';
import '../data/invitations_repository.dart';
import 'invitation_decision_view_model.dart';
import 'invitations_view_model.dart';

class InvitationsPage extends ConsumerWidget {
  const InvitationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WorkScaffold(
    title: 'Convites',
    body: PagedBody<Invitation>(
      model: ref.watch(invitationsViewModelProvider),
      emptyTitle: 'Tudo em dia',
      emptyDescription: 'Você não tem convites pendentes. Os próximos convites aparecerão aqui.',
      header: const WorkHeading(
        'Convites recebidos',
        description:
            'Confira os eventos e as permissões antes de aceitar ou recusar.',
      ),
      itemBuilder: (invite) => WorkCard(
        onTap: () => context.push('/invitations/${invite.id}', extra: invite),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WorkBadge('Pendente'),
            const SizedBox(height: 16),
            Text(
              invite.event.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Organização: ${invite.organizer.name}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            WorkBadge(
              invite.originalAccessLevel.label,
              tone: invite.originalAccessLevel.canCheckin
                  ? BadgeTone.brand
                  : BadgeTone.neutral,
            ),
          ],
        ),
      ),
    ),
  );
}

class InvitationPage extends ConsumerStatefulWidget {
  const InvitationPage({super.key, required this.invitation});
  final Invitation invitation;
  @override
  ConsumerState<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends ConsumerState<InvitationPage> {
  late final InvitationDecisionViewModel _model;
  @override
  void initState() {
    super.initState();
    _model = InvitationDecisionViewModel(
      ref.read(invitationsRepositoryProvider),
      widget.invitation.id,
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _decide(bool accept) async {
    if (!accept) {
      final confirmed = await confirmDestructive(
        context,
        title: 'Recusar convite?',
        message: 'Você não terá acesso a este evento por este convite.',
        action: 'Recusar',
      );
      if (!confirmed || !mounted) return;
    }
    final ok = await _model.decide(accept: accept);
    if (!mounted || !ok) return;
    ref.invalidate(pendingInvitationsProvider);
    ref.invalidate(invitationsViewModelProvider);
    ref.invalidate(eventsViewModelProvider);
    ref.invalidate(eventAccessProvider(widget.invitation.eventId));
    if (!accept) context.go('/invitations');
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _model,
    builder: (context, _) {
      final invite = widget.invitation;
      if (_model.accepted case final accepted?) {
        return WorkScaffold(
          title: 'Convite aceito',
          body: WorkScroll(
            children: [
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    RemixIcons.checkbox_circle_line,
                    size: 40,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              WorkHeading(
                'Convite aceito',
                description:
                    'Agora você pode colaborar em ${invite.event.title}.',
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: WorkBadge(
                  accepted.accessLevel.label,
                  tone: accepted.accessLevel.canCheckin
                      ? BadgeTone.brand
                      : BadgeTone.neutral,
                ),
              ),
            ],
          ),
          footer: CoreventButton(
            label: 'Voltar aos meus eventos',
            onPressed: () => context.go('/events'),
          ),
        );
      }
      return PopScope(
        canPop: !_model.busy,
        child: WorkScaffold(
          title: 'Convite para colaborar',
          backEnabled: !_model.busy,
          onBack: _model.busy ? () {} : () => context.go('/invitations'),
          body: AbsorbPointer(
            absorbing: _model.busy,
            child: WorkScroll(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: WorkBadge('Convite pendente'),
                ),
                const SizedBox(height: 24),
                WorkHeading(
                  invite.event.title,
                  description:
                      '${invite.organizer.name} convidou você para colaborar neste evento.',
                ),
                const SizedBox(height: 28),
                WorkCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.originalAccessLevel.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        invite.originalAccessLevel.description,
                        style: const TextStyle(
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_model.error != null) ...[
                  const SizedBox(height: 20),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _model.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoreventButton(
                label: 'Aceitar convite',
                onPressed: () => _decide(true),
                busy: _model.busy,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _model.busy ? null : () => _decide(false),
                child: const Text(
                  'Recusar convite',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
