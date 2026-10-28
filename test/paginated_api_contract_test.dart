import 'package:corevent_work_app/core/presentation/paged_view_model.dart';
import 'package:corevent_work_app/features/invitations/data/invitations_api.dart';
import 'package:corevent_work_app/features/invitations/data/invitations_repository.dart';
import 'package:corevent_work_app/features/invitations/presentation/invitations_view_model.dart';
import 'package:corevent_work_app/features/participants/data/participants_api.dart';
import 'package:corevent_work_app/features/participants/data/participants_repository.dart';
import 'package:corevent_work_app/features/participants/presentation/participants_view_model.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_events_api.dart';
import 'package:corevent_work_app/features/staff_events/data/staff_events_repository.dart';
import 'package:corevent_work_app/features/staff_events/presentation/events_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases =
      <
        ({
          String name,
          String path,
          PagedViewModel<Object> Function(Dio) create,
        })
      >[
        (
          name: 'eventos',
          path: '/api/events/my/staff',
          create: (dio) =>
              EventsViewModel(StaffEventsRepository(StaffEventsApi(dio))),
        ),
        (
          name: 'convites',
          path: '/api/invitations/me',
          create: (dio) =>
              InvitationsViewModel(InvitationsRepository(InvitationsApi(dio))),
        ),
        (
          name: 'participantes',
          path: '/api/events/event/participants',
          create: (dio) => ParticipantsViewModel(
            ParticipantsRepository(ParticipantsApi(dio)),
            'event',
          ),
        ),
      ];
  for (final scenario in cases) {
    test(
      '${scenario.name}: HTTP 200 vazio com meta real encerra sem erro',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
        addTearDown(() => dio.close(force: true));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              expect(request.path, scenario.path);
              expect(request.queryParameters['page'], 1);
              expect(request.queryParameters['limit'], 20);
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: request,
                  statusCode: 200,
                  data: {
                    'data': <Object>[],
                    'meta': {
                      'totalItems': 0,
                      'totalPages': 0,
                      'currentPage': 1,
                      'itemsPerPage': 20,
                    },
                  },
                ),
              );
            },
          ),
        );
        final model = scenario.create(dio);
        addTearDown(model.dispose);
        await model.load();
        expect(model.state.loading, isFalse);
        expect(model.state.error, isNull);
        expect(model.state.items, isEmpty);
        expect(model.state.meta?.page, 1);
        expect(model.state.meta?.limit, 20);
        expect(model.state.meta?.totalItems, 0);
        expect(model.state.hasMore, isFalse);
      },
    );
  }
}
