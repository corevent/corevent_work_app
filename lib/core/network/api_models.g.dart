// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageMeta _$PageMetaFromJson(Map<String, dynamic> json) => PageMeta(
  page: _readPaginationInt(json['currentPage']),
  limit: _readPaginationInt(json['itemsPerPage']),
  totalItems: _readPaginationInt(json['totalItems']),
  totalPages: _readPaginationInt(json['totalPages']),
);

ApiPage<T> _$ApiPageFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiPage<T>(
  data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
  meta: PageMeta.fromJson(json['meta'] as Map<String, dynamic>),
);

ApiObject<T> _$ApiObjectFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiObject<T>(data: fromJsonT(json['data']));

PersonSummary _$PersonSummaryFromJson(Map<String, dynamic> json) =>
    PersonSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
