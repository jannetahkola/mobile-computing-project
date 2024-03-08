import 'package:json_annotation/json_annotation.dart';
import 'package:mobile_computing_project/data/model/user.dart';

part 'conversation.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Conversation {
  final int? id;
  final List<User> users; // TODO Make a single user. If current user's data is updated this contains stale data.

  Conversation(this.id, this.users);

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}