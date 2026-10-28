// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Participant _$ParticipantFromJson(Map<String, dynamic> json) => Participant(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  ticketsCount: (json['ticketsCount'] as num).toInt(),
);

ParticipantDetails _$ParticipantDetailsFromJson(Map<String, dynamic> json) =>
    ParticipantDetails(
      user: PersonSummary.fromJson(json['user'] as Map<String, dynamic>),
      tickets: (json['tickets'] as List<dynamic>)
          .map((e) => ParticipantTicket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

ParticipantTicket _$ParticipantTicketFromJson(Map<String, dynamic> json) =>
    ParticipantTicket(
      id: json['id'] as String,
      status: json['status'] as String,
      ticketType: TicketType.fromJson(
        json['ticketType'] as Map<String, dynamic>,
      ),
      order: TicketOrder.fromJson(json['order'] as Map<String, dynamic>),
      checkinAt: json['checkinAt'] == null
          ? null
          : DateTime.parse(json['checkinAt'] as String),
    );

TicketType _$TicketTypeFromJson(Map<String, dynamic> json) =>
    TicketType(id: json['id'] as String, name: json['name'] as String);

TicketOrder _$TicketOrderFromJson(Map<String, dynamic> json) =>
    TicketOrder(id: json['id'] as String, status: json['status'] as String);
