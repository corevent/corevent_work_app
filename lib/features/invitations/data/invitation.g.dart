// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
  id: json['id'] as String,
  originalAccessLevel: $enumDecode(
    _$StaffAccessEnumMap,
    json['originalAccessLevel'],
    unknownValue: StaffAccess.readonly,
  ),
  invitationStatus: json['invitationStatus'] as String,
  event: InvitationEvent.fromJson(json['event'] as Map<String, dynamic>),
);

const _$StaffAccessEnumMap = {
  StaffAccess.readonly: 'readonly',
  StaffAccess.checkin: 'checkin',
};

InvitationEvent _$InvitationEventFromJson(Map<String, dynamic> json) =>
    InvitationEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      organizer: PersonSummary.fromJson(
        json['organizer'] as Map<String, dynamic>,
      ),
    );

StaffMembership _$StaffMembershipFromJson(Map<String, dynamic> json) =>
    StaffMembership(
      id: json['id'] as String,
      accessLevel: $enumDecode(
        _$StaffAccessEnumMap,
        json['accessLevel'],
        unknownValue: StaffAccess.readonly,
      ),
    );
