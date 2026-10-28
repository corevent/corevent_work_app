import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../core/network/api_models.dart';
import 'participant.dart';

part 'participants_api.g.dart';

@RestApi()
abstract class ParticipantsApi {
  factory ParticipantsApi(Dio dio, {String? baseUrl}) = _ParticipantsApi;
  @GET('/api/events/{eventId}/participants')
  Future<ApiPage<Participant>> list(
    @Path('eventId') String eventId,
    @Query('page') int page,
    @Query('limit') int limit,
  );
  @GET('/api/events/{eventId}/participants/{userId}/details')
  Future<ApiObject<ParticipantDetails>> details(
    @Path('eventId') String eventId,
    @Path('userId') String userId,
  );
}
