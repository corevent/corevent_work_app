import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/profile_avatar.dart';
import '../../../core/design_system/work_widgets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_session.dart';
import '../../invitations/data/invitations_repository.dart';
import '../data/staff_event.dart';
import 'events_view_model.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final model = ref.watch(eventsViewModelProvider);
    final invites = ref.watch(pendingInvitationsProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final name = session.user?.name ?? 'Colaborador';
        final firstName = name.trim().split(' ').first;
        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Bom dia'
            : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            toolbarHeight:
                (MediaQuery.textScalerOf(context).scale(20) * 1.4 +
                        MediaQuery.textScalerOf(context).scale(12) * 1.5 +
                        24)
                    .clamp(78.0, double.infinity),
            automaticallyImplyLeading: false,
            titleSpacing: 24,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Eventos em que colaboro',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  tooltip: 'Minha conta',
                  onPressed: () => context.push('/account'),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.orangeSoft,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: CoreventProfileAvatar(
                    name: name,
                    url: session.user?.avatarUrl,
                    radius: 18,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListenableBuilder(
                  listenable: model,
                  builder: (context, _) => PagedBody<StaffEvent>(
                    model: model,
                    onRefresh: () async {
                      ref.invalidate(pendingInvitationsProvider);
                      await model.load(refresh: true);
                    },
                    header: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkCard(
                          onTap: () => context.push('/invitations'),
                          child: Row(
                            children: [
                              const Icon(
                                RemixIcons.mail_open_line,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invites.when(
                                        data: (page) =>
                                            page.meta.totalItems == 0
                                            ? 'Seus convites'
                                            : '${page.meta.totalItems} convite${page.meta.totalItems == 1 ? '' : 's'} pendente${page.meta.totalItems == 1 ? '' : 's'}',
                                        loading: () => 'Seus convites',
                                        error: (_, _) => 'Seus convites',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Consulte os convites para colaborar.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                RemixIcons.arrow_right_s_line,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final status in StaffEventStatus.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      status.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: model.status == status
                                            ? AppColors.primaryDark
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    selected: model.status == status,
                                    showCheckmark: false,
                                    onSelected: (_) =>
                                        model.selectStatus(status),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          model.status == StaffEventStatus.opened
                              ? 'Próximos eventos'
                              : model.status.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    emptyTitle: 'Nenhum evento por enquanto',
                    emptyDescription: 'Quando você aceitar um convite, o evento aparecerá nesta lista.',
                    emptyAction: 'Ver convites',
                    onEmptyAction: () => context.push('/invitations'),
                    itemBuilder: (event) => EventCard(event: event),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event});
  final StaffEvent event;
  @override
  Widget build(BuildContext context) => WorkFade(
    child: WorkCard(
      onTap: () => context.push('/events/${event.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd').format(event.startDate.toLocal()),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM',
                        'pt_BR',
                      ).format(event.startDate.toLocal()).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shortDate(event.startDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (event.place.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        event.place,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WorkBadge(
            event.accessLevel.label,
            tone: event.accessLevel.canCheckin
                ? BadgeTone.brand
                : BadgeTone.neutral,
          ),
        ],
      ),
    ),
  );
}
