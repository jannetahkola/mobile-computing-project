import 'package:collection/collection.dart';
import 'package:mobile_computing_project/data/model/message.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:developer';

import 'model/conversation.dart';
import 'model/user.dart';

class LocalDatabase {
  LocalDatabase._();

  static Future<List<User>> getUsers() async {
    log('Fetching all users');
    return await _db.then((db) async {
      var data = await db.query('user');
      if (data.isEmpty) return [];
      return data.map((e) => User.fromJson(e)).toList();
    });
  }

  static Future<User?> getUser(
      {String? username, int? id, bool limit = false}) async {
    log('Fetching user by username=$username, id=$id');
    return await _db.then((db) async {
      String where;
      List<Object> whereArgs;
      List<String> columns = [];

      if (id != null) {
        where = "id = ?";
        whereArgs = [id];
      } else if (username != null) {
        where = "username = ?";
        whereArgs = [username];
      } else {
        return null;
      }

      if (limit) {
        // Required fields only
        columns = ['id', 'username', 'password'];
      }

      log('where=$where, whereArgs=$whereArgs');

      var data = await db.query('user',
          columns: columns, where: where, whereArgs: whereArgs);
      if (data.isEmpty) {
        return null;
      }
      return User.fromJson(data.first);
    });
  }

  static Future<User?> updateUser(int id,
      {String? username, String? profilePicture, String? location}) async {
    log('Updating user with id $id');

    Map<String, Object?> values = {};
    if (username != null) {
      values.putIfAbsent('username', () => username);
    }

    // No null check, these can be deleted
    values.putIfAbsent('picture', () => profilePicture);
    values.putIfAbsent('location', () => location);

    return await _db.then((db) async {
      await db.update('user', values, where: "id = ?", whereArgs: [id]);
      return getUser(id: id);
    });
  }

  static Future<List<Conversation>> getConversations(int userId) async {
    log('Fetching conversations');
    return await _db.then((db) async {
      var data = await db.rawQuery('''
      select c.id as conversation_id, u.* from conversation c
        join conversation_user cu on cu.conversation_id = c.id
        join user u on u.id = cu.user_id 
        where c.id in (
          select cu.conversation_id from conversation_user cu
          where cu.user_id = $userId 
        )
      ''');
      if (data.isEmpty) {
        return List.empty();
      }
      var groupedData = groupBy(data, (Map obj) => obj['conversation_id']);
      return groupedData.entries.map((e) {
        log('mapping users from $e');
        var users = e.value.map((v) {
          var user = User.fromJson(v);
          log('user=${user.toJson()}');
          return user;
        }).toList();
        return Conversation(e.key, users);
      }).toList();
    });
  }

  static Future<Conversation?> getConversation(int id) async {
    log('Fetching conversation with id $id');
    return await _db.then((db) async {
      var data =
          await db.rawQuery('''
          select c.id as conversation_id, u.* from conversation c
            join conversation_user cu on cu.conversation_id = c.id
            join user u on u.id = cu.user_id 
            where c.id = $id
          ''');
      if (data.isEmpty) {
        return null;
      }
      var groupedData = groupBy(data, (Map obj) => obj['conversation_id']);
      return groupedData.entries.map((e) {
        var users = e.value.map((v) => User.fromJson(v)).toList();
        return Conversation(e.key, users);
      }).first;
    });
  }

  static Future<Conversation?> insertConversation(
      {required List<int> participants, required Message message}) async {
    log('Inserting conversation');
    return await _db.then((db) async {
      int conversationId = await db.transaction((txn) async {
        // insert conversation
        int conversationId =
        await txn.rawInsert('insert into conversation default values');

        // insert conversation-user links
        for (var userId in participants) {
          txn.rawInsert(
              'insert into conversation_user (conversation_id, user_id) values (?, ?)',
              [conversationId, userId]);
        }

        // insert message
        message.conversationId = conversationId;
        await txn.insert('message', message.toJson());

        return conversationId;
      });
      return getConversation(conversationId);
    });
  }

