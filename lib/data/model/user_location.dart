import 'package:json_annotation/json_annotation.dart';

part 'user_location.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserLocation {
  final String country;
  final String city;

  UserLocation(this.country, this.city);

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      _$UserLocationFromJson(json);

  Map<String, dynamic> toJson() => _$UserLocationToJson(this);
}
