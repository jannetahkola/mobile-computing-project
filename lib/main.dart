import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_computing_project/api/google_api.dart';
import 'package:mobile_computing_project/components/login_page.dart';
import 'package:mobile_computing_project/routes.dart';
import 'package:mobile_computing_project/state/auth_state.dart';
import 'package:mobile_computing_project/state/conversations_state.dart';
import 'package:provider/provider.dart';

import 'data/model/user.dart';

void main() {
  // Avoid errors caused by flutter upgrade
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState(),
        ),
        ChangeNotifierProvider<ConversationsState>(
          create: (_) => ConversationsState(),
        ),
      ],
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
  bool _loadingDistanceMatrix = false;
  FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('mipmap/ic_launcher');
    notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    notificationsPlugin.initialize(
      const InitializationSettings(android: initializationSettingsAndroid),
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        log('notification received');
        var payload = jsonDecode(notificationResponse.payload!);
        await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Say hi to ${payload['username']}!'),
            content:
                Text('${payload['username']} is ${payload['distance']} away'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Say hi'),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  await Navigator.of(context).pushNamed(
                      Routes.newConversationPage,
                      arguments: payload['username']);
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Nevermind'),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var conversationsState = context.watch<ConversationsState>();
    var authState = context.read<AuthState>();
    var userId = authState.user!.id;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Home'),
        actions: [
          IconButton(
              onPressed: _loadingDistanceMatrix
                  ? null
                  : () async {
                      var authState = context.read<AuthState>();

                      if (authState.user!.userLocation != null) {
                        var conversationsState =
                            context.read<ConversationsState>();
                        var targetUsers = conversationsState.conversations
                            .map((e) => e.users
                                .firstWhere((u) => u.id != authState.user!.id))
                            .toList();
                        setState(() {
                          _loadingDistanceMatrix = true;
                        });
                        var origin = LatLng(authState.user!.userLocation!.lat,
                            authState.user!.userLocation!.lng);
                        List<User> destinations = [];
                        for (User u in targetUsers) {
                          if (u.userLocation != null) {
                            destinations.add(u);
                          }
                        }
                        if (destinations.isEmpty && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'None of your contacts have set their location public'),
                            showCloseIcon: true,
                          ));
                        } else {
                          await GoogleApi.fetchStuff(origin, destinations)
                              .then((value) async {
                            var (user, distText) = value;
                            log('closest user = ${user.toJson()}, dist=$distText');
                            log('Showing notification');

                            const androidPlatformChannelSpecifics =
                                AndroidNotificationDetails(
                                    'channel_ID', 'channel name',
                                    importance: Importance.max,
                                    playSound: true,
                                    showProgress: true,
                                    priority: Priority.high,
                                    ticker: 'test ticker');
                            await notificationsPlugin.show(
                                0,
                                'Closest contact found',
                                'Your closest contact is ${user.username} ($distText away)',
                                payload: jsonEncode({
                                  'username': '${user.username}',
                                  'distance': '$distText'
                                }),
                                const NotificationDetails(
                                    android: androidPlatformChannelSpecifics));
                            log('Notification done');
                          });
                          setState(() {
                            _loadingDistanceMatrix = false;
                          });
                        }
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('No location set'),
                          showCloseIcon: true,
                        ));
                      }
                    },
              icon: const Icon(Icons.location_pin)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, Routes.profilePage),
              icon: const Icon(Icons.person)),
        ],
      ),
      body: Center(
        child: FutureBuilder(
            future: conversationsState.fetchAll(userId),
            builder: (ctx, snapshot) {
              if (snapshot.hasData) {
                var conversations = snapshot.data!;
                return ListView.builder(itemBuilder: (ctx, index) {
                  if (index >= conversations.length) return null;

                  var conversation = conversations.elementAt(index);

                  var recipient = conversation.users
                      .firstWhere((element) => element.id != userId);

                  log('recipient ${recipient.toJson()}');

                  var itemTexts = <Widget>[
                    Text(
                      recipient.username,
                      style: const TextStyle(fontSize: 18.0),
                    )
                  ];

                  if (recipient.userLocation != null) {
                    var loc = recipient.userLocation;
                    itemTexts.add(Row(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Color.fromRGBO(0, 0, 0, 0.3),
                          size: 18.0,
                        ),
                        const SizedBox(
                          width: 8.0,
                        ),
                        Text(
                          '${loc!.city}, ${loc!.country}',
                          style: const TextStyle(fontSize: 14.0),
                        )
                      ],
                    ));
                  }

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
                                      margin:
                                          const EdgeInsets.only(right: 16.0),
                                      child: CircleAvatar(
                                        backgroundImage:
                                            MemoryImage(recipient.pictureBytes),
                                      ),
                                    )
                                  : Container(
                                      margin:
                                          const EdgeInsets.only(right: 16.0),
                                      width: 42,
                                      height: 42,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        color: Colors.black,
                                      )),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: itemTexts,
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right)
                            ],
                          )),
                    ),
                  );
                });
              }
              return const CircularProgressIndicator();
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.of(context).pushNamed(Routes.newConversationPage),
        tooltip: 'New conversation',
        child: const Icon(Icons.edit_note),
      ),
    );
  }
}
