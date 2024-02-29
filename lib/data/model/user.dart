import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final int id;
  final String username;
  final String password;
  final String? picture;
  Uint8List? _pictureBytes;

  get pictureBytes => _pictureBytes;

  User(this.id, this.username, this.password, this.picture);

  factory User.fromJson(Map<String, dynamic> json) {
    var user = User(
        json['id'] as int,
        json['username'] as String,
        json['password'] as String,
        json['picture'] as String?
    );
    if (user.picture != null) {
      user._pictureBytes = base64Decode(user.picture!);
    }
    return user;
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);
}