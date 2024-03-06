import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'user_location.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final int id;
  final String username;
  final String password;
  final String? picture;
  final String? location;
  Uint8List? _pictureBytes;
  UserLocation? _userLocation;

  get pictureBytes => _pictureBytes;

  get userLocation => _userLocation;

  User(this.id, this.username, this.password, this.picture, this.location);

  factory User.fromJson(Map<String, dynamic> json) {
    var user = User(
        json['id'] as int,
        json['username'] as String,
        json['password'] as String,
        json['picture'] as String?,
        json['location'] as String?);
    if (user.picture != null) {
      user._pictureBytes = base64Decode(user.picture!);
    }
    if (user.location != null) {
      user._userLocation = UserLocation.fromJson(jsonDecode(user.location!));
    }
    return user;
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
