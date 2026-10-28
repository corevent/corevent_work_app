// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffEvent _$StaffEventFromJson(Map<String, dynamic> json) => StaffEvent(
  id: json['id'] as String,
  title: json['title'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  accessLevel:
      $enumDecodeNullable(
        _$StaffAccessEnumMap,
        json['accessLevel'],
        unknownValue: StaffAccess.readonly,
      ) ??
      StaffAccess.readonly,
  status: json['status'] as String? ?? 'opened',
  cityName: json['cityName'] as String?,
  stateAcronym: json['stateAcronym'] as String?,
  locationName: json['locationName'] as String?,
  locationType: json['locationType'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  description: json['description'] as String?,
  organizer: json['organizer'] == null
      ? null
      : PersonSummary.fromJson(json['organizer'] as Map<String, dynamic>),
  city: json['city'] == null
      ? null
      : EventCity.fromJson(json['city'] as Map<String, dynamic>),
  street: json['street'] as String?,
  number: (json['number'] as num?)?.toInt(),
  neighborhood: json['neighborhood'] as String?,
);

const _$StaffAccessEnumMap = {
  StaffAccess.readonly: 'readonly',
  StaffAccess.checkin: 'checkin',
};

EventCity _$EventCityFromJson(Map<String, dynamic> json) => EventCity(
  name: json['name'] as String,
  state: EventState.fromJson(json['state'] as Map<String, dynamic>),
);

EventState _$EventStateFromJson(Map<String, dynamic> json) =>
    EventState(acronym: json['acronym'] as String);
