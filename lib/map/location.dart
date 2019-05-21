/// map with current position
/// full screen
/// Use Streams to communicate between Location and map button layer

/// Here we can create items
///
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

import 'package:geolocator/geolocator.dart';
import 'buttonLayer.dart';

import '../database/database.dart';
import '../database/models/tourItem.dart';

import 'marker_dialog.dart';


class Location extends StatefulWidget {
  Location();

  @override
  _LocationState createState() => _LocationState();
}


class _LocationState extends State<Location> {
  MapController mapController = MapController();

  GeolocationStatus status = GeolocationStatus.unknown;
  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions = LocationOptions(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10
  );
  StreamSubscription<Position> _positionStream;

  List<LatLng> _trackingPoints = [];

  LatLng location = new LatLng(53.0000, 13.2431);
  List<LatLng> markerPoints = [];
  bool _trackingState = false;

  final _formkey = GlobalKey<FormState>();
  final _dialogMarkerNameController = TextEditingController();
  final _dialogMarkerInfoController = TextEditingController();

  String maptilePath;
  // a StreamController can send data to a stream using it's add method
//  StreamController<LocationMapState> _streamController =
//      new StreamController<LocationMapState>();

  StreamController<LocationMapEvents> _streamController =
  new StreamController<LocationMapEvents>();

  String _markerImagePath = "images/bohusleden_1.png";
  AssetImage _markerImage = AssetImage("images/bohusleden_1.png");

  getMarkerImage() {
    if (_markerImagePath == null) {
      return null;
    } else {
      _markerImage = AssetImage(_markerImagePath);
      return _markerImage;
    }
  }

  @override
  initState() {
    super.initState();

//    final maptilePath =  _getPath();
//    print (maptilePath);
//     Future<GeolocationStatus> permission =  checkPermissions();
//     print(permission);
//     if ( permission == GeolocationStatus.granted ) {
//       updateLocation();
//     } else {
//       print("No Permission to use Geolocation");
//     }

    checkPermissions();
    streamSetup();

    _streamController.add(LocationMapEvents.centerOnLocation);
  }

  Future<String> _getPath() async {
    try {

      String fPath = await FilePicker.getFilePath(type: FileType.ANY);
      if ( maptilePath == '') {
        return null;
      }
      print('fPath: ' + fPath);
      return fPath;
    } on Platform catch (e) {
      print("FilePicker Error: $e");
    }

    return null;
  }


  @override
  void dispose() {
    _streamController.close();
    unsubcribeToPositionStream();

    super.dispose();
  }

  streamSetup() {
    _streamController.stream.listen((LocationMapEvents event) {
      onStreamData(event);
    }, onDone: () {
      print("Done");
    }, onError: (error) {
      print(error);
    });
  }

  subscribeToPositionStream() {
    _positionStream = geolocator.getPositionStream(locationOptions)
        .listen((Position _position) {
          print(_position == null ? 'Unknown' : _position.latitude.toString() + ', ' + _position.longitude.toString());
          if (_position != null) {
            _trackingPoints.add(LatLng(_position.latitude, _position.longitude));
          }
        });
  }

  unsubcribeToPositionStream() {
    if (_positionStream != null ) {
      _positionStream.cancel();
    }
  }


  onStreamData(LocationMapEvents event) {
    switch (event) {
      case LocationMapEvents.centerOnLocation:
        print("CenterOnLocation");
        updateLocation();
        break;

      case LocationMapEvents.zoomIn :
        mapController.move(mapController.center, mapController.zoom + 1);
        break;

      case LocationMapEvents.zoomOut:
        mapController.move(mapController.center, mapController.zoom - 1);
        break;

      case LocationMapEvents.trackOn :
        print("LocationMapEvent.trackOn");
        _trackingState = true;
        _mapButtonLayer.setLcState(_trackingState);
        subscribeToPositionStream();
        print("buttonState: ${_mapButtonLayer.lc.myState}");
        break;

      case LocationMapEvents.trackOff :
        print("LocationMapEvent.trackOff");
        _trackingState = false;
        _mapButtonLayer.setLcState(_trackingState);
        unsubcribeToPositionStream();
        print("buttonState: ${_mapButtonLayer.lc.myState}");
        break;

      default: print("Unknown!");

    }
  }

  /// check permission access to geolocation
  /// updata map position to current position
  checkPermissions() async {
    try {
      GeolocationStatus status =
          await Geolocator().checkGeolocationPermissionStatus();
      if (status == GeolocationStatus.granted) {
        updateLocation();
      }
    } catch (e) {
      print(e);
    }
  }

  updateLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    print("updateLocation: $position");
    location.latitude = position.latitude;
    location.longitude = position.longitude;

    mapController.move(location, mapController.zoom);

