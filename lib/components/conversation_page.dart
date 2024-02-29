import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/data/model/conversation.dart';
import 'package:mobile_computing_project/data/model/message.dart';
import 'package:mobile_computing_project/state/auth_state.dart';
import 'package:provider/provider.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<StatefulWidget> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _messageFormKey = GlobalKey<FormState>();

  late TextEditingController _messageController;

  List<Message>? messages;
  bool canSubmit = false;

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
    var conversation =
        ModalRoute.of(context)!.settings.arguments! as Conversation;
    var recipient = conversation.users
        .firstWhere((element) => element.id != authState.user!.id);
    var msgPadding = MediaQuery.of(context).size.width / 3;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(recipient.username),
      ),
      body: FutureBuilder(
        future: messages == null
            ? LocalDatabase.getMessages(conversation.id)
            : Future.value(messages),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            messages = snapshot.data as List<Message>;
            messages!.sort((a, b) => a.id! > b.id! ? -1 : 1);
            return Stack(
              children: [
                Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 48.0),
                    reverse: true,
                    children: messages!
                        .map((e) => Card(
                              margin: e.userId != authState.user!.id
                                  ? EdgeInsets.only(
                                      right: msgPadding, bottom: 8.0)
                                  : EdgeInsets.only(
                                      left: msgPadding, bottom: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.content,
                                      style: const TextStyle(fontSize: 16.0),
                                    ),
                                    Text(
                                      DateFormat('MMM dd y HH:mm')
                                          .format(e.createdAt!.toLocal())
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 12.0, color: Colors.grey),
                                    )
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      color: Colors.white,
                      child: Form(
                        key: _messageFormKey,
                        child: Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width - 48.0,
                              child: TextFormField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                    hintText: 'Message...',
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    border: InputBorder.none),
                                onChanged: (value) {
                                  setState(() {
                                    canSubmit = value.trim().isNotEmpty;
                                  });
                                },
                                onTapOutside: (e) => FocusManager
                                    .instance.primaryFocus
                                    ?.unfocus(),
                              ),
                            ),
                            IconButton(
                                onPressed: canSubmit
                                    ? () {
                                        var text =
                                            _messageController.value.text;
                                        if (text.trim().isNotEmpty) {
                                          var message = Message(
                                              null,
                                              conversation.id,
                                              _messageController.value.text
                                                  .trim(),
                                              authState.user!.id,
                                              null);
                                          LocalDatabase.insertMessage(message)
                                              .then((createdMessage) {
                                            setState(() {
                                              _messageController.clear();
                                              messages?.add(createdMessage!);
                                            });
                                          });
                                        }
                                      }
                                    : null,
                                icon: const Icon(Icons.send))
                          ],
                        ),
                      ),
                    ))
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
