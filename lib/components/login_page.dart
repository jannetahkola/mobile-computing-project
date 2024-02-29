import 'package:flutter/material.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/state/auth_state.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Log In'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Form(
              key: _loginFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(hintText: 'Username'),
                    controller: _usernameController,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Invalid username'
                        : null,
                    onTapOutside: (e) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onFieldSubmitted: (value) => _submit(),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.visiblePassword,
                    decoration: const InputDecoration(hintText: 'Password'),
                    controller: _passwordController,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Invalid password'
                        : null,
                    onTapOutside: (e) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onFieldSubmitted: (value) => _submit(),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton(
                        onPressed: () => _submit(),
                        child: const Text('Log In')),
                  )
                ],
              ),
            ),
          ),
        ));
  }

  void _submit() {
    if (_loginFormKey.currentState!.validate()) {
      LocalDatabase.getUser(
          username: _usernameController.value.text)
          .then((value) {
        if (value == null ||
            _passwordController.value.text !=
                value.password) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Invalid credentials')));
          return;
        }
        context.read<AuthState>().login(value);
      });
    }
  }
}
