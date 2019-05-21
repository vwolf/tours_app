
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:latlong/latlong.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database.dart';
import '../database/models/tour.dart';
import '../database/models/tourCoord.dart';
import '../database/models/tourItem.dart';
import '../xml/gpx_parser.dart';
import '../xml/read_file.dart';
import '../services/geolocation.dart';

/// Provide current tour properties
/// Database service
/// Path from *.gpx file
class TourServices {
  final Tour tour;

  TourServices(this.tour);

  GpxFileData gpxFileData = GpxFileData();
  List<TourCoord> trackPoints;
  List<LatLng> trackLatlngPoints = [];
  TourCoord markerSelected;

  /// Read file and parse into TourGpxData
  /// Convert GpxCoords to LatLng
  /// path: path to file
  Future<TourGpxData> getTrack(String path) async {
    // read file
    final fc = await ReadFile().readFile(path);
    // print(fc);

    // parse file
    gpxFileData = await new GpxParser(fc).parseData();
    print(gpxFileData.gpxCoords.length);
    // create LatLng points for markers
    gpxFileData.coordsToLatlng();
  }


  /// Read table 'tourname_+ track
  /// Put into _trackPoints list
  /// If no trackPoints start with blank tour
  /// 1. set start coordinates of tour
  /// Try tour.coords, then try geolocation.currentPosition
  Future<bool> getDatabaseData() async {
    List<TourCoord> coords = await DBProvider.db.getTourCoords(tour.track);
    if (coords.length > 0) {
      print("Coords in ${tour.track}: ${coords.length}");
      trackPoints = coords.toList();
      /// make list with LatLng points
      coordsToLatlng(trackPoints);
      return true;
    } else {
      trackPoints = [];
      if (tour.coords != null) {
        /// add tour.coords as first point to trackPoints
        var startCoordJson = jsonDecode(tour.coords);
        TourCoord startCoord = TourCoord(
            latitude: double.parse(startCoordJson["lat"]),
            longitude: double.parse(startCoordJson["lon"]));
        trackPoints.add(startCoord);
        coordsToLatlng(trackPoints);
        await addTrackPoint(LatLng(startCoord.latitude, startCoord.longitude));
        return true;

      } else {
        LatLng currentPosition = await GeolocationService.gls.simpleLocation();
        if (currentPosition != null) {
          /// use currentPosition as start coords
          TourCoord startCoord = TourCoord(latitude: currentPosition.latitude,
              longitude: currentPosition.longitude);
          trackPoints.add(startCoord);
          coordsToLatlng(trackPoints);
          /// set tour.coords to startCoord
        }

        /// if still no start coords set default
        trackPoints = coords.toList();
        return true;
      }
    }

  }


  /// convert GpxCoords to LatLng
  coordsToLatlng(List<TourCoord> tourCoordList) {
    trackLatlngPoints = [];
    tourCoordList.forEach((TourCoord f) {
      trackLatlngPoints.add(new LatLng(f.latitude, f.longitude));
    });
  }


  getStartCoord() {
    if (trackLatlngPoints.length > 0) {
      return trackLatlngPoints[0];
    }
    return LatLng(0.0, 0.0);
  }


  /// Add new track point to end of track
  /// Update trackPoints and trackLatLngPoints
  addTrackPoint(LatLng latlng) {
    TourCoord newTourCoord = TourCoord(latitude: latlng.latitude, longitude: latlng.longitude, timestamp: DateTime.now());

    DBProvider.db.addTourCoord(newTourCoord, tour.track);

    trackPoints.add(newTourCoord);
    trackLatlngPoints.add(latlng);
  }

  /// Add TourCoord
  addTourCoord(TourCoord tourCoord, String table) async {
    await DBProvider.db.addTourCoord(tourCoord, table);
  }