    LatLng cp = LatLng(position.latitude, position.longitude);
    markerPoints.add(cp);
    setState(() {});
  }


  List<Marker> get markerList => makeMarkerList();

  List<Marker> makeMarkerList() {
    List<Marker> ml = [];
    markerPoints.forEach((mpt) {
      Marker newMarker = Marker(
        width: 60.0,
        height: 60.0,
        point: mpt,
        builder: (ctx) => Container(
                child: new GestureDetector(
              onTap: () {
                simpleDialog("Marker", mpt, _markerImage);
              },
              child: Icon(
                Icons.location_on,
                color: Colors.green,
              ),
            )),
      );
      ml.add(newMarker);
    });
    return ml;
  }

  _handleTap(LatLng latlng) {
    setState(() {
      // markerPoints.add(latlng);
      //bottomSheet();
      simpleDialog("Some Marker", latlng, _markerImage);
    });
  }

  MapButtonLayer _mapButtonLayer = MapButtonLayer();

  // listen to stream - events in map button layer

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Position"),
      ),
      body: Column(children: <Widget>[
        new Flexible(
//            child: Text('in flexible'),
          child: new FlutterMap(
              mapController: mapController,
              options: new MapOptions(
                center: location,
                zoom: 13,
                minZoom: 13,
                maxZoom: 18,
                onTap: _handleTap,
                plugins: [
                  _mapButtonLayer,
                ],
              ),
              layers: [
                new TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                new MapButtonLayerOptions(
                    streamController: _streamController),
                new MarkerLayerOptions(
                  markers: markerList,
                ),
              ]),
        ),
      ]),
    );
  }


  simpleDialog(String title, LatLng latlng, AssetImage assetImage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MarkerDialog(title, latlng);
      }
    );
  }

//  simpleDialog(String title, LatLng latlng, AssetImage assetImage) {
//    _dialogMarkerNameController.text = "Marker";
//    _dialogMarkerInfoController.text = "Info";
//
//    showDialog(
//        context: context,
//        builder: (BuildContext context) {
//          return SimpleDialog(
//            //title: Text(title),
//            children: <Widget>[
//              Padding(
//                padding: EdgeInsets.only(left: 12.0, right: 12.0),
//                child: TextFormField(
//                  controller: _dialogMarkerNameController,
//                  keyboardType: TextInputType.text,
//                  textInputAction: TextInputAction.done,
//                  //initialValue: "Marker",
//                  decoration: InputDecoration(
//                      labelText: 'Enter marker name'
//                  ),
//                ),
//              ),
//
//              Padding(
//                padding: EdgeInsets.only(top: 6.0, left: 12.0, right: 12.0),
//                child: Text(
//                    "(${latlng.latitude}, ${latlng.longitude})",
//                          style: TextStyle(
//                              fontSize: 12.0)
//                ),
//              ),
//
//              Padding(
//                padding: EdgeInsets.only(left: 12.0, right: 12.0),
//                child: TextField(
//                  controller: _dialogMarkerInfoController,
//                  keyboardType: TextInputType.text,
//                  maxLines: null,
//                  decoration: InputDecoration(
//                    labelText: "Marker Infos",
//                  ),
//                ) ,
//              ),
////              DialogImageSection(),
//              Padding(
//                padding: EdgeInsets.only(top:4.0, left: 12.0, right: 12.0),
//                child: SimpleDialogOption(
//                  child: Row(
//                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                    children: <Widget>[
//                      Column(
//                        children: <Widget>[
//                          IconButton(
//                            icon: Icon(
//                              Icons.image,
//                              color: Colors.white,
//                              ),
//                            onPressed: () {
//                              addImage();
//                            },
//                          ),
//                          Container(
//                            margin: const EdgeInsets.only(top: 6.0),
//                            child: Text(
//                              "Add Image",
//                              style: TextStyle(
//                                fontSize: 12.0,
//                                fontWeight: FontWeight.w400,
//                                color: Colors.white,
//                              ),
//                            ),
//                          ),
//                        ],
//                      ),
//                      Column(
//                        children: <Widget>[
//                          IconButton(
//                            icon: Icon(
//                              Icons.camera,
//                              color: Colors.white,
//                            ),
//                            onPressed: () {
//                              takePicture();
//                            },
//                          ),
//                          Container(
//                            margin: const EdgeInsets.only(top: 4.0),
//                            child: Text(
//                              "Take Picture",
//                              style: TextStyle(
//                                fontSize: 12.0,
//                                fontWeight: FontWeight.w400,
//                                color: Colors.white,
//                              ),
//                            ),
//                          ),
//                        ],
//                      ),
//                    ],
//                  ),
//                )
//              ),
//
//              Divider(
//                height: 8.0,
//                color: Colors.white70,
//              ),
//              new MarkerImages(markerImages: _markerImage),
////              markerImage,
////              Container(
////                height: 50.0,
////                alignment: Alignment.center,
////                decoration: BoxDecoration(
////                  shape: BoxShape.rectangle,
////                  image: DecorationImage(
////                      image: assetImage,
////                      fit: BoxFit.fitHeight
////                  ),
////                ),
////              ),
//              Row(
//                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                children: <Widget>[
//                  IconButton(
//                    icon: Icon(Icons.save),
//                    onPressed: () {
//                      saveMarker(latlng);
//                      Navigator.of(context).pop('');},
//                  ),
//                  IconButton(
//                    icon: Icon(Icons.cancel),
//                    onPressed: () {
//                      Navigator.of(context).pop('');
//                    },
//                  )
//                ],
//              )
//
//            ],
//          );
//        });
//
//  }

