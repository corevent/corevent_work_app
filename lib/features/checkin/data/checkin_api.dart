import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

import '../../../core/network/api_models.dart';
import '../../participants/data/participant.dart';

part 'checkin_api.g.dart';

@JsonSerializable()
class CheckinRequest {
  const CheckinRequest(this.qrToken);
  final String qrToken;
  factory CheckinRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckinRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CheckinRequestToJson(this);
}

@JsonSerializable(createToJson: false)
class CheckinRecord {
  const CheckinRecord({
    required this.ticketId,
    required this.status,
    required this.checkinAt,
    required this.user,
    required this.ticketType,
    required this.checkedInBy,
  });
  final String ticketId;
  final String status;
  final DateTime checkinAt;
  final PersonSummary user;
  final TicketType ticketType;
  final PersonSummary checkedInBy;
  factory CheckinRecord.fromJson(Map<String, dynamic> json) =>
      _$CheckinRecordFromJson(json);
}

@RestApi()
abstract class CheckinApi {
  factory CheckinApi(Dio dio, {String? baseUrl}) = _CheckinApi;
  @POST('/api/events/{eventId}/checkin')
  Future<ApiObject<CheckinRecord>> checkin(
    @Path('eventId') String eventId,
    @Body() CheckinRequest request,
  );
}
