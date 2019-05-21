/**
 * A tour can have following sources for a path
 * gpx path file
 * Db table TourTrack_+ tourname
 * If gpxTrack then use it
 * Are there data in database?
 * Yes: send to TourGpxData
 *
 */

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'database/database.dart';
import 'database/models/tour.dart';
import 'tour_new.dart';
import 'map/tourmap.dart';
import './tour/tour_service.dart';

/// Display a tour.
/// Set or change tour options.
/// Tour map: use TourMap in map directory
/// Options: start gps coord set?
/// tour: Tour
class TourDetailPage extends StatefulWidget {
  final Tour tour;
  TourDetailPage(this.tour);

  @override
  _TourDetailPageState createState() => _TourDetailPageState();
}

/// * mapFullScreen: bool
/// * _coords: List<TourCoord>,
class _TourDetailPageState extends State<TourDetailPage> {
  /// communication with map via streams
  StreamController<StreamMsg> _streamController =
      new StreamController.broadcast();

  /// Get a map instance and the service for map (TourServices)
  TourMap get _tourMap => TourMap(_streamController);
  TourServices tourServices;

  bool _mapFullscreen = true;
  bool _trackingEnabled = false;
  bool _currentPosition = false;
  bool _displayGpxTileTrack = false;

  /// action after tap on map _tourMap
  MapTapAction _mapTapAction = MapTapAction.NOACTION;

  @override
  void initState() {
    super.initState();

    initStreamController();

    tourServices = TourServices(widget.tour);

    /// If path to gpx file exist, read gpx file
    String tourGpxPath = widget.tour.getOption("_gpxFilePath");
    if (tourGpxPath != null) {
      getFileData(tourGpxPath);
    }

    getDatabaseData();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }


  /// Initialize _streamController subscription to listen for StreamMsg and
  /// handle in onMapEvent()
  initStreamController() {
    _streamController.stream.listen((StreamMsg streamMsg) {
      onMapEvent(streamMsg);
    }, onDone: () {
      print("Done streamMsg");
    }, onError: (error) {
      print("StreamController Error $error");
    });
  }


  /// load data from gpx file
  getFileData(filePath) async {
    var result = await tourServices.getTrack(filePath);
    _streamController.add(new StreamMsg("gpxFileData", true));
    _displayGpxTileTrack = true;
    setState(() {
      gpxFilePathDisplay;
    });
  }

  /// get tour data from database
  getDatabaseData() async {
    var result = await tourServices.getDatabaseData();
    print("getData $result");
    _streamController.add(new StreamMsg("newDefaultCoord", true));
  }



  /// Handle taps on map, depending on options
  /// StreamMsg comes from TourMap
  onMapEvent(StreamMsg streamMsg) {
    switch (streamMsg.type) {
      case "tapOnMap":
        // msg of tapOnMap has to be of type LatLng
        print("onMapEvent.tapOnMap at ${streamMsg.msg}");
        // tourServices.trackPoints.add(streamMsg.msg);
        // action depending on -_mapTapAction
        if (_mapTapAction == MapTapAction.ADD_MARKER ) {
          tourServices.addTrackPoint(streamMsg.msg);
        }

        if (_mapTapAction == MapTapAction.ADD_ITEM ) {
          /// add to tour item table
          ///
        }

        if (_mapTapAction == MapTapAction.SELECT_MARKER) {

        }

        if (_mapTapAction == MapTapAction.ADD_PATHMARKER) {

        }

        break;

      default:
        print("Unkown event");
    }
  }


  set _tourMap(tourMap) {
    print("set _tourMap");
    setState(() {
      _tourMap;
    });
  }

  // is there a tourImage?
  // no tourImage, use image AssetImage
  getTourImage() {
    print('tour image $widget.tour.tourImage');
    print(tourServices.tour.tourImage);
    if (tourServices.tour.tourImage == null) {
      //return AssetImage('images/bohusleden_1.png');
      return null;
    } else {
      return AssetImage(tourServices.tour.tourImage);
    }
  }

  // select image for tour and save to db
  setTourImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    print('Selected image is $image.path');

    widget.tour.tourImage = image.path;

