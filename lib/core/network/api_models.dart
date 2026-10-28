import 'package:json_annotation/json_annotation.dart';

part 'api_models.g.dart';

@JsonSerializable(createToJson: false)
class PageMeta {
  const PageMeta({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });
  @JsonKey(name: 'currentPage', fromJson: _readPaginationInt)
  final int page;
  @JsonKey(name: 'itemsPerPage', fromJson: _readPaginationInt)
  final int limit;
  @JsonKey(fromJson: _readPaginationInt)
  final int totalItems;
  @JsonKey(fromJson: _readPaginationInt)
  final int totalPages;
  bool get hasMore => page < totalPages;
  factory PageMeta.fromJson(Map<String, dynamic> json) =>
      _$PageMetaFromJson(json);
}

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class ApiPage<T> {
  const ApiPage({required this.data, required this.meta});
  final List<T> data;
  final PageMeta meta;
  factory ApiPage.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiPageFromJson(json, fromJsonT);
}

@JsonSerializable(genericArgumentFactories: true, createToJson: false)
class ApiObject<T> {
  const ApiObject({required this.data});
  final T data;
  factory ApiObject.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiObjectFromJson(json, fromJsonT);
}

@JsonSerializable(createToJson: false)
class PersonSummary {
  const PersonSummary({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  factory PersonSummary.fromJson(Map<String, dynamic> json) =>
      _$PersonSummaryFromJson(json);
}

int _readPaginationInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.parse(text),
  _ => throw FormatException('Invalid pagination integer: $value'),
};