//  Widget get markerImage {
//    if( _markerImagePath == null ) {
//      return Container(
//        height: 5.0,
//      );
//    } else {
//      return Container(
//        height: 50.0,
//        decoration: BoxDecoration(
//          shape: BoxShape.rectangle,
//          image: DecorationImage(
//              fit: BoxFit.fitHeight,
//              image: getMarkerImage()
//          ),
//        ),
//      );
//    }
//
//  }

  saveMarker(LatLng latlng) {
    print('saveMarker()');
    print(_dialogMarkerNameController.text);
    print(_dialogMarkerInfoController.text);
    print( latlng);

    TourItem tourItem = TourItem(name: _dialogMarkerNameController.text);
    DBProvider.db.addTourItem(tourItem, "noTourItems");

  }

  addImage() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.gallery);

    print("Selected image: ${image.path}");
    _markerImagePath = image.path;
    _markerImage = await AssetImage(_markerImagePath);
    setState(() {

    });

  }


  takePicture() async {
    var image = await ImagePicker.pickImage(
        source: ImageSource.camera);

    print("imagetaken: ${image.path}");
  }


  bottomSheet() {
    showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Add text or image to marker',
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
              new ListTile(
                leading: new Icon(Icons.music_note),
                title: new Text('Music'),
                onTap: () => print("bottomSheet"),
              ),
              new ListTile(
                leading: new Icon(Icons.photo_album),
                title: new Text('Photos'),
                onTap: () => print("bottomSheet"),
              ),
              new ListTile(
                leading: new Icon(Icons.videocam),
                title: new Text('Video'),
                onTap: () => print("bottomSheet"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Text("ADD"),
                    onPressed: () {},
                  ),
                  RaisedButton(
                    child: Text("CANCEL"),
                    onPressed: () {},
                  )
                ],
              )
            ],
          );
        });
  }

  mapButtonTap() {
    print('mapButtonTap');
  }

}






class LocationMapState {
  final bool isInitial;
  final bool isUpdating;
  final bool isZoomIn;
  final bool isZoomOut;

  LocationMapState.initial(
      {this.isInitial = true,
      this.isUpdating = false,
      this.isZoomIn = false,
      this.isZoomOut = false});

  LocationMapState.updating(
      {this.isInitial = false,
      this.isUpdating = true,
      this.isZoomIn = false,
      this.isZoomOut = false});

  LocationMapState.zoomIn(
      {this.isInitial = false,
      this.isUpdating = false,
      this.isZoomIn = true,
      this.isZoomOut = false});

  LocationMapState.zoomOut(
      {this.isInitial = false,
      this.isUpdating = false,
      this.isZoomIn = false,
      this.isZoomOut = true});
}


/// row add image buttons and image row

class DialogImageSection extends StatefulWidget {

  @override
  _DialogImageSectionState createState() => new _DialogImageSectionState();
}


class _DialogImageSectionState extends State<DialogImageSection> {

  @override
  void initState() {
    super.initState();
  }

  addImage() {}
  takePicture() {}

  _getContent() {
    return (
        Padding(
          padding: EdgeInsets.only(top:4.0, left: 12.0, right: 12.0),
            child: SimpleDialogOption(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.image,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    addImage();
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "Add Image",
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.camera,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    takePicture();
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Take Picture",
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

      ),
    )
    );
  }


  @override
  Widget build(BuildContext context) {
    return _getContent();
  }
}



class MarkerImages extends StatefulWidget {
  MarkerImages({
    Key key,
    this.markerImages
}): super(key: key);

  final AssetImage markerImages;

  @override
  _MarkerImagesState createState() => new _MarkerImagesState();
}



class _MarkerImagesState extends State<MarkerImages> {

  @override
  void initState() {
    super.initState();
  }

  _getContent() {

    return Container(
      height: 50.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
            image: DecorationImage(
              image: widget.markerImages,
              fit: BoxFit.fitHeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _getContent();
  }
}


//Container(
//                height: 50.0,
//                alignment: Alignment.center,
//                decoration: BoxDecoration(
//                  shape: BoxShape.rectangle,
//                  image: DecorationImage(
//                      image: assetImage,
//                      fit: BoxFit.fitHeight
//                  ),
//                ),
//              ),