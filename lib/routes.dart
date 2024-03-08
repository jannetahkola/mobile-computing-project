import 'package:flutter/widgets.dart';
import 'package:mobile_computing_project/components/conversation_page.dart';
import 'package:mobile_computing_project/components/login_page.dart';
import 'package:mobile_computing_project/components/new_conversation_page.dart';
import 'package:mobile_computing_project/components/profile_page.dart';
import 'package:mobile_computing_project/main.dart';

class Routes {
  static const String loginPage = "login";
  static const String homePage = "home";
  static const String profilePage = "profile";
  static const String conversationPage = "conversation";
  static const String newConversationPage = "new_conversation";

  static Map<String, WidgetBuilder> routes() {
    return {
      loginPage: (context) => const LoginPage(),
      homePage: (context) => const MyHomePage(),
      profilePage: (context) => const ProfilePage(),
      conversationPage: (context) => const ConversationPage(),
      newConversationPage: (context) => const NewConversationPage()
    };
  }
}