  static Future<Message?> getMessage(int messageId) async {
    log('Fetching message');
    return await _db.then((db) async {
      var data =
          await db.rawQuery('select * from message where id = $messageId');
      if (data.isEmpty) {
        return null;
      }
      return Message.fromJson(data.first);
    });
  }

  static Future<List<Message>> getMessages(int conversationId) async {
    log('Fetching messages');
    return await _db.then((db) async {
      var data = await db.rawQuery(
          "select * from message where conversation_id = $conversationId");
      return data.map((e) => Message.fromJson(e)).toList();
    });
  }

  static Future<Message?> insertMessage(Message message) async {
    log('Inserting message');
    return await _db.then((db) async {
      int rowId = await db.insert('message', message.toJson());
      return getMessage(rowId);
    });
  }

  static Future<Database> get _db async =>
      await openDatabase('mobile_computing.db', version: 1,
          onCreate: (db, version) async {
        Batch batch = db.batch();
        batch.execute('''
            create table user (
              id integer primary key autoincrement,
              username text not null,
              password text not null,
              picture text,
              location text
            )
            ''');
        batch.execute('''
            create table conversation (
              id integer primary key autoincrement
            )
            ''');
        batch.execute('''
            create table conversation_user (
              conversation_id integer not null,
              user_id integer not null,
              foreign key(conversation_id) references conversation(id),
              foreign key(user_id) references user(id)
            )
            ''');
        batch.execute('''
            create table message (
              id integer primary key autoincrement,
              conversation_id integer not null,
              user_id integer not null,
              content text not null,
              created_at timestamp not null default current_timestamp,
              foreign key(conversation_id) references conversation(id),
              foreign key(user_id) references user(id)
            )
            ''');

        batch.execute(
            "insert into user (id, username, password, location) values (1, 'make', 'pass', '{\"country\":\"United States\",\"city\":\"Mountain View\",\"lat\":37.42796133580664,\"lng\":-122.085749655962}')");
        batch.execute(
            "insert into user (id, username, password, location) values (2, 'risto', 'pass', '{\"country\":\"United States\",\"city\":\"Palo Alto\",\"lat\":37.398159232239436,\"lng\":-122.13477272540331}')");
        batch.execute(
            "insert into user (id, username, password, location) values (3, 'hermanni', 'pass', '{\"country\":\"United States\",\"city\":\"Daly City\",\"lat\":37.687019682186225,\"lng\":-122.47089609503746}')");
        batch.execute(
            "insert into user (id, username, password) values (4, 'karen', 'pass')");
        batch.execute(
            "insert into user (id, username, password) values (5, 'einoleino', 'pass')");
        batch.execute(
            "insert into user (id, username, password) values (6, 'jack', 'pass')");
        batch.execute(
            "insert into user (id, username, password) values (7, 'michelle', 'pass')");

        batch.execute('insert into conversation (id) values (1)');
        batch.execute('insert into conversation (id) values (2)');
        batch.execute('insert into conversation (id) values (3)');

        batch.execute(
            'insert into conversation_user (conversation_id, user_id) values (1, 1)');
        batch.execute(
            'insert into conversation_user (conversation_id, user_id) values (1, 2)');
        batch.execute(
            'insert into conversation_user (conversation_id, user_id) values (2, 2)');
        batch.execute(
            'insert into conversation_user (conversation_id, user_id) values (2, 3)');
        batch.execute(
            'insert into conversation_user (conversation_id, user_id) values (3, 1)');
        batch.execute(
            'insert into conversation_user (conversation_id, user_id) values (3, 3)');

        batch.execute(
            "insert into message (id, conversation_id, user_id, content) values (1, 1, 1, \"What's up bro?\")");
        batch.execute(
            "insert into message (id, conversation_id, user_id, content) values (2, 1, 2, \"Not much, enjoying life\")");
        batch.execute(
            "insert into message (id, conversation_id, user_id, content) values (3, 1, 2, \"You?\")");
        batch.execute(
            "insert into message (id, conversation_id, user_id, content) values (4, 3, 1, \"Hello\")");

        await batch.commit(noResult: true);
      });
}
