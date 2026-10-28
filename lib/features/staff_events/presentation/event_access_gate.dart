import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/work_widgets.dart';
import '../../../core/network/api_error.dart';
import '../data/staff_event.dart';
import '../data/staff_events_repository.dart';

class EventAccessGate extends ConsumerWidget {
  const EventAccessGate({
    super.key,
    required this.eventId,
    required this.builder,
    this.checkin = false,
  });
  final String eventId;
  final bool checkin;
  final Widget Function(StaffEvent event) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(eventAccessProvider(eventId))
      .when(
        loading: () => const WorkScaffold(
          title: 'Carregando evento',
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => WorkScaffold(
          title: 'Acesso ao evento',
          body: WorkState(
            title: isAccessDenied(error)
                ? 'Seu acesso mudou'
                : 'Não foi possível abrir o evento',
            description: apiErrorMessage(error),
            error: true,
            icon: isAccessDenied(error)
                ? RemixIcons.lock_line
                : RemixIcons.wifi_off_line,
            action: isAccessDenied(error)
                ? 'Voltar aos meus eventos'
                : 'Tentar novamente',
            onAction: () {
              if (isAccessDenied(error)) {
                context.go('/events');
              } else {
                ref.invalidate(eventAccessProvider(eventId));
              }
            },
          ),
        ),
        data: (event) => checkin && !event.accessLevel.canCheckin
            ? WorkScaffold(
                title: 'Acesso ao evento',
                body: WorkState(
                  title: 'Acesso somente leitura',
                  description: 'Seu acesso permite consultar os participantes. O credenciamento exige permissão de check-in.',
                  icon: RemixIcons.lock_line,
                  action: 'Voltar ao evento',
                  onAction: () => context.go('/events/$eventId'),
                ),
              )
            : builder(event),
      );
}
