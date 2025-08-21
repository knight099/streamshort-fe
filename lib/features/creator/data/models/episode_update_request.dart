import 'package:json_annotation/json_annotation.dart';

part 'episode_update_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EpisodeUpdateRequest {
  final String status;

  const EpisodeUpdateRequest({
    required this.status,
  });

  factory EpisodeUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$EpisodeUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EpisodeUpdateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SeriesUpdateRequest {
  final String status;

  const SeriesUpdateRequest({
    required this.status,
  });

  factory SeriesUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$SeriesUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesUpdateRequestToJson(this);
}
