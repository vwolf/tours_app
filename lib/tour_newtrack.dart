/// Read *.gpx files from local storage
/// ToDo read from remote
/// ToDo read from sqllite
///

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';

import 'package:file_picker/file_picker.dart';
import 'xml/gpx_parser.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

import 'xml/read_file.dart';


class TourNewTrack extends StatefulWidget {
  @override
  _TourNewTrackState createState() => _TourNewTrackState();
}

class _TourNewTrackState extends State<TourNewTrack> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String _filePath;
  TourGpxData tourGpxData = new TourGpxData();

  MapController mapController;

  var points = <LatLng>[
    new LatLng(59.923229, 15.040512),
    new LatLng(59.9229726, 15.041148),
    new LatLng(59.9228518, 15.041509),
    new LatLng(59.921619, 15.0431753),
    new LatLng(59.9208435, 15.0442863),
  ];
  //lat="59.9204458" lon="15.0445243"
  //LatLng _mapCenter;

//  AnchorPos anchorPos;
  bool _offlineModus = false;
  String _maptilePath = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";

  void initState() {
    super.initState();
    mapController = new MapController();
  }
//
//  void _setAnchorAlignPos(AnchorPos alignOpt) {
//    setState(() {
//      anchorPos = AnchorPos.align(alignOpt);
//    });
//  }

  String get tourname {
    if (tourGpxData.tour_name != "") {
      return tourGpxData.tour_name;
    } else {
      return "no kown yet";
    }
  }

  switchOnlineModus() {

    setState(() {
      _offlineModus = !_offlineModus;

      if ( _offlineModus == true) {
        _maptilePath = "/storage/emulated/0/Download/gransee_zedenick/{z}/{x}/{y}.png";
      } else {
        _maptilePath = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
      }
    });
  }

  void getFilePath() async {
    try {
      String filePath = await FilePicker.getFilePath(type: FileType.ANY);
      //String filePath = await FilePicker.getFilePath(type: FileType.CUSTOM, fileExtension: 'pdf');
      if (filePath == '') {
        return;
      }
      print("File path: " + filePath);
      setState(() {
        this._filePath = filePath;
      });
    } on Platform catch (e) {
      print(e);
    }
  }

  getFileContents() {
    Future <List> fileContents = ReadFile().getFilePath();
    print(fileContents);
  }


  /// send file contents to parser
  Future<int> loadFile() async {
    try {
      String contents = await File(this._filePath).readAsString();
      print(contents);
      tourGpxData = await new GpxParser(contents).parseData();
      setState(() {
        print('parseData finished: ');
        print(tourGpxData.gpxCoords.length);
        LatLng newLatLon = new LatLng(
            tourGpxData.gpxCoords[0].lat,
            tourGpxData.gpxCoords[0].lon);
        print(newLatLon);
        //_mapCenter =
        _mapCenter = newLatLon;
        //setMapCenter(newLatLon);
        print('new _mapCenter');
      });
    } catch (e) {
      return null;
    }
  }

  Future<String> get _externalPath async {
    final directory = await getExternalStorageDirectory();
    return directory.path;
  }

  /// Openlayers map stuff
  /// _mapCenter
  LatLng get _mapCenter {
    return new LatLng(53.0000, 13.2431);
  }

  set _mapCenter(latlon) {}

  newPos() {
    _mapCenter = new LatLng(59.92, 15.04);
    //mapController.move(new LatLng(59.92, 15.04), 12.0);
    mapController.move(new LatLng(59.92, 15.04), mapController.zoom + 1.0);
  }

  addPos() {
    setState(() {
      var newLatLng = new LatLng( 59.9204458, 15.0445243 );
      if ( !points.contains(newLatLng ) ) {
        points.add(newLatLng);
      } else {
        print("Marker already exists");
      }
    });

  }


  @override
  Widget build(BuildContext context) {
    var markers = <Marker>[
      new Marker(
        width: 40.0,
        height: 40.0,
        point: new LatLng(51.5, -0.09),
        builder: (ctx) => new Container(
          child: new GestureDetector(
            onTap: () {
              print("Tap on marker");
              _scaffoldKey.currentState.showSnackBar(new SnackBar(
                  content: new Text("Tapped on blue FlutterLogo Marker"),
              ));
            },

            child: new Icon(
              Icons.location_on,
              color: Colors.red,
            ),
          ),
        ),
      ),
      new Marker(
        width: 80.0,
        height: 80.0,
        point: new LatLng(53.3498, -6.2603),
        builder: (ctx) => new Container(
          child: IconButton(
            icon: Icon(Icons.location_on),
            color: Colors.green,
            onPressed: () {
              print("Marker tapped");
            },
          ),
        ),
      ),
    ];

    return new Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Load Track"),
      ),
      endDrawer: new Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: const Center(
                child: const Text("Load Track Settings"),
              ),
            ),
            new ListTile(
              leading: Icon(Icons.check_box),
              title: _offlineModus == true ? const Text("Offline Modus") : const Text("Online Modus"),
              onTap: () {
                  switchOnlineModus();
              }
            ),
            new ListTile(
                leading: Icon(Icons.offline_pin),
                title: const Text("Offline Modus"),
            ),
          ],
        )
      ),
      body: Column(
        children: <Widget>[
//          Padding(
//            padding: EdgeInsets.all(24.0),
//            child: _filePath == null
//                ? new Text('No file selected')
//                : new Text(_filePath),
//          ),
//          new Center(
//             child: _filePath == null ? new Text('No file selected') : new Text(_filePath),
//          ),

//          new Center(
//              child: RaisedButton(
//                  child: Text('Load File'),
//                  color: Colors.blue,
//                  onPressed: loadFile)),

//          Padding(
//            padding: EdgeInsets.all(24.0),
//            child: Text(tourname),
//          ),
//          new Row(
//            children: <Widget>[
//              RaisedButton(
//                child: Text("new Pos"),
//                color: Colors.blue,
//                onPressed: newPos,
//              ),
//              new RaisedButton(
//                  child: new Text("Add Pos"),
//                  onPressed: addPos
//              ),
//            ],
//          ),

          //new Text(tourname),
          new Flexible(
            child: new FlutterMap(
              mapController: mapController,
              options: new MapOptions(
                center: _mapCenter,
                zoom: 13.0,
                maxZoom: 18.0,
                minZoom: 13.0,
              ),
              layers: [
                new TileLayerOptions(
                  offlineMode: _offlineModus,
                  maxZoom: 18,
                    urlTemplate: _maptilePath,
//                  urlTemplate: "/storage/emulated/0/Download/gransee_zedenick/{z}/{x}/{y}.png",
                    //urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                ),

                new PolylineLayerOptions(
                  polylines: [
                    new Polyline(
                      points: points,
                      strokeWidth: 2.0,
                      color: Colors.blueAccent,
                    ),
                  ]
                ),

                new MarkerLayerOptions(markers: _markersList),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: new FloatingActionButton(
        key: UniqueKey(),
        onPressed: getFilePath,
        tooltip: 'Select file',
        child: new Icon(Icons.sd_storage),
      ),
    );
  }

//  Widget get flutterMap {
//    return new Flexible(
//      child: new FlutterMap(
//        mapController: mapController,
//        options: new MapOptions(
//          center: _mapCenter,
//          zoom: 10.0,
//          maxZoom: 18.0,
//          minZoom: 2.0,
//        ),
//        layers: [
//          new TileLayerOptions(
//            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
//            subdomains: ['a', 'b', 'c'],
//          ),
//          new MarkerLayerOptions(markers: markers),
//          new PolylineLayerOptions(
//            polylines: [
//              new Polyline(
//                points: points,
//                strokeWidth: 2.0,
//                color: Colors.blueAccent,
//              ),
//            ]
//          )
//        ],
//      ),
//    );
//  }

  List<Marker> get _markersList {
    List<Marker> ml = [];
    points.forEach((f) {
      var m = new Marker(
          width: 40.0,
          height: 40.0,
          point: f,
          builder: (ctx) => new Container(
            child: new GestureDetector(
              onTap: () {
                print("Marker taped");
                _scaffoldKey.currentState.showSnackBar(new SnackBar(
                  content: new Text("Tapped on blue FlutterLogo Marker"),
                ));
              },

              child: new Icon(
                  Icons.location_on,
                  color: Colors.green,
                ),
              ),
          ),
        );
      ml.add(m);
    });
    return ml;
  }

}
