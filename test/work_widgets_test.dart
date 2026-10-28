import 'package:corevent_work_app/core/design_system/work_widgets.dart';
import 'package:corevent_work_app/core/network/api_models.dart';
import 'package:corevent_work_app/core/theme/app_colors.dart';
import 'package:corevent_work_app/core/theme/app_theme.dart';
import 'package:corevent_work_app/features/checkin/data/checkin_api.dart';
import 'package:corevent_work_app/features/checkin/domain/checkin_outcome.dart';
import 'package:corevent_work_app/features/checkin/presentation/checkin_pages.dart';
import 'package:corevent_work_app/features/participants/data/participant.dart';
import 'package:corevent_work_app/features/participants/presentation/participants_pages.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_event.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_events_repository.dart';
import 'package:corevent_work_app/features/staff_events/presentation/event_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));
  testWidgets('badge credenciado usa fundo verde suave', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TicketDetailsCard(
            ticket: ParticipantTicket(
              id: 'ticket',
              status: 'checked_in',
              ticketType: TicketType(id: 'type', name: 'Entrada'),
              order: TicketOrder(id: 'order', status: 'paid'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Credenciado'), findsOneWidget);
    final badge = find
        .ancestor(
          of: find.text('Credenciado'),
          matching: find.byType(Container),
        )
        .first;
    final decoration =
        tester.widget<Container>(badge).decoration! as BoxDecoration;
    expect(decoration.color, AppColors.successSoft);
  });
  testWidgets('somente leitura não oferece scanner nem totem', (tester) async {
    final event = StaffEvent(
      id: 'event',
      title: 'Evento de leitura',
      startDate: DateTime(2026),
      endDate: DateTime(2027),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventAccessProvider('event').overrideWith((ref) async => event),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EventDashboardPage(eventId: 'event'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Consultar participantes'), findsOneWidget);
    expect(find.text('Ler QR Code'), findsNothing);
    expect(find.text('Ativar modo totem'), findsNothing);
  });
  for (final scale in [1.5, 2.0]) {
    testWidgets(
      'resultado de check-in rola sem overflow em 320px com fonte $scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final record = CheckinRecord(
          ticketId: 'ticket',
          status: 'checked_in',
          checkinAt: DateTime.utc(2026, 10, 27, 18),
          user: const PersonSummary(
            id: 'user',
            name: 'Participante com nome bastante comprido',
          ),
          ticketType: const TicketType(
            id: 'type',
            name: 'Ingresso para o credenciamento',
          ),
          checkedInBy: const PersonSummary(
            id: 'staff',
            name: 'Colaborador responsável',
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: WorkScaffold(
              title: 'Check-in',
              body: CheckinResultView(
                outcome: CheckinOutcome.success(record),
                eventTitle: 'Evento com nome comprido',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('recusa usa ícone vermelho e fundo vermelho suave', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const WorkScaffold(
          title: 'Check-in',
          body: CheckinResultView(
            outcome: CheckinOutcome.failure(CheckinFailure.alreadyUsed),
            eventTitle: 'Evento',
            totem: true,
          ),
        ),
      ),
    );
    final mark = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color == AppColors.errorSoft,
    );
    expect(mark, findsOneWidget);
    expect(find.text('Ingresso já utilizado'), findsOneWidget);
  });
}
