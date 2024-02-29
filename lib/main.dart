import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_computing_project/components/login_page.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/data/model/conversation.dart';
import 'package:mobile_computing_project/routes.dart';
import 'package:mobile_computing_project/state/auth_state.dart';
import 'package:provider/provider.dart';

void main() {
  // Avoid errors caused by flutter upgrade
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: MaterialApp(
        title: 'Mobile Computing Project',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const FirstPage(),
        routes: Routes.routes(),
      ),
    );
  }
}

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This will replace the current route so there's no stale back stack
    var authState = context.watch<AuthState>();
    return FutureBuilder(
        future: authState.isLoggedIn(),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            var loggedIn = snapshot.data as bool;
            return loggedIn ? const MyHomePage() : const LoginPage();
          }
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Conversation>? conversations;

  @override
  Widget build(BuildContext context) {
    var authState = context.read<AuthState>();
    var userId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Home'),
        actions: [
          IconButton(
              onPressed: () => Navigator.pushNamed(context, Routes.profilePage),
              icon: const Icon(Icons.person))
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            FutureBuilder(
                future: conversations == null
                    ? LocalDatabase.getConversations(userId)
                    : Future.value(conversations),
                builder: (ctx, snapshot) {
                  if (snapshot.hasData) {
                    conversations = snapshot.data!;
                    return Column(
                      children: conversations!.map((conversation) {
                        var recipient = conversation.users
                            .firstWhere((element) => element.id != userId);
                        return Material(
                          child: InkWell(
                            onTap: () => Navigator.pushNamed(
                                context, Routes.conversationPage,
                                arguments: conversation),
                            child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 82.0,
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    recipient.pictureBytes != null
                                        ? Container(
                                            margin: const EdgeInsets.only(
                                                right: 16.0),
                                            child: CircleAvatar(
                                              backgroundImage: MemoryImage(
                                                  recipient.pictureBytes),
                                            ),
                                          )
                                        : Container(
                                            margin: const EdgeInsets.only(
                                                right: 16.0),
                                            width: 42,
                                            height: 42,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                            ),
                                            child: Container(
                                              color: Colors.black,
                                            )),
                                    Text(
                                      recipient.username,
                                      style: const TextStyle(fontSize: 18.0),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.chevron_right)
                                  ],
                                )),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return const CircularProgressIndicator();
                })
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO
        },
        tooltip: 'New conversation',
        child: const Icon(Icons.edit_note),
      ),
    );
  }
}
