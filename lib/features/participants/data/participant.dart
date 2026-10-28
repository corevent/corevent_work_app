import 'package:json_annotation/json_annotation.dart';

import '../../../core/network/api_models.dart';

part 'participant.g.dart';

@JsonSerializable(createToJson: false)
class Participant {
  const Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.ticketsCount,
  });
  final String id;
  final String name;
  final String email;
  final int ticketsCount;
  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
}

@JsonSerializable(createToJson: false)
class ParticipantDetails {
  const ParticipantDetails({required this.user, required this.tickets});
  final PersonSummary user;
  final List<ParticipantTicket> tickets;
  factory ParticipantDetails.fromJson(Map<String, dynamic> json) =>
      _$ParticipantDetailsFromJson(json);
}

@JsonSerializable(createToJson: false)
class ParticipantTicket {
  const ParticipantTicket({
    required this.id,
    required this.status,
    required this.ticketType,
    required this.order,
    this.checkinAt,
  });
  final String id;
  final String status;
  final TicketType ticketType;
  final TicketOrder order;
  final DateTime? checkinAt;
  bool get checkedIn => status == 'checked_in';
  bool get cancelled => status == 'cancelled' || order.status == 'cancelled';
  String get label => cancelled
      ? 'Cancelado'
      : checkedIn
      ? 'Credenciado'
      : order.status == 'paid'
      ? 'Não utilizado'
      : 'Pagamento pendente';
  factory ParticipantTicket.fromJson(Map<String, dynamic> json) =>
      _$ParticipantTicketFromJson(json);
}

@JsonSerializable(createToJson: false)
class TicketType {
  const TicketType({required this.id, required this.name});
  final String id;
  final String name;
  factory TicketType.fromJson(Map<String, dynamic> json) =>
      _$TicketTypeFromJson(json);
}

@JsonSerializable(createToJson: false)
class TicketOrder {
  const TicketOrder({required this.id, required this.status});
  final String id;
  final String status;
  factory TicketOrder.fromJson(Map<String, dynamic> json) =>
      _$TicketOrderFromJson(json);
}
