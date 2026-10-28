import 'package:json_annotation/json_annotation.dart';

import '../../../core/network/api_models.dart';
import '../../staff_events/data/staff_event.dart';

part 'invitation.g.dart';

@JsonSerializable(createToJson: false)
class Invitation {
  const Invitation({
    required this.id,
    required this.originalAccessLevel,
    required this.invitationStatus,
    required this.event,
  });
  final String id;
  @JsonKey(unknownEnumValue: StaffAccess.readonly)
  final StaffAccess originalAccessLevel;
  final String invitationStatus;
  final InvitationEvent event;
  String get eventId => event.id;
  PersonSummary get organizer => event.organizer;
  factory Invitation.fromJson(Map<String, dynamic> json) =>
      _$InvitationFromJson(json);
}

@JsonSerializable(createToJson: false)
class InvitationEvent {
  const InvitationEvent({
    required this.id,
    required this.title,
    required this.organizer,
  });
  final String id;
  final String title;
  final PersonSummary organizer;
  factory InvitationEvent.fromJson(Map<String, dynamic> json) =>
      _$InvitationEventFromJson(json);
}

@JsonSerializable(createToJson: false)
class StaffMembership {
  const StaffMembership({required this.id, required this.accessLevel});
  final String id;
  @JsonKey(unknownEnumValue: StaffAccess.readonly)
  final StaffAccess accessLevel;
  factory StaffMembership.fromJson(Map<String, dynamic> json) =>
      _$StaffMembershipFromJson(json);
}
