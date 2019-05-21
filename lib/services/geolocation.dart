import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';

class GeolocationService {

  GeolocationStatus status = GeolocationStatus.unknown;
  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions = LocationOptions(
    accuracy: LocationAccuracy.best,
    distanceFilter: 10,
  );

  LatLng location = new LatLng(0.0000, 0.0000);

  StreamSubscription<Position> _positionStream;
  StreamController trackerStream;
  StreamSubscription<int> _generatorStream;

  //GeolocationService();
  GeolocationService._();
  static final GeolocationService gls = GeolocationService._();

  GeolocationStatus _geolocationStatus;

  Future<GeolocationStatus> get geolocationStatus async {
    if (_geolocationStatus == GeolocationStatus.granted) {

    } else {
      try {
        GeolocationStatus status = await Geolocator().checkGeolocationPermissionStatus();
        if (status == GeolocationStatus.granted) {
          _geolocationStatus = status;
        }
      } catch (e) {

      }
    }
  }


  Future<LatLng>getLocation() async {
    if (_geolocationStatus == GeolocationStatus.denied) {
      Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

      location.latitude = position.latitude;
      location.longitude = position.longitude;
      return location;
    } else {
      return null;
    }
  }

  Future<LatLng> simpleLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    location.latitude = position.latitude;
    location.longitude = position.longitude;
    return location;
  }


  /// check permission access to geolocation
  /// updata map position to current position
  checkPermissions() async {
    try {
      GeolocationStatus status =
      await Geolocator().checkGeolocationPermissionStatus();
      if (status == GeolocationStatus.granted) {
       // getLocation();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  String latLngToJson(LatLng latlng) {
    var latlngObj = { "lat": latlng.latitude, "lon": latlng.longitude };
    var latlngJson = jsonEncode(latlngObj);
    return  json.encode(latlngJson);
  }


  LatLng fromLatlngJson(String latlng) {
    var latlngJson = jsonDecode(latlng);
    return LatLng(double.parse(latlngJson["lat"]), double.parse(latlngJson["lon"]));
  }


  subscribeToPositionStream( [StreamController streamToParent]) {
    trackerStream = streamToParent;
    _positionStream = geolocator.getPositionStream(locationOptions)
        .listen((Position _position) {
      print(_position == null ? 'Unknown' : _position.latitude.toString() + ', ' + _position.longitude.toString());
      if (_position != null) {
        if ( streamToParent == null ) {
          //_trackingPoints.add(LatLng(_position.latitude, _position.longitude));
        } else {
          trackerStream.add(_position);
        }
        //

      }
    });
  }


  unsubcribeToPositionStream() {
    if (_positionStream != null ) {
      _positionStream.cancel();
    }
  }

  /// generate stream events
  streamGenerator( StreamController streamToParent ) {
    trackerStream = streamToParent;

    _generatorStream = asynchronousTo(10).listen((i) {
      print("generatet: $i");
    });
  }

  Stream<int> asynchronousTo(int n ) async* {
    int k = 0;
    while (k < n) {
      yield k++;
      await Future.delayed(const Duration(seconds: 1), () {
        print(k);
      });

    }
  }

}

//  getLocation() async {
//    switch (status) {
//      case GeolocationStatus.granted :
//        break;
//      case GeolocationStatus.denied :
//        break;
//      case GeolocationStatus.unknown :
//        checkPermissions();
//        break;
//      case GeolocationStatus.disabled :
//        break;
//      case GeolocationStatus.restricted :
//        break;
//    }
//
//    if (status == GeolocationStatus.unknown) {
//      checkPermissions();
//    }
//    Position position = await Geolocator()
//        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
//
//    location.latitude = position.latitude;
//    location.longitude = position.longitude;
//
//  }
