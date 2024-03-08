// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      json['id'] as int?,
      json['conversation_id'] as int?,
      json['content'] as String,
      json['user_id'] as int,
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('conversation_id', instance.conversationId);
  val['content'] = instance.content;
  val['user_id'] = instance.userId;
  writeNotNull('created_at', instance.createdAt?.toIso8601String());
  return val;
}