  /// To add a new trackpoint at index
  /// Use to add a marker to a path
  /// Update trackPoints and trackLatLngPoints
  addTrackPointAtIndex(LatLng latlng, int index) {
    TourCoord newTourCoord = TourCoord(latitude: latlng.latitude, longitude: latlng.longitude, timestamp: DateTime.now());

    DBProvider.db.insertTourCoords(newTourCoord, tour.track, index + 1);

    trackPoints.insert(index, newTourCoord);
    trackLatlngPoints.insert(index, latlng);
  }



  /// Get index in trackPoint for LatLng
  int getTrackPointIndex(LatLng latlng) {
    int idxForLatLng = trackLatlngPoints.indexOf(latlng);
    if (idxForLatLng >= 0) {
      print("TrackPoint found at index $idxForLatLng");
      return idxForLatLng;
    }
    return null;
  }


  /// Delete trackpoint at index
  /// Special case: first trackpoint, which is also the startPoint
  /// in tour.coords
  deleteTrackPoint(int index) {
    if ( index < trackLatlngPoints.length) {
      int tourCoordId = trackPoints[index].id;
      trackLatlngPoints.removeAt(index);
      trackPoints.removeAt(index);

      DBProvider.db.deleteTourCoord(tourCoordId, tour.track);
    }
  }


  updateTrackPoint(int index, String prop, dynamic val) {
    int id = trackPoints[index].id;
    double speed = 20.00;

    DBProvider.db.updateTourCoord(id, tour.track, prop, val);
  }

  /// get TourItem for TourCoord
  /// Use TourCoord id 
  Future getItem(int trackPointIdx) async {
    int tourCoordId = trackPoints[trackPointIdx].id;
    var  item = await DBProvider.db.getTourItem(tour.items, "markerId", tourCoordId);
    return item;
    if (item.isNotEmpty) {
      return item[0];
    }

  }

  Future getImage() async {

      var image = await ImagePicker.pickImage(
          source: ImageSource.gallery
      );
      print('Selected image is $image.path');
      return image;

//      setState(() {
//        _image = image;
//        // Todo save image to db
//        savedTour.tourImage = _image.path;
//        print(savedTour);
//
//        DBProvider.db.updateTour(savedTour);
//      });
  }

  selectMarker( {trackPointIdx: null} ) {
    if ( trackPointIdx == null ) {
      markerSelected = null;
    } else {
      markerSelected = trackPoints[trackPointIdx];
    }
  }

  /// Save an item
  /// Add item id to marker with id trackPointIdx
  Future saveItem(TourItem newTourItem, int trackPointIdx) async {
    var ret = await DBProvider.db.addTourItem(newTourItem, tour.items);
    print(ret);
    if (ret > 0) {
      updateTrackPoint(trackPointIdx, "item", ret);
    }
  }

  /// Save a item from external source

}

/// Service class for adding point to path
/// Add point between to points on path
class AddPointToPath {

  List<int> pathMarker = [];


  /// add max 2 marker index's to pathMarker list
  /// If index already in list, remove
  int addPathMarker(int markerIdx) {

    bool validate() {

      if (pathMarker.indexOf(markerIdx) >= 0 ) {
        pathMarker.removeAt(pathMarker.indexOf(markerIdx));
        return false;
      }

      if (pathMarker.length == 1 ) {
        if (markerIdx == pathMarker[0] - 1 || markerIdx == pathMarker[0] + 1 ) {
          // ok
          pathMarker.add(markerIdx);
        } else {
          print("Points have to be directly conneted.");
        }
      }

      if ( pathMarker.length > 2 ) {
        print("Only 2 points allowed");
        // if new point + or - of first point then replace pathMarker[1]
      }
      return true;
    }


    pathMarker.length == 0 ? pathMarker.add(markerIdx) : validate();

    return pathMarker.length;
  }


  int removePathMarker(int markerIdx) {
    if (pathMarker.indexOf(markerIdx) >= 0 ) {
      pathMarker.removeAt(pathMarker.indexOf(markerIdx));
    }

    return pathMarker.length;
  }


  int getLastPathMarker() {
    return  max(pathMarker[0], pathMarker[1]);
  }
}

