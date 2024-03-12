import 'dart:convert';
import 'dart:developer';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_computing_project/data/model/user.dart';

class GoogleApi {
  static const String _apiKey = 'AIzaSyDRiw-nqHFzYZ5VG4gCvJI3LsxJ9nCmKvo';
  static const String _baseUri = 'https://maps.googleapis.com/maps/api/distancematrix';

  static Future<(User, String)> fetchStuff(LatLng origins, List<User> users) async {
    String destQuery = '';
    for (var user in users) {
      destQuery += '${user.userLocation!.lat},${user.userLocation!.lng}|';
    }
    var response = await http.get(Uri.parse('$_baseUri/json?destinations=$destQuery&origins=${origins.latitude},${origins.longitude}&key=$_apiKey'));
    log('${response.body}');
    var responseJson = jsonDecode(response.body);
    List<dynamic> results = responseJson['rows'][0]['elements'];

    int idx = 0;
    int distIndex = -1;
    String distText = '';
    double dist = double.maxFinite;
    for (var r in results) {
      var d = r['distance'];
      var temp = d['value'].toDouble();
      if (temp < dist) {
        dist = temp;
        distIndex = idx;
        distText = r['distance']['text'] as String;
      }
      idx++;
    }
    return (users[distIndex], distText);
  }
}