    DBProvider.db.updateTour(widget.tour);
  }

  /// Toggle each action, if action is on then NOACTION
  /// If different action then set to action
  setMapTapAction(MapTapAction action) {
    if ( _mapTapAction == MapTapAction.NOACTION || _mapTapAction != action ) {
      switch (action) {
        case MapTapAction.ADD_MARKER :
          break;
        case MapTapAction.ADD_ITEM:
          break;
        case MapTapAction.MOVE_MARKER:
          break;
        case MapTapAction.SELECT_MARKER:
          break;
        case MapTapAction.ADD_PATHMARKER:
          break;
        case MapTapAction.NOACTION :
          break;
      }

      _mapTapAction = action;
      _streamController.add(new StreamMsg('mapTapAction', _mapTapAction));
    } else {

      _mapTapAction = MapTapAction.NOACTION;
      _streamController.add(new StreamMsg('mapTapAction', _mapTapAction));
    }
    setState(() {});
  }


//  toggleMapTapAction(MapTapAction actionTo) {
//    if ( actionTo != _mapTapAction) {
//      _mapTapAction = actionTo;
//
//      if (_mapTapAction == MapTapAction.SELECT_MARKER) {
//        enableAddToPath();
//      }
//    } else {
//      _mapTapAction = MapTapAction.ADD_MARKER;
//      _streamController.add(new StreamMsg('mapTapAction', _mapTapAction));
//    }
//    setState(() {});
//  }


  toggleTracking() {
    _trackingEnabled = !_trackingEnabled;
    setState(() {});
    _streamController.add(new StreamMsg("toggleTracker", _trackingEnabled));
  }

  enableAddToPath() {
    _streamController.add(new StreamMsg("mapTapAction", _mapTapAction));
  }

  /// Toggle display of current position
  toggleCurrentPosition() {
    _currentPosition = !_currentPosition;
    setState(() {});
    _streamController.add(new StreamMsg("toggleCurrentPosition", _currentPosition));
  }


  buttonrowEvent(label) {
    print('buttonrowevent $label');
    if (label == 'ROUTE') {
      if (widget.tour.options != null) {
        // load gpx track file
        print('gpx filePath: ' + widget.tour.options);
        var tourOptions = json.decode(widget.tour.options);
        var tourGpxPath = tourOptions['_gpxFilePath'];

        if (tourGpxPath != null) {
          tourServices.getTrack(tourGpxPath);
        } else {
          print(" No gpx file path for tour!");
        }
      } else {
        print("No options for tour!");
      }
    }

    if (label == "Location") {
      _streamController.add(new StreamMsg("page", "addCoords"));
    }

    if (label == "HIDE") {
      _mapFullscreen = true;
      setState(() {});
    }

    if (label == "EDIT") {
      Navigator.of(context).push(new MaterialPageRoute(builder: (context) {
        return new TourNewPage(widget.tour);
      }));
    }
  }



  // if no tourImage set, return IconButton Camera or Gallery
  Widget get tourImage {
    if (!_mapFullscreen) {
      var tourImage = getTourImage();
      if (tourImage == null) {
        return Container(
          child: IconButton(
              icon: Icon(Icons.camera_enhance), onPressed: setTourImage),
        );
      } else {}
      return Container(
        height: 150.0,
        alignment: Alignment.center,
        //width: 150.0,

        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          boxShadow: [
            const BoxShadow(
                offset: const Offset(1.0, 2.0),
                blurRadius: 2.0,
                spreadRadius: -1.0,
                color: const Color(0x33000000)),
            const BoxShadow(
                offset: const Offset(2.0, 1.0),
                blurRadius: 3.0,
                spreadRadius: 0.0,
                color: const Color(0x24000000)),
            const BoxShadow(
                offset: const Offset(3.0, 1.0),
                blurRadius: 4.0,
                spreadRadius: 2.0,
                color: const Color(0x1F000000)),
          ],
          // add image to container background
          image: DecorationImage(
            fit: BoxFit.fitHeight,
            //image: AssetImage('images/bohusleden_1.png'),
            //image: AssetImage('images/${widget.tour.tourImage}'),
            image: getTourImage(),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget get titleRow {
    if (!_mapFullscreen) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          widget.tour.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
      );
    } else {
      return Container(
//          alignment: Alignment.centerLeft,
//          padding: const EdgeInsets.only(left: 12.0, top: 4.0),
//          child: Row(
//            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//            children: <Widget>[
//              Text(
//                widget.tour.name,
//                style: TextStyle(
//                  fontWeight: FontWeight.w400,
//                  fontSize: 18.0,
//                ),
//              ),
//              IconButton(
//                icon: Icon(Icons.arrow_downward),
//                onPressed: () {
//                  setState(() {
//                    _mapFullscreen = false;
//                  });
//                },
//              )
//            ],
//          )
//        child: Text(widget.tour.name,
//          style: TextStyle(
//            fontWeight: FontWeight.w400,
//            fontSize: 18.0,
//          ),
//        ),
          );
    }
  }

  Widget get buttonRow {
    if (!_mapFullscreen) {
      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            buildButtonColumn(Icons.near_me, 'ROUTE'),
            buildButtonColumn(Icons.add_location, 'Location'),
            buildButtonColumn(Icons.edit, 'EDIT'),
            buildButtonColumn(Icons.arrow_upward, 'HIDE'),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Column buildButtonColumn(IconData icon, String label) {
    //Color color = Theme.of(context).primaryColor;
    Color color = Colors.white70;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
            icon: Icon(
              icon,
              color: color,
            ),
            //onPressed: buttonrowEvent,
            onPressed: () {
              buttonrowEvent(label);
            }),
        //Icon(icon, color: color),
        Container(
          margin: const EdgeInsets.only(top: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  /// Drawer item for path from gpx file
  Widget get gpxFilePathDisplay {
    if ( tourServices.gpxFileData.gpxLatlng.length > 0 ) {
      return ListTile(
          title: Text("Show gpx file track"),
          trailing: Icon(_displayGpxTileTrack == true ? Icons.check : Icons.not_interested),
          onTap: () {
            _displayGpxTileTrack = !_displayGpxTileTrack;
            _streamController.add(new StreamMsg('displayGpxTileTrack', _displayGpxTileTrack));
            setState(() {});
          }
      );
    } else {
      return Container();
    }
  }


  @override
  Widget build(BuildContext context) {
    print('mainImage ${widget.tour.tourImage}');
    print('tourName ${widget.tour.location}');
    return new TourInherited(
      //tourGpxData: _tourGpxData,
      tourServices: tourServices,
      child: new Scaffold(
        backgroundColor: Colors.black87,
        appBar: new AppBar(
          backgroundColor: Colors.black87,
          title: new Text('Tour ${widget.tour.name}'),
        ),
        endDrawer: new Drawer(
          child: ListView(
            children: <Widget>[
              const DrawerHeader(
                child: const Center(
                  child: const Text("Tour Settings"),
                ),
              ),
              ListTile(
                title: const Text("Set Start position to current location?"),
              ),
              ListTile(
                  title: Text("Add marker at tap"),
                  trailing: Icon(_mapTapAction == MapTapAction.ADD_MARKER
                      ? Icons.check
                      : Icons.not_interested),
                  onTap: () {
                    setMapTapAction(MapTapAction.ADD_MARKER);
                    Navigator.pop(context);
                  }),
              ListTile(
                  title: Text("Add item at tap"),
                  trailing: Icon(_mapTapAction == MapTapAction.ADD_ITEM
                      ? Icons.check
                      : Icons.not_interested),
                  onTap: () {
                    setMapTapAction(MapTapAction.ADD_ITEM);
                  }),
              ListTile(
                title: Text("Add marker to path"),
                trailing: Icon( _mapTapAction == MapTapAction.SELECT_MARKER ? Icons.check : Icons.not_interested),
                onTap: () {
                  setMapTapAction(MapTapAction.SELECT_MARKER);
                }
              ),
              gpxFilePathDisplay,
              ListTile(
                title: Text("Show current Position"),
                trailing: Icon(_currentPosition == true ? Icons.check : Icons.not_interested),
                onTap: () {},
              ),
              ListTile(
                  title: Text("Tracking enabled"),
                  trailing: Icon(_trackingEnabled == true ? Icons.check : Icons.not_interested),
                  onTap: () {
                    toggleTracking();
                  }
              ),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            tourImage,
            titleRow,
            buttonRow,
            _tourMap,
          ],
        ),
      ),
    );
  }
}

class TourInherited extends InheritedWidget {
  TourInherited({
    Key key,
    @required this.tourServices,
    @required Widget child,
  })  : assert(tourServices != null),
        assert(child != null),
        super(key: key, child: child);


  final TourServices tourServices;

  static TourInherited of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(TourInherited) as TourInherited;
  }

  @override
  bool updateShouldNotify(TourInherited old) {
    print("updateShouldNotify");
    //return tourGpxData != old.tourGpxData;
    return tourServices != old.tourServices;
  }
}


class StreamMsg {
  String type;
  var msg;

  StreamMsg(this.type, this.msg);
}
