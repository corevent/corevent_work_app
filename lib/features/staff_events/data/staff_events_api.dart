import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../core/network/api_models.dart';
import 'staff_event.dart';

part 'staff_events_api.g.dart';

@RestApi()
abstract class StaffEventsApi {
  factory StaffEventsApi(Dio dio, {String? baseUrl}) = _StaffEventsApi;

  @GET('/api/events/my/staff')
  Future<ApiPage<StaffEvent>> list(
    @Query('page') int page,
    @Query('limit') int limit,
    @Query('status') String status,
    @Query('search') String? search,
  );

  @GET('/api/events/{id}')
  Future<ApiObject<StaffEvent>> details(@Path('id') String id);
}
