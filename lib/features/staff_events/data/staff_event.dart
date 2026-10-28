import 'package:json_annotation/json_annotation.dart';

import '../../../core/network/api_models.dart';

part 'staff_event.g.dart';

enum StaffAccess {
  @JsonValue('readonly')
  readonly,
  @JsonValue('checkin')
  checkin;

  bool get canCheckin => this == StaffAccess.checkin;
  String get label => canCheckin ? 'Check-in' : 'Somente leitura';
  String get description => canCheckin
      ? 'Consultar participantes e registrar entradas por QR Code, no modo manual ou totem.'
      : 'Consultar participantes e ingressos. Este acesso não permite registrar entradas nem usar o totem.';
}

enum StaffEventStatus {
  @JsonValue('opened')
  opened,
  @JsonValue('going')
  going,
  @JsonValue('finished')
  finished;

  String get label => switch (this) {
    opened => 'Próximos',
    going => 'Em andamento',
    finished => 'Encerrados',
  };
}

@JsonSerializable(createToJson: false)
class StaffEvent {
  const StaffEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.accessLevel = StaffAccess.readonly,
    this.status = 'opened',
    this.cityName,
    this.stateAcronym,
    this.locationName,
    this.locationType,
    this.bannerUrl,
    this.description,
    this.organizer,
    this.city,
    this.street,
    this.number,
    this.neighborhood,
  });
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  @JsonKey(unknownEnumValue: StaffAccess.readonly)
  final StaffAccess accessLevel;
  final String status;
  final String? cityName;
  final String? stateAcronym;
  final String? locationName;
  final String? locationType;
  final String? bannerUrl;
  final String? description;
  final PersonSummary? organizer;
  final EventCity? city;
  final String? street;
  final int? number;
  final String? neighborhood;
  String get place => locationType == 'online'
      ? 'Evento online'
      : [
          locationName,
          cityName ?? city?.name,
          stateAcronym ?? city?.state.acronym,
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
  factory StaffEvent.fromJson(Map<String, dynamic> json) =>
      _$StaffEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventCity {
  const EventCity({required this.name, required this.state});
  final String name;
  final EventState state;
  factory EventCity.fromJson(Map<String, dynamic> json) =>
      _$EventCityFromJson(json);
}

@JsonSerializable(createToJson: false)
class EventState {
  const EventState({required this.acronym});
  final String acronym;
  factory EventState.fromJson(Map<String, dynamic> json) =>
      _$EventStateFromJson(json);
}
