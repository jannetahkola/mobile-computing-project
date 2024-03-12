import 'package:flutter/widgets.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/data/model/conversation.dart';

class ConversationsState with ChangeNotifier {
  final List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;

  void add(Conversation conversation) {
    if (!_conversations.contains(conversation)) {
      _conversations.add(conversation);
    }
    notifyListeners();
  }

  void replaceAll(List<Conversation> conversations) {
    _conversations.clear();
    _conversations.addAll(conversations);
    notifyListeners();
  }

  Future<List<Conversation>> fetchAll(int userId) async {
    if (_conversations.isEmpty) {
      replaceAll(await LocalDatabase.getConversations(userId));
    }
    return _conversations;
  }

  void clear() {
    _conversations.clear();
  }
}