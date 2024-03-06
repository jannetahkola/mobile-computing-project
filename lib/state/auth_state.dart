import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/user.dart';

class AuthState with ChangeNotifier {
  User? _user;

  get user => _user;

  void login(User user) {
    log('Logging in user id ${user.id}');
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString('user', jsonEncode(user.toJson())))
        .then((value) {
      _user = user;
      notifyListeners();
      log('User id ${_user!.id} logged in');
    });
  }

  void logout(BuildContext context) {
    log('Logging out user id ${user.id}');
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove('user'))
        .then((value) {
      log('User id ${_user!.id} logged out');
      _user = null;
      notifyListeners();
    });
  }

  Future<bool> isLoggedIn() {
    if (_user != null) return Future.value(true);
    return SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('user'))
        .then((value) {
          if (value != null) {
            _user = User.fromJson(jsonDecode(value));
          }
          return _user != null;
    });
  }
}
