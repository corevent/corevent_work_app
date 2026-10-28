import 'package:corevent_work_app/core/theme/app_theme.dart';
import 'package:corevent_work_app/features/invitations/data/invitation.dart';
import 'package:corevent_work_app/features/invitations/data/invitations_api.dart';
import 'package:corevent_work_app/features/invitations/data/invitations_repository.dart';
import 'package:corevent_work_app/features/invitations/presentation/invitations_pages.dart';
import 'package:corevent_work_app/features/invitations/presentation/invitations_view_model.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_event.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// GET /api/invitations/me selects event.id and event.organizer, without
// duplicating eventId or organizer at the invitation root.
Map<String, dynamic> _invitation({
  required String id,
  required String title,
  required String accessLevel,
}) => {
  'id': id,
  'userId': 'staff-user',
  'originalAccessLevel': accessLevel,
  'invitationStatus': 'pending',
  'createdAt': '2026-10-27T12:00:00.000Z',
  'event': {
    'id': 'event-$id',
    'title': title,
    'organizer': {
      'id': 'organizer',
      'name': 'Ana Souza',
      'email': 'organizacao@example.com',
      'avatarUrl': null,
    },
  },
};

Map<String, dynamic> _pendingPage() => {
  'data': [
    _invitation(
      id: 'invite-checkin',
      title: 'Festival para credenciamento',
      accessLevel: 'checkin',
    ),
    _invitation(
      id: 'invite-readonly',
      title: 'Feira para consulta',
      accessLevel: 'readonly',
    ),
  ],
  'meta': {
    'totalItems': 2,
    'totalPages': 1,
    'currentPage': 1,
    'itemsPerPage': 20,
  },
};

void _respondWith(
  Dio dio,
  Map<String, dynamic> body, {
  int statusCode = 200,
  void Function(RequestOptions)? inspect,
}) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        inspect?.call(request);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: request,
            statusCode: statusCode,
            data: body,
          ),
        );
      },
    ),
  );
}

void main() {
  late Dio dio;
  late InvitationsRepository repository;
  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.invalid'));
    repository = InvitationsRepository(InvitationsApi(dio));
  });
  tearDown(() => dio.close(force: true));

  test('HTTP 200 com convites aninhados carrega a lista sem erro', () async {
    var requests = 0;
    _respondWith(
      dio,
      _pendingPage(),
      inspect: (request) {
        requests++;
        expect(request.method, 'GET');
        expect(request.path, '/api/invitations/me');
        expect(request.queryParameters, {
          'page': 1,
          'limit': 20,
          'invitationStatus': 'pending',
        });
      },
    );
    final model = InvitationsViewModel(repository);
    addTearDown(model.dispose);

    await model.load();

    expect(model.state.error, isNull);
    expect(model.state.loading, isFalse);
    expect(model.state.items, hasLength(2));
    expect(model.state.meta?.totalItems, 2);
    expect(model.state.hasMore, isFalse);
    final checkin = model.state.items[0];
    expect(checkin.eventId, 'event-invite-checkin');
    expect(checkin.event.title, 'Festival para credenciamento');
    expect(checkin.organizer.name, 'Ana Souza');
    expect(checkin.organizer.email, 'organizacao@example.com');
    expect(checkin.organizer.avatarUrl, isNull);
    expect(checkin.originalAccessLevel.canCheckin, isTrue);
    final readonly = model.state.items[1];
    expect(readonly.eventId, 'event-invite-readonly');
    expect(readonly.originalAccessLevel.canCheckin, isFalse);
    expect(requests, 1);
  });

  test('permissão desconhecida não concede check-in', () {
    final invitation = Invitation.fromJson(
      _invitation(id: 'invite', title: 'Evento', accessLevel: 'future-value'),
    );
    expect(invitation.originalAccessLevel, StaffAccess.readonly);
    expect(invitation.originalAccessLevel.canCheckin, isFalse);
  });

  for (final access in StaffAccess.values) {
    test(
      'aceite lê o vínculo e a permissão ${access.name} retornados pela API',
      () async {
        _respondWith(
          dio,
          {
            'data': {
              'id': 'membership',
              'userId': 'staff-user',
              'eventId': 'event',
              'staffInvitationId': 'invite',
              'accessLevel': access.name,
              'createdAt': '2026-10-27T12:00:00.000Z',
            },
          },
          statusCode: 201,
          inspect: (request) {
            expect(request.method, 'POST');
            expect(request.path, '/api/invitations/invite/accept');
            expect(request.data, isNull);
          },
        );
        final membership = await repository.accept('invite');
        expect(membership.id, 'membership');
        expect(membership.accessLevel, access);
      },
    );
  }

  test('recusa usa o ID do convite e aceita a resposta de mensagem', () async {
    _respondWith(
      dio,
      {'message': 'Invitation rejected successfully'},
      statusCode: 201,
      inspect: (request) {
        expect(request.method, 'POST');
        expect(request.path, '/api/invitations/invite/reject');
        expect(request.data, isNull);
      },
    );
    await repository.reject('invite');
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('convites e detalhe usam o contrato real com fonte $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _respondWith(dio, _pendingPage());
      final router = GoRouter(
        initialLocation: '/invitations',
        routes: [
          GoRoute(
            path: '/invitations',
            builder: (context, state) => const InvitationsPage(),
          ),
          GoRoute(
            path: '/invitations/:id',
            builder: (context, state) =>
                InvitationPage(invitation: state.extra! as Invitation),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invitationsRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Convites recebidos'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Festival para credenciamento'),
        160,
      );
      await tester.pumpAndSettle();
      expect(find.text('Festival para credenciamento'), findsOneWidget);
      expect(find.text('Check-in'), findsOneWidget);
      expect(find.text('Vamos tentar novamente?'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('Feira para consulta'), 160);
      await tester.pumpAndSettle();
      expect(find.text('Somente leitura'), findsOneWidget);
      expect(find.text('Organização: Ana Souza'), findsWidgets);
      await tester.tap(find.text('Feira para consulta'));
      await tester.pumpAndSettle();

      expect(find.byType(InvitationPage), findsOneWidget);
      final detail = tester.widget<InvitationPage>(find.byType(InvitationPage));
      expect(detail.invitation.id, 'invite-readonly');
      expect(detail.invitation.eventId, 'event-invite-readonly');
      expect(find.text('Feira para consulta'), findsOneWidget);
      expect(
        find.text('Ana Souza convidou você para colaborar neste evento.'),
        findsOneWidget,
      );
      expect(find.text('Somente leitura'), findsOneWidget);
      expect(find.text('Aceitar convite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
