import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Message {
  final int? id;
  final int conversationId;
  final String content;
  final int userId;
  final DateTime? createdAt;

  Message(
      this.id, this.conversationId, this.content, this.userId, this.createdAt);

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
