import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_computing_project/data/local_database.dart';
import 'package:mobile_computing_project/data/model/user_location.dart';
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

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Uint8List? _selectedPicture;

  bool _usernameSetOnce = false;
  bool _profilePictureSetOnce = false;
  bool _locationSetOnce = false;

  bool _canSubmit = false;

  bool _usernameValid = true;
  bool _usernameChanged = false;
  bool _profilePictureChanged = false;

  String? _currentCountry;
  String? _currentCity;
  LatLng? _currentLatLng;
  String? _selectedCountry;
  String? _selectedCity;
  LatLng? _selectedLatLng;
  bool _locationChanged = false;

  bool _mapMoving = false;
  CameraPosition? _currentMapPosition;

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
    var authState = context.watch<AuthState>();
    if (!_usernameSetOnce) {
      log('username=${authState.user!.username}');
      _usernameController.text = authState.user!.username;
      _usernameSetOnce = true;
    }
    if (!_profilePictureSetOnce && authState.user!.pictureBytes != null) {
      _selectedPicture = authState.user!.pictureBytes;
      _profilePictureSetOnce = true;
    }
    if (!_locationSetOnce && authState.user!.userLocation != null) {
      var loc = authState.user!.userLocation;
      if (loc != null) {
        _selectedCountry = loc.country;
        _selectedCity = loc.city;
        _selectedLatLng = LatLng(loc.lat, loc.lng);
      }

      _locationSetOnce = true;
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
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  const Text(
                    'Location',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const Spacer(),
                  SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedCity != null
                                  ? '$_selectedCity, $_selectedCountry'
                                  : 'None',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                              onPressed: () => showModalBottomSheet(
                                  context: context,
                                  builder: (ctx) => _mapModalContent()),
                              icon: const Icon(Icons.chevron_right))
                        ],
                      )),
                ],
              ),
            ),
            Container(
                margin: const EdgeInsets.only(top: 16.0),
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                    onPressed: _canSubmit ? () => _saveChanges(context) : null,
                    child: const Text('Save')))
          ],
        ),
      ),
    );
  }

  StatefulBuilder _mapModalContent() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          children: [
            SizedBox(
              height: 400,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  var maxWidth = constraints.biggest.width;
                  var maxHeight = constraints.biggest.height;
                  return Stack(
                    children: [
                      SizedBox(
                        height: maxHeight,
                        width: maxWidth,
                        child: GoogleMap(
                          mapType: MapType.normal,
                          initialCameraPosition: _kGooglePlex,
                          onMapCreated: (controller) {
                            _mapController.complete(controller);
                            _findCurrentLocationFromMapMarker().then((value) =>
                                // Set modal state separately to make sure modal is updated too
                                setModalState(() {}));
                          },
                          onCameraIdle: () {
                            setModalState(() => _mapMoving = false);
                            // Delay search start to reduce redundant calls
                            Future.delayed(const Duration(seconds: 2))
                                .then((value) async {
                              if (!_mapMoving) {
                                log('Loading new location from map marker');
                                await _findCurrentLocationFromMapMarker();
                                setModalState(() {});
                              } else {
                                log('Cancelled');
                              }
                            });
                          },
                          onCameraMoveStarted: () => setModalState(() {
                            _currentCountry = null;
                            _currentCity = null;
                            _mapMoving = true;
                          }),
                          onCameraMove: (position) {
                            _currentMapPosition = position;
                          },
                          onTap: (latLng) {},
                          // Override modal drag gestures when scrolling the map
                          gestureRecognizers: <Factory<
                              OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                        ),
                      ),
                      Positioned(
                        bottom: maxHeight / 2,
                        right: (maxWidth - 30) / 2,
                        child: const Icon(
                          Icons.person_pin_circle,
                          size: 30,
                          color: Colors.redAccent,
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: 30,
                        child: Container(
                          color: Colors.white,
                          child: IconButton(
                            onPressed: () async {
                              var position =
                                  await _findCurrentLocationCoordinates();
                              final GoogleMapController controller =
                                  await _mapController.future;
                              await controller.animateCamera(
                                  CameraUpdate.newCameraPosition(CameraPosition(
                                      target: LatLng(position.latitude,
                                          position.longitude),
                                      zoom: 14.4746)));
                              await _findCurrentLocationFromMapMarker();
                            },
                            icon: const Icon(Icons.my_location),
                          ),
                        ),
                      ),
                      Positioned(
                          top: 5,
                          right: 5,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _currentCountry = null;
                                _currentCity = null;
                              });
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.close),
                          ))
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text((_currentCity != null && !_mapMoving)
                  ? '$_currentCity, $_currentCountry'
                  : 'Please select a valid location'),
            ),
            SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                    onPressed: (_currentCity != null && _currentCountry != null)
                        ? () {
                            setState(() {
                              _selectedCity = _currentCity;
                              _selectedCountry = _currentCountry;
                              _selectedLatLng = _currentLatLng;

                              _currentCity = null;
                              _currentCountry = null;
                              _currentLatLng = null;

                              _locationChanged = true;
                              _refreshCanSubmitFlag();
                            });
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text('Select as your public location'))),
          ],
        );
      },
    );
  }

  void _resetCurrentLocation() {
    setState(() {
      _currentCity = null;
      _currentCountry = null;
    });
  }

  Future<bool> _findCurrentLocationFromMapMarker() async {
    log('Finding current location');

    var latLng = _currentMapPosition!.target;

    List<Placemark> placemarks = [];

    try {
      placemarks =
          await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    } catch (e) {
      if (e is PlatformException && e.code == 'NOT_FOUND') {
        log('No address found', error: e);
      } else {
        log('Unknown error finding address', error: e);
      }
    }

    if (placemarks.isEmpty) {
      // TODO
      log('No address found');
      _resetCurrentLocation();
      return Future.value(false);
    }

    Placemark placemark = placemarks.first;
    String? country = placemark.country;
    String? city = placemark.locality;

    if (country == null || country.isEmpty || city == null || city.isEmpty) {
      log('Invalid address - no city or country');
      _resetCurrentLocation();
      return Future.value(false);
    }

    setState(() {
      _currentCountry = placemark.country;
      _currentCity = placemark.locality;
      _currentLatLng = latLng;
      log('Set current location to $_currentCity, $_currentCountry, $_currentLatLng');
    });

    return Future.value(true);
  }

  Future<Position> _findCurrentLocationCoordinates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      // TODO
    }
    var locationPermission = await Geolocator.checkPermission();
    if (!(locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse)) {
      await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition();
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
        ((!_usernameChanged || _usernameValid) &&
            (_profilePictureChanged || _locationChanged));
  }

  void _saveChanges(BuildContext context) async {
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

    String? location;
    if (_selectedCountry != null && _selectedCity != null) {
      location = jsonEncode(UserLocation(_selectedCountry!, _selectedCity!,
          _selectedLatLng!.latitude, _selectedLatLng!.longitude));
      log('encoded location=$location');
    }

    var updatedUser = await LocalDatabase.updateUser(authState.user!.id,
        username: username, profilePicture: profilePicture, location: location);

    await authState.login(updatedUser!);

    setState(() {
      _canSubmit = false;
      _profilePictureSetOnce = false;
      _usernameSetOnce = false;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          showCloseIcon: true, content: Text('Changes saved successfully')));
    }
  }
}
