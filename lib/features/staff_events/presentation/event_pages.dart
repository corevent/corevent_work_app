import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/corevent_button.dart';
import '../../../core/design_system/work_widgets.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../data/staff_events_repository.dart';
import 'event_access_gate.dart';

class EventDashboardPage extends StatelessWidget {
  const EventDashboardPage({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context) => EventAccessGate(
    eventId: eventId,
    builder: (event) => WorkScaffold(
      title: 'Evento selecionado',
      body: WorkScroll(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: WorkBadge(
              event.accessLevel.label,
              tone: event.accessLevel.canCheckin
                  ? BadgeTone.brand
                  : BadgeTone.neutral,
            ),
          ),
          const SizedBox(height: 24),
          WorkHeading(event.title, description: fullDate(event.startDate)),
          const SizedBox(height: 12),
          Text(
            event.place,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          WorkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  event.accessLevel.canCheckin
                      ? RemixIcons.qr_code_line
                      : RemixIcons.book_open_line,
                  color: event.accessLevel.canCheckin
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 30,
                ),
                const SizedBox(height: 16),
                Text(
                  event.accessLevel.canCheckin
                      ? 'Credenciamento de ingressos'
                      : 'Consulta de participantes',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  event.accessLevel.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (event.accessLevel.canCheckin) ...[
            CoreventButton(
              label: 'Ler QR Code',
              onPressed: () => context.push('/events/$eventId/scan'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/events/$eventId/totem-setup'),
              child: const Text('Ativar modo totem'),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton(
            onPressed: () => context.push('/events/$eventId/participants'),
            child: const Text('Consultar participantes'),
          ),
          const SizedBox(height: 12),
          CoreventTextAction(
            label: 'Informações do evento',
            onPressed: () => context.push('/events/$eventId/info'),
          ),
        ],
      ),
      footer: CoreventTextAction(
        label: 'Trocar evento',
        onPressed: () => context.go('/events'),
      ),
    ),
  );
}

class EventInfoPage extends ConsumerWidget {
  const EventInfoPage({super.key, required this.eventId});
  final String eventId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => EventAccessGate(
    eventId: eventId,
    builder: (membership) => WorkScaffold(
      title: 'Informações do evento',
      body: ref
          .watch(eventDetailsProvider(eventId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => WorkState(
              title: 'Não foi possível carregar o evento',
              description: apiErrorMessage(error),
              error: true,
              action: 'Tentar novamente',
              onAction: () => ref.invalidate(eventDetailsProvider(eventId)),
            ),
            data: (event) => WorkScroll(
              children: [
                WorkHeading(event.title),
                const SizedBox(height: 28),
                WorkFact(
                  icon: RemixIcons.calendar_event_line,
                  label: 'Início',
                  value: fullDate(event.startDate),
                ),
                WorkFact(
                  icon: RemixIcons.time_line,
                  label: 'Término',
                  value: fullDate(event.endDate),
                ),
                WorkFact(
                  icon: RemixIcons.map_pin_line,
                  label: 'Local',
                  value: event.place.isEmpty
                      ? 'Local não informado'
                      : event.place,
                ),
                if (event.organizer != null)
                  WorkFact(
                    icon: RemixIcons.user_line,
                    label: 'Organização',
                    value: event.organizer!.name,
                  ),
                if (event.description?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Sobre o evento',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    event.description!,
                    style: const TextStyle(
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
    ),
  );
}
