import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/work_widgets.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../staff_events/presentation/event_access_gate.dart';
import '../data/participant.dart';
import '../data/participants_repository.dart';
import 'participants_view_model.dart';

class ParticipantsPage extends ConsumerWidget {
  const ParticipantsPage({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => EventAccessGate(
    eventId: eventId,
    builder: (event) {
      final model = ref.watch(participantsViewModelProvider(eventId));
      return WorkScaffold(
        title: 'Participantes',
        body: ListenableBuilder(
          listenable: model,
          builder: (context, _) => PagedBody<Participant>(
            model: model,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Selecione uma pessoa para consultar os ingressos.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                ),
                if (model.state.meta != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    '${model.state.meta!.totalItems} participante${model.state.meta!.totalItems == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            emptyTitle: 'Nenhum participante por enquanto',
            emptyDescription: 'Os participantes aparecerão quando houver ingressos elegíveis neste evento.',
            itemBuilder: (person) => WorkCard(
              onTap: () =>
                  context.push('/events/$eventId/participants/${person.id}'),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    RemixIcons.user_line,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          person.email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${person.ticketsCount} ingresso${person.ticketsCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(RemixIcons.arrow_right_s_line, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ParticipantDetailsPage extends ConsumerWidget {
  const ParticipantDetailsPage({
    super.key,
    required this.eventId,
    required this.userId,
  });
  final String eventId;
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (eventId: eventId, userId: userId);
    return EventAccessGate(
      eventId: eventId,
      builder: (event) => WorkScaffold(
        title: 'Dados do ingresso',
        body: ref
            .watch(participantDetailsProvider(key))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => WorkState(
                title: isAccessDenied(error)
                    ? 'Seu acesso mudou'
                    : 'Não foi possível consultar',
                description: apiErrorMessage(error),
                error: true,
                action: isAccessDenied(error)
                    ? 'Voltar aos eventos'
                    : 'Tentar novamente',
                onAction: () {
                  if (isAccessDenied(error)) {
                    context.go('/events');
                  } else {
                    ref.invalidate(participantDetailsProvider(key));
                  }
                },
              ),
              data: (details) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(participantDetailsProvider(key));
                  await ref.read(participantDetailsProvider(key).future);
                },
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    WorkHeading(
                      details.user.name,
                      description: details.user.email,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${details.tickets.length} ingresso${details.tickets.length == 1 ? '' : 's'} neste evento',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final ticket in details.tickets) ...[
                      TicketDetailsCard(ticket: ticket),
                      const SizedBox(height: 16),
                    ],
                    if (details.tickets.isEmpty)
                      const Text('Nenhum ingresso disponível.'),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class TicketDetailsCard extends StatelessWidget {
  const TicketDetailsCard({super.key, required this.ticket});
  final ParticipantTicket ticket;
  @override
  Widget build(BuildContext context) => WorkCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticket.ticketType.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 14),
        WorkBadge(
          ticket.label,
          tone: ticket.cancelled
              ? BadgeTone.error
              : ticket.checkedIn
              ? BadgeTone.success
              : BadgeTone.neutral,
        ),
        const SizedBox(height: 14),
        Text(
          ticket.checkedIn && ticket.checkinAt != null
              ? 'Check-in em ${fullDate(ticket.checkinAt!)}'
              : ticket.cancelled
              ? 'A entrada não está disponível.'
              : 'Entrada ainda não registrada',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          switch (ticket.order.status) {
            'paid' => 'Pedido pago',
            'cancelled' => 'Pedido cancelado',
            _ => 'Pagamento pendente',
          },
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}
