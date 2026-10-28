import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../core/network/api_models.dart';
import 'invitation.dart';

part 'invitations_api.g.dart';

@RestApi()
abstract class InvitationsApi {
  factory InvitationsApi(Dio dio, {String? baseUrl}) = _InvitationsApi;
  @GET('/api/invitations/me')
  Future<ApiPage<Invitation>> list(
    @Query('page') int page,
    @Query('limit') int limit,
    @Query('invitationStatus') String status,
  );
  @POST('/api/invitations/{id}/accept')
  Future<ApiObject<StaffMembership>> accept(@Path('id') String id);
  @POST('/api/invitations/{id}/reject')
  Future<void> reject(@Path('id') String id);
}
