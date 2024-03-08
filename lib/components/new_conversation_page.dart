import 'package:flutter/material.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/data/model/conversation.dart';
import 'package:mobile_computing_project/data/model/message.dart';
import 'package:mobile_computing_project/data/model/user.dart';
import 'package:mobile_computing_project/routes.dart';
import 'package:mobile_computing_project/state/auth_state.dart';
import 'package:mobile_computing_project/state/conversations_state.dart';
import 'package:provider/provider.dart';

class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<StatefulWidget> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  late TextEditingController _messageController;

  List<User>? users;
  User? _newConversationRecipient;

  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var authState = context.read<AuthState>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('New Conversation'),
      ),
      body: FutureBuilder(
          future:
              users == null ? LocalDatabase.getUsers() : Future.value(users),
          builder: (ctx, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            // TODO filter those who already have a conversation here, or just send a new message to existing one
            users = snapshot.data!
                .where((element) => element.id != authState.user.id)
                .toList();
            users!.sort((a, b) => a.username.compareTo(b.username));
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(children: [
                _titleTextRow('To'),
                LayoutBuilder(builder: (ctx, constraints) {
                  return DropdownMenu(
                    width: constraints.biggest.width,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    hintText: 'Select recipient...',
                    dropdownMenuEntries: users!.map((e) {
                      return DropdownMenuEntry(
                          value: e.username, label: e.username);
                    }).toList(),
                    onSelected: (username) {
                      _newConversationRecipient =
                          users!.firstWhere((u) => u.username == username);
                      _refreshCanSubmitFlag(); // Handles state update
                    },
                  );
                }),
                _titleTextRow('Message'),
                TextFormField(
                  maxLines: 4,
                  minLines: 4,
                  controller: _messageController,
                  decoration: const InputDecoration(
                      hintText: 'Type message...',
                      border: OutlineInputBorder()),
                  onTapOutside: (e) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: (text) => _refreshCanSubmitFlag(),
                ),
                const SizedBox(
                  height: 16.0,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                      onPressed: _canSubmit
                          ? () async =>
                              await _onSubmit(context).then((conversation) {
                                if (conversation != null) {
                                  context
                                      .read<ConversationsState>()
                                      .add(conversation);
                                  Navigator.of(context).pushReplacementNamed(
                                      Routes.conversationPage,
                                      arguments: conversation);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          showCloseIcon: true,
                                          content: Text('An error occurred')));
                                }
                              })
                          : null,
                      child: const Text('Send')),
                )
              ]),
            );
          }),
    );
  }

  Future<Conversation?> _onSubmit(BuildContext context) async {
    if (!_canSubmit) return Future.value();
    var authorUserId = context.read<AuthState>().user.id;
    var recipientUserId = _newConversationRecipient!.id;

    // Append to existing conversations if there is one
    var conversations =
        await context.read<ConversationsState>().fetchAll(authorUserId);
    var existingConversation = conversations.where((c) {
      return c.users.map((e) => e.id).toList().contains(recipientUserId);
    }).firstOrNull;

    if (existingConversation != null) {
      await LocalDatabase.insertMessage(Message(null, existingConversation.id,
          _messageController.value.text, authorUserId, null));
      return Future.value(existingConversation);
    }

    // Else create a new one
    return await LocalDatabase.insertConversation(
        participants: [recipientUserId, authorUserId],
        message: Message(
            null, null, _messageController.value.text, authorUserId, null));
  }

  void _refreshCanSubmitFlag() {
    setState(() {
      var text = _messageController.value.text.trim();
      _canSubmit = _newConversationRecipient != null && text.isNotEmpty;
    });
  }

  Widget _titleTextRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
