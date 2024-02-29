import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/state/auth_state.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<StatefulWidget> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const double _rowHeight = 60.0;
  static const int _usernameMinLength = 3;
  static const int _usernameMaxLength = 10;

  late TextEditingController _usernameController;

  Uint8List? _selectedPicture;

  bool _usernameSetOnce = false;
  bool _profilePictureSetOnce = false;

  bool _canSubmit = false;

  bool _usernameValid = true;
  bool _usernameChanged = false;
  bool _profilePictureChanged = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var authState = context.read<AuthState>();
    if (!_usernameSetOnce) {
      _usernameController.text = authState.user!.username;
      _usernameSetOnce = true;
    }
    if (!_profilePictureSetOnce && authState.user!.pictureBytes != null) {
      _selectedPicture = authState.user!.pictureBytes;
      _profilePictureSetOnce = true;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${authState.user!.username}\'s profile'),
        actions: [
          IconButton(
              onPressed: () {
                authState.logout(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  const Text(
                    'Picture',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (ctx) {
                            var children = [
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: const Text(
                                  'Choose picture from:',
                                  style: TextStyle(fontSize: 22.0),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton.icon(
                                      onPressed: () => _pickImage(
                                          ImageSource.gallery, authState),
                                      icon: const Icon(Icons.image),
                                      label: const Text('Gallery')),
                                  TextButton.icon(
                                      onPressed: () => _pickImage(
                                          ImageSource.camera, authState),
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Camera')),
                                ],
                              )
                            ];
                            if (_selectedPicture != null) {
                              children.add(SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedPicture = null;
                                        _profilePictureChanged = true;
                                        _refreshCanSubmitFlag();
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Clear selected image')),
                              ));
                            }
                            children.add(SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close')),
                            ));
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: children,
                            );
                          });
                    },
                    child: _selectedPicture == null
                        ? Container(
                            width: 35,
                            height: 35,
                            clipBehavior: Clip.antiAlias,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              color: Colors.black,
                            ))
                        : CircleAvatar(
                            backgroundImage: MemoryImage(_selectedPicture!),
                          ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  const Text(
                    'Username',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: TextFormField(
                      controller: _usernameController,
                      onChanged: (value) {
                        setState(() {
                          var sanitizedValue = value.trim();
                          _usernameChanged =
                              sanitizedValue != authState.user!.username;
                          _usernameValid =
                              sanitizedValue.length >= _usernameMinLength &&
                                  !sanitizedValue.contains(' ');
                          _refreshCanSubmitFlag();
                        });
                      },
                      decoration: const InputDecoration(
                          helperText: '3 to 10 characters, no space'),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(_usernameMaxLength)
                      ],
                      onTapOutside: (e) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  )
                ],
              ),
            ),
            Container(
                margin: const EdgeInsets.only(top: 16.0),
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                    onPressed: _canSubmit ? () => saveChanges(context) : null,
                    child: const Text('Save')))
          ],
        ),
      ),
    );
  }

  void _pickImage(ImageSource imageSource, AuthState authState) async {
    var imagePicker = ImagePicker();
    var image = await imagePicker.pickImage(source: imageSource);
    if (image == null) {
      log('No image picked');
      return;
    }
    log('Picked image=${image.path}');
    image.readAsBytes().then((bytes) {
      Navigator.pop(context); // Close bottom sheet
      setState(() {
        _selectedPicture = bytes;
        _profilePictureChanged = true;
        _refreshCanSubmitFlag();
      });
    });
  }

  void _refreshCanSubmitFlag() {
    _canSubmit = (_usernameChanged && _usernameValid) ||
        ((!_usernameChanged || _usernameValid) && _profilePictureChanged);
  }

  void saveChanges(BuildContext context) async {
    if (!_canSubmit) return;

    // Username
    var authState = context.read<AuthState>();
    var username = authState.user!.username;
    if (_usernameChanged) {
      username = _usernameController.value.text.trim();
      var existingUser =
          await LocalDatabase.getUser(username: username, limit: true);
      if (existingUser != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            showCloseIcon: true,
            content: Text('Cannot save - username already taken')));
        return;
      }
    }

    // Profile pic
    String? profilePicture;
    if (_selectedPicture != null) {
      profilePicture = base64Encode(_selectedPicture!);
    }

    var updatedUser = await LocalDatabase.updateUser(authState.user!.id,
        username: username, profilePicture: profilePicture);

    authState.login(updatedUser!);
    _canSubmit = false;
    _usernameSetOnce = false;
    _profilePictureSetOnce = false;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          showCloseIcon: true, content: Text('Changes saved successfully')));
    }
  }
}
